-- ============================================================
--                       BREADCRUMB
-- ============================================================
-- LSP-first, Treesitter-fallback symbol path ("function > class > method")
-- across C/C++/Rust/Python/JS/TS/Go/Lua.

local M = {}

function M.show()
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
end

return M
