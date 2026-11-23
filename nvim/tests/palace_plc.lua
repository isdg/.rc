-- lua/palace.lua: :Plc and the palace layer's notes keys, on a throwaway
-- vault with fzf-lua stubbed. Needs plc:
--   nvim --clean --headless -l nvim/tests/palace_plc.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local notes, answer, asked, picked = {}, nil, 0, nil
vim.notify = function(msg) notes[#notes + 1] = msg end
vim.ui.input = function(_, done)
    asked = asked + 1
    done(answer)
end
package.loaded["fzf-lua"] = {
    fzf_exec = function(names, opts)
        picked = { names = names, opts = opts }
    end,
}
local function name() return vim.api.nvim_buf_get_name(0) end
local function base() return vim.fs.basename(name()) end
local function same(a, b)
    return vim.uv.fs_realpath(a) == vim.uv.fs_realpath(b)
end
local function plc(...)
    return vim.trim(vim.fn.system(vim.list_extend({ "plc" }, { ... })))
end

local tmp = vim.fs.normalize(vim.fn.tempname())
local ok, err = pcall(function()
    vim.fn.mkdir(tmp .. "/vault/notes", "p")
    vim.env.HOME, vim.env.PALACE_DIR = tmp, tmp .. "/vault"
    local palace = require("palace")
    local Plc = palace.command

    Plc({ "dl" })
    check("dl: opens the note plc prints", same(name(), plc("daily")), name())
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "a", "b" })
    vim.cmd("silent write")
    vim.cmd.enew()
    Plc({ "dl" })
    check("dl: at its last line",
        vim.fn.line(".") == vim.fn.line("$"), vim.fn.line("."))
    Plc({ "dl", "01", "02", "26" })
    check("dl: takes plc's args", base() == "2026-02-01.md", name())

    vim.cmd.enew()
    Plc({ "ig" })
    check("a plc error is shown, nothing opened",
        name() == "" and (notes[#notes] or ""):find("no isg notes"), notes)
    Plc({ "xx" })
    check("an unknown alias says so",
        (notes[#notes] or ""):find("xx is none of dl ig mm nt pt st td wk"),
        notes)

    answer = "two words"
    Plc({ "nt" })
    check("nt: asks for the name, then opens it",
        asked == 1 and base() == "two words.md", name())
    Plc({ "nt", "given" })
    check("nt NAME: asks nothing", asked == 1 and base() == "given.md", name())
    vim.cmd.enew()
    Plc({ "mm" })
    check("mm: no name is plc's error, asks nothing, opens nothing",
        asked == 1 and name() == ""
            and (notes[#notes] or ""):find("a note name is required"), notes)

    Plc({ "mm", "first" })
    check("mm NAME: a new murmur note", base() == "first.md", name())
    Plc({ "mm", "-l" })
    check("mm -l: lists murmur notes, previewed from their dir",
        vim.tbl_contains(picked.names, "first.md") and same(picked.opts.cwd,
            vim.fs.dirname(name())), picked)
    vim.cmd.enew()
    picked.opts.actions.enter({ "first.md" })
    check("mm -l: opens the pick", base() == "first.md", name())

    local old = plc("todo", "-n")
    local new = plc("todo", "-n", "-x", "b")
    Plc({ "td", "-l" })
    check("td -l: names without the last note's star", vim.deep_equal(
        vim.fn.sort(vim.deepcopy(picked.names)),
        vim.fn.sort({ vim.fs.basename(old), vim.fs.basename(new) })),
        picked.names)
    check("td -l: previewed from plc config todo",
        same(picked.opts.cwd, vim.fs.dirname(old)), picked.opts.cwd)
    picked.opts.actions.enter({ vim.fs.basename(old) })
    check("td -l: opens the pick", same(name(), old), name())
    check("td -l: and marks it last", same(plc("todo"), old), plc("todo"))
    picked.opts.actions.enter({})
    check("td -l: nothing picked, nothing opened", same(name(), old), name())

    plc("isg", "-n")
    plc("isg", "-n")
    Plc({ "ig", "-L", "isg0" })
    check("ig -L: marks without opening",
        base() ~= "isg0.md" and vim.fs.basename(plc("isg")) == "isg0.md",
        name())
    Plc({ "ig", "-l" })
    picked.opts.actions.enter({ "isg1.md" })
    check("ig -l: opens the pick", base() == "isg1.md", name())
end)
if not ok then
    failed = failed + 1
    io.stdout:write("FAIL error: " .. tostring(err) .. "\n")
end
vim.fn.delete(tmp, "rf")
io.stdout:write(failed == 0 and "ok\n" or ("%d failed\n"):format(failed))
os.exit(failed == 0 and 0 or 1)
