-- ============================================================
--                  EDITING / FORMATTING
-- ============================================================
return {
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
        "isdg/zen-mode.nvim",
        config = function()
            -- Guard for the case where vim.g.zen_height is unset. options.lua sets
            -- it at startup, so in practice this never decides the height — it is
            -- named once anyway so the height function and :ZenHeight's readout
            -- cannot report different numbers.
            local DEFAULT_HEIGHT = 0.9

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
                    -- Height comes from `vim.g.zen_height` so it can be
                    -- changed at runtime (see :ZenHeight below). <= 1 is a
                    -- fraction of the editor height, > 1 is a row count.
                    -- Default 0.9 leaves a margin above and below rather than
                    -- filling the screen edge to edge.
                    height = function()
                        local h = tonumber(vim.g.zen_height) or DEFAULT_HEIGHT
                        local max = vim.o.lines - vim.o.cmdheight
                        if vim.o.laststatus == 3 then max = max - 1 end
                        return h <= 1 and max * h or h
                    end,
                    col_offset = -20,
                    options = {
                        number = false,
                        wrap = true,
                        linebreak = true,
                        breakindent = true,
                    },
                },
            })

            -- :ZenHeight            → show the current value
            -- :ZenHeight 0.8        → 80% of the editor height
            -- :ZenHeight 30         → 30 rows
            -- If zen mode is open, reopen it so the change is visible now.
            vim.api.nvim_create_user_command("ZenHeight", function(args)
                if args.args == "" then
                    vim.notify("zen height: " .. tostring(vim.g.zen_height or DEFAULT_HEIGHT))
                    return
                end
                local h = tonumber(args.args)
                if not h or h <= 0 then
                    vim.notify("ZenHeight: expected a positive number", vim.log.levels.ERROR)
                    return
                end
                vim.g.zen_height = h
                local ok, view = pcall(require, "zen-mode.view")
                if ok and view.is_open() then
                    require("zen-mode").close()
                    vim.schedule(function() require("zen-mode").open() end)
                end
            end, { nargs = "?", desc = "Get/set zen-mode window height" })
        end,
    },

    -- Rainbow delimiters (replaces luochen1990/rainbow)
    { "HiPhish/rainbow-delimiters.nvim" },

    -- Formatter (prettier for markdown). Formatting is on demand only —
    -- <leader>F, see keymaps/edit.lua. No format_on_save here on purpose: a save
    -- should write the file and nothing else. The per-filetype opt-outs this used
    -- to need (TS/JS via a conform_on_save_disabled flag) went with it.
    {
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    markdown = { "prettier" },
                    python = { "ruff_format", "ruff_organize_imports" },
                },
            })
        end,
    },
}
