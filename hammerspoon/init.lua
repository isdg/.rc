-- ============================================================
--                 HAMMERSPOON CONFIGURATION (isg)
-- ============================================================
-- Open source (MIT) macOS automation in Lua. Config is tracked in
-- ~/.dotfiles/hammerspoon and symlinked to ~/.hammerspoon (see bootstrap).
--
-- Feature: a Spotlight-style translation / dictionary popup on a hotkey.

local translate = require("translate")

-- Hotkey: ⌘⌃T opens the popup. Change the mods/key here.
translate.bind({ "cmd", "ctrl" }, "t")

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

hs.alert.show("Hammerspoon: config loaded (⌘⌃T = translate)")
