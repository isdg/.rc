-- ============================================================
--                  LEADER-KEY HELPER
-- ============================================================
-- Shared by every keymaps/*.lua domain file: map() is plain vim.keymap.set,
-- lmap() additionally duplicates a <leader>-prefixed mapping onto its
-- Russian-layout equivalent key.

local M = {}

M.map = vim.keymap.set

-- English → Russian mapping for leader key duplication
local eng_to_ru = {
   q="й", w="ц", e="у", r="к", t="е", y="н", u="г", i="ш", o="щ", p="з",
   a="ф", s="ы", d="в", f="а", g="п", h="р", j="о", k="л", l="д",
   z="я", x="ч", c="с", v="м", b="и", n="т", m="ь",
   Q="Й", W="Ц", E="У", R="К", T="Е", Y="Н", U="Г", I="Ш", O="Щ", P="З",
   A="Ф", S="Ы", D="В", F="А", G="П", H="Р", J="О", K="Л", L="Д",
   Z="Я", X="Ч", C="С", V="М", B="И", N="Т", M="Ь",
}

-- Map leader key for both English and Russian layouts
function M.lmap(mode, key, action, opts)
   opts = opts or {}
   M.map(mode, "<leader>" .. key, action, opts)
   if eng_to_ru[key] then
      M.map(mode, "<leader>" .. eng_to_ru[key], action, opts)
   end
end

return M
