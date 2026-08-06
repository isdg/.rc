-- ============================================================
--             RUSSIAN LAYOUT REMAPPING
-- ============================================================
-- Maps Cyrillic keys to their Latin equivalents so Vim commands
-- work on the Russian keyboard layout.

local ru_eng = {
    ["й"]="q", ["ц"]="w", ["у"]="e", ["к"]="r", ["е"]="t",
    ["н"]="y", ["г"]="u", ["ш"]="i", ["щ"]="o", ["з"]="p",
    ["х"]="[", ["ъ"]="]",
    ["ф"]="a", ["ы"]="s", ["в"]="d", ["а"]="f", ["п"]="g",
    ["р"]="h", ["о"]="j", ["л"]="k", ["д"]="l", ["ж"]=";",
    ["э"]="'",
    ["я"]="z", ["ч"]="x", ["с"]="c", ["м"]="v", ["и"]="b",
    ["т"]="n", ["ь"]="m", ["б"]=",", ["ю"]=".", ["ё"]="`",
}

local ru_eng_upper = {
    ["Й"]="Q", ["Ц"]="W", ["У"]="E", ["К"]="R", ["Е"]="T",
    ["Н"]="Y", ["Г"]="U", ["Ш"]="I", ["Щ"]="O", ["З"]="P",
    ["Х"]="{", ["Ъ"]="}",
    ["Ф"]="A", ["Ы"]="S", ["В"]="D", ["А"]="F", ["П"]="G",
    ["Р"]="H", ["О"]="J", ["Л"]="K", ["Д"]="L", ["Ж"]=":",
    ["Э"]='"',
    ["Я"]="Z", ["Ч"]="X", ["С"]="C", ["М"]="V", ["И"]="B",
    ["Т"]="N", ["Ь"]="M", ["Б"]="<", ["Ю"]=">", ["Ё"]="~",
}

-- Merge tables
local all = {}
for k, v in pairs(ru_eng) do all[k] = v end
for k, v in pairs(ru_eng_upper) do all[k] = v end

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
