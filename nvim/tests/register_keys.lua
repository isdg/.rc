-- <leader>" yanks into and <leader>' pastes from a register picked in fzf,
-- with the picker faked and an in-memory clipboard:
--   nvim --clean --headless -l nvim/tests/register_keys.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)

local function clip() return { { "C" }, "v" } end
vim.g.clipboard = {
    name = "test",
    copy = { ["+"] = function() end, ["*"] = function() end },
    paste = { ["+"] = clip, ["*"] = clip },
}
vim.g.mapleader = " "
dofile(nvim .. "/rc.d/04-keys-editor.lua")
local picker = require("register_picker")

-- The fake picks the entry for choice.reg, or aborts when choice is nil.
local spec, choice
picker.run = function(_, s)
    spec = s
    if not choice then return end
    for _, line in ipairs(s.source) do
        if line:sub(2, 2) == choice.reg then
            s["sink*"]({ choice.alt and "alt-enter" or "", line })
            return
        end
    end
    error("no entry for register " .. choice.reg)
end

local failed = 0
local function check(name, got, want)
    local ok = vim.deep_equal(got, want)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- got " .. vim.inspect(got))))
end

-- Empties a-z, sets the unnamed register to "U" and the given ones, puts
-- lines in the buffer with the cursor at {row, col}, picks reg (alt-enter
-- when alt) and types keys; returns the buffer lines.
local function run(lines, cursor, keys, reg, alt, regs)
    for r in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
        vim.fn.setreg(r, {}, "v")
    end
    vim.fn.setreg('"', "U", "v")
    for r, v in pairs(regs or {}) do vim.fn.setreg(r, v[1], v[2]) end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, cursor)
    spec, choice = nil, reg and { reg = reg, alt = alt } or nil
    vim.api.nvim_feedkeys(vim.keycode(keys), "mx", false)
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local reg = vim.fn.getreg

run({ "one two" }, { 1, 0 }, ' "iw', "a")
check('<leader>" then a, iw yanks the word into a', reg("a"), "one")

run({ "one two" }, { 1, 4 }, ' "iw', "a", true, { a = { "one", "v" } })
check("alt-enter appends to a", reg("a"), "onetwo")

run({ "1", "2", "3" }, { 1, 0 }, '2 "y', "c")
check('2<leader>" then c, y yanks two lines into c', reg("c"), "1\n2\n")

run({ "one two" }, { 1, 4 }, 'viw "', "b")
check('visual <leader>" yanks the selection into b', reg("b"), "two")

run({ "one two" }, { 1, 0 }, ' Эiw', "d")
check('<leader>Э is the Russian twin', reg("d"), "one")

run({ "one two" }, { 1, 0 }, ' "iw', nil, false, { a = { "keep", "v" } })
check("aborting the picker leaves a alone", reg("a"), "keep")

run({ "x" }, { 1, 0 }, ' "', nil, false,
    { a = { "one", "v" }, b = { { "x", "y" }, "V" } })
check("yank list: all of a-z with type and contents",
    { #spec.source, spec.source[1], spec.source[2], spec.source[3] },
    { 26, '"a  c  one', '"b  l  x^Jy', '"c' })

local function pasted(keys, alt, regs)
    regs = regs or {}
    regs.a = regs.a or { "X", "v" }
    return run({ "abc" }, { 1, 1 }, keys, "a", alt, regs)[1]
end

check("<leader>' then a pastes a after", pasted(" '"), "abXc")
check("alt-enter pastes a before", pasted(" '", true), "aXbc")
check("2<leader>' pastes a twice", pasted("2 '"), "abXXc")
check("visual <leader>' replaces with a", pasted("v '"), "aXc")
check("visual <leader>' keeps the unnamed register",
    (pasted("v '") and reg('"')), "U")
check("visual alt-enter swaps the replaced text into the unnamed register",
    (pasted("v '", true) and reg('"')), "b")
check("<leader>э is the Russian twin", pasted(" э"), "abXc")
check("<leader>R is free again", vim.fn.maparg(" R", "n"), "")

run({ "abc" }, { 1, 1 }, " '", "+")
check("<leader>' then + pastes the clipboard", vim.api.nvim_get_current_line(),
    "abCc")

local names = {}
for _, line in ipairs(spec.source) do names[#names + 1] = line:sub(2, 2) end
check("paste list: only filled registers, * folded into +, no =",
    { vim.tbl_contains(names, "b"), vim.tbl_contains(names, "*"),
        vim.tbl_contains(names, "="), vim.tbl_contains(names, "+") },
    { false, false, false, true })

os.exit(failed == 0 and 0 or 1)
