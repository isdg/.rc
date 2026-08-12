-- ============================================================
--                  LSP keymaps (on attach)
-- ============================================================
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap

-- Global toggle: show/hide diagnostics (virtual text, signs, underlines).
lmap("n", "D", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- Searchable list of all diagnostics (pairs with ]d/[d jump, gK float).
lmap("n", "d", "<cmd>Telescope diagnostics<CR>", { desc = "List diagnostics" })

-- Global toggle: the auto-popping completion menu on/off.
--
-- This flips completion.autocomplete rather than cmp's `enabled`, because
-- `enabled = false` also makes CursorMovedI reset the view: a manually
-- triggered menu would then vanish on the next keystroke. With autocomplete
-- off cmp stays live, so <C-l> still opens the menu and it still filters as
-- you type — the popup just stops appearing unasked.
--
-- cmp.setup() re-merges into the global config and bumps its revision, which
-- is what invalidates cmp's config cache; mutating cmp.get_config() would not.
local autosuggest = true
lmap("n", "S", function()
    local cmp = require("cmp")
    autosuggest = not autosuggest
    cmp.setup({
        completion = {
            autocomplete = autosuggest and { cmp.TriggerEvent.TextChanged } or false,
        },
    })
    vim.notify("Suggestions " .. (autosuggest and "on (auto)" or "off (<C-l> to invoke)"))
end, { desc = "Toggle auto-suggestions" })

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
        map("n", "gy", "<cmd>Telescope lsp_type_definitions<CR>", opts)
        map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
        map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
        map("n", "K", vim.lsp.buf.hover, opts)
        map("n", "gK", function()
            vim.diagnostic.open_float({ scope = "cursor" })
        end, opts)
        map("n", "]d", vim.diagnostic.goto_next, opts)
        map("n", "[d", vim.diagnostic.goto_prev, opts)
    end,
})
