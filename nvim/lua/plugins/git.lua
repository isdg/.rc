-- ============================================================
--                       GIT
-- ============================================================
return {
    -- Git: gutter signs, blame popup, hunk preview
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                current_line_blame = false,
            })
        end,
    },

    -- Git: unified diff & git commands (:Git diff, :Git blame, :Git log).
    -- Also powers the Enter action of fzf.vim's :Commits/:BCommits.
    { "tpope/vim-fugitive" },

    -- Git: commit message popup on current line
    { "rhysd/git-messenger.vim" },
}
