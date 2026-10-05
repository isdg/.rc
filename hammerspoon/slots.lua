-- ============================================================
--  slots — window per hotkey, focus + maximize, cycle, last
-- ============================================================
-- Windows stay maximized on one Space instead of native fullscreen, whose
-- per-window Spaces force macOS's slide animation on every switch.

local M = {}

hs.window.animationDuration = 0

local STORE = "slots"
local slots = {} -- key -> { app = bundleID, win = windowID or nil }

local function save()
    hs.settings.set(STORE, slots)
end

local function claimedElsewhere(key, id)
    for k, s in pairs(slots) do
        if k ~= key and s.win == id then return true end
    end
    return false
end

local function windowsOf(app)
    local wins = {}
    for _, w in ipairs(app:allWindows()) do
        if w:isStandard() then wins[#wins + 1] = w end
    end
    table.sort(wins, function(a, b) return a:id() < b:id() end)
    return wins
end

local pending -- held so the timer isn't garbage-collected; one wait at a time

-- Run fn once pred holds, polling every 50ms; give up after 3s.
local function when(pred, fn)
    if pending then pending:stop() end
    local deadline = hs.timer.secondsSinceEpoch() + 3
    pending = hs.timer.doUntil(function()
        return pending == nil or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        if pred() then
            pending:stop()
            pending = nil
            fn()
        end
    end, 0.05)
end

-- Native fullscreen is the slow path this module exists to avoid: leave it.
local function maximize(win)
    if not win:isFullScreen() then
        win:maximize()
        return
    end
    win:setFullScreen(false)
    when(function() return not win:isFullScreen() end, function() win:maximize() end)
end

local function show(win)
    if win:isMinimized() then win:unminimize() end
    win:focus()
    maximize(win)
end

-- A window on another Space is invisible to allWindows; once macOS has
-- switched there, pull whatever got focused back out of fullscreen.
local function reopen(bundleID)
    hs.task.new("/usr/bin/open", nil, { "-b", bundleID }):start()
    when(function()
        local w = hs.window.focusedWindow()
        return w and w:application():bundleID() == bundleID
    end, function() maximize(hs.window.focusedWindow()) end)
end

-- Next window after index `from` (wrapping) that no other slot holds; nil if none.
local function nextFree(key, wins, from)
    for step = 1, #wins do
        local w = wins[(from + step - 1) % #wins + 1]
        if not claimedElsewhere(key, w:id()) then return w end
    end
end

local function jump(key)
    local slot = slots[key]
    if not slot then return end
    local app = hs.application.get(slot.app)
    local wins = app and windowsOf(app) or {}
    if #wins == 0 then
        -- `open` sends a reopen event, so a windowless app (Finder) gets a window
        reopen(slot.app)
        return
    end

    local focused = hs.window.focusedWindow()
    local target
    for i, w in ipairs(wins) do
        if w:id() == slot.win then
            target = w
            if focused and focused:id() == w:id() then
                target = nextFree(key, wins, i) or w
            end
            break
        end
    end
    if not target then
        local main = app:mainWindow()
        if main and main:isStandard() and not claimedElsewhere(key, main:id()) then
            target = main
        else
            target = nextFree(key, wins, 0) or wins[1]
        end
    end

    slot.win = target:id()
    save()
    show(target)
end

local function pin(key)
    local w = hs.window.focusedWindow()
    if not w then return end
    for k, s in pairs(slots) do
        if k ~= key and s.win == w:id() then s.win = nil end
    end
    slots[key] = { app = w:application():bundleID(), win = w:id() }
    save()
    hs.alert.show("slot " .. key .. " → " .. w:application():name())
end

local current, previous -- { win = windowID, app = bundleID } of the last two focused
local focusWatch -- held so the subscription isn't garbage-collected

local function track(win)
    if not win or (current and current.win == win:id()) then return end
    local app = win:application()
    previous = current
    current = { win = win:id(), app = app and app:bundleID() }
end

local function last()
    if not previous then return end
    local win = hs.window.get(previous.win)
    if win then
        show(win)
    elseif previous.app then
        reopen(previous.app)
    end
end

-- defaults: { ["1"] = "com.mitchellh.ghostty", ... } seeds slots never pinned
function M.bind(mods, pinMods, defaults)
    for key, bundleID in pairs(defaults) do
        slots[key] = { app = bundleID }
    end
    for key, s in pairs(hs.settings.get(STORE) or {}) do
        slots[key] = s
    end
    focusWatch = hs.window.filter.new():subscribe(hs.window.filter.windowFocused, track)
    track(hs.window.focusedWindow())
    hs.hotkey.bind(mods, "9", last)
    hs.hotkey.bind(mods, "-", function()
        local w = hs.window.focusedWindow()
        if w then show(w) end
    end)
    for n = 1, 8 do
        local key = tostring(n)
        hs.hotkey.bind(mods, key, function() jump(key) end)
        hs.hotkey.bind(pinMods, key, function() pin(key) end)
    end
end

return M
