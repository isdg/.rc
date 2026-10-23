-- Full suite: for each case, the raw server answer, what the picker does with
-- it, and fzf-lua's own parse and jump of the rows it shows; every target is
-- also checked against the source text. Returns the number of failures.
local OUT = _G.LT_OUT
local SEP = "\31"
local picker = require("lsp_picker")
local fzf = require("fzf-lua")
local actions = require("fzf-lua.actions")
local fzfpath = require("fzf-lua.path")
local cases = dofile(_G.LT_DIR .. "/cases.lua")

-- Faults of the picker or of this config. Anything else is rust-analyzer's
-- own semantics (gy lands on a type, Self on Sender<T>) and only reported.
local FAIL = {
    pipeline_vs_raw = true, pipeline_timeout = true, pipeline_error = true,
    silent_empty = true, jump_wrong = true, tagstack_wrong = true,
    picker_not_opened = true, row_count = true, row_unparsable = true,
    row_location_unknown = true, row_shown_lnum = true, fzf_parse = true,
    enter_error = true, enter_jump_wrong = true, qf_error = true,
    qf_count = true, qf_empty_text = true, not_attached = true,
    harness_error = true, error_without_raw_error = true,
    library_own_server = true,
}

local METHOD = {
    definition = "textDocument/definition",
    references = "textDocument/references",
    implementation = "textDocument/implementation",
    type_definition = "textDocument/typeDefinition",
}
local TITLE = {
    definition = "Definitions", references = "References",
    implementation = "Implementations", type_definition = "Type Definitions",
}

local HOME = vim.env.HOME
local LIBS = { HOME .. "/.cargo/registry/src", HOME .. "/.cargo/git/checkouts",
    HOME .. "/.rustup/toolchains" }

local function append(name, line)
    local f = assert(io.open(OUT .. "/" .. name, "a"))
    f:write(line, "\n")
    f:close()
end
local function say(msg)
    io.stdout:write(msg, "\n")
    append("suite.log", os.date("%H:%M:%S ") .. msg)
end

local function real(p) return vim.uv.fs_realpath(p) or p end
local function key(file, lnum, col)
    return ("%s:%d:%d"):format(real(file), lnum, col)
end
local function is_library(f)
    for _, d in ipairs(LIBS) do
        if vim.fs.relpath(d, f) then return true end
    end
end
local function ra(bufnr)
    return vim.lsp.get_clients({ bufnr = bufnr, name = "rust_analyzer" })
end
local function attached() return #ra(0) > 0 end

local cache = {}
local function lines_of(path)
    if not cache[path] then
        local t, f = {}, io.open(path)
        if f then
            for l in f:lines() do t[#t + 1] = l end
            f:close()
        end
        cache[path] = t
    end
    return cache[path]
end

local function conv(loc, enc)
    local range = loc.range or loc.targetSelectionRange
    local file = vim.uri_to_fname(loc.uri or loc.targetUri)
    local s, e = range.start, range["end"]
    local L = lines_of(file)
    local sl, el = L[s.line + 1] or "", L[e.line + 1] or ""
    local sc = vim.str_byteindex(sl, enc, s.character, false)
    local ec = vim.str_byteindex(el, enc, e.character, false)
    return {
        file = real(file), lnum = s.line + 1, col = sc + 1, line = sl,
        text = s.line == e.line and sl:sub(sc + 1, ec) or nil,
    }
end

-- Whether a target's text is the name asked about, or one of the forms
-- rust-analyzer legitimately answers with instead.
local function classify(case, loc, src_line)
    if not loc.text then return "multiline" end
    local text, name = loc.text, case.name
    if case.cat == "lifetime" then text = text:gsub("^'", "") end
    if case.cat == "metavar" then
        text, name = text:gsub("^%$", ""), name:gsub("^%$", "")
    end
    if text == name then return "exact" end
    if loc.text == "" and loc.lnum == 1 and loc.col == 1 then
        return "file_start"
    end
    if src_line:find("as%s+" .. vim.pesc(case.name) .. "%f[^%w_]")
        or loc.line:find("%sas%s") then
        return "alias"
    end
    if loc.file:match("primitive_docs%.rs$") then return "primitive_doc" end
    if loc.text:find("%$") then return "in_macro" end
    return "mismatch"
end

local function raw_request(fn)
    local function params(c)
        local p = vim.lsp.util.make_position_params(0, c.offset_encoding)
        if fn == "references" then
            p.context = { includeDeclaration = true }
        end
        return p
    end
    local res, err = vim.lsp.buf_request_sync(0, METHOD[fn], params, 60000)
    local locs, errs = {}, {}
    for id, r in pairs(res or {}) do
        local c = vim.lsp.get_client_by_id(id)
        if r.err then
            errs[#errs + 1] = ("%s %s"):format(r.err.code, r.err.message)
        end
        local result = r.result
        if result and not vim.islist(result) then result = { result } end
        for _, loc in ipairs(result or {}) do
            locs[#locs + 1] = conv(loc, c.offset_encoding)
        end
    end
    return { locs = locs, err = #errs > 0 and table.concat(errs, "; ") or err }
end

-- The picker as the user meets it, with fzf and vim.notify captured.
local captured, notes, items_call
local real_exec, real_notify, real_items = fzf.fzf_exec, vim.notify,
    picker.items
local function install()
    fzf.fzf_exec = function(contents, opts)
        captured = { contents = contents, opts = opts }
    end
    vim.notify = function(msg) notes[#notes + 1] = tostring(msg) end
    picker.items = function(title, items, extra)
        items_call = { items = vim.deepcopy(items) }
        local ok, err = pcall(real_items, title, items, extra)
        if not ok then items_call.error = tostring(err) end
        items_call.done = true
    end
end
local function uninstall()
    fzf.fzf_exec, vim.notify, picker.items = real_exec, real_notify,
        real_items
end
local function note(pattern)
    for _, n in ipairs(notes) do
        if n:find(pattern) then return n end
    end
end

local function where()
    local c = vim.api.nvim_win_get_cursor(0)
    return real(vim.api.nvim_buf_get_name(0)), c[1], c[2] + 1
end

local function goto_case(case)
    vim.cmd("silent! edit " .. vim.fn.fnameescape(case.file))
    vim.wait(15000, attached, 5)
    pcall(vim.api.nvim_win_set_cursor, 0, { case.row + 1, case.col })
end

-- The rows on screen, checked against the items they came from, then
-- replayed through fzf-lua: Enter on a few rows, two rows into quickfix.
local function check_rows(issue, items, buf0, cur0)
    local rows = captured.contents
    if #rows ~= #items then issue("row_count", #rows .. " vs " .. #items) end
    local known = {}
    for _, i in ipairs(items) do
        known[key(i.filename, i.lnum, i.col)] = true
    end
    local parsed = {}
    for idx, line in ipairs(rows) do
        local file, lnum, col = picker.location_of(line)
        local disp = line:gsub("\27%[[%d;]*m", ""):match("^(.-)" .. SEP)
        local shown = disp and tonumber(disp:match("^%s*%d+%s+[^%s]-(%d+)%s"))
        if not file then
            issue("row_unparsable", line:sub(1, 80))
        else
            parsed[idx] = { file = file, lnum = lnum, col = col }
            if not known[key(file, lnum, col)] then
                issue("row_location_unknown", line:sub(1, 120))
            end
            if shown ~= lnum then issue("row_shown_lnum", disp) end
            local ent = fzfpath.entry_to_file(line, captured.opts)
            if real(ent.path or "") ~= real(file) or ent.line ~= lnum
                or ent.col ~= col then
                issue("fzf_parse", ("%s:%s:%s"):format(
                    ent.path, ent.line, ent.col))
            end
        end
    end
    local enter = captured.opts.actions.enter
    enter = type(enter) == "table" and (enter.fn or enter[1]) or enter
    for _, idx in ipairs({ 1, math.floor((#rows + 1) / 2), #rows }) do
        local p = parsed[idx]
        if p then
            vim.api.nvim_set_current_buf(buf0)
            vim.api.nvim_win_set_cursor(0, cur0)
            local ok, err = pcall(enter, { rows[idx] }, captured.opts)
            local f, l, c = where()
            if not ok then
                issue("enter_error", tostring(err))
            elseif f ~= real(p.file) or l ~= p.lnum or c ~= p.col then
                issue("enter_jump_wrong", ("row %d at %s:%d:%d"):format(
                    idx, f, l, c))
            end
        end
    end
    local qopts = vim.tbl_extend("force", {}, captured.opts,
        { copen = false, __resume_key = "lsp-test" })
    vim.fn.setqflist({}, "r", { items = {} })
    local ends = { rows[1], rows[#rows] }
    local ok, err = pcall(actions.file_sel_to_qf, ends, qopts)
    if not ok then return issue("qf_error", tostring(err)) end
    local qf = vim.fn.getqflist()
    if #qf ~= 2 then issue("qf_count", #qf) end
    for _, q in ipairs(qf) do
        if (q.text or "") == "" then return issue("qf_empty_text") end
    end
end

local function run_case(case, fn)
    local rec = { cat = case.cat, file = case.file, row = case.row + 1,
        col = case.col + 1, name = case.name, fn = fn, issues = {} }
    local function issue(kind, detail)
        rec.issues[#rec.issues + 1] = { kind = kind, detail = detail }
    end
    goto_case(case)
    if not attached() then
        issue("not_attached")
        return rec
    end
    local src_line = vim.api.nvim_get_current_line()

    local raw = raw_request(fn)
    rec.n, rec.raw_err = #raw.locs, raw.err
    for _, l in ipairs(raw.locs) do
        if classify(case, l, src_line) == "mismatch" then
            issue("text_mismatch", ("%s:%d %q"):format(
                vim.fn.fnamemodify(l.file, ":~:."), l.lnum, l.text))
        end
    end
    if fn == "references" and #raw.locs > 0 then
        local me = real(vim.api.nvim_buf_get_name(0))
        local found = false
        for _, l in ipairs(raw.locs) do
            if l.file == me and l.lnum == rec.row and l.col <= rec.col
                and rec.col < l.col + math.max(#(l.text or ""), 1) then
                found = true
            end
        end
        if not found then issue("self_not_in_refs") end
    end

    local buf0 = vim.api.nvim_get_current_buf()
    local cur0 = vim.api.nvim_win_get_cursor(0)
    captured, notes, items_call = nil, {}, nil
    vim.fn.settagstack(0, { items = {} }, "r")
    picker.locations(fn, TITLE[fn])()
    local done = vim.wait(60000, function()
        return (items_call and items_call.done) or note("^No .* found")
            or note("^" .. vim.pesc(TITLE[fn]) .. ":")
    end, 5)
    if not done then
        issue("pipeline_timeout")
        return rec
    end
    if items_call and items_call.error then
        issue("pipeline_error", items_call.error)
    end
    local err_note = note("^" .. vim.pesc(TITLE[fn]) .. ":")
    if err_note then
        rec.outcome = "error"
        if not raw.err then issue("error_without_raw_error", err_note) end
        return rec
    end

    -- Expect what the picker should do: one row per distinct location.
    local items, seen = {}, {}
    for _, i in ipairs(items_call and items_call.items or {}) do
        local k = key(i.filename, i.lnum, i.col)
        if i.filename ~= "" and not seen[k] then
            seen[k] = true
            items[#items + 1] = i
        end
    end
    local rk = {}
    for _, l in ipairs(raw.locs) do rk[key(l.file, l.lnum, l.col)] = true end
    local diff = 0
    for k in pairs(rk) do if not seen[k] then diff = diff + 1 end end
    for k in pairs(seen) do if not rk[k] then diff = diff + 1 end end
    if diff > 0 and not raw.err then
        issue("pipeline_vs_raw", ("raw %d, picker %d"):format(
            #raw.locs, #items))
    end

    if #items == 0 then
        rec.outcome = "none"
        rec.why = note("^No .* found")
        if not rec.why then issue("silent_empty") end
    elseif #items == 1 then
        rec.outcome = "jump"
        local f, l, c = where()
        local it = items[1]
        rec.jump = { file = f, lnum = l, col = c }
        if f ~= real(it.filename) or l ~= it.lnum or c ~= it.col then
            issue("jump_wrong", ("%s:%d:%d"):format(f, l, c))
        end
        local stack = vim.fn.gettagstack().items
        local top = stack[#stack]
        if not top or top.from[1] ~= buf0 or top.from[2] ~= cur0[1] then
            issue("tagstack_wrong")
        end
    else
        rec.outcome = "picker"
        if not captured then
            issue("picker_not_opened")
        else
            check_rows(issue, items, buf0, cur0)
        end
    end
    return rec
end

-- gd into std or a dependency, then gr and gd from there: the file has to
-- be served by the workspace's own rust-analyzer, which knows its callers.
local function library_chain(rec, root)
    vim.cmd("silent! edit " .. vim.fn.fnameescape(rec.jump.file))
    vim.wait(15000, attached, 5)
    pcall(vim.api.nvim_win_set_cursor, 0, { rec.jump.lnum, rec.jump.col - 1 })
    local out = { from = rec.file .. ":" .. rec.row, name = rec.name,
        target = vim.fn.fnamemodify(rec.jump.file, ":~"), issues = {} }
    local c = ra(0)[1]
    if not c then
        out.issues[1] = { kind = "not_attached" }
    elseif c.root_dir ~= root then
        out.issues[1] = { kind = "library_own_server", detail = c.root_dir }
    end
    out.refs = #raw_request("references").locs
    out.defs = #raw_request("definition").locs
    return out
end

local PLAN = {
    { fn = "definition", per = 40 },
    { fn = "references", per = 10 },
    { fn = "implementation", per = 6, cats = { decl_name = true,
        impl_trait = true, trait_bound = true, type_ref = true,
        method_call = true } },
    { fn = "type_definition", per = 6, cats = { expr_ident = true,
        let_binding = true, param_decl = true, field_access = true,
        method_call = true, self = true } },
}

local root = assert(_G.LT_ROOT, "settle.lua first")
local buckets = cases.collect()
local failures, info = {}, {}
-- Cases per kind, not issues: gr on `crate` alone has thousands of targets.
local function tally(rec)
    local kinds = {}
    for _, i in ipairs(rec.issues) do kinds[i.kind] = true end
    for kind in pairs(kinds) do
        local t = FAIL[kind] and failures or info
        t[kind] = (t[kind] or 0) + 1
    end
end

install()
local ok, err = pcall(function()
    for _, step in ipairs(PLAN) do
        local sub = {}
        for cat, list in pairs(buckets) do
            if not step.cats or step.cats[cat] then sub[cat] = list end
        end
        local sample = cases.sample(sub, step.per, 1234)
        local outcomes, recs = {}, {}
        for _, case in ipairs(sample) do
            local okc, rec = pcall(run_case, case, step.fn)
            if not okc then
                rec = { file = case.file, row = case.row + 1, fn = step.fn,
                    issues = { { kind = "harness_error", detail = rec } } }
            end
            tally(rec)
            local o = rec.outcome or "?"
            outcomes[o] = (outcomes[o] or 0) + 1
            recs[#recs + 1] = rec
            append("results.jsonl", vim.json.encode(rec))
        end
        say(("%-16s %4d cases  %s"):format(step.fn, #sample,
            vim.inspect(outcomes, { newline = " ", indent = "" })))
        if step.fn == "definition" then
            local seen, n = {}, 0
            for _, rec in ipairs(recs) do
                local f = rec.jump and rec.jump.file
                if f and is_library(f) and not seen[f] and n < 40 then
                    seen[f], n = true, n + 1
                    local out = library_chain(rec, root)
                    tally(out)
                    append("chain.jsonl", vim.json.encode(out))
                end
            end
            say(("library chain    %4d dependency files"):format(n))
        end
    end
end)
uninstall()
if not ok then failures.harness_error = (failures.harness_error or 0) + 1 end

local servers = vim.lsp.get_clients({ name = "rust_analyzer" })
if #servers ~= 1 then failures.servers = #servers end
local flat = { newline = " ", indent = "" }
say("informational, cases: " .. vim.inspect(info, flat))
say("failures, cases:      " .. vim.inspect(failures, flat))
if not ok then say("harness error: " .. tostring(err)) end
say("details in " .. OUT)
local total = 0
for _, n in pairs(failures) do total = total + n end
return total
