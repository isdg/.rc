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

--- Open the note `plc args...` prints at its last line, where a note grows,
--- as the zsh wrappers (zsh/palace.zsh) do.
function M.open(args)
    local out = vim.system(vim.list_extend({ "plc" }, args), { text = true })
        :wait()
    if out.code ~= 0 then
        vim.notify(vim.trim(out.stderr), vim.log.levels.WARN)
        return
    end
    vim.cmd.edit(vim.fn.fnameescape(vim.trim(out.stdout)))
    vim.cmd("normal! G")
end

--- M.open with a name asked for last; nothing for an empty one.
function M.open_named(prompt, args)
    vim.ui.input({ prompt = prompt }, function(name)
        if name and name ~= "" then
            M.open(vim.list_extend(vim.list_slice(args), { name }))
        end
    end)
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
