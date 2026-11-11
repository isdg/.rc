-- lua/keymaps/layer.lua: a key whose `cond` fails is neither shown nor run.
--   nvim --clean --headless -l nvim/tests/layer.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
local layer = require("keymaps.layer")

local failed = 0
local function check(name, got, want)
    local ok = vim.deep_equal(got, want)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- got " .. vim.inspect(got))))
end

local typed, hints = {}, {}
vim.fn.getcharstr = function() return table.remove(typed, 1) or "\27" end
vim.api.nvim_echo = function(chunks)
    if #chunks > 1 then hints[#hints + 1] = chunks end
end

-- Opens a layer with a hidden x, a shown s and an unconditional a, types
-- keys, and returns what ran and the keys the first hint named.
local function run(...)
    typed, hints = { ... }, {}
    local ran = {}
    local function verb(ch) return function() ran[#ran + 1] = ch end end
    local function yes() return true end
    local function no() return false end
    layer.open("T", {
        a = { desc = "always", run = verb("a") },
        s = { desc = "shown", run = verb("s"), cond = yes },
        x = { desc = "hidden", run = verb("x"), cond = no },
    })
    local named = {}
    for i = 2, #(hints[1] or {}), 2 do named[#named + 1] = hints[1][i][1] end
    return ran, named
end

local _, named = run()
check("hint names the shown and unconditional keys only", named, { "a", "s" })
check("a hidden key does not run", (run("x")), {})
check("a hidden key leaves the layer", (run("x", "s")), {})
check("a shown key runs", (run("s")), { "s" })
check("a key without cond runs", (run("a")), { "a" })

os.exit(failed == 0 and 0 or 1)
