-- :Commits/:BCommits previews from vim/fzf-layout.vim, headless:
--   nvim --clean --headless -l nvim/tests/commits_preview.lua
-- fzf.vim is stubbed, except that its plugin file, when installed, is
-- sourced last to show it leaves our commands in place.
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
local repo = vim.fs.dirname(nvim)

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local calls = {}
_G.record = function(fn, first, last, log_opts, spec, bang)
    calls[#calls + 1] = { fn = fn, range = { first, last },
        log_opts = log_opts, spec = spec, bang = bang }
end
-- Autoload names can only be defined in their autoload files.
local stubs = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(stubs .. "/autoload/fzf", "p")
vim.fn.writefile({
    "function! fzf#shellescape(arg, ...)",
    "    return shellescape(a:arg)",
    "endfunction",
}, stubs .. "/autoload/fzf.vim")
local stub = {
    "function! fzf#vim#with_preview(spec)",
    "    return extend(copy(a:spec),",
    "        \\ { 'options': ['--preview-window', 'down,60%'] })",
    "endfunction",
}
for _, fn in ipairs({ "commits", "buffer_commits" }) do
    vim.list_extend(stub, {
        ("function! fzf#vim#%s(log_opts, spec, bang) range"):format(fn),
        ("    call v:lua.record('%s', a:firstline, a:lastline,"):format(fn),
        "        \\ a:log_opts, a:spec, a:bang)",
        "endfunction",
    })
end
vim.fn.writefile(stub, stubs .. "/autoload/fzf/vim.vim")
vim.opt.rtp:prepend(stubs)
vim.cmd.source(repo .. "/vim/fzf-layout.vim")

local root = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(root, "p")
local function git(...)
    local out = vim.fn.system({ "git", "-C", root,
        "-c", "user.name=t", "-c", "user.email=t@t", ... })
    assert(vim.v.shell_error == 0, out)
    return vim.trim(out)
end
local function plain(s) return (s:gsub("\27%[[%d;]*m", "")) end
-- What fzf does to a preview command: quote each placeholder it fills.
local function run(cmd, line)
    cmd = cmd:gsub("{1}", vim.fn.shellescape(line:match("%S+")))
    cmd = cmd:gsub("{}", vim.fn.shellescape(line))
    cmd = "export FZF_PREVIEW_COLUMNS=80; " .. cmd
    return plain(vim.fn.system({ "sh", "-c", cmd }))
end
local function preview(call)
    local o = call.spec.options
    for i, v in ipairs(o) do
        if v == "--preview" then return o[i + 1] end
    end
end

local ok, err = pcall(function()
    git("init", "-q")
    local file = root .. "/a.txt"
    vim.fn.writefile({ "one", "two", "three" }, file)
    git("add", ".")
    git("commit", "-qm", "first")
    vim.fn.writefile({ "one", "TWO", "three" }, file)
    git("commit", "-qam", "second")
    local head = git("rev-parse", "--short", "HEAD")
    vim.cmd.edit(file)
    vim.o.columns = 80

    vim.cmd("Commits")
    local c = calls[#calls]
    check("Commits: delegates to fzf#vim#commits, no range",
        c.fn == "commits" and c.bang == 0, c)
    check("Commits: keeps the preview window and adds a preview",
        c.spec.options[1] == "--preview-window" and preview(c) ~= nil,
        c.spec.options)
    local shown = run(preview(c), "* " .. head .. " (HEAD) second")
    check("Commits: preview at 80 columns shows the diff",
        shown:find("TWO", 1, true) and not shown:find("first", 1, true),
        shown)

    vim.cmd("BCommits! --no-merges")
    c = calls[#calls]
    check("BCommits: buffer history, log options and bang pass through",
        c.fn == "buffer_commits" and c.log_opts == "--no-merges"
            and c.bang == 1, c)

    vim.cmd("2BCommits")
    c = calls[#calls]
    check("2BCommits: the range reaches fzf.vim",
        c.fn == "buffer_commits" and vim.deep_equal(c.range, { 2, 2 }), c)
    check("2BCommits: preview follows the line with log -L",
        preview(c):find("log -L 2,2:", 1, true), preview(c))
    shown = run(preview(c), head .. " second")
    check("2BCommits: preview shows only that commit's line diff",
        shown:find("TWO", 1, true) and shown:find(head, 1, true), shown)

    local fzf_vim = vim.fn.stdpath("data") .. "/lazy/fzf.vim/plugin/fzf.vim"
    if vim.uv.fs_stat(fzf_vim) then
        vim.cmd.source(fzf_vim)
        local def = vim.api.nvim_get_commands({}).Commits.definition
        check("fzf.vim loaded after leaves our Commits",
            def:find("Commits(0", 1, true), def)
    else
        io.stdout:write("SKIP fzf.vim not installed\n")
    end
end)
check("no error", ok, err)
vim.fn.delete(root, "rf")
os.exit(failed == 0 and 0 or 1)
