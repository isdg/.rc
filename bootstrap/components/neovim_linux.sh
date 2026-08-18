#!/usr/bin/env bash
# Component: modern Neovim (Linux)
#
# nvim/init.lua needs Neovim >= 0.10 — lazy.nvim, telescope, mason and gitsigns
# all require it. Debian bookworm packages 0.7.2, on which init.lua dies at the
# first option call ("E5113: … E546: Illegal mode"), so lazy.nvim never
# bootstraps and nvim opens with no plugins at all. Distro packages lag Neovim
# badly and always will, so when apt's copy is too old, fetch the official
# static build into ~/.local rather than pinning the config to a 2022 API.
#
# ~/.local/bin must precede /usr/bin on PATH for this to take effect; .zshrc
# prepends it.

NVIM_MIN_MINOR=10   # minimum 0.x we support

# Resolve nvim the way an interactive shell would. Plain `command -v nvim` is
# not enough: ~/.local/bin is prepended by .zshrc, so a bash-run --ensure (or
# any script, or a $EDITOR spawned from a non-zsh context) still sees the
# distro's older /usr/bin/nvim and reports it.
_nvim_bin() {
    local candidate
    for candidate in "$HOME/.local/bin/nvim" /usr/local/bin/nvim; do
        [ -x "$candidate" ] && { echo "$candidate"; return 0; }
    done
    command -v nvim 2>/dev/null
}

_nvim_installed_version() {
    local bin; bin="$(_nvim_bin)"
    [ -n "$bin" ] || return 1
    "$bin" --version 2>/dev/null | head -1 | sed -n 's/^NVIM v\([0-9][0-9.]*\).*/\1/p'
}

# 0 = needs replacing (missing, unparseable, or older than the minimum).
_nvim_too_old() {
    local version major minor
    version="$(_nvim_installed_version)" || return 0
    [ -n "$version" ] || return 0

    major="${version%%.*}"
    minor="${version#*.}"; minor="${minor%%.*}"
    case "$major$minor" in *[!0-9]*) return 0 ;; esac

    [ "$major" -gt 0 ] && return 1
    [ "$minor" -ge "$NVIM_MIN_MINOR" ] && return 1
    return 0
}

_nvim_release_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)  echo "x86_64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *)               echo "" ;;
    esac
}

ensure_neovim_linux() {
    echo "[STEP] Verifying Neovim version..."
    local version
    version="$(_nvim_installed_version)"
    if [ -z "$version" ]; then
        echo "[FAIL] nvim not installed"
        return 1
    fi
    if _nvim_too_old; then
        echo "[FAIL] nvim $version at $(_nvim_bin) is older than 0.$NVIM_MIN_MINOR (this config will not load)"
        return 1
    fi
    echo "[OK] nvim $version ($(_nvim_bin))"
}

install_neovim_linux() {
    echo "[STEP] Checking Neovim version..."

    local version
    version="$(_nvim_installed_version)"

    if ! _nvim_too_old; then
        echo "[SKIP] nvim $version is new enough (>= 0.$NVIM_MIN_MINOR)"
        return 0
    fi

    if [ -n "$version" ]; then
        echo "[INFO] nvim $version is too old for this config (need >= 0.$NVIM_MIN_MINOR)"
    else
        echo "[INFO] nvim not found"
    fi

    local arch
    arch="$(_nvim_release_arch)"
    if [ -z "$arch" ]; then
        echo "[WARN] no official Neovim build for $(uname -m) — install a newer nvim manually"
        return 0
    fi

    local url="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${arch}.tar.gz"
    local prefix="$HOME/.local/share/nvim-release"
    local tarball="${TMPDIR:-/tmp}/nvim-linux-${arch}.tar.gz"

    echo "[INFO] Installing the official Neovim static build ($arch) into $prefix..."
    if ! curl -fsSL -o "$tarball" "$url"; then
        echo "[WARN] could not download $url — leaving the distro's nvim in place"
        return 0
    fi

    rm -rf "$prefix"
    mkdir -p "$prefix" "$HOME/.local/bin"
    if ! tar -xzf "$tarball" -C "$prefix" --strip-components=1; then
        echo "[WARN] could not unpack the Neovim tarball"
        rm -f "$tarball"
        return 0
    fi
    rm -f "$tarball"

    ln -sf "$prefix/bin/nvim" "$HOME/.local/bin/nvim"
    echo "[OK] Installed nvim $("$prefix/bin/nvim" --version | head -1 | sed 's/^NVIM v//') -> ~/.local/bin/nvim"

    # The rest of the bootstrap (vim.sh's Lazy sync) shells out to `nvim`, and
    # this script's PATH still has the old one in front.
    export PATH="$HOME/.local/bin:$PATH"
    hash -r 2>/dev/null || true
}
