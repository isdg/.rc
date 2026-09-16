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
-- for hover), l and L list them. <leader>d is a prefix and nothing else — leaving
-- the list on the bare <leader>d as well would make every press of it sit out
-- 'timeoutlen' first, waiting to see whether a k or an l follows.
--
-- Global rather than on LspAttach, where the float used to live as gK: a
-- diagnostic need not come from a language server, and its two siblings here
-- are global already.
lmap("n", "dk", function()
    vim.diagnostic.open_float({ scope = "cursor" })
end, { desc = "Diagnostic under cursor" })

-- Searchable list of diagnostics (pairs with ]d/[d jump, <leader>dk float).
-- Lowercase is this buffer, uppercase widens it, the same split <leader>l/L and
-- <leader>e/E use in keymaps/find.lua.
lmap("n", "dl", function()
    require("telescope.builtin").diagnostics({ bufnr = 0 })
end, { desc = "List diagnostics (buffer)" })

-- The repo root rather than the cwd, because nvim is as often started a few
-- directories inside it. Trailing slash: telescope's root_dir filter is a raw
-- prefix match on the filename, so ".../.rc" without it also keeps ".../.rc-main".
--
-- Scope is what the servers have already published — clangd and ts_ls only
-- diagnose files you have opened, rust_analyzer and gopls report the whole
-- crate or package. Nothing here opens files to make them report more.
lmap("n", "dL", function()
    local root = vim.fs.root(0, ".git") or vim.uv.cwd()
    require("telescope.builtin").diagnostics({ root_dir = root .. "/" })
end, { desc = "List diagnostics (repo)" })

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

        -- <leader>df: act on what dk just read. It completes the <leader>d verb
        -- set — k reads the diagnostic, l/L list them, f fixes it — so the
        -- thing you do *about* a diagnostic sits with the two that show it to
        -- you, and the whole group stays one key apart. Named for the intent
        -- (fix) rather than the LSP's word for the mechanism (code action):
        -- the list it opens is reached because something is wrong on this line.
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
        lmap("n", "df", vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "Fix diagnostic (code action)" }))
    end,
})
