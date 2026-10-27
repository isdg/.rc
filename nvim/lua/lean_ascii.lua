-- ============================================================
--              LEAN ASCII (lean.nvim UI glyphs as ASCII)
-- ============================================================
-- lean.nvim hardcodes its UI glyphs, so its modules load through a searcher
-- that swaps them for ASCII in the source. Glyphs that are also Lean
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
    ["—"] = "-", ["µ"] = "u",
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

function M.rewrite(modname, src)
    return swap(swap(src, M.per_module[modname] or {}), M.glyphs)
end

-- Serves every module under dir/lua; goes ahead of lazy's and vim.loader's
-- searchers, which sit at index 2 once set up.
function M.install(dir)
    local root = vim.fs.joinpath(dir, "lua")
    table.insert(package.loaders, 2, function(modname)
        local rel = modname:gsub("%.", "/")
        for _, path in ipairs({ root .. "/" .. rel .. ".lua",
            root .. "/" .. rel .. "/init.lua" }) do
            local fd = io.open(path, "rb")
            if fd then
                local src = fd:read("*a")
                fd:close()
                return assert(load(M.rewrite(modname, src), "@" .. path))
            end
        end
    end)
end

return M
