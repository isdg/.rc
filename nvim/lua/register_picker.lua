-- ============================================================
--                     REGISTER PICKER
-- ============================================================
-- fzf over registers: pick the named register a yank goes into while seeing
-- what it would overwrite, or the register to paste while seeing what it holds.
local M = {}

local NAMED = "abcdefghijklmnopqrstuvwxyz"
-- No "=": reading it evaluates an expression.
local READABLE = '"0123456789' .. NAMED .. '-.:/%#+*'
local SHOWN = 200

-- The picker itself; tests swap in a fake that calls spec["sink*"].
function M.run(name, spec)
    vim.fn["fzf#run"](vim.fn["fzf#wrap"](name, spec))
end

local function entry(reg)
    local lines = vim.tbl_map(vim.fn.strtrans, vim.fn.getreg(reg, 1, true))
    local text = vim.fn.strcharpart(table.concat(lines, "^J"), 0, SHOWN)
    local regtype = vim.fn.getregtype(reg)
    local kind = ({ v = "c", V = "l", [""] = " " })[regtype] or "b"
    return (('"%s  %s  %s'):format(reg, kind, text):gsub("%s+$", ""))
end

-- Leaves visual mode so '< and '> hold the selection for gv once fzf closes.
local function leave_visual()
    local mode = vim.fn.mode()
    if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
        return false
    end
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    return true
end

local function pick(name, source, options, on_pick)
    M.run(name, {
        source = source,
        options = vim.list_extend({ "+m", "--expect", "alt-enter",
            "--tiebreak", "index" }, options),
        ["sink*"] = function(out)
            if out[2] then
                on_pick(out[2]:sub(2, 2), out[1] == "alt-enter")
            end
        end,
    })
end

-- 'i': the keys go ahead of anything still typed, as if they came first.
local function feed(keys)
    vim.api.nvim_feedkeys(keys, "in", false)
end

-- Normal mode feeds [count]"xy and leaves the motion to be typed; alt-enter
-- appends ("X) instead of overwriting.
function M.yank()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    local visual = leave_visual()
    local source = {}
    for reg in NAMED:gmatch(".") do
        source[#source + 1] = entry(reg)
    end
    pick("register-yank", source, {
        "--nth", "1", "--prompt", "Yank to:> ",
        "--header", "enter: overwrite, alt-enter: append",
    }, function(reg, append)
        local target = '"' .. (append and reg:upper() or reg)
        feed(visual and "gv" .. target .. "y" or count .. target .. "y")
    end)
end

-- Enter pastes after the cursor, or over a selection keeping the unnamed
-- register as <leader>p does; alt-enter pastes before, or over a selection
-- putting what it replaced in the unnamed register.
function M.paste()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    local visual = leave_visual()
    local plus = vim.fn.getreg("+")
    local source = {}
    for reg in READABLE:gmatch(".") do
        local skip = reg == "*" and vim.fn.getreg("*") == plus
        if not skip and vim.fn.getreg(reg) ~= "" then
            source[#source + 1] = entry(reg)
        end
    end
    if #source == 0 then
        vim.notify("All registers are empty", vim.log.levels.INFO)
        return
    end
    local header = visual and "enter: replace, alt-enter: replace and swap"
        or "enter: after, alt-enter: before"
    pick("register-paste", source, {
        "--prompt", "Paste:> ", "--header", header,
    }, function(reg, alt)
        local put = '"' .. reg .. count
        if visual then
            feed("gv" .. put .. (alt and "p" or "P"))
        else
            feed(put .. (alt and "P" or "p"))
        end
    end)
end

return M
