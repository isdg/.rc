-- lua/text_rename.lua, headless and without the rest of the config:
--   nvim --clean --headless -l nvim/tests/text_rename.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
local tr = require("text_rename")

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end
local function lines(b) return vim.api.nvim_buf_get_lines(b, 0, -1, true) end

local notes = {}
vim.notify = function(msg) notes[#notes + 1] = msg end
local answer, confirmed
vim.ui.input = function(_, cb) cb(answer) end
vim.fn.confirm = function() confirmed = true return 1 end

local root = vim.fs.normalize(vim.fn.tempname())
local function write(rel, text)
    local path = root .. "/" .. rel
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(vim.split(text, "\n"), path)
    return path
end
vim.fn.mkdir(root .. "/.git", "p")

local ok, err = pcall(function()
    vim.cmd.edit(write("other.txt", "foo"))
    vim.cmd.edit(write("one.txt", "foo foobar foo_x é foo\nx.foo(foo)"))
    local one = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    answer = "bar"
    tr.buffer()
    check("buffer: whole words only, past multibyte text", vim.deep_equal(
        lines(one), { "bar foobar foo_x é bar", "x.bar(bar)" }), lines(one))
    check("buffer: the alternate buffer is left alone",
        lines(vim.fn.bufnr("#"))[1] == "foo", lines(vim.fn.bufnr("#")))
    vim.cmd("silent undo")
    check("buffer: one undo restores it", vim.deep_equal(lines(one),
        { "foo foobar foo_x é foo", "x.foo(foo)" }), lines(one))

    vim.api.nvim_win_set_cursor(0, { 2, 9 })
    notes = {}
    tr.buffer()
    check("not on a word: says so, changes nothing",
        notes[1] == "Not on a word" and lines(one)[2] == "x.foo(foo)", notes)

    write("sub/two.lua", "local foo = foo .. 'foo'")
    write("odd:name.txt", "foo")
    write("ignored.txt", "foo")
    write(".gitignore", "ignored.txt")
    vim.api.nvim_buf_set_lines(one, 0, 0, true, { "foo unsaved" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    answer, confirmed = "baz", false
    tr.project()
    local two = vim.fn.bufnr(root .. "/sub/two.lua")
    check("project: asks before applying", confirmed, confirmed)
    check("project: loaded buffer is read as it stands", vim.deep_equal(
        lines(one), { "baz unsaved", "baz foobar foo_x é baz",
            "x.baz(baz)" }), lines(one))
    check("project: unloaded files from disk, every match on a line",
        two > 0 and lines(two)[1] == "local baz = baz .. 'baz'",
        two > 0 and lines(two))
    check("project: a colon in a path", lines(vim.fn.bufnr(root ..
        "/odd:name.txt"))[1] == "baz", vim.fn.getqflist())
    check("project: .gitignore is honoured",
        vim.fn.bufnr(root .. "/ignored.txt") == -1, vim.fn.getqflist())
    check("project: nothing is written",
        vim.fn.readfile(root .. "/sub/two.lua")[1]:find("foo") ~= nil,
        vim.fn.readfile(root .. "/sub/two.lua"))

    vim.fn.confirm = function() return 2 end
    answer = "qux"
    tr.project()
    check("project: declining leaves buffers alone",
        lines(one)[1] == "baz unsaved", lines(one))
end)
if not ok then check("ran to the end", false, err) end
vim.fn.delete(root, "rf")
os.exit(failed == 0 and 0 or 1)
