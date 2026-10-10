-- ============================================================
--                    DEBUGGER (DAP)
-- ============================================================
-- Loaded on the first require("dap"), which only the debug layer makes
-- (<leader><leader>d, rc.d/10-keys-plugins.lua). Python only for now: further
-- languages are an adapter + configurations each, beside dap-python's.
return {
    {
        "mfussenegger/nvim-dap",
        lazy = true,
        dependencies = {
            "mfussenegger/nvim-dap-python",
            "igorlfs/nvim-dap-view",
            "theHamsta/nvim-dap-virtual-text",
            "williamboman/mason.nvim",
        },
        config = function()
            local dap = require("dap")

            -- The adapter comes from mason; the debuggee runs on the project's
            -- interpreter, which dap-python finds via $VIRTUAL_ENV or ./.venv.
            local registry = require("mason-registry")
            if not registry.is_installed("debugpy") then
                vim.notify("debugpy: installing via mason, retry when done")
                registry.get_package("debugpy"):install()
            end
            require("dap-python").setup("debugpy-adapter")
            require("dap-python").test_runner = "pytest"

            require("nvim-dap-virtual-text").setup({})
            require("dap-view").setup({})

            -- A stop lands while the layer blocks in getcharstr(), which runs
            -- callbacks but never redraws. scopes follows the jump to a frame.
            dap.listeners.after.scopes["isg"] = function()
                vim.cmd.redraw()
            end
            dap.listeners.after.event_initialized["isg"] = function()
                require("dap-view").open()
            end
            dap.listeners.before.event_terminated["isg"] = function()
                require("dap-view").close()
            end
        end,
    },
}
