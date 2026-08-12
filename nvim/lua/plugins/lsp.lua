-- ============================================================
--                    LSP / COMPLETION
-- ============================================================
return {
    -- Treesitter (parser installation + highlight)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            -- Install parsers:  :TSInstall c cpp python rust go lua javascript typescript markdown json bash
            require("nvim-treesitter").setup({
                ensure_installed = {
                    "c", "cpp", "python", "rust", "go", "lua", "zig",
                    "javascript", "typescript", "markdown", "json", "bash",
                },
            })
            -- vim.api.nvim_create_autocmd("FileType", {
            --    callback = function()
            --       pcall(vim.treesitter.start)
            --    end,
            -- })
        end,
    },

    -- Mason (LSP server installer)
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "hrsh7th/cmp-nvim-lsp" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "clangd", "rust_analyzer", "gopls", "ts_ls", "zls",
                },
            })

            -- Configure LSP servers using neovim 0.11+ native API
            vim.lsp.set_log_level("WARN")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Apply capabilities to all servers
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            vim.lsp.config("clangd", {
                -- NB: do not add "--header-filter=.*" here. It is a clang-tidy
                -- flag, not a clangd one: clangd does not recognise it, prints its
                -- usage text to stdout and exits 0 without ever serving LSP. The
                -- failure is silent (empty stderr, clean exit code), so no client
                -- attaches in any C/C++ project. Configure header diagnostics in a
                -- per-project .clangd file instead.
                cmd = { "clangd", "--clang-tidy", "--background-index" },
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
                root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
            })

            -- vim.lsp.config("pyright", {
            --    cmd = { "pyright-langserver", "--stdio" },
            --    filetypes = { "python" },
            --    root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
            --    settings = {
            --       python = {
            --          analysis = {
            --             typeCheckingMode = "strict",
            --             autoImportCompletions = true,
            --             diagnosticMode = "workspace",
            --          },
            --       },
            --    },
            -- })

            vim.lsp.config("ty", {
                cmd = { "ty", "server" },
                filetypes = { "python" },
                root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
            })

            vim.lsp.config("rust_analyzer", {
                cmd = { "rust-analyzer" },
                filetypes = { "rust" },
                root_markers = { "Cargo.toml", "rust-project.json", ".git" },
                settings = {
                    ["rust-analyzer"] = { check = { command = "clippy" } },
                },
            })

            vim.lsp.config("gopls", {
                cmd = { "gopls" },
                filetypes = { "go", "gomod", "gowork", "gotmpl" },
                root_markers = { "go.mod", "go.work", ".git" },
                settings = {
                    gopls = { staticcheck = true },
                },
            })

            vim.lsp.config("ts_ls", {
                cmd = { "typescript-language-server", "--stdio" },
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
            })

            vim.lsp.config("zls", {
                cmd = { "zls" },
                filetypes = { "zig", "zir" },
                root_markers = { "build.zig", "build.zig.zon", ".git" },
            })

            -- Only enable servers whose binary is actually present: one missing
            -- executable makes vim.lsp.enable() abort the whole pass, which
            -- silently prevents *every* server from attaching.
            for _, name in ipairs({ "clangd", "ty", "rust_analyzer", "gopls", "ts_ls", "zls" }) do
                local cfg = vim.lsp.config[name]
                local bin = cfg and cfg.cmd and cfg.cmd[1]
                -- bin == nil => cmd comes from lspconfig defaults; leave it alone.
                if bin == nil or vim.fn.executable(bin) == 1 then
                    vim.lsp.enable(name)
                end
            end

            -- Disable diagnostic signs (matches coc-settings.json)
            vim.diagnostic.config({ signs = false })

            -- No format-on-save. json/rust/go/zig used to be reformatted here via
            -- vim.lsp.buf.format on BufWritePre; they are covered on demand by
            -- <leader>F, which falls back to the LSP formatter when conform has no
            -- formatter configured for the filetype.
        end,
    },

    -- Completion (replaces CoC completion)
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    -- Coarse movement, <C-d>/<C-u> as in normal mode. These stay
                    -- scoped to the menu for free: cmp.mapping.select_*_item runs
                    -- fallback() when the menu is closed, so with no menu up the
                    -- insert-mode defaults survive untouched (|i_CTRL-D| removes
                    -- a shiftwidth of indent, |i_CTRL-U| kills what you typed).
                    -- Select, not the Insert default, so a 4-entry jump doesn't
                    -- drag four candidates through the buffer on the way past.
                    ["<C-d>"] = cmp.mapping.select_next_item({
                        behavior = cmp.SelectBehavior.Select,
                        count = 4,
                    }),
                    ["<C-u>"] = cmp.mapping.select_prev_item({
                        behavior = cmp.SelectBehavior.Select,
                        count = 4,
                    }),
                    -- Trigger the menu on demand. This is the escape hatch that
                    -- makes <leader>S (toggle auto-suggestions) usable: it goes
                    -- through cmp.complete(), which ignores
                    -- completion.autocomplete entirely.
                    -- <C-l>, not <C-Space>: macOS binds Ctrl+Space to the input
                    -- source switcher, so the terminal never sees it. Insert-mode
                    -- CTRL-L has no Neovim default (:h i_CTRL-L does not exist —
                    -- CTRL-L is only meaningful inside |i_CTRL-X| completion
                    -- mode), and this is a different mode from the normal-mode
                    -- <C-l> window motion in keymaps/editor.lua.
                    --
                    -- One key, three states, because what you want from it
                    -- depends on what is on screen:
                    --   no menu      → open the menu
                    --   menu, no doc → pin the doc float for the entry
                    --   doc pinned   → put it away
                    -- The float cannot be *entered*: cmp opens it with
                    -- nvim_open_win(..., false, ...) and never focuses it, and
                    -- any window jump leaves insert mode, which closes the menu
                    -- underneath it. Pinning (is_docs_view_pinned) is the
                    -- equivalent — it keeps the float up while <C-j>/<C-k> walk
                    -- the list, instead of it coming and going per entry.
                    ["<C-l>"] = cmp.mapping(function()
                        if not cmp.visible() then
                            cmp.complete()
                        elseif cmp.visible_docs() then
                            cmp.close_docs()
                        else
                            -- completeopt has `noselect`, so a freshly opened
                            -- menu has no selected entry — and open_docs() is a
                            -- no-op without one. Land on the first entry (Select,
                            -- so nothing is written to the buffer) first.
                            if not cmp.get_selected_entry() then
                                cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                            end
                            cmp.open_docs()
                        end
                    end, { "i" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },
}
