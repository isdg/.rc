-- Run by run.sh in headless nvim: settle, the focused checks, then unless
-- LSP_TEST_QUICK the full suite. Exits non-zero on any failure.
local dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
_G.LT_DIR = dir
_G.LT_NVIM = vim.fs.dirname(vim.fs.dirname(dir))
_G.LT_OUT = vim.env.LSP_TEST_OUT
vim.defer_fn(function()
    local ok, failed = pcall(function()
        _G.LT_ROOT = dofile(dir .. "/settle.lua")
        local n = dofile(dir .. "/unit.lua")
        if vim.env.LSP_TEST_QUICK ~= "1" then
            n = n + dofile(dir .. "/suite.lua")
        end
        return n
    end)
    if not ok then io.stdout:write(tostring(failed), "\n") end
    vim.cmd(ok and failed == 0 and "qa!" or "cquit 1")
end, 100)
