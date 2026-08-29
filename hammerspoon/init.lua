-- ============================================================
--                 HAMMERSPOON CONFIGURATION (isg)
-- ============================================================
-- Open source (MIT) macOS automation in Lua. Config is tracked in
-- ~/.rc/hammerspoon and symlinked to ~/.hammerspoon (see bootstrap).
--
-- Feature: a Spotlight-style translation / dictionary popup on a hotkey.

-- Message port for the `hs` CLI (already on PATH via the homebrew cask). Without
-- this the binary is installed but inert — every call answers "can't access
-- Hammerspoon message port". Loading it makes `hs -c '<lua>'` evaluate in this
-- config, which is the only way to test a hotkey's effects without pressing it.
require("hs.ipc")

local translate = require("translate")

-- Hotkey: ⌘⌃T opens the popup. Change the mods/key here.
translate.bind({ "cmd", "ctrl" }, "t")

-- Auto-copy new screenshots (⌘⇧4 etc.) to the clipboard, keeping the file.
require("screenshot_clip").start()

-- Keyboard scrolling: ⌘⇧J enters scroll mode; then jk (up/down), du (half-page),
-- hl (left/right), hold to scroll smoothly, ⇧ for fast, esc/q/i to exit. Any app.
-- Entering warps the pointer onto the focused window (in Ghostty, onto the
-- focused tmux pane) so the keys scroll what you are looking at — see scroll.lua.
local scroll = require("scroll")
scroll.bind({ "cmd", "shift" }, "j")

-- Auto-reload this config when any file in it changes (so editing is live).
hs.pathwatcher
    .new(hs.configdir, function(files)
        for _, f in ipairs(files) do
            if f:sub(-4) == ".lua" then
                hs.reload()
                return
            end
        end
    end)
    :start()

hs.alert.show("Hammerspoon: config loaded (⌘⌃T translate · ⌘⇧J scroll · 📋 screenshots)")
