-- ============================================================
--        PALACE GRAPH: `plc graph` in a tab, git log style
-- ============================================================
-- Every note is a row, newest first; a link to an older note is a parent
-- lane, roots are drawn o (plc's README, PLC GRAPH). The tab stays around:
-- Enter opens a note in the tab you came from, and opening the graph again
-- refreshes it and lands on the note you were in.
local palace = require("palace")

local M = {}

local NS = vim.api.nvim_create_namespace("palace_graph")
local HL = {
    PalaceGraphDate = "Comment",
    PalaceGraphRefs = "Special",
    PalaceGraphForward = "Comment",
}
for group, link in pairs(HL) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
end

local KEYS = {
    { "j / k", "next / previous note" },
    { "p / P", "parent / pick a parent" },
    { "c / C", "newest child / pick a child" },
    { "<CR> o", "open in the tab you came from" },
    -- The jumplist keys as rc.d/04-keys-editor.lua swaps them.
    { "<C-i>", "back along p and c jumps (<C-o> forward)" },
    { "u", "hide / show notes without links" },
    { "R", "refresh" },
    { "q", "close" },
    { "?", "these keys" },
}

-- buf: the graph buffer; origin: the tab notes open in; linked: the
-- --linked view; notes[lnum]: the note drawn on that line; line_of[row]:
-- the line of the note plc numbered row.
local state = { linked = false, notes = {}, line_of = {} }

local function graph_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == state.buf then return win end
    end
end

local function cut(s, width)
    if width < 1 then return "" end
    if vim.fn.strdisplaywidth(s) <= width then return s end
    local out = vim.fn.strcharpart(s, 0, width - 1)
    while vim.fn.strdisplaywidth(out) > width - 1 do
        out = vim.fn.strcharpart(out, 0, vim.fn.strchars(out) - 1)
    end
    return out .. "…"
end

-- One note's line and its highlights; refs give way first to the width.
local function draw(row, width)
    local note = row.note
    local head = ("%s%s  %s"):format(row.graph, note.date, note.name)
    local fwd = note.forward > 0 and (" ->%d"):format(note.forward) or ""
    local refs = #note.refs > 0
        and (" (%s)"):format(table.concat(note.refs, ", ")) or ""
    local room = width - vim.fn.strdisplaywidth(head .. fwd)
    refs = room > 3 and cut(refs, room) or ""
    local text = head .. refs .. fwd
    local date = #row.graph
    return text, {
        { date, date + #note.date, "PalaceGraphDate" },
        { #head, #head + #refs, "PalaceGraphRefs" },
        { #head + #refs, #text, "PalaceGraphForward" },
    }
end

local function render(rows, width)
    local lines, marks = {}, {}
    state.notes, state.line_of = {}, {}
    for lnum, row in ipairs(rows) do
        if row.note then
            local text, hl = draw(row, width)
            lines[lnum], marks[lnum] = text, hl
            state.notes[lnum] = row.note
            state.line_of[row.note.row] = lnum
        else
            lines[lnum] = row.graph:gsub("%s+$", "")
        end
    end
    local buf = state.buf
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
    for lnum, hls in pairs(marks) do
        for _, h in ipairs(hls) do
            if h[2] > h[1] then
                vim.api.nvim_buf_set_extmark(buf, NS, lnum - 1, h[1],
                    { end_col = h[2], hl_group = h[3] })
            end
        end
    end
end

local function note_line(lnum)
    return state.notes[lnum] ~= nil
end

-- The cursor on a note's commit glyph, after marking the jumplist.
local function land(lnum, mark)
    local win = graph_win()
    if not win or not lnum then return end
    if mark then vim.cmd("normal! m'") end
    local text = vim.api.nvim_buf_get_lines(state.buf, lnum - 1, lnum,
        false)[1] or ""
    local col = (text:find("[*o]") or 1) - 1
    vim.api.nvim_win_set_cursor(win, { lnum, col })
end

local function current()
    local win = graph_win()
    if not win then return end
    return state.notes[vim.api.nvim_win_get_cursor(win)[1]]
end

local function find(path)
    if not path then return end
    local want = palace.real(path)
    local base = vim.fs.basename(path)
    for lnum, note in pairs(state.notes) do
        if vim.fs.basename(note.path) == base
            and palace.real(note.path) == want then
            return lnum
        end
    end
end

local function load(target)
    local args = { "plc", "graph", "--json" }
    if state.linked then args[#args + 1] = "--linked" end
    local keep = target or (current() or {}).path
    vim.system(args, { text = true }, vim.schedule_wrap(function(out)
        if not vim.api.nvim_buf_is_valid(state.buf or -1) then return end
        if out.code ~= 0 then
            vim.notify("plc graph: " .. vim.trim(out.stderr or ""),
                vim.log.levels.ERROR)
            return
        end
        local rows = {}
        for line in vim.gsplit(out.stdout, "\n", { trimempty = true }) do
            rows[#rows + 1] = vim.json.decode(line)
        end
        local win = graph_win()
        render(rows, win and vim.api.nvim_win_get_width(win) or 80)
        local n = vim.tbl_count(state.notes)
        vim.b[state.buf].palace_graph = { notes = n, linked = state.linked }
        if win then
            vim.wo[win].winbar = (" palace graph  %d notes%s   ? keys")
                :format(n, state.linked and "  (linked only)" or "")
        end
        land(find(keep) or 1, false)
    end))
end

--- Move count notes down (or up, when negative), skipping connector lines.
function M.step(count)
    local win = graph_win()
    if not win then return end
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    local last = vim.api.nvim_buf_line_count(state.buf)
    local dir = count < 0 and -1 or 1
    for _ = 1, math.abs(count) do
        local n = lnum + dir
        while n >= 1 and n <= last and not note_line(n) do n = n + dir end
        if n < 1 or n > last then break end
        lnum = n
    end
    land(lnum, false)
end

local function rows_of(note, key)
    return vim.tbl_map(function(row) return state.notes[state.line_of[row]] end,
        note[key])
end

local function pick(notes, prompt)
    local fzf = require("fzf-lua")
    local root = palace.root()
    local by_path, entries = {}, {}
    for _, note in ipairs(notes) do
        local rel = root and vim.fs.relpath(root, palace.real(note.path))
            or note.path
        by_path[rel] = note
        entries[#entries + 1] = rel
    end
    fzf.fzf_exec(entries, {
        prompt = prompt .. " > ",
        cwd = root,
        previewer = "builtin",
        actions = {
            ["enter"] = function(selected)
                local note = selected[1] and by_path[selected[1]]
                if note then land(state.line_of[note.row], true) end
            end,
        },
    })
end

-- how: "first" jumps to the first (c: the newest child), "pick" always
-- asks, "auto" jumps when there is one and asks otherwise (p on a merge).
local function follow(key, how, what)
    local note = current()
    if not note then return end
    local notes = rows_of(note, key)
    if #notes == 0 then
        vim.notify(("%s: no %s"):format(note.name, what))
    elseif how == "first" or (how == "auto" and #notes == 1) then
        land(state.line_of[notes[1].row], true)
    else
        pick(notes, what)
    end
end

--- Open the note under the cursor in the tab the graph was opened from.
function M.open_note()
    local note = current()
    if not note then return end
    if state.origin and vim.api.nvim_tabpage_is_valid(state.origin)
        and state.origin ~= vim.api.nvim_get_current_tabpage() then
        vim.api.nvim_set_current_tabpage(state.origin)
    else
        vim.cmd.tabnew()
        state.origin = vim.api.nvim_get_current_tabpage()
    end
    vim.cmd.edit(vim.fn.fnameescape(note.path))
end

local function close()
    if #vim.api.nvim_list_tabpages() > 1 then
        vim.cmd.tabclose()
    else
        vim.cmd.enew()
    end
end

local function help()
    local lines = vim.tbl_map(function(k)
        return ("%-8s %s"):format(k[1], k[2])
    end, KEYS)
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO,
        { title = "palace graph" })
end

local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = state.buf, desc = desc,
        nowait = true })
end

local function create()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "palace://graph")
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].filetype = "palacegraph"
    vim.bo[buf].modifiable = false
    state.buf = buf
    map("j", function() M.step(vim.v.count1) end, "Next note")
    map("k", function() M.step(-vim.v.count1) end, "Previous note")
    map("p", function() follow("parents", "auto", "parents") end, "Parent")
    map("P", function() follow("parents", "pick", "parents") end,
        "Pick a parent")
    map("c", function() follow("children", "first", "children") end,
        "Newest child")
    map("C", function() follow("children", "pick", "children") end,
        "Pick a child")
    map("<CR>", M.open_note, "Open note")
    map("o", M.open_note, "Open note")
    map("u", function()
        state.linked = not state.linked
        load()
    end, "Toggle notes without links")
    map("R", function() load() end, "Refresh")
    map("q", close, "Close graph")
    map("?", help, "Graph keys")
end

local function show()
    local win = graph_win()
    if win then
        vim.api.nvim_set_current_win(win)
        return
    end
    vim.cmd.tabnew()
    local scratch = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_set_buf(0, state.buf)
    if scratch ~= state.buf then
        pcall(vim.api.nvim_buf_delete, scratch, {})
    end
    -- A new tab inherits its window's jumplist, which leads out of here.
    vim.cmd.clearjumps()
    local wo = vim.wo[0][0]
    wo.wrap, wo.number, wo.relativenumber = false, false, false
    wo.signcolumn, wo.foldcolumn, wo.list = "no", "0", false
    wo.cursorline, wo.spell = true, false
end

--- Open (or return to) the graph tab, refreshed, on the note in the
--- current buffer when it is one.
function M.open()
    if not palace.root() then
        vim.notify("plc names no vault", vim.log.levels.WARN)
        return
    end
    local here = vim.api.nvim_get_current_buf()
    local target
    if here ~= state.buf then
        state.origin = vim.api.nvim_get_current_tabpage()
        if palace.owner(here) then
            target = vim.api.nvim_buf_get_name(here)
        end
    end
    if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
        create()
    end
    show()
    load(target)
end

return M
