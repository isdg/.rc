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
-- rows of the whole extent), children, and the server's detail if it sent one.

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
                    detail = s.detail and s.detail:gsub("%s+", " "),
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

local GREY, DIM, RESET = "\27[90m", "\27[2m", "\27[0m"

-- What alt-i shows: the server's detail (a signature or type), else the line
-- that declares the symbol.
local function detail_of(bufnr, n)
    if n.detail and n.detail ~= "" then return n.detail end
    local line = vim.api.nvim_buf_get_lines(bufnr, n.lnum - 1, n.lnum, false)[1]
    return vim.trim(line or "")
end

-- scope "object": the outermost symbol on the cursor's path (the file when
-- outside all); "file": the whole file. Keys change fold/detail state and
-- reload, which re-runs render(); file:lnum:col is each row's --id-nth.
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

    local at_pos, parent = {}, {}
    local function index(list, up)
        for _, n in ipairs(list) do
            at_pos[n.lnum .. ":" .. n.col] = n
            parent[n] = up
            index(n.children, n)
        end
    end
    index(roots, nil)

    local folded, details = {}, false
    local function render()
        local items = {}
        local function add(n, lead, branch)
            local mark = #n.children == 0 and ""
                or folded[n] and "▸ " or "▾ "
            local info = details
                and " " .. GREY .. detail_of(bufnr, n) .. RESET or ""
            items[#items + 1] = {
                filename = file, lnum = n.lnum, col = n.col, verbatim = true,
                text = ("%s%s%s%s%s  %s%s%s"):format(lead, branch, mark,
                    n.name, info, DIM, n.kind, RESET),
            }
            if folded[n] then return end
            local under = lead .. (branch == "└─ " and "   "
                or branch == "" and "" or "│  ")
            for i, c in ipairs(n.children) do
                add(c, under, i == #n.children and "└─ " or "├─ ")
            end
        end
        for _, r in ipairs(roots) do add(r, "", "") end
        return items
    end

    local function selected_node(selected)
        local row = selected[1] or ""
        local _, lnum, col = require("lsp_picker").location_of(row)
        return lnum and at_pos[lnum .. ":" .. col]
    end

    -- --track loses a symbol that a fold hides, so aim() writes pos() of its
    -- folded ancestor here for the next load to read; --tac lists bottom-up,
    -- so pos() counts from the far end.
    local focus = vim.fn.tempname()
    local function aim(n)
        local items, row = render(), nil
        for i, item in ipairs(items) do
            if n and item.lnum == n.lnum and item.col == n.col then row = i end
        end
        local f = assert(io.open(focus, "w"))
        f:write(row and ("pos(%d)"):format(#items - row + 1) or "")
        f:close()
    end
    local function shown(n)
        local up = n
        for p in function(_, c) return parent[c] end, nil, n do
            if folded[p] then up = p end
        end
        return up
    end
    local function reload(fn)
        return {
            fn = function(sel)
                local n = selected_node(sel)
                fn(n)
                aim(n and shown(n) ~= n and shown(n) or nil)
            end,
            reload = true,
            field_index = "{}",
        }
    end
    local function fold_all(list, keep_open)
        for _, n in ipairs(list) do
            if #n.children > 0 and not keep_open then folded[n] = true end
            fold_all(n.children, false)
        end
    end
    local actions = {
        -- Left on a leaf or a folded node folds its parent, as in JetBrains.
        ["left"] = reload(function(n)
            if n and (#n.children == 0 or folded[n]) then n = parent[n] end
            if n then folded[n] = true end
        end),
        ["right"] = reload(function(n)
            if n then folded[n] = nil end
        end),
        -- An object's root stays open, or collapsing would leave one row.
        ["alt-h"] = reload(function() fold_all(roots, not whole) end),
        ["alt-l"] = reload(function() folded = {} end),
        ["alt-i"] = reload(function() details = not details end),
    }
    aim(here)

    local title = whole and vim.fn.fnamemodify(file, ":t") or trail[1].name
    local names = vim.tbl_map(function(n) return n.name end, trail)
    local crumb = #names > 0 and table.concat(names, " > ") or "(top level)"
    local legend = "←/→ fold · alt-h/alt-l all · alt-i details"
    -- fzf_args passes through sh, hence the quoting; + keeps fzf-lua's own
    -- load binding, which re-enables the reload keys.
    local on_load = ("load:+transform(cat %s)"):format(
        vim.fn.shellescape(focus))
    require("lsp_picker").items("Structure: " .. title, render, {
        opts = {
            actions = actions,
            fzf_opts = {
                ["--tac"] = true,
                -- A filter keeps tree order, as the JetBrains view does.
                ["--no-sort"] = true,
                ["--track"] = true,
                ["--id-nth"] = "2",
                ["--header"] = crumb .. "\n" .. legend,
            },
            fzf_args = "--bind=" .. vim.fn.shellescape(on_load),
        },
    })
end

-- The symbols whose extent holds rows first..last (0-based), outermost first.
function M.enclosing(bufnr, first, last)
    local trail = path(symbols(bufnr) or {}, first)
    return vim.tbl_filter(function(n) return n.last >= last end, trail)
end

return M
