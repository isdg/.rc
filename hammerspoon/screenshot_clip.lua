-- ============================================================
--   screenshot_clip — auto-copy new screenshots to the clipboard
-- ============================================================
-- macOS's default capture shortcuts (⌘⇧3 / ⌘⇧4) save a PNG to disk; only the
-- ⌃ variants copy to the clipboard. This watches the screenshot save folder and,
-- whenever a fresh screenshot lands, also puts the image on the pasteboard — so
-- you capture the normal way and can paste immediately. The file is kept on disk.
--
-- Naming/localization: matches the default "Screenshot …png" prefix (English).
-- Timing guard: only files modified in the last few seconds, so a folder rescan
-- never re-copies old images.

local M = {}

-- Resolve the screenshot save location, honouring
-- `defaults write com.apple.screencapture location`; falls back to ~/Desktop.
local function screenshotDir()
   local home = os.getenv("HOME")
   local out = hs.execute("defaults read com.apple.screencapture location 2>/dev/null") or ""
   out = out:gsub("%s+$", "")
   if out == "" then return home .. "/Desktop" end
   if out:sub(1, 1) == "~" then out = home .. out:sub(2) end
   return out
end

-- Small top-right toast (hs.alert only centers, so use a tiny canvas instead).
local function toast(text)
   local scr = hs.screen.mainScreen():frame()
   local w, h, margin = 108, 26, 12
   local c = hs.canvas.new({
      x = scr.x + scr.w - w - margin,
      y = scr.y + margin,
      w = w,
      h = h,
   })
   c:appendElements({
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 6, yRadius = 6 },
      fillColor = { alpha = 0.8, red = 0, green = 0, blue = 0 },
   }, {
      type = "text",
      text = text,
      textSize = 12,
      textColor = { white = 1 },
      textAlignment = "center",
      frame = { x = 0, y = 5, w = w, h = h },
   })
   c:level(hs.canvas.windowLevels.overlay)
   c:show()
   hs.timer.doAfter(1.2, function() c:delete() end)
end

local seen = {}

local function handle(files)
   for _, path in ipairs(files) do
      local name = path:match("[^/]+$") or ""
      if name:match("^Screenshot") and name:sub(-4):lower() == ".png" and not seen[path] then
         local attr = hs.fs.attributes(path)
         -- only act on just-created files (avoid re-copying on dir rescans)
         if attr and (os.time() - attr.modification) <= 5 then
            seen[path] = true
            -- the file may still be flushing when the watcher fires; give it a
            -- moment, then copy the image onto the pasteboard.
            hs.timer.doAfter(0.3, function()
               local img = hs.image.imageFromPath(path)
               if img then
                  hs.pasteboard.writeObjects(img)
                  toast("📋 copied")
               end
            end)
         end
      end
   end
end

function M.start()
   M.watcher = hs.pathwatcher.new(screenshotDir(), handle):start()
   return M
end

return M
