-- ============================================================
--             RUSSIAN LAYOUT REMAPPING
-- ============================================================
local all = require("russian").to_latin

-- Map in normal, visual, operator-pending modes
for ru, en in pairs(all) do
    vim.keymap.set({ "n", "v", "o" }, ru, en, { noremap = true })
end

-- Double-key Russian mappings (dd, yy, cc, gg, zz equivalents)
local ru_jumps = {
    ["вв"]="dd", ["фф"]="yy", ["сс"]="cc", ["пп"]="gg", ["яя"]="zz",
}

for ru, en in pairs(ru_jumps) do
    vim.keymap.set({ "n", "v" }, ru, en, { noremap = true })
end
