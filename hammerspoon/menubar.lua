-- ============================================================
--   menubar — toggle pinned / auto-hidden, keep windows filling
-- ============================================================

local M = {}

local task, pending

local function hidden()
    return (hs.execute("defaults read NSGlobalDomain _HIHideMenuBar 2>/dev/null")):match("1") ~= nil
end

local function maximizedOn(screen)
    local frame, wins = screen:frame(), {}
    for _, w in ipairs(hs.window.visibleWindows()) do
        if w:isStandard() and w:screen():id() == screen:id() and w:frame() == frame then
            wins[#wins + 1] = w
        end
    end
    return wins
end

-- Windows that filled the old usable area get maximized to the new one,
-- once the screen reports the change (polled; gives up after 3s).
function M.toggle()
    local screen = hs.screen.mainScreen()
    local before = screen:frame()
    local wins = maximizedOn(screen)

    task = hs.task.new("/usr/bin/defaults", function()
        hs.distributednotifications.post("AppleInterfaceMenuBarHidingChangedNotification")
    end, { "write", "NSGlobalDomain", "_HIHideMenuBar", "-bool", tostring(not hidden()) })
    task:start()

    if pending then pending:stop() end
    local deadline = hs.timer.secondsSinceEpoch() + 3
    pending = hs.timer.doEvery(0.05, function()
        if screen:frame() == before and hs.timer.secondsSinceEpoch() < deadline then return end
        pending:stop()
        for _, w in ipairs(wins) do w:maximize() end
    end)
end

function M.bind(mods, key)
    hs.hotkey.bind(mods, key, M.toggle)
end

return M
