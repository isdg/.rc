-- Insert-mode <C-n>/<C-p>: emacs line moves, the menu's entries only after
-- <C-l>. Drives an embedded nvim on this checkout's config and installed
-- plugins:  nvim --clean --headless -l nvim/tests/completion_keys.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))

-- A HOME without ~/.config/rc/nvim makes init.lua run this checkout's rc.d.
local home = vim.fn.tempname()
vim.fn.mkdir(home .. "/xdg", "p")
vim.uv.fs_symlink(nvim, home .. "/xdg/nvim")
local ch = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, {
    rpc = true,
    env = {
        HOME = home,
        XDG_CONFIG_HOME = home .. "/xdg",
        XDG_DATA_HOME = vim.fs.dirname(vim.fn.stdpath("data")),
        XDG_STATE_HOME = home .. "/state",
        XDG_CACHE_HOME = home .. "/cache",
    },
})

local function rq(m, ...) return vim.fn.rpcrequest(ch, m, ...) end
local function lua(code) return rq("nvim_exec_lua", code, {}) end
local function state()
    return lua([[
        local cmp = require("blink.cmp")
        local ctx = cmp.is_menu_visible() and cmp.get_context()
        return {
            line = vim.fn.line("."),
            menu = ctx and ctx.trigger.initial_kind or false,
            sel = cmp.get_selected_item_idx() or false,
        }
    ]])
end
-- Keys land asynchronously; wait until the state settles on the expected.
local function press(keys, want)
    rq("nvim_input", keys)
    local got
    vim.wait(3000, function()
        got = state()
        for k, v in pairs(want) do
            if got[k] ~= v then return false end
        end
        return true
    end, 20)
    return got
end

local failed = 0
local function check(name, keys, want)
    local got = press(keys, want)
    local ok = true
    for k, v in pairs(want) do ok = ok and got[k] == v end
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(got))))
end

local ok, err = pcall(function()
    lua([[
        require("blink.cmp")
        vim.g.completion_autoshow = true
        vim.api.nvim_buf_set_lines(0, 0, -1, false,
            { "alpha alphabet alphanumeric", "", "third" })
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
    ]])
    rq("nvim_input", "i")

    check("<C-n> with no menu moves down", "<C-n>", { line = 3, menu = false })
    check("<C-p> with no menu moves up", "<C-p>", { line = 2, menu = false })
    check("typing pops the auto menu", "al", { line = 2, menu = "keyword" })
    check("<C-n> on the auto menu moves down", "<C-n>", { line = 3 })

    lua("vim.g.completion_autoshow = false")
    press("<Esc>", { menu = false })
    lua([[
        vim.api.nvim_buf_set_lines(0, 1, 2, false, { "al" })
        vim.api.nvim_win_set_cursor(0, { 2, 1 })
    ]])
    rq("nvim_input", "a")
    check("<C-l> opens the menu", "<C-l>", { line = 2, menu = "manual" })
    check("typing filters the <C-l> list", "p",
        { line = 2, menu = "manual", sel = false })
    check("<C-n> selects in the <C-l> menu", "<C-n>",
        { line = 2, menu = "manual", sel = 1 })
    check("<C-n> selects the next entry", "<C-n>", { line = 2, sel = 2 })
    check("<C-p> selects the previous entry", "<C-p>", { line = 2, sel = 1 })
    check("<C-e> closes the menu", "<C-e>", { line = 2, menu = false })
    check("<C-n> moves down again", "<C-n>", { line = 3, menu = false })
end)
if not ok then
    failed = failed + 1
    io.stdout:write("FAIL " .. tostring(err) .. "\n")
end
pcall(rq, "nvim_command", "qa!")
vim.fn.delete(home, "rf")
os.exit(failed == 0 and 0 or 1)
