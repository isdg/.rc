-- ============================================================
--                    LSP / COMPLETION
-- ============================================================
return {
    -- Treesitter highlight. The main branch neither installs parsers from
    -- setup() nor starts highlighting; .rcboot installs lua/ts_parsers.lua.
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        config = function()
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(ev)
                    pcall(vim.treesitter.start, ev.buf)
                end,
            })
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
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "clangd", "rust_analyzer", "gopls", "ts_ls", "zls",
                },
                -- The loop below is the one place that enables servers.
                automatic_enable = false,
            })

            -- Configure LSP servers using neovim 0.11+ native API
            -- Completion capabilities come from blink.cmp's plugin/ file.
            vim.lsp.log.set_level("WARN")

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

            -- Through lspmux when its server is up, so rust-analyzer and its
            -- index outlive this nvim; plain rust-analyzer otherwise.
            local function ra_cmd()
                local ra = vim.fn.exepath("rust-analyzer")
                if ra == "" or vim.fn.executable("lspmux") == 0 then
                    return { "rust-analyzer" }
                end
                return {
                    "sh", "-c",
                    'if lspmux status >/dev/null 2>&1; then '
                        .. 'exec lspmux client --server-path "$1"; fi; '
                        .. 'exec "$1"',
                    "sh", ra,
                }
            end
            local ra_settings = { check = { command = "clippy" } }

            vim.lsp.config("rust_analyzer", {
                cmd = ra_cmd(),
                filetypes = { "rust" },
                root_markers = { "Cargo.toml", "rust-project.json", ".git" },
                settings = { ["rust-analyzer"] = ra_settings },
                -- lspmux drops server-to-client requests, among them
                -- workspace/configuration: settings must come at initialize.
                init_options = ra_settings,
            })

            vim.lsp.config("gopls", {
                cmd = { "gopls" },
                filetypes = { "go", "gomod", "gowork", "gotmpl" },
                root_markers = { "go.mod", "go.work", ".git" },
                settings = {
                    -- semanticTokens: gopls advertises semanticTokensProvider
                    -- unconditionally but its own setting defaults to false, so
                    -- textDocument/semanticTokens/full answers with an empty token
                    -- array and Neovim paints nothing. Without it Go highlighting
                    -- is whatever $VIMRUNTIME/syntax/go.vim manages on its own,
                    -- which leaves types, function names and consts uncoloured.
                    -- Tokens land on the @lsp.type.*.go / @lsp.mod.*.go groups.
                    gopls = { staticcheck = true, semanticTokens = true },
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

    -- Lean 4: infoview + leanls. The server comes from the project's elan
    -- toolchain, not mason, and lean.nvim enables it itself. Its suggested
    -- <LocalLeader> maps stay off; keys live in the plugins layer (<leader><leader>l).
    {
        "Julian/lean.nvim",
        event = { "BufReadPre *.lean", "BufNewFile *.lean" },
    },

    -- Completion (replaces CoC completion)
    {
        "saghen/blink.cmp",
        version = "1.*",
        dependencies = { { "L3MON4D3/LuaSnip", version = "v2.*" } },
        -- Fetch the prebuilt fuzzy matcher here, in Lazy's build step, which
        -- .rcboot runs, instead of on first start.
        build = function()
            local done, err = false, nil
            require("blink.cmp.fuzzy.download").ensure_downloaded(
                function(e) done, err = true, e end)
            vim.wait(120000, function() return done end)
            if err then error(err) end
        end,
        opts = {
            snippets = { preset = "luasnip" },
            sources = { default = { "lsp", "snippets", "buffer", "path" } },
            cmdline = { enabled = false },
            completion = {
                -- <leader>S flips vim.g.completion_autoshow
                -- (rc.d/09-keys-lsp.lua); show() opens the menu regardless.
                menu = {
                    auto_show = function()
                        return vim.g.completion_autoshow ~= false
                    end,
                },
                list = { selection = { preselect = false } },
                documentation = { auto_show = true },
            },
            keymap = {
                preset = "none",
                -- Nothing selected: accept() declines and <CR> is a newline.
                ["<CR>"] = { "accept", "fallback" },
                ["<C-y>"] = { "accept", "fallback" },
                ["<C-e>"] = { "cancel", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" },
                -- Coarse movement, <C-d>/<C-u> as in normal mode, without
                -- inserting the entries passed over. With no menu up, the
                -- insert-mode defaults (|i_CTRL-D|, |i_CTRL-U|) still run.
                ["<C-d>"] = {
                    function(cmp)
                        return cmp.select_next(
                            { count = 4, auto_insert = false })
                    end,
                    "fallback",
                },
                ["<C-u>"] = {
                    function(cmp)
                        return cmp.select_prev(
                            { count = 4, auto_insert = false })
                    end,
                    "fallback",
                },
                -- <C-l>, not <C-Space>: Darwin takes Ctrl+Space for the input
                -- source switcher. One key, three states:
                --   no menu → open it   menu → show docs   docs → hide them
                ["<C-l>"] = {
                    function(cmp)
                        if not cmp.is_menu_visible() then
                            return cmp.show()
                        elseif cmp.is_documentation_visible() then
                            return cmp.hide_documentation()
                        end
                        -- Docs need a selected entry; nothing is preselected.
                        if not cmp.get_selected_item() then
                            cmp.select_next({ auto_insert = false })
                        end
                        vim.schedule(cmp.show_documentation)
                        return true
                    end,
                },
            },
        },
    },
}
