-- lua/palace.lua: the notes the palace layer opens (dl, nt, ...), on a
-- throwaway vault. Needs plc:
--   nvim --clean --headless -l nvim/tests/palace_open.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local notes, answer = {}, nil
vim.notify = function(msg) notes[#notes + 1] = msg end
vim.ui.input = function(_, done) done(answer) end
local function name() return vim.api.nvim_buf_get_name(0) end
local function at_last_line()
    return vim.api.nvim_win_get_cursor(0)[1] == vim.fn.line("$")
end

local tmp = vim.fs.normalize(vim.fn.tempname())
local ok, err = pcall(function()
    vim.fn.mkdir(tmp .. "/vault/notes", "p")
    vim.env.HOME, vim.env.PALACE_DIR = tmp, tmp .. "/vault"
    local palace = require("palace")

    palace.open({ "daily" })
    local daily = vim.trim(vim.fn.system({ "plc", "daily" }))
    check("dl: opens the note plc prints",
        vim.uv.fs_realpath(name()) == vim.uv.fs_realpath(daily),
        { name(), daily })
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "a", "b" })
    vim.cmd("silent write")
    vim.cmd.enew()
    palace.open({ "daily" })
    check("dl: at its last line", at_last_line(), vim.fn.line("."))

    vim.cmd.enew()
    palace.open({ "isg" })
    check("a plc error is shown, nothing opened",
        name() == "" and notes[1] and notes[1]:find("no isg notes"), notes)

    local args = { "add" }
    answer = "two words"
    palace.open_named("note: ", args)
    check("nt: opens the named note",
        vim.fs.basename(name()) == "two words.md", name())
    check("nt: the args are left as they were",
        vim.deep_equal(args, { "add" }), args)

    for _, given in ipairs({ "", false }) do
        vim.cmd.enew()
        answer = given or nil
        palace.open_named("note: ", args)
        local what = given and "an empty" or "no"
        check(("nt: %s name opens nothing"):format(what), name() == "", name())
    end
end)
if not ok then
    failed = failed + 1
    io.stdout:write("FAIL error: " .. tostring(err) .. "\n")
end
vim.fn.delete(tmp, "rf")
io.stdout:write(failed == 0 and "ok\n" or ("%d failed\n"):format(failed))
os.exit(failed == 0 and 0 or 1)
