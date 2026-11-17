-- ============================================================
--  picker — every window in one filterable list, recent first
-- ============================================================

local M = {}

-- wins: front to back, each { id, title, app }, repeats allowed. The focused
-- window goes last, so Enter on the first row is the previous window.
function M.rows(wins, focused)
    local rows, seen, own = {}, {}, nil
    for _, w in ipairs(wins) do
        if not seen[w.id] then
            seen[w.id] = true
            local row = {
                text = w.title ~= "" and w.title or w.app,
                subText = w.app,
                id = w.id,
            }
            if w.id == focused then
                own = row
            else
                rows[#rows + 1] = row
            end
        end
    end
    rows[#rows + 1] = own
    return rows
end

local function describe(w)
    local app = w:application()
    return {
        id = w:id(),
        title = w:title() or "",
        app = app and app:name() or "",
    }
end

-- orderedWindows is front to back but skips minimized windows and hidden
-- apps; allWindows brings those in after it.
local function windows()
    local list = {}
    local sources = { hs.window.orderedWindows(), hs.window.allWindows() }
    for _, source in ipairs(sources) do
        for _, w in ipairs(source) do
            if w:isStandard() then list[#list + 1] = describe(w) end
        end
    end
    return list
end

local function focus(choice)
    local w = choice and hs.window.get(choice.id)
    if not w then return end
    if w:isMinimized() then w:unminimize() end
    local app = w:application()
    if app and app:isHidden() then app:unhide() end
    w:focus()
end

local chooser

function M.bind(mods, key)
    chooser = hs.chooser.new(focus)
    chooser:searchSubText(true)
    hs.hotkey.bind(mods, key, function()
        if chooser:isVisible() then
            chooser:hide()
            return
        end
        local focused = hs.window.focusedWindow()
        chooser:choices(M.rows(windows(), focused and focused:id()))
        chooser:query("")
        chooser:show()
    end)
end

return M
