-- ============================================================
--                  NAVIGATION / FUZZY FIND
-- ============================================================
return {
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
                -- Close the tree once a file is opened: the explorer is for picking
                -- a file, not for living next to the buffer. Same as NERDTreeQuitOnOpen
                -- in vim/rc.d/05-nerdtree.vim. Reopen with <leader>t.
                actions = { open_file = { quit_on_open = true } },
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

    -- Window, previewer and actions behind lua/lsp_picker.lua, plus code actions
    -- and vim.ui.select, on fzf.vim's fzf binary and $FZF_DEFAULT_OPTS_FILE.
    {
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local fzf_lua = require("fzf-lua")
            fzf_lua.setup({
                -- Mirrors vim/fzf-layout.vim: full screen, preview below at 60%.
                winopts = {
                    fullscreen = true,
                    preview = { layout = "vertical", vertical = "down:60%" },
                },
                -- fzf.vim leaves layout and info to fzf, and our binds live in
                -- the opts file, so drop fzf-lua's overrides of both.
                fzf_opts = { ["--layout"] = "default", ["--info"] = false },
                keymap = {
                    fzf = {},
                    -- The builtin previewer is an nvim window fzf can't see, so
                    -- fzf.vim's ctrl-/ toggle has to be an nvim map here.
                    builtin = { true, ["<C-/>"] = "toggle-preview", ["<C-_>"] = "toggle-preview" },
                },
            })
            fzf_lua.register_ui_select()
        end,
    },


    -- flash: label-based visual jump (the avy/EasyMotion equivalent). Trigger,
    -- type 1-2 chars of any on-screen target, then a label appears -- type it to
    -- jump. O(1) regardless of distance, complementing <leader>l (BLines) which
    -- is search-list style. Single binding for now; format lives on <leader>F.
    --   <leader>j -> jump (normal/visual/operator-pending: d<leader>j<label>)
    --   <c-s>     -> toggle flash labels while typing a / search (no vi conflict)
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        -- modes.search.enabled = true: show jump labels on every / and ? search
        -- automatically (no need to press <c-s> first). <c-s> still toggles it off.
        opts = {
            modes = { search = { enabled = true } },
        },
        config = function(_, opts)
            require("flash").setup(opts)
            -- FlashBackdrop (the dimmed non-matched text while flash/char mode is
            -- active) links to Comment, which is gui=italic in the vs_* themes, so
            -- triggering flash italicizes the whole screen. Keep the dim colour but
            -- drop the italic; re-apply on ColorScheme so it survives the toggle.
            local function fix_backdrop()
                local c = vim.api.nvim_get_hl(0, { name = "Comment" })
                vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = c.fg, italic = false })
            end
            fix_backdrop()
            vim.api.nvim_create_autocmd("ColorScheme", { callback = fix_backdrop })
        end,
        keys = {
            { "<leader>j", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
            { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
    },

    -- harpoon: pin the handful of files in the current task to ordered slots and
    -- jump to them with one keystroke (stable slot, cursor position preserved).
    -- Per-project list, persisted across sessions. All under the <leader>u prefix
    -- (split-nav stays on <leader>h/j/k/l):
    --   <leader>ua  -> add current file to the list
    --   <leader>ud  -> remove current file from the list (or dd a line in the menu)
    --   <leader>ue  -> toggle the quick menu (reorder/delete inline)
    --   <leader>u1..u9, u0 -> jump to slot 1-10
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")
            -- save_on_toggle: persist menu edits (e.g. dd to delete a line) when the
            -- menu closes via q/<Esc>, not just on :w. Without it, deletions are lost.
            harpoon:setup({
                settings = { save_on_toggle = true },
            })
            local map = vim.keymap.set
            map("n", "<leader>ua", function() harpoon:list():add() end, { desc = "Harpoon add file" })
            map("n", "<leader>ud", function() harpoon:list():remove() end, { desc = "Harpoon remove file" })
            map("n", "<leader>ue", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })
            for i = 1, 10 do
                local key = (i == 10) and "0" or tostring(i)
                map("n", "<leader>u" .. key, function() harpoon:list():select(i) end,
                    { desc = "Harpoon jump to " .. i })
            end
        end,
    },
}
