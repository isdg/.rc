-- lua/plugins/nav.lua's fzf-lua keymap after fzf-lua's own normalisation,
-- which lowercases builtin keys. Needs the installed fzf-lua:
--   nvim --clean --headless -l nvim/tests/fzf_lua_keys.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/fzf-lua")

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

for _, spec in ipairs(require("plugins.nav")) do
    if spec[1] == "ibhagwan/fzf-lua" then spec.config() end
end
local opts = require("fzf-lua.config").normalize_opts({}, "files")
local builtin = opts.keymap.builtin
local function keys_of(action)
    local keys = {}
    for key, act in pairs(builtin) do
        if act == action then keys[vim.fn.keytrans(vim.keycode(key))] = true end
    end
    return keys
end

for action, want in pairs({
    ["preview-down"] = "<M-J>",
    ["preview-up"] = "<M-K>",
    ["preview-half-page-down"] = "<M-D>",
    ["preview-half-page-up"] = "<M-U>",
}) do
    local keys = keys_of(action)
    check(action .. " on " .. want, keys[want], keys)
end

-- The opts file's list keys reach fzf only if no nvim map shadows them.
for _, key in ipairs({ "<M-j>", "<M-d>", "<M-u>", "<M-g>" }) do
    local taken
    for k in pairs(builtin) do
        if vim.keycode(k) == vim.keycode(key) then taken = k end
    end
    check(key .. " left to fzf", taken == nil, taken)
end

io.stdout:write(failed == 0 and "ok\n" or ("%d failed\n"):format(failed))
os.exit(failed == 0 and 0 or 1)
