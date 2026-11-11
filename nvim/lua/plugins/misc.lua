-- ============================================================
--                       MISC
-- ============================================================
return {
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
    -- the :Hr* commands, fired by <leader><leader>h (rc.d/10-keys-plugins.lua),
    -- and on opening any markdown file, so its autocmd logs vault articles
    -- opened from hrl or the shell for `hr recent`.
    {
        "isdg/hr.vim",
        event = "BufReadPost *.md",
        cmd = {
            "Hr", "HrToggle", "HrOpen", "HrClose", "HrStart", "HrRefresh",
            "HrSync", "HrLocate", "HrBookmark", "HrResume", "HrView",
        },
    },
}
