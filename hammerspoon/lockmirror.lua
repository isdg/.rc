-- ============================================================
--   lockmirror — lock while the screen stays exactly as it was
-- ============================================================
-- Snapshots every display into legacyScreenSaver's container, where the
-- LockMirror saver (lockmirror/, installed by its module) draws each one,
-- then starts the saver. With the lock set to immediate it is a real lock.

local M = {}

local dir = os.getenv("HOME") .. "/Library/Containers/"
    .. "com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/"

-- Brightening that cancels the screen saver's dimming, tuned by eye per
-- display: exposure in stops, gamma below 1 lifts mid-tones. See Tone.swift.
M.tone = { exposure = 0, gamma = 1 }

-- Snapshots hold whatever was on screen, so none outlive the lock.
local function clear()
    if not hs.fs.attributes(dir) then return end
    for file in hs.fs.dir(dir) do
        if file:match("^lockmirror%-.+%.png$") then
            os.remove(dir .. file)
        end
    end
end

function M.lock()
    clear()
    for _, scr in ipairs(hs.screen.allScreens()) do
        local shot = scr:snapshot()
        if shot then
            shot:saveToFile(dir .. "lockmirror-" .. scr:getUUID() .. ".png")
        end
    end
    hs.plist.write(dir .. "lockmirror-tone.plist", M.tone)
    hs.caffeinate.startScreensaver()
end

-- tone, optional: { exposure = <stops>, gamma = <power> }.
function M.bind(mods, key, tone)
    for k, v in pairs(tone or {}) do M.tone[k] = v end
    clear()
    local w = hs.caffeinate.watcher
    M.watcher = w.new(function(event)
        if event == w.screensDidUnlock or event == w.screensaverDidStop then
            clear()
        end
    end):start()
    hs.hotkey.bind(mods, key, M.lock)
end

return M
