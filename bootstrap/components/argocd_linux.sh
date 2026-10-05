#!/usr/bin/env bash
# Component: argocd CLI (Linux only — Darwin takes it from the Brewfile).
# No distro ships it, so this pulls the official release binary. Unlike the
# Neovim build it arrives bare rather than in a tarball, so there is nothing
# to unpack — just mark it executable and drop it in ~/.local/bin (on PATH
# via zsh/.zshrc).

_argocd_release_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)  echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *)               echo "" ;;
    esac
}

ensure_argocd_linux() {
    echo "[STEP] Verifying argocd..."
    if command -v argocd > /dev/null 2>&1; then
        echo "[OK] $(argocd version --client --short 2>/dev/null || echo 'argocd installed')"
    else
        echo "[FAIL] argocd not installed"
        return 1
    fi
}

install_argocd_linux() {
    echo "[STEP] Installing argocd CLI..."

    # No version floor, unlike nvim: nothing in this repo requires a particular
    # argocd, and the CLI talks to whatever server the cluster runs.
    if command -v argocd > /dev/null 2>&1; then
        echo "[SKIP] argocd already installed ($(command -v argocd))"
        return 0
    fi

    local arch
    arch="$(_argocd_release_arch)"
    if [ -z "$arch" ]; then
        echo "[WARN] no official argocd build for $(uname -m) — install it manually"
        return 0
    fi

    local url="https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${arch}"
    local tmp="${TMPDIR:-/tmp}/argocd-linux-${arch}"

    echo "[INFO] Downloading the official argocd release ($arch)..."
    if ! curl -fsSL -o "$tmp" "$url"; then
        echo "[WARN] could not download $url — skipping argocd"
        rm -f "$tmp"
        return 0
    fi

    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp" "$HOME/.local/bin/argocd"
    rm -f "$tmp"
    echo "[OK] Installed $("$HOME/.local/bin/argocd" version --client --short 2>/dev/null) -> ~/.local/bin/argocd"
}
