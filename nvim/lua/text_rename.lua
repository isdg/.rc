-- ============================================================
--              TEXT RENAME (no language server needed)
-- ============================================================
-- Whole-word renames by plain text, in this buffer or across the repo. Like
-- vim.lsp.buf.rename, edits land in buffers and are left for you to write.
local M = {}

local function word_pattern(word)
    return [[\V\<]] .. vim.fn.escape(word, [[\]]) .. [[\>]]
end

-- Each whole-word word in a loaded buffer, as {bufnr, lnum, col, text} with
-- a 1-based byte col.
local function scan(bufnr, word)
    local spots = {}
    local hits = vim.fn.matchbufline(bufnr, word_pattern(word), 1, "$")
    for _, m in ipairs(hits) do
        spots[#spots + 1] = { bufnr = bufnr, lnum = m.lnum,
            col = m.byteidx + 1, text = m.text }
    end
    return spots
end

-- Loaded buffers are read as they stand, unsaved edits included; ripgrep
-- reads the rest from disk, honouring .gitignore.
function M.find(word, root)
    local spots, loaded = {}, {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(b)
        if vim.api.nvim_buf_is_loaded(b) and name ~= ""
            and vim.fs.relpath(root, name) then
            loaded[vim.fs.normalize(name)] = true
            vim.list_extend(spots, scan(b, word))
        end
    end
    local res = vim.system({ "rg", "--vimgrep", "--null", "--word-regexp",
        "--fixed-strings", "--", word, root }, { text = true }):wait()
    if res.code > 1 then error("rg: " .. res.stderr, 0) end
    for line in res.stdout:gmatch("[^\n]+") do
        local nul = line:find("\0", 1, true)
        local file = vim.fs.normalize(line:sub(1, nul - 1))
        local lnum, col, text = line:sub(nul + 1):match("^(%d+):(%d+):(.*)$")
        if not loaded[file] then
            spots[#spots + 1] = { filename = file, lnum = tonumber(lnum),
                col = tonumber(col), text = text }
        end
    end
    return spots
end

-- Right to left within a line, so the columns still to come stay valid.
-- Spots whose text no longer reads old are skipped. Returns edits, buffers.
function M.apply(spots, old, new)
    for _, s in ipairs(spots) do
        if not s.bufnr then
            s.bufnr = vim.fn.bufadd(s.filename)
            vim.fn.bufload(s.bufnr)
            vim.bo[s.bufnr].buflisted = true
        end
    end
    table.sort(spots, function(a, b)
        if a.bufnr ~= b.bufnr then return a.bufnr < b.bufnr end
        if a.lnum ~= b.lnum then return a.lnum > b.lnum end
        return a.col > b.col
    end)
    local edits, bufs = 0, {}
    for _, s in ipairs(spots) do
        local row, c = s.lnum - 1, s.col - 1
        local line = vim.api.nvim_buf_get_lines(s.bufnr, row, s.lnum, true)[1]
        if line:sub(s.col, c + #old) == old then
            vim.api.nvim_buf_set_text(s.bufnr, row, c, row, c + #old, { new })
            edits, bufs[s.bufnr] = edits + 1, true
        end
    end
    return edits, vim.tbl_count(bufs)
end

local function cword()
    local w = vim.fn.expand("<cword>")
    if w == "" or vim.fn.match(w, [[^\k\+$]]) < 0 then
        vim.notify("Not on a word", vim.log.levels.INFO)
        return nil
    end
    return w
end

local function ask(prompt, old, fn)
    vim.ui.input({ prompt = prompt, default = old }, function(new)
        if new and new ~= "" and new ~= old then fn(new) end
    end)
end

function M.buffer()
    local old = cword()
    if not old then return end
    ask("Rename: ", old, function(new)
        local bufnr = vim.api.nvim_get_current_buf()
        local n = M.apply(scan(bufnr, old), old, new)
        vim.notify(("Renamed %d × %s → %s"):format(n, old, new))
    end)
end

-- Lists every match in the quickfix window and asks before touching any.
function M.project()
    local old = cword()
    if not old then return end
    local root = vim.fs.root(0, ".git") or vim.uv.cwd()
    ask("Rename in repo: ", old, function(new)
        local spots = M.find(old, root)
        if #spots == 0 then
            vim.notify("No " .. old .. " under " .. root, vim.log.levels.INFO)
            return
        end
        vim.fn.setqflist({}, " ", { items = spots,
            title = ("Rename %s → %s"):format(old, new) })
        vim.cmd("copen | redraw")
        local q = ("Rename %d × %s → %s?"):format(#spots, old, new)
        if vim.fn.confirm(q, "&Yes\n&No", 2) ~= 1 then return end
        local n, files = M.apply(spots, old, new)
        vim.notify(("Renamed %d in %d files; :wa writes them"):format(n, files))
    end)
end

return M
