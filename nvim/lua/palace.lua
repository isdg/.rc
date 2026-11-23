-- ============================================================
--          PALACE: the vault `plc config` names, and links into it
-- ============================================================
local M = {}

-- Resolved, since the vault may be reached via a symlink; a file not yet
-- written resolves through its directory.
local function real(path)
    local dir = vim.fs.dirname(path)
    return vim.uv.fs_realpath(path) or vim.fs.joinpath(
        vim.uv.fs_realpath(dir) or dir, vim.fs.basename(path))
end
M.real = real

local vault

--- The vault's real path, or nil when `plc` names none. Asked once.
function M.root()
    if vault == nil then
        local ok, out = pcall(function()
            return vim.system({ "plc", "config" }, { text = true }):wait()
        end)
        vault = ok and out.code == 0 and real(vim.trim(out.stdout)) or false
    end
    return vault or nil
end

--- The vault when buffer bufnr is a note inside it, else nil.
function M.owner(bufnr)
    local root, name = M.root(), vim.api.nvim_buf_get_name(bufnr)
    if root and name ~= "" and vim.fs.relpath(root, real(name)) then
        return root
    end
end

--- `[[name]]` for each note path, by basename as wikilinks resolve it.
function M.links(paths)
    return vim.tbl_map(function(path)
        return ("[[%s]]"):format(vim.fn.fnamemodify(path, ":t:r"))
    end, paths)
end

-- plc's stdout, or nil once its error is shown.
local function plc(args)
    local out = vim.system(vim.list_extend({ "plc" }, args), { text = true })
        :wait()
    if out.code ~= 0 then
        vim.notify(vim.trim(out.stderr), vim.log.levels.WARN)
        return nil
    end
    return out.stdout
end

--- Open the note `plc args...` prints at its last line, where a note grows,
--- as the zsh wrappers (zsh/palace.zsh) do.
function M.open(args)
    local path = plc(args)
    if not path then return end
    vim.cmd.edit(vim.fn.fnameescape(vim.trim(path)))
    vim.cmd("normal! G")
end

-- Pick one of the notes `plc <sub> -l` lists, in its order, previewed from
-- the dir `plc config <sub>` names, and open it.
local function pick(sub, open)
    local list, dir = plc({ sub, "-l" }), plc({ "config", sub })
    if not list or not dir then return end
    local names = {}
    for line in vim.gsplit(list, "\n", { trimempty = true }) do
        names[#names + 1] = (line:gsub("^%s*%*?%s*", ""))
    end
    require("fzf-lua").fzf_exec(names, {
        prompt = sub .. " > ",
        cwd = vim.trim(dir),
        previewer = "builtin",
        fzf_opts = { ["--no-sort"] = true },
        actions = {
            ["enter"] = function(selected)
                if selected[1] then open(selected[1]) end
            end,
        },
    })
end

local function run(sub)
    return function(args) M.open(vim.list_extend({ sub }, args)) end
end

-- -l picks a note to open and -L marks one, as the zsh wrappers do.
local function listed(sub, open, otherwise)
    return function(args)
        if args[1] == "-l" or args[1] == "--list" then
            pick(sub, open)
        elseif args[1] == "-L" or args[1] == "--mark" then
            plc(vim.list_extend({ sub }, args))
        else
            otherwise(args)
        end
    end
end

-- plc todo opens no note by name, so a pick marks it last first.
local function open_todo(name)
    if plc({ "todo", "-L", name }) then M.open({ "todo" }) end
end

-- zsh/palace.zsh's aliases.
local ALIASES = {
    dl = run("daily"),
    wk = run("weekly"),
    st = run("shot"),
    nt = run("add"),
    pt = run("top"),
    td = listed("todo", open_todo, run("todo")),
    mm = listed("murmur", function(name) M.open({ "murmur", "-n", name }) end,
        run("murmur")),
    ig = listed("isg", function(name) M.open({ "isg", name }) end, run("isg")),
}

M.aliases = vim.tbl_keys(ALIASES)
table.sort(M.aliases)

--- :Plc ALIAS [ARGS]: the zsh alias ALIAS, with its args.
function M.command(args)
    local alias = ALIASES[args[1]]
    if not alias then
        vim.notify(("Plc: %s is none of %s"):format(tostring(args[1]),
            table.concat(M.aliases, " ")), vim.log.levels.ERROR)
        return
    end
    alias(vim.list_slice(args, 2))
end

--- Pick vault notes in fzf, newest first, and put links to them at the
--- cursor: after it like p, or before it like P.
function M.link(after)
    local root = M.root()
    if not root then
        vim.notify("plc names no vault", vim.log.levels.WARN)
        return
    end
    local fzf = require("fzf-lua")
    local win = vim.api.nvim_get_current_win()
    fzf.files({
        cwd = root,
        prompt = after and "link > " or "link before > ",
        cmd = "rg --files --sortr modified -g '*.md'",
        file_icons = false,
        git_icons = false,
        actions = {
            ["enter"] = function(selected, opts)
                local paths = vim.tbl_map(function(entry)
                    return fzf.path.entry_to_file(entry, opts).path
                end, selected)
                if #paths == 0 or not vim.api.nvim_win_is_valid(win) then
                    return
                end
                vim.api.nvim_win_call(win, function()
                    vim.api.nvim_put({ table.concat(M.links(paths), " ") },
                        "c", after, true)
                end)
            end,
        },
    })
end

return M
