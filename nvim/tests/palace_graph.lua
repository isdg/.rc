-- lua/palace_graph.lua on a small vault through the real `plc graph`, with
-- fzf-lua's picker stubbed. Needs plc and the installed fzf-lua:
--   nvim --clean --headless -l nvim/tests/palace_graph.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/fzf-lua")
local fzf = require("fzf-lua")

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local picked, notes = nil, {}
fzf.fzf_exec = function(entries, opts) picked = { entries, opts } end
vim.notify = function(msg) notes[#notes + 1] = msg end

local tmp = vim.fs.normalize(vim.fn.tempname())
local vault = tmp .. "/vault"
local function note(rel, stamp, body)
    local path = vault .. "/" .. rel
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile({ "isg " .. stamp .. " +0000", "", body }, path)
    return path
end
local function day(d) return ("2026-01-%02d 10:00:00"):format(d) end

local graph, buf
local function lnum() return vim.api.nvim_win_get_cursor(0)[1] end
local function line() return vim.api.nvim_get_current_line() end
local function keys(k)
    vim.api.nvim_feedkeys(vim.keycode(k), "x", false)
end
local function loaded(linked)
    return vim.wait(10000, function()
        local b = buf and vim.b[buf].palace_graph
        return b ~= nil and b.linked == linked
    end, 20)
end

local ok, err = pcall(function()
    note("notes/daily.md", day(1), "[[later]]")
    note("notes/later.md", day(2), "")
    local d1 = note("notes/d1.md", day(3), "[[daily]] [[revolut]]")
    note("notes/lone.md", day(4), "[[tag]]")
    note("notes/d2.md", day(5), "[[daily]] [[d1]]")
    note("notes/many.md", "2025-12-31 10:00:00",
        ("[[tag%d]] "):rep(30):format(unpack(vim.fn.range(30))))
    vim.env.HOME, vim.env.PALACE_DIR = tmp, vault
    graph = require("palace_graph")

    vim.cmd.edit(d1)
    local origin = vim.api.nvim_get_current_tabpage()
    graph.open()
    buf = vim.api.nvim_get_current_buf()
    check("open: the graph loads in its own tab",
        loaded(false) and vim.api.nvim_get_current_tabpage() ~= origin)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, 7, false)
    check("rows read as git log", vim.deep_equal(lines, {
        "*   2026-01-05  d2",
        "|\\",
        "| | o 2026-01-04  lone (tag)",
        "| * 2026-01-03  d1 (revolut)",
        "|/",
        "| o 2026-01-02  later",
        "o 2026-01-01  daily ->1",
    }), lines)
    check("open: the cursor sits on the note you came from",
        lnum() == 4 and vim.api.nvim_win_get_cursor(0)[2] == 2,
        vim.api.nvim_win_get_cursor(0))
    local many = vim.api.nvim_buf_get_lines(buf, 7, 8, false)[1]
    check("refs give way to the window width",
        vim.fn.strdisplaywidth(many) <= vim.api.nvim_win_get_width(0)
            and many:find("…", 1, true) ~= nil, many)

    keys("j")
    check("j skips connector lines", lnum() == 6, lnum())
    keys("k")
    check("k comes back", lnum() == 4, lnum())
    keys("2j")
    check("a count moves that many notes", lnum() == 7, lnum())

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    keys("p")
    check("p: a single parent is a jump", lnum() == 7, lnum())
    keys("<C-o>")
    check("<C-o> comes back along the jump",
        lnum() == 4 and vim.api.nvim_get_current_buf() == buf, lnum())
    keys("<C-o><C-o>")
    check("<C-o> never leaves the graph",
        vim.api.nvim_get_current_buf() == buf)

    vim.api.nvim_win_set_cursor(0, { 7, 0 })
    keys("c")
    check("c: the newest child", line():find("d2", 1, true) ~= nil, line())

    picked = nil
    keys("p")
    check("p on a merge asks, parents in text order",
        picked and vim.deep_equal(picked[1],
            { "notes/daily.md", "notes/d1.md" }), picked and picked[1])
    picked[2].actions.enter({ "notes/d1.md" })
    check("the pick lands on that note", lnum() == 4, lnum())

    picked = nil
    keys("P")
    check("P asks even for one parent",
        picked and vim.deep_equal(picked[1], { "notes/daily.md" }))

    vim.api.nvim_win_set_cursor(0, { 7, 0 })
    picked = nil
    keys("C")
    check("C asks, children newest first", picked
        and vim.deep_equal(picked[1], { "notes/d2.md", "notes/d1.md" }),
        picked and picked[1])

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    notes = {}
    keys("p")
    check("p on a root says so and stays",
        lnum() == 6 and notes[1] == "later: no parents", notes)

    keys("u")
    check("u: notes without links go", loaded(true)
        and not table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false),
            "\n"):find("lone"))
    check("u: the cursor stays on its note",
        line():find("later", 1, true) ~= nil, line())

    keys("<CR>")
    check("<CR>: the note opens in the tab you came from",
        vim.api.nvim_get_current_tabpage() == origin
            and vim.fs.basename(vim.api.nvim_buf_get_name(0)) == "later.md",
        vim.api.nvim_buf_get_name(0))

    vim.b[buf].palace_graph = nil
    graph.open()
    check("open again: back in the graph, on the note you were in",
        loaded(true) and line():find("later", 1, true) ~= nil, line())

    keys("q")
    check("q closes the graph tab",
        #vim.api.nvim_list_tabpages() == 1
            and vim.api.nvim_get_current_tabpage() == origin)
end)
if not ok then
    failed = failed + 1
    io.stdout:write("FAIL error: " .. tostring(err) .. "\n")
end
vim.fn.delete(tmp, "rf")
io.stdout:write(failed == 0 and "ok\n" or ("%d failed\n"):format(failed))
os.exit(failed == 0 and 0 or 1)
