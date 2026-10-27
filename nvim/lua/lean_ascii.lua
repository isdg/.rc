-- ============================================================
--              LEAN ASCII (lean.nvim UI glyphs as ASCII)
-- ============================================================
-- lean.nvim hardcodes its UI glyphs, so its Lua loads through a searcher and
-- loadfile that swap them for ASCII in the source. Glyphs that are also Lean
-- notation (· → ← •) are swapped only where a module uses them as chrome.
local M = {}

M.glyphs = {
    ["│"] = "|", ["─"] = "-", ["┼"] = "+", ["┴"] = "+",
    ["┌"] = "+", ["└"] = "+",
    ["╭"] = "+", ["╮"] = "+", ["╰"] = "+", ["╯"] = "+",
    ["▼"] = "v", ["▾"] = "v", ["▶"] = ">",
    ["◦"] = "-", ["▪"] = "+",
    ["▁"] = ".", ["▂"] = ":", ["▃"] = "-", ["▄"] = "=",
    ["▅"] = "+", ["▆"] = "*", ["▇"] = "#", ["█"] = "@",
    ["₍"] = "_(", ["₎"] = ")", ["⁽"] = "^(", ["⁾"] = ")",
    ["—"] = "-",
    ["✅"] = "[x]", ["❌"] = "[ ]",
    ["🎉"] = "*", ["⚒"] = "!", ["🪦 "] = "",
}

M.per_module = {
    ["lean.infoview"] = { ["← "] = "<- " },
    ["lean.module_hierarchy"] = { ["·"] = "|" },
    ["lean.widgets.ProofWidgets.GraphDisplay"] = {
        ["•"] = "*", ["→"] = "->",
    },
    ["tui.html"] = { ["•"] = "*" },
}

local function swap(src, map)
    for from, to in pairs(map) do
        src = src:gsub(vim.pesc(from), function() return to end)
    end
    return src
end

function M.rewrite(name, src)
    return swap(swap(src, M.per_module[name] or {}), M.glyphs)
end

-- lua/lean/infoview.lua is lean.infoview, syntax/leaninfo.lua is
-- syntax.leaninfo.
function M.name(dir, path)
    return (vim.fs.relpath(dir, path):gsub("^lua/", ""):gsub("%.lua$", "")
        :gsub("/init$", ""):gsub("/", "."))
end

local function load_rewritten(dir, path, ...)
    local fd, err = io.open(path, "rb")
    if not fd then return nil, err end
    local src = fd:read("*a")
    fd:close()
    return load(M.rewrite(M.name(dir, path), src), "@" .. path, ...)
end

-- The searcher goes ahead of lazy's and vim.loader's, which sit at index 2
-- once set up. Sourced files (syntax/, ftplugin/) and lsp/ configs are read
-- through the global loadfile instead.
function M.install(dir)
    local root = vim.fs.joinpath(dir, "lua")
    table.insert(package.loaders, 2, function(modname)
        local rel = modname:gsub("%.", "/")
        for _, path in ipairs({ root .. "/" .. rel .. ".lua",
            root .. "/" .. rel .. "/init.lua" }) do
            if vim.uv.fs_stat(path) then
                return assert(load_rewritten(dir, path))
            end
        end
    end)
    local loadfile = _G.loadfile
    _G.loadfile = function(path, ...)
        if path and vim.fs.relpath(dir, path) then
            return load_rewritten(dir, path, ...)
        end
        return loadfile(path, ...)
    end
end

return M
