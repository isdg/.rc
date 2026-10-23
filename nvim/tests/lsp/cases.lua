-- Cases for the suite: identifiers across tokio, bucketed by syntactic
-- context with Treesitter, plus intra-doc links, then sampled per bucket.
local M = {}

local ROOTS = {
    "tokio/src", "tokio-util/src", "tokio-stream/src", "tokio-macros/src",
    "tokio-test/src", "tokio/tests", "examples",
}

local DECL = {
    function_item = true, struct_item = true, enum_item = true,
    trait_item = true, type_item = true, const_item = true,
    static_item = true, mod_item = true, macro_definition = true,
    enum_variant = true, function_signature_item = true, union_item = true,
    associated_type = true,
}

local WANT = {
    identifier = true, type_identifier = true, field_identifier = true,
    shorthand_field_identifier = true, primitive_type = true, self = true,
    crate = true, super = true, metavariable = true,
}

local function rs_files()
    local out = {}
    for _, root in ipairs(ROOTS) do
        for name, kind in vim.fs.dir(root, { depth = 10 }) do
            if kind == "file" and name:match("%.rs$") then
                out[#out + 1] = root .. "/" .. name
            end
        end
    end
    table.sort(out)
    return out
end

local function ancestor(node, types)
    local p = node:parent()
    while p do
        if types[p:type()] then return p end
        p = p:parent()
    end
end

local function is_field(parent, name, node)
    for _, n in ipairs(parent:field(name)) do
        if n:id() == node:id() then return true end
    end
end

local function category(node, src)
    local t, p = node:type(), node:parent()
    if not p then return nil end
    local pt = p:type()
    local text = vim.treesitter.get_node_text(node, src)
    local attr = { attribute_item = true, inner_attribute_item = true }
    if ancestor(node, attr) then return "attribute" end
    if ancestor(node, { token_tree = true }) then
        local call = ancestor(node, { macro_invocation = true })
        local name = call and call:field("macro")[1]
        local macro = name and vim.treesitter.get_node_text(name, src) or ""
        return macro:match("^cfg_") and "cfg_macro_body" or "macro_body"
    end
    if ancestor(node, { use_declaration = true }) then return "use" end
    if t == "self" then return "self" end
    if t == "crate" or t == "super" then return "crate_super" end
    if t == "primitive_type" then return "primitive" end
    if t == "metavariable" then return "metavar" end
    if pt == "lifetime" then return "lifetime" end
    if t == "shorthand_field_identifier" then return "shorthand_field" end
    if t == "field_identifier" then
        local call = p:parent()
        if pt == "field_expression" and call
            and call:type() == "call_expression"
            and is_field(call, "function", p) then
            return "method_call"
        end
        return ({
            field_expression = "field_access",
            field_initializer = "struct_init_field",
            field_declaration = "field_decl",
            field_pattern = "field_pattern",
        })[pt]
    end
    if DECL[pt] and is_field(p, "name", node) then return "decl_name" end
    if pt == "macro_invocation" then return "macro_name" end
    if pt == "scoped_identifier" or pt == "scoped_type_identifier" then
        return is_field(p, "name", node) and "path_tail" or "path_head"
    end
    if t == "type_identifier" then
        if text == "Self" then return "Self" end
        local impl = ancestor(node, { impl_item = true })
        if impl and pt == "impl_item" and is_field(impl, "trait", node) then
            return "impl_trait"
        end
        if ancestor(node, { trait_bounds = true }) then return "trait_bound" end
        return "type_ref"
    end
    if t == "identifier" then
        return ({
            call_expression = "fn_call",
            parameter = "param_decl",
            let_declaration = "let_binding",
            closure_parameters = "closure_param",
        })[pt] or "expr_ident"
    end
end

-- Intra-doc links, [`Name`] or [`path::Name`], with the cursor on the last
-- segment: Treesitter does not parse inside doc comments.
local function doc_links(file, src, add)
    local row = 0
    for line in (src .. "\n"):gmatch("(.-)\n") do
        if line:match("^%s*//[/!]") then
            for s, inner in line:gmatch("()%[`([%w_:]+)`%]") do
                local last = inner:match("([%w_]+)$")
                if last and #last > 1 then
                    add("doc_link", { file = file, row = row, name = last,
                        col = s + 1 + #inner - #last })
                end
            end
        end
        row = row + 1
    end
end

function M.collect()
    local buckets = {}
    local function add(cat, case)
        case.cat = cat
        buckets[cat] = buckets[cat] or {}
        table.insert(buckets[cat], case)
    end
    for _, file in ipairs(rs_files()) do
        local f = assert(io.open(file))
        local src = f:read("a")
        f:close()
        local root = vim.treesitter.get_string_parser(src, "rust"):parse()[1]
        local function walk(node)
            for child in node:iter_children() do
                if WANT[child:type()] and child:named() then
                    local cat = category(child, src)
                    if cat then
                        local r, c = child:start()
                        add(cat, { file = file, row = r, col = c,
                            name = vim.treesitter.get_node_text(child, src) })
                    end
                end
                walk(child)
            end
        end
        walk(root:root())
        doc_links(file, src, add)
    end
    return buckets
end

-- Park-Miller, so one tokio tag always yields the same cases.
local function rng(seed)
    local state = seed
    return function(n)
        state = (state * 16807) % 2147483647
        return state % n + 1
    end
end

function M.sample(buckets, per_cat, seed)
    local pick = rng(seed)
    local cats = vim.tbl_keys(buckets)
    table.sort(cats)
    local out = {}
    for _, cat in ipairs(cats) do
        local list, seen, taken = buckets[cat], {}, 0
        for _ = 1, per_cat * 20 do
            if taken == math.min(per_cat, #list) then break end
            local i = pick(#list)
            if not seen[i] then
                seen[i] = true
                taken = taken + 1
                out[#out + 1] = list[i]
            end
        end
    end
    return out
end

return M
