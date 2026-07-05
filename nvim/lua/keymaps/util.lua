-- ============================================================
--                  KEYMAP HELPERS (shared, non-leader)
-- ============================================================

local M = {}

-- Close zen-mode if active, then run cmd. Splits/sidebars opened from inside
-- zen-mode collapse the floating window in a confusing way (focus jumps,
-- current file looks like it changed). Close zen first so the action lands
-- in the normal layout.
function M.exit_zen_then(cmd)
   return function()
      local ok, view = pcall(require, "zen-mode.view")
      if ok and view.is_open() then
         require("zen-mode").close()
         -- Defer so zen-mode finishes restoring the original window/buffer
         -- before the command runs; otherwise NvimTreeFindFile lands on
         -- the floating buffer instead of the actual file.
         vim.schedule(function() vim.cmd(cmd) end)
      else
         vim.cmd(cmd)
      end
   end
end

return M
