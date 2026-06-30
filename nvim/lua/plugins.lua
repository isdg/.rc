-- ============================================================
--                       PLUGINS
-- ============================================================
-- Plugin specs for lazy.nvim. Each entry is the neovim-native
-- equivalent of a vim-plug plugin from the original vimrc.

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

   -- File tree (replaces NERDTree)
   {
      "nvim-tree/nvim-tree.lua",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
         -- Session-scoped stack of previous roots, for back-navigation.
         local root_history = {}
         local function tree_root()
            local ok, core = pcall(require, "nvim-tree.core")
            local e = ok and core.get_explorer()
            return e and e.absolute_path or nil
         end

         require("nvim-tree").setup({
            view = { width = 40, number = true },
            filters = { dotfiles = false, git_ignored = false },
            on_attach = function(bufnr)
               local api = require("nvim-tree.api")
               api.config.mappings.default_on_attach(bufnr) -- keep all defaults

               local function push() -- remember the root we're leaving
                  local r = tree_root()
                  if r then table.insert(root_history, r) end
               end
               -- change-root actions that record history first
               local function to_node() push(); api.tree.change_root_to_node() end
               local function to_parent() push(); api.tree.change_root_to_parent() end
               -- pop the stack and return to the previous root (does not re-push)
               local function back()
                  local prev = table.remove(root_history)
                  if prev then
                     api.tree.change_root(prev)
                  else
                     vim.notify("nvim-tree: no previous root", vim.log.levels.INFO)
                  end
               end

               local function map(lhs, fn, desc)
                  vim.keymap.set("n", lhs, fn,
                     { buffer = bufnr, noremap = true, silent = true, desc = desc })
               end
               map("C", to_node, "nvim-tree: change root to node (+history)")
               map("<C-]>", to_node, "nvim-tree: change root to node (+history)")
               map("-", to_parent, "nvim-tree: root to parent (+history)")
               map("<C-o>", back, "nvim-tree: previous root (back)")
            end,
         })
      end,
   },

   -- fzf.vim (fast native fzf for file finding)
   {
      "junegunn/fzf",
      build = "./install --all",
   },
   {
      "junegunn/fzf.vim",
      init = function()
      vim.g.fzf_commits_log_options = '--color=always --format="%C(auto)%h%d %s %C(blue)[%an]%C(reset) %C(black)%C(bold)%cr"'
      end,
   },

   -- Fuzzy finder (replaces fzf.vim)
   {
      "nvim-telescope/telescope.nvim",
      dependencies = {
         "nvim-lua/plenary.nvim",
         { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      },
      config = function()
         local telescope = require("telescope")
         telescope.setup({
            defaults = {
               vimgrep_arguments = {
                  "rg", "--color=never", "--no-heading", "--with-filename",
                  "--line-number", "--column", "--smart-case", "--hidden",
                  "--glob", "!.git/",
               },
            },
            pickers = {
               find_files = {
                  hidden = true,
                  no_ignore = true,
                  file_ignore_patterns = {
                     "^%.git/", "node_modules/", "__pycache__/",
                     "%.mypy_cache/", "%.ruff_cache/", "%.pytest_cache/",
                  },
               },
            },
         })
         telescope.load_extension("fzf")
      end,
   },

   -- Commenting (replaces NERDCommenter)
   {
      "numToStr/Comment.nvim",
      config = function()
         require("Comment").setup()
      end,
   },

   -- Zen mode (Goyo — commented out)
   -- {
   --    "junegunn/goyo.vim",
   --    config = function()
   --       vim.g.goyo_width = 80
   --       vim.g.goyo_height = "100%"
   --       vim.g.goyo_linenr = 1
   --    end,
   -- },

   -- Zen mode
   {
      "isaigordeev/zen-mode.nvim",
      config = function()
         require("zen-mode").setup({
            window = {
               -- A floating window's width is the *total* width -- the
               -- line-number gutter and sign column are drawn inside it. So
               -- plain `width = 80` gives only ~74 cols of text. Return
               -- 80 + gutters so the actual TEXT column is a true 80.
               width = function()
                  local text = 80
                  local gutter = 0
                  if vim.wo.number or vim.wo.relativenumber then
                     -- numberwidth, or wider if the file needs more digits
                     local digits = #tostring(vim.api.nvim_buf_line_count(0)) + 1
                     gutter = gutter + math.max(vim.o.numberwidth, digits)
                  end
                  local sc = vim.wo.signcolumn
                  if sc == "yes" or sc == "auto" then
                     gutter = gutter + 2
                  else
                     local n = sc:match("^yes:(%d+)")
                     if n then gutter = gutter + 2 * tonumber(n) end
                  end
                  return text + gutter
               end,
               col_offset = -20,
               options = {
                  number = true,
                  wrap = true,
                  linebreak = true,
                  breakindent = true,
               },
            },
         })
      end,
   },

   -- Rainbow delimiters (replaces luochen1990/rainbow)
   { "HiPhish/rainbow-delimiters.nvim" },

   -- Formatter (prettier for markdown)
   {
      "stevearc/conform.nvim",
      config = function()
         require("conform").setup({
            formatters_by_ft = {
               markdown = { "prettier" },
               python = { "ruff_format", "ruff_organize_imports" },
            },
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
         })
         vim.api.nvim_create_autocmd("FileType", {
            pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
            callback = function() vim.b.conform_on_save_disabled = true end,
         })
      end,
   },

   -- Git: gutter signs, blame popup, hunk preview
   {
      "lewis6991/gitsigns.nvim",
      config = function()
         require("gitsigns").setup({
            current_line_blame = false,
         })
      end,
   },

   -- Git: full commit/diff browser
   {
      "sindrets/diffview.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
         local actions = require("diffview.actions")
         require("diffview").setup({
            keymaps = {
               file_history_panel = {
                  -- Press <leader>go on a commit to see ALL files in that commit
                  { "n", "<leader>go", function()
                     -- Get commit hash from current line
                     local line = vim.fn.getline(".")
                     local hash = line:match("(%x%x%x%x%x%x%x+)")
                     if hash then
                        vim.cmd("DiffviewClose")
                        vim.schedule(function()
                           vim.cmd("DiffviewOpen " .. hash .. "^!")
                        end)
                     end
                  end, { desc = "Open commit (all files)" } },
               },
            },
         })
      end,
   },

   -- Git: unified diff & git commands (:Git diff, :Git blame, :Git log)
   { "tpope/vim-fugitive" },

   -- Git: commit message popup on current line
   { "rhysd/git-messenger.vim" },

   -- Claude Code IDE integration. nvim acts as the IDE; the `claude` CLI
   -- (run in a separate terminal in the same project) auto-discovers this
   -- instance and pipes proposed edits as vim diff buffers.
   {
      "coder/claudecode.nvim",
      dependencies = { "folke/snacks.nvim" },
      opts = {
         diff_opts = { layout = "horizontal" },
      },
   },

   -- ANSI colorizer for captured tmux scrollback (prefix N). Renders raw
   -- escape sequences as real highlights while keeping text searchable.
   -- lazy = true: only loaded when require("baleia") is called, which happens
   -- exclusively from the tmux capture launch -- never in normal editing.
   {
      "m00qek/baleia.nvim",
      lazy = true,
   },

   -- hr: reading-list sidebar over the `hr` CLI. Portable Vimscript plugin
   -- (works in vim too); replaces the old lua/hr/init.lua module. Loaded on
   -- the :Hr* commands, fired by <leader>r (see lua/keymaps.lua).
   {
      "isdg/hr.vim",
      cmd = { "Hr", "HrToggle", "HrOpen", "HrClose", "HrStart", "HrRefresh", "HrSync" },
   },

   -- flash: label-based visual jump (the avy/EasyMotion equivalent). Trigger,
   -- type 1-2 chars of any on-screen target, then a label appears -- type it to
   -- jump. O(1) regardless of distance, complementing <leader>C (BLines) which
   -- is search-list style. Single binding for now; format lives on <leader>F.
   --   <leader>f -> jump (normal/visual/operator-pending: d<leader>f<label>)
   --   <c-s>     -> toggle flash labels while typing a / search (no vi conflict)
   {
      "folke/flash.nvim",
      event = "VeryLazy",
      -- modes.search.enabled = true: show jump labels on every / and ? search
      -- automatically (no need to press <c-s> first). <c-s> still toggles it off
      -- mid-search if a particular search gets too noisy.
      opts = {
         modes = { search = { enabled = true } },
      },
      keys = {
         { "<leader>f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
         { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
      },
   },

   -- harpoon: pin the handful of files in the current task to ordered slots and
   -- jump to them with one keystroke (stable slot, cursor position preserved).
   -- Per-project list, persisted across sessions. All under the <leader>h prefix
   -- (freed by moving split-nav to <C-h/j/k/l>):
   --   <leader>ha  -> add current file to the list
   --   <leader>he  -> toggle the quick menu (reorder/delete inline)
   --   <leader>h1..h4 -> jump to slot 1-4
   {
      "ThePrimeagen/harpoon",
      branch = "harpoon2",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
         local harpoon = require("harpoon")
         harpoon:setup()
         local map = vim.keymap.set
         map("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon add file" })
         map("n", "<leader>he", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })
         for i = 1, 4 do
            map("n", "<leader>h" .. i, function() harpoon:list():select(i) end,
               { desc = "Harpoon jump to " .. i })
         end
      end,
   },

   -- TODO: nvim-dap (Debug Adapter Protocol) - enable after learning raw GDB
   -- Plugins: mfussenegger/nvim-dap, rcarriga/nvim-dap-ui, theHamsta/nvim-dap-virtual-text
   -- Install codelldb via Mason: :MasonInstall codelldb
}
