-- The <leader><leader> plugins layer shows each tool only in its context
-- (rc.d/10-keys-plugins.lua), with palace and `hr vault` stubbed:
--   nvim --clean --headless -l nvim/tests/plugins_layer.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
vim.g.mapleader = " "

local failed = 0
local function check(name, got, want)
    local ok = vim.deep_equal(got, want)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- got " .. vim.inspect(got))))
end

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
root = vim.uv.fs_realpath(root)
local feed, palace = root .. "/feed", root .. "/palace"
local files = { feed .. "/a.md", palace .. "/n.md", root .. "/o.md" }
for _, file in ipairs(files) do
    vim.fn.mkdir(vim.fs.dirname(file), "p")
    vim.fn.writefile({}, file)
end

package.loaded.palace = {
    owner = function(buf)
        local name = vim.api.nvim_buf_get_name(buf)
        return vim.startswith(name, palace .. "/") and palace or nil
    end,
}

local asked, system = {}, vim.system
vim.system = function(cmd, opts, ...)
    if cmd[1] ~= "hr" then return system(cmd, opts, ...) end
    asked[#asked + 1] = { cmd = cmd, cwd = opts and opts.cwd }
    return { wait = function() return { code = 0, stdout = feed .. "\n" } end }
end

local layer = require("keymaps.layer")
local shown
package.loaded["keymaps.layer"] = {
    open = function(_, keys)
        shown = vim.tbl_keys(layer.visible(keys))
        table.sort(shown)
        shown = table.concat(shown)
    end,
}
dofile(nvim .. "/rc.d/10-keys-plugins.lua")
local open = vim.fn.maparg("<leader><leader>", "n", false, true).callback

local function show(file, filetype)
    vim.cmd(file and ("edit " .. vim.fn.fnameescape(file)) or "enew")
    vim.bo.filetype = filetype
    open()
    return shown
end

check("python: debug only", show(nil, "python"), "d")
check("lean source: lean", show(nil, "lean"), "dl")
check("lean infoview: lean", show(nil, "leaninfo"), "dl")
check("hr panel: hr", show(nil, "hr"), "dh")
check("hr vault article: hr", show(feed .. "/a.md", "markdown"), "dh")
check("palace note: palace", show(palace .. "/n.md", "markdown"), "dp")
check("other markdown: debug only", show(root .. "/o.md", "markdown"), "d")
check("hr vault asked once, from $HOME", asked,
    { { cmd = { "hr", "vault" }, cwd = vim.env.HOME } })

os.exit(failed == 0 and 0 or 1)
