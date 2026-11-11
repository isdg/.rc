-- <leader>p / <leader>P paste "+ after / before the cursor, against an
-- in-memory clipboard:
--   nvim --clean --headless -l nvim/tests/clipboard_keys.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)

local clip = { { "" }, "v" }
vim.g.clipboard = {
    name = "test",
    copy = {
        ["+"] = function(lines, regtype) clip = { lines, regtype } end,
        ["*"] = function(lines, regtype) clip = { lines, regtype } end,
    },
    paste = {
        ["+"] = function() return clip end,
        ["*"] = function() return clip end,
    },
}
vim.g.mapleader = " "
dofile(nvim .. "/rc.d/04-keys-editor.lua")

local failed = 0
local function check(name, got, want)
    local ok = vim.deep_equal(got, want)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- got " .. vim.inspect(got))))
end

-- Puts "abc" with the cursor on b, the unnamed register holding "U" and the
-- clipboard "C", then types keys and returns the line.
local function run(keys)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "abc" })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    vim.fn.setreg('"', "U", "v")
    clip = { { "C" }, "v" }
    vim.api.nvim_feedkeys(vim.keycode(keys), "mx", false)
    return vim.api.nvim_get_current_line()
end

check("<leader>p pastes the clipboard after", run(" p"), "abCc")
check("<leader>P pastes the clipboard before", run(" P"), "aCbc")
check("<leader>З is its Russian twin", run(" З"), "aCbc")
check("visual <leader>P replaces with the clipboard", run("v P"), "aCc")
check("visual <leader>P keeps the unnamed register",
    (run("v P") and vim.fn.getreg('"')), "U")

os.exit(failed == 0 and 0 or 1)
