-- Focused checks of the picker and the rust-analyzer setup, on real
-- rust-analyzer; replies are stubbed only for states it cannot be put in on
-- demand (mid-indexing, an error). Returns the number of failures.
local picker = require("lsp_picker")
local fzf = require("fzf-lua")
local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. tostring(detail))))
end

local captured, notes = nil, {}
local real_exec, real_notify = fzf.fzf_exec, vim.notify
local real_all = vim.lsp.buf_request_all
fzf.fzf_exec = function(contents, opts)
    captured = { contents = contents, opts = opts }
end
vim.notify = function(msg, level)
    notes[#notes + 1] = { msg = tostring(msg), level = level }
end

local function ra()
    return vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" })[1]
end
local function open(file, row, col)
    vim.cmd("silent! edit " .. file)
    vim.wait(60000, function() return ra() ~= nil end, 10)
    vim.api.nvim_win_set_cursor(0, { row, col })
end
local function find(file, needle)
    local n = 0
    for line in io.lines(file) do
        n = n + 1
        local c = line:find(needle, 1, true)
        if c then return n, c - 1 end
    end
end
local function run(fn, title)
    captured, notes = nil, {}
    local start = vim.api.nvim_get_current_buf()
    picker.locations(fn, title)()
    vim.wait(30000, function()
        return captured ~= nil or #notes > 0
            or vim.api.nvim_get_current_buf() ~= start
    end, 10)
end
local function first_note() return notes[1] and notes[1].msg end
local function stub(reply)
    vim.lsp.buf_request_all = function(_, _, _, handler)
        handler({ [ra().id] = reply })
    end
end

local ok, err = pcall(function()
    local row, at = find("tokio/src/task/join_set.rs", "self.builder.name(")
    open("tokio/src/task/join_set.rs", row, at + #"self.")
    vim.wait(10000, function() return #vim.diagnostic.get(0) > 0 end, 50)
    run("definition", "Definitions")
    check("cfg-inactive code says why gd is empty",
        (first_note() or ""):find("inactive due to #%[cfg%]"), first_note())

    open("tokio/src/runtime/driver/op.rs", 1, 0)
    vim.wait(10000, function() return #vim.diagnostic.get(0) > 0 end, 50)
    run("definition", "Definitions")
    check("a file outside the module tree says why",
        (first_note() or ""):find("not included anywhere"), first_note())

    row = find("tokio/src/runtime/runtime.rs", "pub struct Runtime")
    open("tokio/src/runtime/runtime.rs", row, 11)
    local c = ra()
    c.progress.pending["lsp-test"] = "Indexing"
    stub({ result = {} })
    run("references", "References")
    c.progress.pending["lsp-test"] = nil
    check("an empty answer while indexing says so",
        (first_note() or ""):find("Indexing in progress"), first_note())

    stub({ err = { code = -32801, message = "content modified" } })
    run("definition", "Definitions")
    check("a server error is a warning, not 'No ... found'",
        first_note() == "Definitions: rust_analyzer: content modified"
            and notes[1].level == vim.log.levels.WARN, first_note())

    local range = { start = { line = row - 1, character = 11 },
        ["end"] = { line = row - 1, character = 18 } }
    local loc = { uri = vim.uri_from_bufnr(0), range = range }
    stub({ result = { loc, loc } })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    run("definition", "Definitions")
    local cur = vim.api.nvim_win_get_cursor(0)
    check("one location reported twice jumps instead of listing",
        captured == nil and cur[1] == row and cur[2] == 11, vim.inspect(cur))
    vim.lsp.buf_request_all = real_all

    local rows = picker.format({
        { filename = "/tmp/a.rs", lnum = 3, col = 5,
            text = "\27[31mE\27[0m x" },
        { filename = "/tmp/b.rs", lnum = 10, col = 1, text = "  let y = 1;" },
    })
    local f, l, col = picker.location_of(rows[1])
    check("location_of reads a row back", f == "/tmp/a.rs" and l == 3
        and col == 5, ("%s %s %s"):format(f, l, col))
    local opts = { _fmt = { from = function(s)
        local hidden = s:match("\31(.*)$")
        return hidden and (hidden:gsub("\31", "")) or s
    end }, __resume_key = "lsp-test", copen = false }
    vim.fn.setqflist({}, "r", { items = {} })
    require("fzf-lua.actions").file_sel_to_qf(rows, opts)
    local texts = vim.tbl_map(function(q) return q.text end, vim.fn.getqflist())
    check("quickfix entries keep the row's plain text",
        texts[1] == "E x" and texts[2] == "let y = 1;", vim.inspect(texts))

    dofile(_G.LT_NVIM .. "/rc.d/09-keys-lsp.lua")
    vim.api.nvim_exec_autocmds("LspAttach",
        { buffer = 0, data = { client_id = ra().id } })
    local m = vim.fn.maparg("gr", "n", false, true)
    check("gr is buffer-local and nowait", m.buffer == 1 and m.nowait == 1,
        ("buffer %s nowait %s"):format(m.buffer, m.nowait))
    local rn = vim.fn.maparg("<leader>rn", "n", false, true)
    local rr = vim.fn.maparg("<leader>rr", "x", false, true)
    check("<leader>rn and visual <leader>rr are buffer-local",
        rn.buffer == 1 and rr.buffer == 1, vim.inspect({ rn.lhs, rr.lhs }))

    row, col = find("tokio/src/runtime/runtime.rs", "self.handle.enter()")
    vim.api.nvim_win_set_cursor(0, { row, col })
    local ui = require("fzf-lua.providers.ui_select")
    local real_select, offered = ui.ui_select, nil
    ui.ui_select = function(items) offered = items end
    vim.api.nvim_feedkeys(("v%dl"):format(#"self.handle" - 1), "nx", false)
    vim.api.nvim_feedkeys(vim.keycode("<leader>rr"), "x", false)
    vim.wait(30000, function() return offered ~= nil end, 10)
    ui.ui_select = real_select
    vim.cmd("normal! \27")
    local titles, only_refactor, span = {}, offered ~= nil, nil
    for _, it in ipairs(offered or {}) do
        titles[#titles + 1] = it.action.title
        only_refactor = only_refactor
            and (it.action.kind or ""):find("^refactor") ~= nil
        span = it.ctx.params.range
    end
    check("<leader>rr offers refactors only, on the selection",
        only_refactor and vim.tbl_contains(titles, "Extract into variable")
            and span.start.character == col
            and span["end"].character == col + #"self.handle",
        vim.inspect({ titles, span }))

    row, col = find("tokio/src/runtime/runtime.rs", "Duration")
    open("tokio/src/runtime/runtime.rs", row, col)
    local workspace = ra()
    run("definition", "Definitions")
    vim.wait(60000, function() return ra() ~= nil end, 10)
    local name = vim.api.nvim_buf_get_name(0)
    check("gd into std joins the workspace's rust-analyzer",
        name:find("/library/", 1, true) and ra() and ra().id == workspace.id,
        ("%s on client %s"):format(name, ra() and ra().root_dir))
    run("references", "References")
    check("gr inside std finds the workspace's references",
        captured and #captured.contents > 1, first_note())

    for _, file in ipairs({ "tokio-util/src/lib.rs", "tokio-stream/src/lib.rs",
        "examples/chat.rs", "benches/fs.rs" }) do
        open(file, 1, 0)
    end
    local roots = vim.tbl_map(function(s) return s.root_dir end,
        vim.lsp.get_clients({ name = "rust_analyzer" }))
    check("one rust-analyzer serves every crate", #roots == 1,
        vim.inspect(roots))

    row = find("tokio/src/runtime/runtime.rs", "pub fn block_on")
    open("tokio/src/runtime/runtime.rs", row, 11)
    captured = nil
    require("structure").tree("object")
    local function shown()
        local out = {}
        captured.contents(function(r) if r then out[#out + 1] = r end end)
        return out
    end
    local before = captured and #shown()
    local top
    for _, r in ipairs(before and shown() or {}) do
        if r:find("Runtime", 1, true) then top = r break end
    end
    if top then captured.opts.actions.left.fn({ top }) end
    check("the structure tree folds a row of the new format",
        top and #shown() < before, before)
end)
fzf.fzf_exec, vim.notify = real_exec, real_notify
vim.lsp.buf_request_all = real_all
if not ok then check("unit checks ran to the end", false, err) end
return failed
