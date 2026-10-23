-- Opens tokio's lib.rs and waits for rust-analyzer to attach and go quiet,
-- ten seconds with no unfinished progress. Returns its root.
vim.cmd("edit tokio/src/lib.rs")
local function client()
    return vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" })[1]
end
vim.wait(120000, function() return client() ~= nil end, 50)
local c = assert(client(), "rust-analyzer did not attach")
local quiet = vim.uv.now()
vim.wait(30 * 60000, function()
    if next(c.progress.pending) then quiet = vim.uv.now() end
    return vim.uv.now() - quiet > 10000
end, 200)
io.stdout:write("rust-analyzer ready, root ", c.root_dir, "\n")
return c.root_dir
