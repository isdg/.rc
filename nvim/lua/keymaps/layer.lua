-- ============================================================
--                  LAYER: a durable key table
-- ============================================================
-- nvim has no key tables, so a layer is a read-key loop rather than a set of
-- mappings: each key dispatches itself and says whether the layer stays open,
-- which is what tmux gets from `switch-client -T <table>` (see
-- tmux/rc.d/10-layer.conf).
--
-- Being a loop rather than a prefix is what buys the two things a prefix map
-- cannot have: a hint on screen for as long as the layer is up, and no
-- 'timeoutlen' pause, since nothing here is waiting to see if more keys follow.
-- The cost is that getcharstr() blocks -- autocmds do not fire while a layer is
-- open -- so layers are for punctual verbs, not for anything long-running.

local to_latin = require("russian").to_latin

local M = {}

local function reach(keys, typed)
    local out = {}
    for key, entry in pairs(keys) do
        if vim.startswith(key, typed) then out[key] = entry end
    end
    return out
end

-- typed plus ch, or plus its Latin twin when ch alone reaches nothing: one
-- lookup covers a whole layer's worth of Russian twins, where lmap has to make
-- a second mapping for every key it binds (keymaps/leader.lua).
local function extend(keys, typed, ch)
    for _, seq in ipairs({ typed .. ch, typed .. (to_latin[ch] or "") }) do
        if seq ~= typed and next(reach(keys, seq)) then return seq end
    end
end

local function hint(name, keys)
    local order = vim.tbl_keys(keys)
    table.sort(order, function(a, b)
        if a:lower() ~= b:lower() then return a:lower() < b:lower() end
        return a > b -- 'T' after 't', so a pair reads as one entry
    end)
    local chunks = { { "-- " .. name .. " --  ", "ModeMsg" } }
    for _, key in ipairs(order) do
        chunks[#chunks + 1] = { key, "Special" }
        chunks[#chunks + 1] = { " " .. keys[key].desc .. "   " }
    end
    return chunks
end

-- An echo wider than the command line raises a hit-enter prompt, so a hint
-- that does not fit loses its tail instead.
local function fit(chunks)
    local room, out = vim.v.echospace, {}
    for _, chunk in ipairs(chunks) do
        room = room - vim.fn.strdisplaywidth(chunk[1])
        if room < 0 then break end
        out[#out + 1] = chunk
    end
    return out
end

-- Read chars until they spell a key: its entry, or nil when they leave.
local function read(name, keys)
    local typed = ""
    repeat
        vim.api.nvim_echo(fit(hint(name, reach(keys, typed))), false, {})
        local ok, ch = pcall(vim.fn.getcharstr)
        -- Cleared before the action draws.
        vim.api.nvim_echo({ { "" } }, false, {})
        if not ok then return end -- <C-c>
        typed = extend(keys, typed, ch)
    until not typed or keys[typed]
    return typed and keys[typed]
end

--- Open a layer and run keys until one of them ends it.
--- keys: { [chars] = { desc = "shown in the hint", run = cmd|fn, stay = ... } }
---       or { desc = ..., name = "SUB", keys = {...} } to hand off to a sub-layer
--- A key of several chars is typed in turn, the hint narrowing as it goes; no
--- key may be a prefix of another, since the shorter one would always win.
--- Esc, <C-c> and any unbound key leave, matching how the tmux tables behave;
--- `stay` is the per-key opt-in that makes a verb repeat: true, or a function
--- asked before the verb runs, for a verb that only sometimes may keep keys.
--- A sub-layer replaces its parent rather than nesting inside it, so leaving
--- one leaves them all -- which is what `switch-client -T splits` does to the
--- plugins table.
function M.open(name, keys)
    while true do
        local entry = read(name, keys)
        if not entry then return end
        if entry.keys then return M.open(entry.name, entry.keys) end
        local stay = entry.stay
        if type(stay) == "function" then stay = stay() end
        local ok, err = pcall(function()
            if type(entry.run) == "function" then entry.run() else vim.cmd(entry.run) end
        end)
        if not ok then
            vim.notify(err, vim.log.levels.ERROR)
            return -- a layer that keeps going after an error hides the error
        end
        if not stay then return end
    end
end

return M
