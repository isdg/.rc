-- ============================================================
--                       STRUCTURE
-- ============================================================
-- LSP-first, Treesitter-fallback symbol tree of the buffer, opened in fzf:
-- the object the cursor is in, or the whole file, under the path to the
-- cursor ("class > method").

local M = {}

-- Treesitter containers and the kind each shows as, across C/C++/Rust/Python/
-- JS/TS/Go/Lua. function_definition and function_declaration are shared names.
local TS_KINDS = {
    function_definition = "Function", class_specifier = "Class",
    struct_specifier = "Struct", namespace_definition = "Namespace",
    enum_specifier = "Enum",
    function_item = "Function", struct_item = "Struct", impl_item = "Impl",
    enum_item = "Enum", mod_item = "Module",
    class_definition = "Class",
    function_declaration = "Function", method_definition = "Method",
    class_declaration = "Class", arrow_function = "Function",
    method_declaration = "Method",
}

-- A node: name, kind, lnum/col (1-based, of the name), first/last (0-based
-- rows of the whole extent), children.

-- LSP columns count in the server's encoding (UTF-16 by default), not bytes.
local function byte_col(bufnr, pos, encoding)
    local row = pos.line
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    local ok, col = pcall(vim.str_byteindex, line or "", encoding,
        pos.character, false)
    return (ok and col or pos.character) + 1
end

-- Positions, not rows: a one-line struct and its fields share every row.
local function before(a, b)
    return a.line < b.line or a.line == b.line and a.character < b.character
end

local function contains(outer, inner)
    return not before(inner.from, outer.from) and not before(outer.to, inner.to)
end

-- SymbolInformation is a flat list, so its hierarchy is rebuilt from ranges.
local function nest(flat)
    for i, n in ipairs(flat) do n.index = i end
    table.sort(flat, function(a, b)
        if before(a.from, b.from) then return true end
        if before(b.from, a.from) then return false end
        if before(b.to, a.to) then return true end
        if before(a.to, b.to) then return false end
        return a.index < b.index
    end)
    local roots, stack = {}, {}
    for _, n in ipairs(flat) do
        while #stack > 0 and not contains(stack[#stack], n) do
            table.remove(stack)
        end
        local parent = stack[#stack]
        table.insert(parent and parent.children or roots, n)
        stack[#stack + 1] = n
    end
    return roots
end

local function lsp_nodes(bufnr)
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
    }
    local results = vim.lsp.buf_request_sync(bufnr,
        "textDocument/documentSymbol", params, 1000)
    for client_id, res in pairs(results or {}) do
        local symbols = res.result
        if symbols and #symbols > 0 then
            local client = vim.lsp.get_client_by_id(client_id)
            local enc = client and client.offset_encoding or "utf-16"
            local flat = symbols[1].location ~= nil
            local function convert(s)
                local range = s.range or s.location.range
                local at = (s.selectionRange or range).start
                local n = {
                    name = s.name,
                    kind = vim.lsp.protocol.SymbolKind[s.kind] or "?",
                    lnum = at.line + 1,
                    col = byte_col(bufnr, at, enc),
                    first = range.start.line,
                    last = range["end"].line,
                    from = range.start,
                    to = range["end"],
                    children = {},
                }
                for _, c in ipairs(s.children or {}) do
                    n.children[#n.children + 1] = convert(c)
                end
                return n
            end
            local nodes = vim.tbl_map(convert, symbols)
            return flat and nest(nodes) or nodes
        end
    end
end

-- The "name" field; for C/C++ the innermost declarator under
-- function_declarator, pointer_declarator and the like; for a Rust impl, its
-- type.
local function name_node(n)
    local name = n:field("name")[1]
    if name then return name end
    local decl = n:field("declarator")[1]
    while decl and decl:field("declarator")[1] do
        decl = decl:field("declarator")[1]
    end
    return decl or n:field("type")[1]
end

local function ts_nodes(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then return nil end
    -- An unnamed container (an arrow function) passes its children up.
    local function walk(tsnode, out)
        for child in tsnode:iter_children() do
            local kind = TS_KINDS[child:type()]
            local name = kind and name_node(child)
            if name then
                local first, _, last = child:range()
                local lnum, col = name:range()
                local text = vim.treesitter.get_node_text(name, bufnr)
                local n = {
                    name = text:match("^[^\n]*"),
                    kind = kind,
                    lnum = lnum + 1,
                    col = col + 1,
                    first = first,
                    last = last,
                    children = {},
                }
                out[#out + 1] = n
                walk(child, n.children)
            else
                walk(child, out)
            end
        end
    end
    local roots = {}
    walk(parser:parse()[1]:root(), roots)
    return roots
end

local function symbols(bufnr)
    if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
        local nodes = lsp_nodes(bufnr)
        if nodes then return nodes end
    end
    return ts_nodes(bufnr)
end

-- The nodes whose extent holds row, outermost first.
local function path(nodes, row)
    local out = {}
    while true do
        local inner
        for _, n in ipairs(nodes) do
            if n.first <= row and row <= n.last then inner = n break end
        end
        if not inner then return out end
        out[#out + 1] = inner
        nodes = inner.children
    end
end

local function cursor_row()
    return vim.api.nvim_win_get_cursor(0)[1] - 1
end

-- scope "object" is the outermost symbol on the cursor's path, or the whole
-- file outside every symbol; "file" is always the whole file. fzf opens on
-- the innermost symbol holding the cursor, the last link of that path.
function M.tree(scope)
    local bufnr = vim.api.nvim_get_current_buf()
    local nodes = symbols(bufnr) or {}
    if #nodes == 0 then
        vim.notify("No symbols found", vim.log.levels.INFO)
        return
    end
    local trail = path(nodes, cursor_row())
    local whole = scope == "file" or #trail == 0
    local roots = whole and nodes or { trail[1] }
    local here = trail[#trail]
    local file = vim.api.nvim_buf_get_name(bufnr)

    local items, at = {}, nil
    local function add(n, lead, branch)
        items[#items + 1] = {
            filename = file, lnum = n.lnum, col = n.col, verbatim = true,
            text = ("%s%s%s  \27[90m%s\27[0m"):format(lead, branch, n.name,
                n.kind),
        }
        if n == here then at = #items end
        local under = lead .. (branch == "└─ " and "   "
            or branch == "" and "" or "│  ")
        for i, c in ipairs(n.children) do
            add(c, under, i == #n.children and "└─ " or "├─ ")
        end
    end
    for _, r in ipairs(roots) do add(r, "", "") end

    local title = whole and vim.fn.fnamemodify(file, ":t") or trail[1].name
    local names = vim.tbl_map(function(n) return n.name end, trail)
    local crumb = #names > 0 and table.concat(names, " > ") or "(top level)"
    -- --tac: the default layout lists bottom-up and a tree must read down, so
    -- pos() counts from the far end. fzf_args passes through sh: quote it.
    local pos = at and ("load:pos(%d)"):format(#items - at + 1)
    require("lsp_picker").items("Structure: " .. title, items, {
        opts = {
            fzf_opts = { ["--tac"] = true, ["--header"] = crumb },
            fzf_args = pos and "--bind=" .. vim.fn.shellescape(pos),
        },
    })
end

return M
