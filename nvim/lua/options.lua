-- ============================================================
--                    BASIC SETTINGS
-- ============================================================

-- Leader key (must be set before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable netrw (using nvim-tree instead)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Git messenger: autofocus popup
vim.g.git_messenger_always_into_popup = true

-- Colors
vim.opt.termguicolors = true
vim.opt.background = "light"

-- Colour the terminal cursor from the colorscheme instead of leaving it to
-- Ghostty. The default 'guicursor' names no highlight group, so Neovim never
-- emits OSC 12 and the caret keeps whatever cursor-color the terminal read at
-- launch — which toggle_theme.sh cannot change without a Ghostty reload, and
-- was why the cursor stayed light in a dark editor. Appending -Cursor to each
-- mode makes Neovim set the colour on entry (from `hi Cursor` guibg, defined in
-- both vs_dark and vs_light) and restore it with OSC 112 on exit. Verified to
-- work under TERM=tmux-256color as well, so it survives tmux.
-- The shapes are Neovim's defaults, repeated verbatim; only the group is new.
vim.opt.guicursor = table.concat({
    "n-v-c-sm:block-Cursor",
    "i-ci-ve:ver25-Cursor",
    "r-cr-o:hor20-Cursor",
    "t:block-blinkon500-blinkoff500-TermCursor",
}, ",")

-- Window/terminal title = current file name. tmux captures this as #{pane_title}
-- so it can name the window "nvim:<file>" instead of the cwd (see .tmux.conf
-- automatic-rename-format). %t = filename tail (empty for a [No Name] buffer).
vim.opt.title = true
vim.opt.titlestring = "%t"

-- Wrap
vim.opt.textwidth = 80
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.showbreak = "↳ "
vim.opt.breakindent = true
vim.opt.breakindentopt = "shift:2,min:20"

-- Tabs & indents
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Navigation & search
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.opt.signcolumn = "yes"
vim.opt.incsearch = true
vim.opt.scrolloff = 4

-- Auto-indent
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.copyindent = true

-- Update & timing
vim.opt.showtabline = 0
vim.opt.updatetime = 300
vim.opt.redrawtime = 10000

-- Allow project-specific .nvim.lua config
vim.opt.exrc = true

-- Force the interactive swap dialog instead of the silent W325 auto-ignore
-- when another nvim already has the file open.
vim.api.nvim_create_autocmd("SwapExists", {
    callback = function() vim.v.swapchoice = "" end,
})

-- Clipboard provider, chosen by context:
--   * Local: leave Neovim's default (pbcopy on macOS, xclip/wl on Linux). It
--     writes the OS clipboard via a CLI call, so it works in EVERY terminal --
--     including ones with no OSC 52 support (Terminal.app, Hyper).
--   * Over SSH: pbcopy would target the remote box, so push to the *local*
--     terminal with OSC 52 instead. Needs a terminal that supports OSC 52
--     (Ghostty/iTerm2/kitty/WezTerm/Alacritty), which is what we run.
-- Paste reads the local register rather than querying the terminal (which can
-- hang/prompt) -- use the terminal's own paste (Cmd+V, bracketed) for outside
-- text.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    local osc52 = require("vim.ui.clipboard.osc52")
    local function paste_reg()
        return function()
            return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
        end
    end
    vim.g.clipboard = {
        name = "OSC 52",
        copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
        paste = { ["+"] = paste_reg(), ["*"] = paste_reg() },
    }
end
