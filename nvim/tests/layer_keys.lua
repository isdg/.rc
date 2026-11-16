-- keymaps/layer.lua: single and multi-character keys, Russian twins, the hint.
--   nvim --clean --headless -l nvim/tests/layer_keys.lua
local nvim = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
vim.opt.rtp:prepend(nvim)
local layer = require("keymaps.layer")

local failed = 0
local function check(name, ok, detail)
    if not ok then failed = failed + 1 end
    io.stdout:write(("%s %s%s\n"):format(ok and "PASS" or "FAIL", name,
        ok and "" or ("  -- " .. vim.inspect(detail))))
end

local queue, hints, ran
vim.fn.getcharstr = function()
    local ch = table.remove(queue, 1)
    if ch == nil then error("Keyboard interrupt") end
    return ch
end
vim.api.nvim_echo = function(chunks)
    local text = table.concat(vim.tbl_map(function(c) return c[1] end, chunks))
    if text ~= "" then hints[#hints + 1] = text end
end
local function verb(id, stay)
    return { desc = id, run = function() ran[#ran + 1] = id end, stay = stay }
end
local KEYS = {
    a = verb("a"),
    A = verb("A"),
    dl = verb("dl"),
    tS = verb("tS"),
    ts = verb("ts"),
    n = verb("n", true),
}
local function press(...)
    queue, hints, ran = { ... }, {}, {}
    layer.open("T", KEYS)
    return ran
end

check("a single key runs its verb", vim.deep_equal(press("a"), { "a" }), ran)
check("two keys run a two-character verb",
    vim.deep_equal(press("d", "l"), { "dl" }), ran)
check("case tells tS from ts", vim.deep_equal(press("t", "S"), { "tS" }), ran)
check("Russian twins resolve per key",
    vim.deep_equal(press("в", "д"), { "dl" }), ran)
check("a prefix that leads nowhere leaves, running nothing",
    vim.deep_equal(press("d", "x", "a"), {}) and #queue == 1, queue)
check("Esc mid-sequence leaves", vim.deep_equal(press("t", "\27"), {}), ran)
check("a stay verb starts the next sequence from scratch",
    vim.deep_equal(press("n", "d", "l"), { "n", "dl" }), ran)

press("t", "\27")
check("the hint narrows to what the typed keys still reach",
    hints[2] == "-- T --  ts ts   tS tS   ", hints)
check("a pair lists lowercase first",
    vim.startswith(hints[1], "-- T --  a a   A A   dl dl   "), hints)

io.stdout:write(failed == 0 and "ok\n" or ("%d failed\n"):format(failed))
os.exit(failed == 0 and 0 or 1)
