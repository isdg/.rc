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
            cmd = { "clangd", "--clang-tidy", "--header-filter=.*" },
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

         vim.lsp.enable({ "clangd", "ty", "rust_analyzer", "gopls", "ts_ls", "zls" })

         -- Disable diagnostic signs (matches coc-settings.json)
         vim.diagnostic.config({ signs = false })

         -- Format on save for specific filetypes
         vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = { "*.json", "*.rs", "*.go", "*.zig" },
            callback = function()
               vim.lsp.buf.format({ async = false })
            end,
         })
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
               ["<CR>"] = cmp.mapping.confirm({ select = true }),
               ["<C-j>"] = cmp.mapping.select_next_item(),
               ["<C-k>"] = cmp.mapping.select_prev_item(),
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
