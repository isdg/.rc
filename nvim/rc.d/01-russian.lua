-- ============================================================
--             RUSSIAN LAYOUT REMAPPING
-- ============================================================
local all = require("russian").to_latin

-- Map in normal, visual, operator-pending modes
for ru, en in pairs(all) do
    vim.keymap.set({ "n", "v", "o" }, ru, en)
end

-- Under extended keys Ctrl+т reaches nvim as <C-т>, not <C-n>, so insert and
-- cmdline Ctrl keys get twins; remap lets blink's own <C-n> map answer.
for ru, en in pairs(all) do
    if en:match("^[a-z%[%]]$") then
        vim.keymap.set({ "i", "c" }, "<C-" .. ru .. ">", "<C-" .. en .. ">",
            { remap = true })
    end
end

-- Double-key Russian mappings (dd, yy, cc, gg, zz equivalents)
local ru_jumps = {
    ["вв"]="dd", ["фф"]="yy", ["сс"]="cc", ["пп"]="gg", ["яя"]="zz",
}

for ru, en in pairs(ru_jumps) do
    vim.keymap.set({ "n", "v" }, ru, en)
end
