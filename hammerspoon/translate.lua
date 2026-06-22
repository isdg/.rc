-- ============================================================
--   translate.lua — Spotlight-style translation / dictionary popup
-- ============================================================
-- A centered hs.chooser that translates as you type and lists the main
-- translation plus dictionary alternatives (synonyms grouped by part of
-- speech). Enter / click copies the highlighted entry to the clipboard.
--
-- Direction is auto-detected: Cyrillic input → English, otherwise → Russian.
-- Backend is the public Google translate endpoint (no API key), called over
-- the network. To swap to a different/offline backend (e.g. Apple Translate
-- via `shortcuts run`), replace `fetch()` below — the rest is backend-agnostic.

local M = {}

-- ── config ──────────────────────────────────────────────────
local DEBOUNCE = 0.25 -- seconds to wait after typing stops before translating

-- Cyrillic text → translate to English; anything else → Russian. Lua patterns
-- are byte-based; UTF-8 Cyrillic code points start with bytes 0xD0/0xD1.
local function targetFor(text)
   if text:find("[\208\209]") then
      return "en"
   end
   return "ru"
end

-- ── backend: returns (mainTranslation, dictEntries, detectedSrc) via cb ──
-- dictEntries = { { pos = "noun", terms = {"…","…"} }, ... }
local function fetch(text, cb)
   if not text or text == "" then
      cb(nil)
      return
   end
   local target = targetFor(text)
   local url = "https://translate.googleapis.com/translate_a/single"
      .. "?client=gtx&sl=auto&tl=" .. target
      .. "&dt=t&dt=bd&q=" .. hs.http.encodeForQuery(text)

   hs.http.asyncGet(url, nil, function(status, body)
      if status ~= 200 or not body then
         cb(nil)
         return
      end
      local ok, data = pcall(hs.json.decode, body)
      if not ok or type(data) ~= "table" then
         cb(nil)
         return
      end

      -- data[1]: sentence chunks; concat chunk[1] for the full translation
      local main = ""
      if type(data[1]) == "table" then
         for _, chunk in ipairs(data[1]) do
            if chunk[1] then
               main = main .. chunk[1]
            end
         end
      end

      -- data[2]: dictionary — per part of speech, a list of alternative terms
      local dict = {}
      if type(data[2]) == "table" then
         for _, entry in ipairs(data[2]) do
            local pos = entry[1] or ""
            local terms = {}
            if type(entry[2]) == "table" then
               for _, t in ipairs(entry[2]) do
                  terms[#terms + 1] = t
               end
            end
            if #terms > 0 then
               dict[#dict + 1] = { pos = pos, terms = terms }
            end
         end
      end

      local detected = type(data[3]) == "string" and data[3] or "auto"
      cb(main, dict, detected, target)
   end)
end

-- ── chooser rows ────────────────────────────────────────────
local function rowsFor(main, dict, detected, target)
   local rows = {}
   if main and main ~= "" then
      rows[#rows + 1] = {
         text = main,
         subText = (detected or "auto") .. " → " .. target .. "   (copy)",
         copy = main,
      }
   end
   for _, e in ipairs(dict or {}) do
      rows[#rows + 1] = {
         text = table.concat(e.terms, ", "),
         subText = e.pos,
         copy = e.terms[1],
      }
   end
   if #rows == 0 then
      rows[1] = { text = "no result", subText = "", copy = "" }
   end
   return rows
end

-- ── popup ───────────────────────────────────────────────────
local chooser
local debouncer

local function trim(s)
   return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Translate `q` now and populate the chooser, ignoring stale responses.
local function applyResults(q)
   fetch(q, function(main, dict, detected, target)
      if trim(chooser:query()) ~= q then
         return -- query moved on while the request was in flight
      end
      chooser:choices(rowsFor(main, dict, detected, target))
   end)
end

local function ensureChooser()
   if chooser then
      return chooser
   end
   chooser = hs.chooser.new(function(choice)
      if choice and choice.copy and choice.copy ~= "" then
         hs.pasteboard.setContents(choice.copy)
         hs.alert.show("Copied: " .. choice.copy)
      end
   end)
   chooser:placeholderText("Type a word or phrase to translate…")
   chooser:searchSubText(false)
   chooser:queryChangedCallback(function(q)
      if debouncer then
         debouncer:stop()
      end
      q = trim(q)
      if q == "" then
         chooser:choices({})
         return
      end
      debouncer = hs.timer.doAfter(DEBOUNCE, function()
         applyResults(q)
      end)
   end)
   return chooser
end

function M.bind(mods, key)
   hs.hotkey.bind(mods, key, function()
      local c = ensureChooser()
      c:query("")
      c:choices({})
      c:show()
   end)
end

return M
