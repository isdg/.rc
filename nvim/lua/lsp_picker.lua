-- ============================================================
--        LSP / diagnostic lists in fzf (via fzf-lua)
-- ============================================================
-- Every list reads `<n>  <path:lnum>  <object>`, the location in a fixed-width
-- column like :Jumps/:BLines. fzf-lua's LSP pickers each hardcode a layout, so
-- this formats vim.lsp.buf on_list items and borrows only fzf-lua's UI.
local M = {}

-- Splits the visible text from the `file:lnum:col:` fzf-lua parses; a control
-- char, so it never occurs in a path or a line of source.
local SEP = "\31"
local MAX_LOC_RATIO = 0.4

local function ansi(code, s) return ("\27[%sm%s\27[0m"):format(code, s) end
local SEVERITY_COLOR = { E = "31", W = "33", I = "34", N = "36" }

local function display_path(file)
    return vim.fn.fnamemodify(file, ":~:.")
end

-- Cut from the left so the file name and line number survive.
local function fit(s, width)
    local w = vim.api.nvim_strwidth(s)
    if w <= width then return s .. (" "):rep(width - w) end
    local chars = vim.fn.strchars(s)
    local cut = vim.fn.strcharpart(s, chars - (width - 1))
    while vim.api.nvim_strwidth(cut) > width - 1 do
        cut = vim.fn.strcharpart(cut, 1)
    end
    return "…" .. cut .. (" "):rep(width - 1 - vim.api.nvim_strwidth(cut))
end

-- items: quickfix entries ({ filename, lnum, col, text }).
function M.format(items)
    local one_file = true
    for _, item in ipairs(items) do
        if item.filename ~= items[1].filename then one_file = false break end
    end

    local locs, width = {}, 0
    for i, item in ipairs(items) do
        locs[i] = one_file and tostring(item.lnum)
            or display_path(item.filename) .. ":" .. item.lnum
        width = math.max(width, vim.api.nvim_strwidth(locs[i]))
    end
    width = math.min(width, math.max(math.floor(vim.o.columns * MAX_LOC_RATIO), 10))
    local num_width = #tostring(#items)

    local lines = {}
    for i, item in ipairs(items) do
        local loc = fit(locs[i], width)
        local path = loc:match("^(.-)%d+%s*$")
        loc = path and (ansi("34", path) .. ansi("32", loc:sub(#path + 1))) or loc
        local text = vim.trim(((item.text or ""):gsub("%s*\n%s*", " ")))
        lines[i] = ("%s  %s  %s%s%s:%d:%d:"):format(
            ansi("90", ("%" .. num_width .. "d"):format(i)), loc, text,
            SEP, item.filename, item.lnum, math.max(item.col or 1, 1))
    end
    return lines
end

local function jump(item)
    vim.cmd("normal! m'")
    local buf = item.bufnr or vim.fn.bufadd(item.filename)
    vim.bo[buf].buflisted = true
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_cursor(0, { item.lnum, math.max((item.col or 1) - 1, 0) })
    vim.cmd("normal! zv")
end

-- Same tagstack push vim.lsp.buf.definition() does, so <C-t> returns.
local function tagstack_pusher()
    local win = vim.api.nvim_get_current_win()
    local from = vim.fn.getpos(".")
    from[1] = vim.api.nvim_get_current_buf()
    local tagname = vim.fn.expand("<cword>")
    return function()
        vim.fn.settagstack(win, { items = { { tagname = tagname, from = from } } }, "t")
    end
end

local function picker_opts(title, extra)
    local actions = require("fzf-lua.actions")
    local file_actions = require("fzf-lua.config").globals.actions.files
    local opts = {
        winopts = { title = " " .. title .. " " },
        previewer = "builtin",
        actions = vim.tbl_extend("force", {}, file_actions),
        fzf_opts = { ["--multi"] = true, ["--delimiter"] = SEP, ["--with-nth"] = "{1}" },
        _fmt = { from = function(s) return s:match(SEP .. "(.*)$") or s end },
    }
    if extra and extra.push_tag then
        local push = extra.push_tag
        opts.actions.enter = function(selected, o)
            if #selected == 1 then push() end
            actions.file_edit_or_qf(selected, o)
        end
    end
    return vim.tbl_deep_extend("force", opts, extra and extra.opts or {})
end

-- Show quickfix items; a lone result is jumped to without opening fzf.
function M.items(title, items, extra)
    extra = extra or {}
    items = vim.tbl_filter(function(i) return i.filename and i.filename ~= "" end, items)
    if #items == 0 then
        vim.notify("No " .. title:lower() .. " found", vim.log.levels.INFO)
        return
    end
    if #items == 1 and extra.jump1 then
        if extra.push_tag then extra.push_tag() end
        return jump(items[1])
    end
    require("fzf-lua").fzf_exec(M.format(items), picker_opts(title, extra))
end

-- vim.lsp.buf location requests: definition, type_definition, implementation,
-- references. They notify "No locations found" themselves.
function M.locations(fn_name, title)
    return function()
        local push = tagstack_pusher()
        local on_list = function(t)
            M.items(title, t.items, { jump1 = true, push_tag = push })
        end
        if fn_name == "references" then
            vim.lsp.buf.references(nil, { on_list = on_list })
        else
            vim.lsp.buf[fn_name]({ on_list = on_list })
        end
    end
end

function M.document_symbols()
    vim.lsp.buf.document_symbol({
        on_list = function(t) M.items("Document Symbols", t.items) end,
    })
end

-- The server sees only the first fzf search term, minus its ^ ' $ operators;
-- negated terms are skipped. fzf filters the rest, e.g. a path fragment.
local function server_query(query)
    for term in (query or ""):gmatch("%S+") do
        if not term:find("^!") then
            return (term:gsub("^[\'^]+", ""):gsub("%$$", ""))
        end
    end
    return ""
end

-- Re-queried on every keystroke: servers cap workspace/symbol results, so one
-- up-front list would miss most of the workspace. fzf's own search stays on so
-- typing filters instantly while the server's answer reloads behind it.
function M.workspace_symbols()
    local method = "workspace/symbol"
    local bufnr = vim.api.nvim_get_current_buf()
    if #vim.lsp.get_clients({ bufnr = bufnr, method = method }) == 0 then
        vim.notify("No attached server supports " .. method, vim.log.levels.WARN)
        return
    end
    local contents = function(args)
        return function(cb)
            local params = { query = server_query(args[1]) }
            vim.lsp.buf_request_all(bufnr, method, params, function(results)
                local items = {}
                for client_id, res in pairs(results) do
                    local client = vim.lsp.get_client_by_id(client_id)
                    if client and res.result then
                        vim.list_extend(items, vim.lsp.util.symbols_to_items(
                            res.result, bufnr, client.offset_encoding))
                    end
                end
                items = vim.tbl_filter(function(i) return i.filename and i.filename ~= "" end, items)
                for _, line in ipairs(M.format(items)) do cb(line) end
                cb(nil)
            end)
        end
    end
    require("fzf-lua").fzf_live(contents, picker_opts("Workspace Symbols", {
        opts = { exec_empty_query = true, fzf_args = "--bind=start:+enable-search" },
    }))
end

local SEVERITY_LETTER = { "E", "W", "I", "N" }

-- opts.bufnr limits to one buffer, opts.root to files under that directory.
function M.diagnostics(opts)
    opts = opts or {}
    local diags = vim.diagnostic.get(opts.bufnr)
    local items = {}
    for _, d in ipairs(diags) do
        local file = vim.api.nvim_buf_get_name(d.bufnr)
        if file ~= "" and (not opts.root or vim.fs.relpath(opts.root, file)) then
            local letter = SEVERITY_LETTER[d.severity] or "E"
            local source = d.source and ansi("90", "[" .. d.source .. "] ") or ""
            items[#items + 1] = {
                filename = file, lnum = d.lnum + 1, col = d.col + 1, severity = d.severity,
                text = ansi(SEVERITY_COLOR[letter], letter) .. " " .. source .. d.message,
            }
        end
    end
    table.sort(items, function(a, b)
        if a.severity ~= b.severity then return a.severity < b.severity end
        if a.filename ~= b.filename then return a.filename < b.filename end
        return a.lnum < b.lnum
    end)
    M.items("Diagnostics", items)
end

return M
