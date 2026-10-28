-- ============================================================
--   lockmirror — lock while the screen stays exactly as it was
-- ============================================================
-- Snapshots every display into legacyScreenSaver's container, where the
-- LockMirror saver (lockmirror/, installed by its module) draws each one,
-- then starts the saver. With the lock set to immediate it is a real lock.

local M = {}

local dir = os.getenv("HOME") .. "/Library/Containers/"
    .. "com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/"

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
    hs.caffeinate.startScreensaver()
end

function M.bind(mods, key)
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
