-- lua/agentic_yank.lua, headless and without the rest of the config:
--   nvim --clean --headless -l nvim/tests/agentic_yank.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
local ay = require("agentic_yank")

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local notes, clip = {}, nil
vim.notify = function(msg) notes[#notes + 1] = msg end
vim.fn.setreg = function(reg, text) if reg == "+" then clip = text end end

local root = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(root .. "/.git", "p")
vim.fn.mkdir(root .. "/lua", "p")
local file = root .. "/lua/m.lua"
vim.fn.writefile({
    "local M = {}",
    "function M.outer()",
    "    local function inner()",
    "        return '```'",
    "    end",
    "end",
    "return M",
}, file)

local ok, err = pcall(function()
    vim.cmd.edit(file)
    local b = vim.api.nvim_get_current_buf()

    local text = ay.payload(b, 3, 3)
    check("one line: path from the repo root, both symbols, longer fence",
        text == table.concat({
            "lua/m.lua:4 (function M.outer > inner)",
            "````lua",
            "        return '```'",
            "````",
        }, "\n") .. "\n", text)

    text = ay.payload(b, 1, 5)
    check("range: only the symbol holding every line",
        vim.startswith(text, "lua/m.lua:2-6 (function M.outer)\n````lua\n"),
        text)

    text = ay.payload(b, 0, 6)
    check("outside every symbol: no symbol",
        vim.startswith(text, "lua/m.lua:1-7\n"), text)

    local ns = vim.api.nvim_create_namespace("agentic_yank_test")
    vim.diagnostic.set(ns, b, {
        { lnum = 4, col = 4, severity = vim.diagnostic.severity.WARN,
            message = "two\n  lines", source = "lsp" },
        { lnum = 2, col = 0, severity = vim.diagnostic.severity.ERROR,
            message = "first" },
        { lnum = 6, col = 0, severity = vim.diagnostic.severity.HINT,
            message = "outside" },
    })
    text = ay.payload(b, 2, 4)
    check("diagnostics in range, sorted, one line each",
        vim.endswith(text, table.concat({
            "Diagnostics:",
            "- 3: [error] first",
            "- 5: [warn] two lines (lsp)",
        }, "\n") .. "\n"), text)
    vim.diagnostic.reset(ns, b)

    vim.api.nvim_buf_set_lines(b, 0, 1, true, { "local M = { x = 1 }" })
    text = ay.payload(b, 0, 0)
    check("modified buffer: marked unsaved, code from the buffer",
        text:match("^lua/m.lua:1 %[unsaved%]\n```lua\nlocal M = { x = 1 }\n"),
        text)
    vim.cmd("silent write")

    vim.keymap.set({ "n", "v" }, "Q", ay.yank)
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd("normal Q")
    check("normal mode: the cursor line without a count",
        clip and vim.startswith(clip, "lua/m.lua:2 (function M.outer)\n"),
        clip)
    check("normal mode: notifies the header",
        notes[#notes] == "Copied lua/m.lua:2 (function M.outer)", notes)

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    vim.cmd("normal 9Q")
    check("normal mode: a count stops at the last line",
        clip and vim.startswith(clip, "lua/m.lua:6-7\n"), clip)

    vim.api.nvim_win_set_cursor(0, { 5, 3 })
    vim.cmd("normal vkkQ")
    check("visual mode: whole lines of an upward charwise selection",
        clip and vim.startswith(clip, table.concat({
            "lua/m.lua:3-5 (function M.outer > inner)",
            "````lua",
            "    local function inner()",
        }, "\n")), clip)
    check("visual mode: leaves visual mode",
        vim.fn.mode() == "n", vim.fn.mode())

    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(scratch, 0, -1, true, { "x" })
    text = ay.payload(scratch, 0, 0)
    check("no file name: placeholder path, no filetype",
        text == "[No Name]:1\n```\nx\n```\n", text)
end)
if not ok then
    failed = failed + 1
    io.stdout:write("FAIL error: " .. tostring(err) .. "\n")
end
vim.fn.delete(root, "rf")
io.stdout:write(failed == 0 and "all passed\n" or (failed .. " failed\n"))
os.exit(failed == 0 and 0 or 1)
