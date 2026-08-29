-- ============================================================
--                  LSP keymaps (on attach)
-- ============================================================
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap

-- Global toggle: show/hide diagnostics (virtual text, signs, underlines).
lmap("n", "D", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- Diagnostics sit under <leader>d: k reads the one under the cursor (k as in K
-- for hover), l lists them all. <leader>d is a prefix and nothing else — leaving
-- the list on the bare <leader>d as well would make every press of it sit out
-- 'timeoutlen' first, waiting to see whether a k or an l follows.
--
-- Global rather than on LspAttach, where the float used to live as gK: a
-- diagnostic need not come from a language server, and its two siblings here
-- are global already.
lmap("n", "dk", function()
    vim.diagnostic.open_float({ scope = "cursor" })
end, { desc = "Diagnostic under cursor" })

-- Searchable list of all diagnostics (pairs with ]d/[d jump, <leader>dk float).
lmap("n", "dl", "<cmd>Telescope diagnostics<CR>", { desc = "List diagnostics" })

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
        map("n", "]d", vim.diagnostic.goto_next, opts)
        map("n", "[d", vim.diagnostic.goto_prev, opts)

        -- <leader>da: act on what dk just read. It completes the <leader>d verb
        -- set — k reads the diagnostic, l lists them all, a offers the fixes —
        -- so the thing you do *about* a diagnostic sits with the two that show
        -- it to you, and the whole group stays one key apart.
        --
        -- On LspAttach rather than global, unlike its dk/dl siblings, and the
        -- split is not arbitrary: those two are global precisely because a
        -- diagnostic need not come from a language server, while a code action
        -- by definition does. Buffer-local also means the key is simply absent
        -- where nothing could answer it, instead of opening an empty menu.
        --
        -- The picker, not code_action({ apply = true }): the first action is not
        -- reliably the fix you want — "add import" and "ignore this rule" sit
        -- side by side in the same list — and silently applying an edit you did
        -- not choose is worse than one extra keypress.
        lmap("n", "da", vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "Code action (fix diagnostic)" }))
    end,
})
