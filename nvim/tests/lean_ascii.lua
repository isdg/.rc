-- lua/lean_ascii.lua against the installed lean.nvim, headless:
--   nvim --clean --headless -l nvim/tests/lean_ascii.lua [lean.nvim dir]
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
local la = require("lean_ascii")
local dir = arg[1] or vim.fn.stdpath("data") .. "/lazy/lean.nvim"

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

-- Where Neovim loads the plugin's Lua from; spec/ and scripts/ are its own.
local files = {}
for _, sub in ipairs({ "lua", "plugin", "ftplugin", "syntax", "indent",
    "lsp", "autoload" }) do
    for _, path in ipairs(vim.fn.globpath(dir .. "/" .. sub, "**/*.lua",
        false, true)) do
        files[#files + 1] = { name = la.name(dir, path), path = path,
            module = sub == "lua" }
    end
end
check("lean.nvim is installed", #files > 0, dir)

local kept = la.rewrite("lean.indent", "· ⊢ → ← • ▶")
check("notation is kept outside the scoped modules",
    kept == "· ⊢ → ← • >", kept)
check("a scoped swap applies in its module",
    la.rewrite("lean.module_hierarchy", "a · b") == "a | b",
    la.rewrite("lean.module_hierarchy", "a · b"))

-- Lean notation the plugin matches on, prints or pairs up, and µ.
local allowed = {}
for _, ch in ipairs({ "⊢", "✝", "·", "⟨", "⟩", "‹", "›", "«", "»", "µ" }) do
    allowed[ch] = true
end
local strings = vim.treesitter.query.parse("lua", "(string) @s")
local left = {}
for _, m in ipairs(files) do
    -- Lean notation pairs for the switch plugin to cycle through.
    if m.name == "ftplugin.lean.switch" then goto continue end
    local src = la.rewrite(m.name, table.concat(vim.fn.readfile(m.path), "\n"))
    local tree = vim.treesitter.get_string_parser(src, "lua"):parse()[1]
    for _, node in strings:iter_captures(tree:root(), src) do
        local text = vim.treesitter.get_node_text(node, src)
        for ch in text:gmatch("[\192-\247][\128-\191]*") do
            if not allowed[ch] then
                left[#left + 1] = ("%s:%d %s"):format(m.name,
                    node:start() + 1, ch)
            end
        end
    end
    ::continue::
end
check("no glyph is left in a string literal", #left == 0, left)

la.install(dir)
vim.opt.rtp:append(dir)
local broken = {}
for _, m in ipairs(files) do
    local ok, err = true, nil
    if not m.module then
        ok, err = loadfile(m.path)
        ok = ok ~= nil
    -- Telescope extensions need telescope, which this config doesn't have.
    elseif not m.name:find("^telescope%.") then
        ok, err = pcall(require, m.name)
    end
    if not ok then broken[#broken + 1] = m.name .. ": " .. err end
end
check("every file loads rewritten", #broken == 0, broken)
check("modules load through the searcher",
    require("lean.config")().progress_bars.character == "|",
    require("lean.config")().progress_bars.character)

vim.cmd.syntax("on")
vim.bo.filetype = "leaninfo"
local rule = vim.fn.execute("syntax list leanInfoDiagnosticError")
check("infoview syntax matches the rewritten headers",
    rule:find("/^v.*: error:", 1, true) ~= nil, rule)

os.exit(failed == 0 and 0 or 1)
