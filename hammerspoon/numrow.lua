-- ============================================================
--   numrow — the home row types the number row under a modifier
-- ============================================================
-- a s d f g h j k l ; sit in the columns of 1 2 3 4 5 6 7 8 9 0.

local M = {}

-- Raw ANSI keycodes, not names: hs.keycodes.map follows the active layout,
-- so with Russian active at load "a" would not resolve. Keycodes are physical.
local ROW = {
    { 0, "1" }, { 1, "2" }, { 2, "3" }, { 3, "4" }, { 5, "5" },
    { 4, "6" }, { 38, "7" }, { 40, "8" }, { 37, "9" }, { 41, "0" },
}

-- Explicit empty flags: the modifiers still held must not ride along, or the
-- app sees Ctrl+Option+1 instead of 1.
local function tap(digit)
    hs.eventtap.event.newKeyEvent({}, digit, true):post()
    hs.eventtap.event.newKeyEvent({}, digit, false):post()
end

function M.bind(mods)
    for _, k in ipairs(ROW) do
        local code, digit = k[1], k[2]
        local fn = function() tap(digit) end
        hs.hotkey.bind(mods, code, fn, nil, fn)
    end
end

return M
