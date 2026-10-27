-- lua/lean_ascii.lua against the installed lean.nvim, headless:
--   nvim --clean --headless -l nvim/tests/lean_ascii.lua [lean.nvim dir]
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
local la = require("lean_ascii")
local dir = arg[1] or vim.fn.stdpath("data") .. "/lazy/lean.nvim"
local root = dir .. "/lua"

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local modules = {}
for _, path in ipairs(vim.fn.globpath(root, "**/*.lua", false, true)) do
    local mod = vim.fs.relpath(root, path):gsub("%.lua$", "")
        :gsub("/init$", ""):gsub("/", ".")
    modules[#modules + 1] = { name = mod, path = path }
end
check("lean.nvim is installed", #modules > 0, dir)

local kept = la.rewrite("lean.indent", "· ⊢ → ← • ▶")
check("notation is kept outside the scoped modules",
    kept == "· ⊢ → ← • >", kept)
check("a scoped swap applies in its module",
    la.rewrite("lean.module_hierarchy", "a · b") == "a | b",
    la.rewrite("lean.module_hierarchy", "a · b"))

-- Lean notation the plugin matches on or prints as part of a goal, and µ.
local allowed = { ["⊢"] = true, ["✝"] = true, ["·"] = true, ["µ"] = true }
local strings = vim.treesitter.query.parse("lua", "(string) @s")
local left = {}
for _, m in ipairs(modules) do
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
end
check("no glyph is left in a string literal", #left == 0, left)

la.install(dir)
vim.opt.rtp:append(dir)
local broken = {}
for _, m in ipairs(modules) do
    -- Telescope extensions need telescope, which this config doesn't have.
    if not m.name:find("^telescope%.") then
        local ok, err = pcall(require, m.name)
        if not ok then broken[#broken + 1] = m.name .. ": " .. err end
    end
end
check("every module loads rewritten", #broken == 0, broken)
check("modules load through the searcher",
    require("lean.config")().progress_bars.character == "|",
    require("lean.config")().progress_bars.character)

os.exit(failed == 0 and 0 or 1)
