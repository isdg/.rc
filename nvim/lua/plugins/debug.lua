-- ============================================================
--                    DEBUGGER (DAP)
-- ============================================================
-- Loaded on the first require("dap"), which only the debug layer makes
-- (<leader><leader>d, rc.d/10-keys-plugins.lua). Python through dap-python,
-- C and C++ through lldb-dap; further languages are an adapter each.
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

            -- brew's keg-only lldb when lldb-dap is not on $PATH. The Xcode
            -- tools' copy can lag its LLDB.framework and then fails to load.
            local lldb_dap = vim.fn.exepath("lldb-dap")
            if lldb_dap == "" then
                lldb_dap = "/opt/homebrew/opt/lldb/bin/lldb-dap"
            end
            dap.adapters.lldb = {
                type = "executable",
                command = lldb_dap,
                name = "lldb",
            }

            local utils = require("dap.utils")
            local native = {
                {
                    name = "Launch",
                    type = "lldb",
                    request = "launch",
                    program = function()
                        return utils.pick_file({ executables = true })
                    end,
                    args = function()
                        return utils.splitstr(vim.fn.input("Args: "))
                    end,
                    cwd = "${workspaceFolder}",
                },
                {
                    name = "Attach",
                    type = "lldb",
                    request = "attach",
                    pid = utils.pick_process,
                },
            }
            dap.configurations.c = native
            dap.configurations.cpp = native

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
