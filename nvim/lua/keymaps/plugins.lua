-- ============================================================
--  PLUGINS LAYER: palace/plc stamps, hr reading list, lean
-- ============================================================
-- <leader><leader> opens a layer whose bare letters are tools, each handing off
-- to a sub-layer of that tool's verbs — the shape of tmux's `plugins` table
-- (C-b C-b, then a letter, then the verb), down to the name.
--
-- This replaces <leader>P* and <leader>H*, which spent two shifted top-level
-- prefixes on four keys between them. The letters survive unshifted, so the
-- sequences stay hr / hf / pt / pT and only the way in changes.
local map = require("keymaps.leader").map
local layer = require("keymaps.layer")

local function stamp(fmt)
    return function() vim.api.nvim_put({ os.date(fmt) }, "c", true, true) end
end

-- hr.vim (lua/plugins/misc.lua). Locate reveals the current article's row,
-- opening/refreshing the panel and showing read articles under unread-only.
local HR = {
    r = { desc = "toggle", run = "HrToggle" },
    f = { desc = "locate", run = "HrLocate" },
}

local PALACE = {
    -- format: isg 2026-06-04 13:15:42 +0200  (local time + local UTC offset)
    t = { desc = "stamp", run = stamp("isg %Y-%m-%d %H:%M:%S %z") },
    -- The same clock without the isg prefix, verbatim from the old <leader>PT.
    -- Its desc there said UTC, which the format string never was.
    T = { desc = "stamp bare", run = stamp("%Y-%m-%d %H:%M:%S %z") },
}

-- lean.nvim (lua/plugins/lsp.lua). Its commands exist once a .lean buffer
-- has loaded it, so the verbs error harmlessly anywhere else.
local LEAN = {
    i = { desc = "infoview", run = "LeanInfoviewToggle" },
    g = { desc = "go to infoview", run = "LeanGotoInfoview" },
    a = { desc = "accept suggestion", run = "LeanInfoviewAcceptSuggestion" },
    s = { desc = "fill sorry", run = "LeanSorryFill" },
    r = { desc = "restart file", run = "LeanRestartFile" },
    R = { desc = "refresh deps", run = "LeanRefreshFileDependencies" },
    ["\\"] = { desc = "how to type", run = "LeanAbbreviationsReverseLookup" },
}

local PLUGINS = {
    h = { desc = "hr reading list", name = "HR", keys = HR },
    l = { desc = "lean", name = "LEAN", keys = LEAN },
    p = { desc = "palace/plc", name = "PALACE", keys = PALACE },
}

map("n", "<leader><leader>", function() layer.open("PLUGINS", PLUGINS) end,
    { desc = "Plugins layer" })
