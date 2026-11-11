-- lua/palace.lua: the vault lookup and <leader><leader>p l / L, with fzf-lua's
-- picker stubbed. Needs plc, rg and the installed fzf-lua:
--   nvim --clean --headless -l nvim/tests/palace_link.lua
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
local function line() return vim.api.nvim_get_current_line() end

local picked, notes
fzf.files = function(opts) picked = opts end
vim.notify = function(msg) notes[#notes + 1] = msg end
local function fresh()
    package.loaded.palace = nil
    picked, notes = nil, {}
    return require("palace")
end

local tmp = vim.fs.normalize(vim.fn.tempname())
local vault = tmp .. "/vault"
local function write(rel, text, mtime)
    local path = vault .. "/" .. rel
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile({ text }, path)
    vim.uv.fs_utime(path, mtime, mtime)
    return path
end

local ok, err = pcall(function()
    vim.env.HOME, vim.env.PALACE_DIR = tmp, ""
    local palace = fresh()
    vim.api.nvim_set_current_line("x")
    palace.link(true)
    check("no vault: says so, opens no picker",
        picked == nil and notes[1] == "plc names no vault", notes)

    write("notes/old.md", "", 1000)
    write("notes/me/дар.md", "", 3000)
    write("notes/two words.md", "", 2000)
    write(".git/hidden.md", "", 4000)
    write("notes/skip.txt", "", 5000)
    vim.uv.fs_symlink(vault, tmp .. "/link")
    vim.env.PALACE_DIR = tmp .. "/link"
    palace = fresh()
    check("root: the vault's real path",
        palace.root() == vim.uv.fs_realpath(vault), palace.root())

    vim.cmd.edit(vault .. "/notes/old.md")
    check("owner: a note inside the vault", palace.owner(0) ~= nil)
    vim.cmd.edit(tmp .. "/link/notes/unwritten.md")
    check("owner: an unwritten note reached through the symlink",
        palace.owner(0) ~= nil, vim.api.nvim_buf_get_name(0))
    vim.cmd.edit(tmp .. "/outside.md")
    check("owner: nothing outside the vault", palace.owner(0) == nil)
    vim.cmd.enew()
    check("owner: nothing for an unnamed buffer", palace.owner(0) == nil)

    vim.api.nvim_set_current_line("ab")
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    palace.link(true)
    check("l: the picker runs in the vault",
        picked and picked.cwd == palace.root(), picked)
    local out = vim.system({ "sh", "-c", picked.cmd },
        { cwd = picked.cwd, text = true }):wait()
    local listed = vim.split(vim.trim(out.stdout), "\n")
    check("the list: notes only, newest first, hidden dirs skipped",
        vim.deep_equal(listed, {
            "notes/me/дар.md", "notes/two words.md", "notes/old.md",
        }), listed)

    picked.actions.enter({ listed[1] }, picked)
    check("l: puts the link after the cursor", line() == "a[[дар]]b", line())
    check("l: the cursor ends just past the link, as gp leaves it",
        vim.api.nvim_win_get_cursor(0)[2] == #"a[[дар]]")

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    palace.link(false)
    picked.actions.enter({ listed[2], listed[3] }, picked)
    check("L: several picks go before the cursor, space-separated",
        line() == "[[two words]] [[old]]a[[дар]]b", line())

    local before = line()
    palace.link(true)
    picked.actions.enter({}, picked)
    check("nothing picked: nothing put", line() == before, line())

    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    palace.link(false)
    vim.cmd.split()
    vim.cmd.enew()
    picked.actions.enter({ listed[3] }, picked)
    vim.api.nvim_set_current_win(win)
    check("the link lands in the window the picker was opened from",
        line() == "[[old]]" .. before, line())
end)
if not ok then
    failed = failed + 1
    io.stdout:write("FAIL error: " .. tostring(err) .. "\n")
end
vim.fn.delete(tmp, "rf")
io.stdout:write(failed == 0 and "ok\n" or ("%d failed\n"):format(failed))
os.exit(failed == 0 and 0 or 1)
