#!/usr/bin/env bash
# Component: k9s (Linux only — Darwin takes it from the Brewfile).
#
# This repo configures k9s but never installed it: the skins directory and
# plugins.yaml are symlinked by dotfiles.sh, toggle_theme.sh flips the active
# skin, and zsh/aliases.zsh wraps the binary to fix TERM inside tmux -- while
# k9s itself was in no package list on either platform. All of that config
# verified [OK] against a command that was not there.
#
# No distro ships a current k9s, so this pulls the official release, same idea
# as argocd_linux.sh. Unlike argocd's bare binary it arrives as a tarball, so
# there is one extraction step.

_k9s_release_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)  echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        armv7l)          echo "armv7" ;;
        ppc64le)         echo "ppc64le" ;;
        s390x)           echo "s390x" ;;
        *)               echo "" ;;
    esac
}

ensure_k9s_linux() {
    echo "[STEP] Verifying k9s..."
    if command -v k9s > /dev/null 2>&1; then
        echo "[OK] k9s installed ($(command -v k9s))"
    else
        echo "[FAIL] k9s not installed"
        return 1
    fi
}

install_k9s_linux() {
    echo "[STEP] Installing k9s..."

    if command -v k9s > /dev/null 2>&1; then
        echo "[SKIP] k9s already installed ($(command -v k9s))"
        return 0
    fi

    local arch
    arch="$(_k9s_release_arch)"
    if [ -z "$arch" ]; then
        echo "[WARN] no official k9s build for $(uname -m) — install it manually"
        return 0
    fi

    local url="https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${arch}.tar.gz"
    local tmpdir
    tmpdir="$(mktemp -d)" || {
        echo "[WARN] could not create a temp dir — skipping k9s"
        return 0
    }

    echo "[INFO] Downloading the official k9s release ($arch)..."
    if ! curl -fsSL -o "$tmpdir/k9s.tar.gz" "$url"; then
        echo "[WARN] could not download $url — skipping k9s"
        rm -rf "$tmpdir"
        return 0
    fi

    # Extract only the binary: the tarball also carries LICENSE and README,
    # which have no business in ~/.local/bin.
    if ! tar -xzf "$tmpdir/k9s.tar.gz" -C "$tmpdir" k9s; then
        echo "[WARN] could not extract k9s from the release tarball — skipping"
        rm -rf "$tmpdir"
        return 0
    fi

    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmpdir/k9s" "$HOME/.local/bin/k9s"
    rm -rf "$tmpdir"
    echo "[OK] Installed k9s -> ~/.local/bin/k9s"
}
