-- ============================================================
--                       MISC
-- ============================================================
return {
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
      cmd = { "Hr", "HrToggle", "HrOpen", "HrClose", "HrStart", "HrRefresh", "HrSync", "HrLocate" },
   },

   -- TODO: nvim-dap (Debug Adapter Protocol) - enable after learning raw GDB
   -- Plugins: mfussenegger/nvim-dap, rcarriga/nvim-dap-ui, theHamsta/nvim-dap-virtual-text
   -- Install codelldb via Mason: :MasonInstall codelldb
}
