-- ============================================================
--                       AGENTIC YANK
-- ============================================================
-- Lines plus what an agent needs to place them: repo-relative path:range,
-- the enclosing symbols, whether the buffer differs from disk, the code
-- itself and the diagnostics on those lines.
local M = {}

local function display_path(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then return "[No Name]" end
    local root = vim.fs.root(bufnr, ".git")
    local rel = root and vim.fs.relpath(root, name)
    return rel or vim.fn.fnamemodify(name, ":~:.")
end

-- CommonMark closes a fence only on a run at least as long as its opener.
local function fence(code)
    local longest = 2
    for run in code:gmatch("`+") do longest = math.max(longest, #run) end
    return ("`"):rep(longest + 1)
end

local function diagnostics(bufnr, first, last)
    local found = vim.tbl_filter(function(d)
        return d.lnum >= first and d.lnum <= last
    end, vim.diagnostic.get(bufnr))
    table.sort(found, function(a, b)
        return a.lnum < b.lnum or a.lnum == b.lnum and a.col < b.col
    end)
    return vim.tbl_map(function(d)
        local message = vim.trim(d.message):gsub("%s*\n%s*", " ")
        local severity = vim.diagnostic.severity[d.severity]:lower()
        local source = d.source and (" (" .. d.source .. ")") or ""
        return ("- %d: [%s] %s%s"):format(d.lnum + 1, severity, message,
            source)
    end, found)
end

-- first and last are 0-based rows, inclusive.
function M.payload(bufnr, first, last)
    local range = first == last and tostring(first + 1)
        or ("%d-%d"):format(first + 1, last + 1)
    local header = display_path(bufnr) .. ":" .. range
    local trail = require("structure").enclosing(bufnr, first, last)
    if #trail > 0 then
        local names = vim.tbl_map(function(n) return n.name end, trail)
        header = ("%s (%s %s)"):format(header, trail[#trail].kind:lower(),
            table.concat(names, " > "))
    end
    if vim.bo[bufnr].modified then header = header .. " [unsaved]" end

    local code = table.concat(
        vim.api.nvim_buf_get_lines(bufnr, first, last + 1, true), "\n")
    local f = fence(code)
    local out = { header, f .. vim.bo[bufnr].filetype, code, f }
    local diags = diagnostics(bufnr, first, last)
    if #diags > 0 then
        out[#out + 1] = "Diagnostics:"
        vim.list_extend(out, diags)
    end
    return table.concat(out, "\n") .. "\n"
end

-- Normal mode takes [count] lines from the cursor, like yy; visual mode the
-- selection's whole lines, whatever its kind. The message stays as short as
-- yank's own: the header, symbol trail and all, outgrows the command line.
function M.yank()
    local mode = vim.fn.mode()
    local first, last
    if mode:match("^[vV\22]") then
        first, last = vim.fn.line("v"), vim.fn.line(".")
        if first > last then first, last = last, first end
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    else
        first = vim.fn.line(".")
        last = math.min(first + vim.v.count1 - 1, vim.fn.line("$"))
    end
    vim.fn.setreg("+", M.payload(0, first - 1, last - 1))
    local count = last - first + 1
    vim.notify(('%d line%s with context yanked into "+')
        :format(count, count == 1 and "" or "s"))
end

return M
