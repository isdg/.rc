-- ============================================================
--                       KEYMAPS
-- ============================================================
-- All keybindings in one place, matching vim/.vimrc exactly.
-- Leader mappings are duplicated for Russian layout via lmap().

local map = vim.keymap.set

-- English → Russian mapping for leader key duplication
local eng_to_ru = {
   q="й", w="ц", e="у", r="к", t="е", y="н", u="г", i="ш", o="щ", p="з",
   a="ф", s="ы", d="в", f="а", g="п", h="р", j="о", k="л", l="д",
   z="я", x="ч", c="с", v="м", b="и", n="т", m="ь",
   Q="Й", W="Ц", E="У", R="К", T="Е", Y="Н", U="Г", I="Ш", O="Щ", P="З",
   A="Ф", S="Ы", D="В", F="А", G="П", H="Р", J="О", K="Л", L="Д",
   Z="Я", X="Ч", C="С", V="М", B="И", N="Т", M="Ь",
}

-- Map leader key for both English and Russian layouts
local function lmap(mode, key, action, opts)
   opts = opts or {}
   map(mode, "<leader>" .. key, action, opts)
   if eng_to_ru[key] then
      map(mode, "<leader>" .. eng_to_ru[key], action, opts)
   end
end


-- ─── File management ────────────────────────────────────────────
lmap("n", "s", "<cmd>w<CR>", { desc = "Save file" })
lmap("n", "M", "<cmd>set number!<CR>", { desc = "Toggle line numbers" })
lmap("n", "w", "<cmd>q<CR>", { desc = "Quit file" })
lmap("n", "W", "<cmd>q!<CR>", { desc = "Quit without saving" })
lmap("n", "Q", "<cmd>qa!<CR>", { desc = "Quit all without saving" })


-- ─── Split management ───────────────────────────────────────────
lmap("n", "h", "<C-w>h", { desc = "Move to left split" })
lmap("n", "j", "<C-w>j", { desc = "Move to below split" })
lmap("n", "k", "<C-w>k", { desc = "Move to above split" })
lmap("n", "l", "<C-w>l", { desc = "Move to right split" })

map("n", "<leader>+", "<cmd>resize +5<CR>", { desc = "Increase height" })
map("n", "<leader>-", "<cmd>resize -5<CR>", { desc = "Decrease height" })
map("n", "<leader><", "<cmd>vertical resize -5<CR>", { desc = "Decrease width" })
map("n", "<leader>>", "<cmd>vertical resize +5<CR>", { desc = "Increase width" })
map("n", "<leader>=", "<C-w>=", { desc = "Equalize splits" })


-- ─── Fuzzy find (Telescope) ─────────────────────────────────────
lmap("n", "p", "<cmd>Files<CR>", { desc = "Find files" })
lmap("n", "b", "<cmd>Buffers<CR>", { desc = "Find buffers" })
lmap("n", "C", "<cmd>BLines<CR>", { desc = "Search in buffer" })
lmap("n", "a", "<cmd>RG<CR>", { desc = "Live ripgrep" })
lmap("n", "A", "<cmd>Rg<CR>", { desc = "Ripgrep (fzf filter)" })
lmap("n", "e", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "Workspace symbols" })
lmap("n", "c", function()
   local params = vim.lsp.util.make_position_params()
   local results = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
   local cursor = vim.api.nvim_win_get_cursor(0)
   local row = cursor[1] - 1
   local name = ""
   local function find_symbol(symbols)
      for _, s in ipairs(symbols or {}) do
         local range = s.range or (s.location and s.location.range)
         if range and row >= range.start.line and row <= range["end"].line then
            name = s.name
            if s.children then find_symbol(s.children) end
         end
      end
   end
   for _, res in pairs(results or {}) do
      find_symbol(res.result)
   end
   require("telescope.builtin").lsp_document_symbols()
end, { desc = "Document symbols (focused)" })
lmap("n", "i", function()
   -- Try LSP first
   local clients = vim.lsp.get_clients({ bufnr = 0 })
   if #clients > 0 then
      local params = vim.lsp.util.make_position_params()
      local results = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
      local row = vim.api.nvim_win_get_cursor(0)[1] - 1
      local parts = {}
      local function walk(symbols)
         for _, s in ipairs(symbols or {}) do
            local range = s.range or (s.location and s.location.range)
            if range and row >= range.start.line and row <= range["end"].line then
               table.insert(parts, s.name)
               if s.children then walk(s.children) end
            end
         end
      end
      for _, res in pairs(results or {}) do
         walk(res.result)
      end
      if #parts > 0 then
         print(table.concat(parts, " > "))
         return
      end
   end
   -- Fallback to Treesitter
   local ok, _ = pcall(vim.treesitter.get_parser)
   if not ok then
      print("(no LSP or Treesitter)")
      return
   end
   local node = vim.treesitter.get_node()
   local parts = {}
   local container_types = {
      -- C/C++
      function_definition = true, declaration = false, class_specifier = true,
      struct_specifier = true, namespace_definition = true, enum_specifier = true,
      -- Rust
      function_item = true, struct_item = true, impl_item = true, enum_item = true, mod_item = true,
      -- Python
      function_definition = true, class_definition = true,
      -- JS/TS
      function_declaration = true, method_definition = true, class_declaration = true,
      arrow_function = true, lexical_declaration = false, variable_declaration = false,
      -- Go
      method_declaration = true,
      -- Lua
      function_call = false,
   }
   local function get_name(n)
      -- Try "name" field first (works for most languages)
      local name = n:field("name")[1]
      if name then return vim.treesitter.get_node_text(name, 0) end
      -- C/C++: function_definition has declarator > function_declarator > declarator (identifier)
      local decl = n:field("declarator")[1]
      if decl then
         -- Unwrap nested declarators (function_declarator -> pointer_declarator -> etc)
         while decl and decl:field("declarator")[1] do
            decl = decl:field("declarator")[1]
         end
         return vim.treesitter.get_node_text(decl, 0)
      end
      return nil
   end
   while node do
      if container_types[node:type()] ~= nil then
         local name = get_name(node)
         if name then
            -- Clean up multiline names
            name = name:match("^[^\n]+") or name
            table.insert(parts, 1, name)
         end
      end
      node = node:parent()
   end
   if #parts > 0 then
      print(table.concat(parts, " > "))
   else
      print("(top level)")
   end
end, { desc = "Show breadcrumb" })
lmap("n", "m", "<cmd>Telescope diagnostics<CR>", { desc = "Diagnostics" })
lmap("n", "f", function()
   require("telescope.builtin").live_grep({ search_dirs = { vim.fn.expand("%:p") } })
end, { desc = "Ripgrep in current file" })
lmap("n", "B", "<cmd>History<CR>", { desc = "Recent files (fzf)" })

-- -- Search across open buffers (equivalent to :Lines)
-- lmap("n", "e", function()
--    require("telescope.builtin").live_grep({ grep_open_files = true })
-- end, { desc = "Search open buffers" })

map("n", "<C-p>", "<cmd>Files<CR>", { desc = "Find files" })


-- ─── Helper: close zen-mode if active, then run cmd ─────────────
-- Splits/sidebars opened from inside zen-mode collapse the floating window
-- in a confusing way (focus jumps, current file looks like it changed).
-- Close zen first so the action lands in the normal layout.
local function exit_zen_then(cmd)
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

-- ─── File tree (nvim-tree, replaces NERDTree) ───────────────────
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
map("n", "<C-f>", exit_zen_then("NvimTreeFindFile"), { desc = "Find file in tree" })


-- ─── Commenting (Comment.nvim, replaces NERDCommenter) ──────────
map("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
map("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })


-- ─── History & clipboard ────────────────────────────────────────
lmap("n", ";", "q:", { desc = "Command history" })
lmap("n", "/", "q/", { desc = "Search history" })

-- Clear search highlights
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Terminal: Esc exits terminal mode
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
map("n", "<C-i>", "<C-o>", { noremap = true, desc = "Jump back" })
map("n", "<C-o>", "<C-i>", { noremap = true, desc = "Jump forward" })

-- Yank to system clipboard (visual mode)
lmap("v", "y", '"+y', { desc = "Yank to clipboard" })

-- Reselect last visual selection
lmap("n", "v", "gv", { desc = "Reselect visual" })


-- ─── Sessions ───────────────────────────────────────────────────
local session_path = vim.fn.stdpath("data") .. "/session.vim"

lmap("n", "<Tab>", "<cmd>mksession! " .. session_path .. "<CR><cmd>echo 'Session saved!'<CR>",
   { desc = "Save session" })
lmap("n", "<S-Tab>", "<cmd>source " .. session_path .. "<CR><cmd>echo 'Session loaded!'<CR>",
   { desc = "Load session" })


-- ─── Zen mode ───────────────────────────────────────────────────
-- lmap("n", "z", "<cmd>Goyo-10<CR>", { desc = "Toggle zen mode (Goyo)" })
lmap("n", "z", "<cmd>ZenMode<CR>", { desc = "Toggle zen mode" })


-- ─── Notes namespace: <leader>n* ────────────────────────────────
-- (<leader>nl = palace-link picker, defined in vim/palace-link.vim)
map("n", "<leader>nt", function()
   -- format: isg 2026-06-04 13:15:42 +0200  (local time + local UTC offset)
   vim.api.nvim_put({ os.date("isg %Y-%m-%d %H:%M:%S %z") }, "c", true, true)
end, { desc = "Insert date stamp (isg, local tz)" })

map("n", "<leader>nT", function()
   -- format: isg 2026-06-04 11:15:42 UTC  (UTC variant of <leader>nt)
   vim.api.nvim_put({ os.date("%Y-%m-%d %H:%M:%S %z") }, "c", true, true)
end, { desc = "Insert date stamp (isg, local tz)" })


-- ─── Git (gitsigns + diffview + fugitive) ───────────────────────
-- Quick blame popup (git-messenger)
lmap("n", "gp", "<cmd>GitMessenger<CR>", { desc = "Git blame popup" })

-- Full blame sidebar (GitLens-style) - navigate with j/k, Enter to see commit
map("n", "<leader>gb", exit_zen_then("Git blame"), { desc = "Git blame sidebar" })
map("n", "<leader>gB", "<cmd>windo set scrollbind<CR><cmd>syncbind<CR>",
   { desc = "Re-sync blame scroll" })

-- Open commit at current line in diffview (see all files changed)
map("n", "<leader>gv", function()
   local blame = vim.fn.system("git blame -l -L " .. vim.fn.line(".") .. "," .. vim.fn.line(".") .. " -- " .. vim.fn.expand("%"))
   local hash = blame:match("^(%x+)")
   if hash and not hash:match("^0+$") then
      vim.cmd("DiffviewOpen " .. hash .. "^!")
   else
      print("No commit for this line")
   end
end, { desc = "Git view commit (all files)" })

map("n", "]c", function() require("gitsigns").nav_hunk("next") end, { desc = "Next git hunk" })
map("n", "[c", function() require("gitsigns").nav_hunk("prev") end, { desc = "Prev git hunk" })

map("n", "<leader>gs", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").stage_hunk()
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git stage hunk" })
map("v", "<leader>gs", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git stage selection" })
map("n", "<leader>gu", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").undo_stage_hunk()
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git unstage hunk" })
map("n", "<leader>gr", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").reset_hunk()
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git reset hunk" })

lmap("n", "gf", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git file history" })
lmap("n", "gl", function()
   local line = vim.fn.line(".")
   local file = vim.fn.expand("%")
   vim.cmd("DiffviewFileHistory -L" .. line .. "," .. line .. ":" .. file)
end, { desc = "Git line history" })
map("n", "<leader>gm", "<cmd>DiffviewFileHistory<CR>", { desc = "Git log (all commits)" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Git close diffview" })
map("n", "<leader>gd", function() require("git_range").pick() end,
   { desc = "Git diff range picker" })
map("n", "<leader>gj", "<cmd>Commits<CR>", { desc = "Git commits (fzf)" })
map("n", "<leader>gk", "<cmd>BCommits<CR>", { desc = "Git commits for current file (fzf)" })


-- ─── LSP keymaps (on attach) ───────────────────────────────────
vim.api.nvim_create_autocmd("LspAttach", {
   callback = function(ev)
      local opts = { buffer = ev.buf, silent = true }
      map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
      map("n", "gy", "<cmd>Telescope lsp_type_definitions<CR>", opts)
      map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
      map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
      map("n", "K", vim.lsp.buf.hover, opts)
      map("n", "ge", function()
         vim.diagnostic.open_float({ scope = "cursor" })
      end, opts)
      map("n", "]d", vim.diagnostic.goto_next, opts)
      map("n", "[d", vim.diagnostic.goto_prev, opts)
   end,
})


-- ─── hrb (reading list) ─────────────────────────────────────────
lmap("n", "r", function() require("hrb").toggle() end,
   { desc = "Toggle hrb reading list" })
