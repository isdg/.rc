-- ============================================================
--          LSP SYMBOLS THROUGH FZF (not telescope)
-- ============================================================
-- The engine is the same either way -- nvim's own client answers
-- textDocument/documentSymbol and workspace/symbol. What changes is who draws
-- the list: a real fzf process inherits $FZF_DEFAULT_OPTS_FILE, so these pickers
-- get the theme, M-j jump mode and the M-d/M-u/M-g scroll keys that every other
-- picker here has, and telescope's window has none of.

local M = {}

-- Rows are TAB-separated so a path may contain anything: path, line, col, then
-- the text fzf shows. --with-nth hides the first three; the sink reads them.
local function row(path, lnum, col, text)
    return table.concat({ path, lnum, col, text }, "\t")
end

local function kind(k)
    return vim.lsp.protocol.SymbolKind[k] or "?"
end

-- documentSymbol answers with either shape depending on the server: a flat
-- SymbolInformation[] carrying `location`, or a nested DocumentSymbol[] whose
-- children repeat the structure. Walk both into one list, keeping the nesting
-- as a `parent.child` name so a method reads as the thing it hangs off.
local function flatten(symbols, uri, prefix, out)
    for _, s in ipairs(symbols or {}) do
        local loc = s.location or { uri = uri, range = s.selectionRange or s.range }
        local name = prefix and (prefix .. "." .. s.name) or s.name
        local range = loc.range or {}
        local start = range.start or { line = 0, character = 0 }
        out[#out + 1] = {
            path = vim.uri_to_fname(loc.uri or uri),
            lnum = start.line + 1,
            col = start.character + 1,
            name = name,
            kind = kind(s.kind),
        }
        flatten(s.children, uri, name, out)
    end
    return out
end

local function request(method, params, on_symbols)
    local buf = vim.api.nvim_get_current_buf()
    if #vim.lsp.get_clients({ bufnr = buf, method = method }) == 0 then
        vim.notify("No LSP client for " .. method, vim.log.levels.WARN)
        return
    end
    vim.lsp.buf_request_all(buf, method, params, function(results)
        local out = {}
        for _, res in pairs(results or {}) do
            flatten(res.result, vim.uri_from_bufnr(buf), nil, out)
        end
        on_symbols(out)
    end)
end

-- Centre the symbol's line in the preview, the same arithmetic FzfBLinesPreview
-- does: fzf's own +{2}-/2 offset wants a bare integer field and ours is fine,
-- but doing it here keeps the two previews looking identical.
local PREVIEW = 'n={2}; h=${FZF_PREVIEW_LINES:-40}; s=$(( n - (h - 1) / 2 )); '
    .. '[ "$s" -lt 1 ] && s=1; '
    .. 'bat --color=always --style=numbers --decorations=always '
    .. '--highlight-line "$n" --line-range "$s:$(( s + h - 1 ))" {1}'

local function pick(name, prompt, rows)
    if #rows == 0 then
        vim.notify("No symbols", vim.log.levels.INFO)
        return
    end
    vim.fn["fzf#run"](vim.fn["fzf#wrap"](name, {
        source = rows,
        options = {
            "+m", "--prompt", prompt,
            "--delimiter", "\t", "--with-nth", "4..",
            "--preview", PREVIEW,
        },
        -- m' first: jumping to a symbol is a jump, and '' should come back.
        sink = function(line)
            local path, lnum, col = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t")
            if not path then
                return
            end
            vim.cmd("normal! m'")
            vim.cmd.edit(vim.fn.fnameescape(path))
            pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(lnum), tonumber(col) - 1 })
            vim.cmd("normal! zz")
        end,
    }))
end

function M.document()
    request("textDocument/documentSymbol", { textDocument = vim.lsp.util.make_text_document_params() },
        function(symbols)
            local rows = {}
            for _, s in ipairs(symbols) do
                rows[#rows + 1] = row(s.path, s.lnum, s.col,
                    string.format("%-14s %s", s.kind, s.name))
            end
            pick("lsp-document-symbols", "Symbols> ", rows)
        end)
end

-- The empty query first, because that is what makes this fuzzy rather than a
-- search box: servers that answer it (lua_ls, rust-analyzer) hand over the whole
-- index and fzf filters locally, with no round trip per keystroke.
function M.workspace()
    request("workspace/symbol", { query = "" }, function(symbols)
        if #symbols > 0 then
            return M.show_workspace(symbols)
        end
        -- gopls and friends answer an empty query with nothing, so ask for one
        -- rather than reporting a workspace with no symbols in it.
        local query = vim.fn.input("Workspace symbol: ")
        if query == "" then
            return
        end
        request("workspace/symbol", { query = query }, M.show_workspace)
    end)
end

function M.show_workspace(symbols)
    local rows = {}
    for _, s in ipairs(symbols) do
        rows[#rows + 1] = row(s.path, s.lnum, s.col, string.format("%-14s %-40s %s",
            s.kind, s.name, vim.fn.fnamemodify(s.path, ":.")))
    end
    pick("lsp-workspace-symbols", "Workspace> ", rows)
end

return M
