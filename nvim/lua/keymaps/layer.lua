-- ============================================================
--                  LAYER: a durable key table
-- ============================================================
-- nvim has no key tables, so a layer is a read-key loop rather than a set of
-- mappings: each key dispatches itself and says whether the layer stays open,
-- which is what tmux gets from `switch-client -T <table>` (see .tmux.conf).
--
-- Being a loop rather than a prefix is what buys the two things a prefix map
-- cannot have: a hint on screen for as long as the layer is up, and no
-- 'timeoutlen' pause, since nothing here is waiting to see if more keys follow.
-- The cost is that getcharstr() blocks -- autocmds do not fire while a layer is
-- open -- so layers are for punctual verbs, not for anything long-running.

local to_latin = require("russian").to_latin

local M = {}

-- One lookup covers a whole layer's worth of Russian twins, where lmap has to
-- make a second mapping for every key it binds (keymaps/leader.lua).
local function resolve(keys, ch)
    return keys[ch] or keys[to_latin[ch] or ""]
end

local function hint(name, keys)
    local order = vim.tbl_keys(keys)
    table.sort(order, function(a, b)
        if a:lower() ~= b:lower() then return a:lower() < b:lower() end
        return a < b -- 'T' after 't', so a pair reads as one entry
    end)
    local chunks = { { "-- " .. name .. " --  ", "ModeMsg" } }
    for _, key in ipairs(order) do
        chunks[#chunks + 1] = { key, "Special" }
        chunks[#chunks + 1] = { " " .. keys[key].desc .. "   " }
    end
    return chunks
end

--- Open a layer and run keys until one of them ends it.
--- keys: { [char] = { desc = "shown in the hint", run = cmd|fn, stay = bool } }
---       or { desc = ..., name = "SUB", keys = {...} } to hand off to a sub-layer
--- Esc, <C-c> and any unbound key leave, matching how the tmux tables behave;
--- `stay` is the per-key opt-in that makes a verb repeat. A sub-layer replaces
--- its parent rather than nesting inside it, so leaving one leaves them all --
--- which is what `switch-client -T splits` does to the plugins table.
function M.open(name, keys)
    local chunks = hint(name, keys)
    while true do
        vim.api.nvim_echo(chunks, false, {})
        local typed, ch = pcall(vim.fn.getcharstr)
        vim.api.nvim_echo({ { "" } }, false, {}) -- clear before the action draws
        if not typed then return end             -- <C-c>
        local entry = resolve(keys, ch)
        if not entry then return end
        if entry.keys then return M.open(entry.name, entry.keys) end
        local ok, err = pcall(function()
            if type(entry.run) == "function" then entry.run() else vim.cmd(entry.run) end
        end)
        if not ok then
            vim.notify(err, vim.log.levels.ERROR)
            return -- a layer that keeps going after an error hides the error
        end
        if not entry.stay then return end
    end
end

return M
