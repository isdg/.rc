#!/usr/bin/env bash
# Component: lazy.nvim and the Neovim plugins (shared)

_lazy_path() {
    echo "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
}

# The parsers in nvim/lua/ts_parsers.lua that nvim-treesitter lacks.
_missing_ts_parsers() {
    nvim --headless +'lua
        local have = require("nvim-treesitter").get_installed("parsers")
        for _, p in ipairs(require("ts_parsers")) do
            if not vim.list_contains(have, p) then io.stdout:write(p, "\n") end
        end' +qa 2>/dev/null
}

ensure_nvim_plugins() {
    echo "[STEP] Verifying Neovim plugins..."
    if [ -d "$(_lazy_path)" ]; then
        echo "[OK] lazy.nvim installed"
    else
        echo "[FAIL] lazy.nvim not found ($(_lazy_path) missing)"
        return 1
    fi
    local missing
    missing="$(_missing_ts_parsers)"
    if [ -z "$missing" ]; then
        echo "[OK] Treesitter parsers installed"
    else
        echo "[FAIL] Treesitter parsers missing:" $missing
        return 1
    fi
}

# The clone used to happen in nvim's own startup; a config only loads
# plugins, it does not fetch them, so without this nvim starts plain.
install_nvim_plugins() {
    echo "[STEP] Installing Neovim plugins..."
    if [ ! -d "$(_lazy_path)" ]; then
        git clone --filter=blob:none --branch=stable \
            https://github.com/folke/lazy.nvim.git "$(_lazy_path)"
    fi
    # nvim exits 0 even when init.lua throws (and then syncs nothing), so its
    # own error banner is what tells failure apart.
    local out
    if out="$(nvim --headless "+Lazy! sync" +qa 2>&1)" &&
        ! printf '%s' "$out" | grep -q 'Error detected while processing'; then
        echo "[OK] Neovim plugins installed"
    else
        printf '%s\n' "$out" | grep -A3 'Error detected' | sed 's/^/       /'
        echo "[WARN] Neovim plugin install failed — run" \
            "'nvim --headless \"+Lazy! sync\" +qa' to see why"
    fi
    # Built by the tree-sitter CLI, so that and a C compiler must be present.
    echo "[STEP] Installing Treesitter parsers..."
    nvim --headless +'lua require("nvim-treesitter")
        .install(require("ts_parsers")):wait(300000)' +qa 2>&1 |
        sed 's/^/       /'
    if [ -z "$(_missing_ts_parsers)" ]; then
        echo "[OK] Treesitter parsers installed"
    else
        echo "[WARN] Treesitter parsers missing:" $(_missing_ts_parsers)
    fi
}
