-- Theme mode (dark|light) from the single source of truth (~/.config/isg/theme,
-- written by toggle_theme.sh). Read at startup so new instances always match the
-- current theme — no sed of this file. Falls back to light.
local function isg_theme_mode()
    local cfg = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
    local fh = io.open(cfg .. "/isg/theme", "r")
    if not fh then
        return "light"
    end
    local m = (fh:read("l") or ""):gsub("%s+", "")
    fh:close()
    return (m == "dark" or m == "light") and m or "light"
end
vim.cmd("colorscheme vs_" .. isg_theme_mode())
