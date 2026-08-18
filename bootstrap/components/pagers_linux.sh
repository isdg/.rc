#!/usr/bin/env bash
# Component: pagers and pager helpers (Linux)
#
# The dotfiles hard-wire two pager helpers that Debian either renames or does
# not package at all, and both failed silently:
#
#   bat   — zsh/fzf.zsh and zsh/palace.zsh use it for previews, isg.zsh-theme
#           exports $BAT_THEME, and dotfiles.sh links ~/.config/bat and runs
#           `bat cache --build` to register the repo's vs_dark/vs_light themes.
#           Debian installs the binary as `batcat` (the name `bat` is taken by
#           bacula-console-qt), so every `command -v bat` guard is false: the
#           previews quietly fall back to awk, $BAT_THEME goes unread and the
#           theme cache is never built. A shim on PATH fixes all of it at once.
#
#   delta — .gitconfig sets `core.pager = delta` and `interactive.diffFilter =
#           delta --color-only`, plus a whole [delta] style block. bookworm has
#           no git-delta package (it arrives in trixie), so git silently falls
#           back to unstyled output. Worse, bookworm DOES ship a package called
#           `delta` — an unrelated 2006 "heuristic minimiser of interesting
#           files" — so `apt install delta` would put a bogus /usr/bin/delta in
#           front of git. Never install that one; fetch the real release.
#
# less needs no help: it is a base package on every distro, and the theme's
# LESS_TERMCAP_* exports (zsh/isg.zsh-theme) colour man pages through it.

DELTA_REPO="dandavison/delta"
BAT_REPO="sharkdp/bat"

_have() { command -v "$1" > /dev/null 2>&1; }

_bat_themes_dir() { echo "${XDG_CONFIG_HOME:-$HOME/.config}/bat/themes"; }

# Can this bat actually read bat/themes/vs_*.tmTheme? bookworm's 0.22.1 cannot —
# it rejects them with "Invalid syntax theme settings", so $BAT_THEME=vs_light
# resolves to nothing and every preview silently falls back to bat's default
# theme. 0.26.1 reads them. Rather than guess where between those the cutoff
# lies, ask bat directly: this is the requirement, a version number is a proxy.
_bat_reads_repo_themes() {
    local themes_dir; themes_dir="$(_bat_themes_dir)"
    [ -d "$themes_dir" ] || return 0   # nothing to test against yet
    bat cache --build 2>&1 | grep -q 'Failed to load one or more themes' && return 1
    return 0
}

ensure_pagers_linux() {
    echo "[STEP] Verifying pagers..."
    local failed=0

    if _have less; then
        echo "[OK] less"
    else
        echo "[FAIL] less not found"
        failed=1
    fi

    if _have bat; then
        if [ ! -d "$(_bat_themes_dir)" ] || bat --list-themes 2>/dev/null | grep -q '^vs_'; then
            echo "[OK] bat ($(command -v bat))"
        else
            echo "[FAIL] bat is installed but the vs_ themes are not registered — \$BAT_THEME falls back to bat's default"
            failed=1
        fi
    elif _have batcat; then
        echo "[FAIL] only batcat is on PATH — the 'bat' shim is missing, so fzf previews and \$BAT_THEME are dead"
        failed=1
    else
        echo "[FAIL] bat not found (fzf previews fall back to awk)"
        failed=1
    fi

    if _have delta; then
        echo "[OK] delta ($(command -v delta))"
    else
        echo "[FAIL] delta not found — .gitconfig sets core.pager = delta"
        failed=1
    fi

    return $failed
}

_bat_release_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)  echo "x86_64-unknown-linux-gnu" ;;
        aarch64 | arm64) echo "aarch64-unknown-linux-gnu" ;;
        *)               echo "" ;;
    esac
}

_install_bat_release_linux() {
    local arch; arch="$(_bat_release_arch)"
    if [ -z "$arch" ]; then
        echo "[WARN] no bat release for $(uname -m) — previews keep the distro's bat"
        return 1
    fi

    local tag
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$BAT_REPO/releases/latest" 2>/dev/null)"
    tag="${tag##*/}"
    if [ -z "$tag" ] || [ "$tag" = "latest" ]; then
        echo "[WARN] could not resolve the latest bat release — skipping"
        return 1
    fi

    local name="bat-${tag}-${arch}"
    local url="https://github.com/$BAT_REPO/releases/download/${tag}/${name}.tar.gz"
    local tmp="${TMPDIR:-/tmp}/${name}.tar.gz"
    local unpack="${TMPDIR:-/tmp}/bat-unpack.$$"

    if ! curl -fsSL -o "$tmp" "$url"; then
        echo "[WARN] could not download $url"
        return 1
    fi

    mkdir -p "$unpack" "$HOME/.local/bin"
    if tar -xzf "$tmp" -C "$unpack" --strip-components=1 && [ -f "$unpack/bat" ]; then
        install -m 755 "$unpack/bat" "$HOME/.local/bin/bat"
        rm -rf "$unpack" "$tmp"
        export PATH="$HOME/.local/bin:$PATH"
        hash -r 2>/dev/null || true
        echo "[OK] Installed bat ${tag#v} -> ~/.local/bin/bat"
        return 0
    fi

    echo "[WARN] could not unpack the bat tarball"
    rm -rf "$unpack" "$tmp"
    return 1
}

# Debian names it batcat; bridge that to the `bat` every config here expects,
# then make sure that bat is new enough to read the repo's own themes.
_install_bat_linux() {
    if ! _have bat && ! _have batcat; then
        case "$(detect_package_manager)" in
            apt)    _apt_install "bat" bat ;;
            dnf)    sudo dnf install -y bat || true ;;
            yum)    sudo yum install -y bat || true ;;
            pacman) sudo pacman -S --noconfirm bat || true ;;
            zypper) sudo zypper install -y bat || true ;;
        esac
    fi

    # `bat` is bacula-console-qt on Debian, so the package installs /usr/bin/
    # batcat. Without this shim every `command -v bat` guard in zsh/fzf.zsh and
    # zsh/palace.zsh is false and the previews drop to their awk fallback.
    if ! _have bat && _have batcat; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        export PATH="$HOME/.local/bin:$PATH"
        hash -r 2>/dev/null || true
        echo "[OK] Shimmed ~/.local/bin/bat -> $(command -v batcat) (Debian names it batcat)"
    fi

    if ! _have bat; then
        echo "[WARN] bat not installed — fzf previews will fall back to awk"
        return 0
    fi

    if _bat_reads_repo_themes; then
        echo "[OK] bat $(bat --version | cut -d' ' -f2) reads the repo themes ($(command -v bat))"
    else
        echo "[INFO] bat $(bat --version | cut -d' ' -f2) cannot parse bat/themes/vs_*.tmTheme — fetching a current release..."
        _install_bat_release_linux || true
    fi

    # Register vs_dark/vs_light so $BAT_THEME (zsh/isg.zsh-theme) resolves.
    if [ -d "$(_bat_themes_dir)" ]; then
        bat cache --build > /dev/null 2>&1 || true
        if bat --list-themes 2>/dev/null | grep -q '^vs_'; then
            echo "[OK] bat theme cache built (vs_dark, vs_light registered)"
        else
            echo "[WARN] bat did not register the vs_ themes — \$BAT_THEME will fall back to bat's default"
        fi
    fi
}

_delta_release_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)  echo "x86_64-unknown-linux-gnu" ;;
        aarch64 | arm64) echo "aarch64-unknown-linux-gnu" ;;
        *)               echo "" ;;
    esac
}

_install_delta_linux() {
    if _have delta; then
        echo "[SKIP] delta already on PATH ($(command -v delta))"
        return 0
    fi

    # git-delta is the correct package name where it exists (trixie+, Fedora,
    # Arch). The bare `delta` package is a different program — never use it.
    case "$(detect_package_manager)" in
        apt)
            if apt-cache show git-delta 2>/dev/null | grep -q '^Package:'; then
                sudo apt-get install -y git-delta || true
            fi
            ;;
        dnf)    sudo dnf install -y git-delta || true ;;
        pacman) sudo pacman -S --noconfirm git-delta || true ;;
        zypper) sudo zypper install -y git-delta || true ;;
    esac

    if _have delta; then
        echo "[OK] delta installed from the package manager ($(command -v delta))"
        return 0
    fi

    local arch; arch="$(_delta_release_arch)"
    if [ -z "$arch" ]; then
        echo "[WARN] no delta release for $(uname -m) — git will page without styling"
        return 0
    fi

    local tag
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$DELTA_REPO/releases/latest" 2>/dev/null)"
    tag="${tag##*/}"
    if [ -z "$tag" ] || [ "$tag" = "latest" ]; then
        echo "[WARN] could not resolve the latest delta release — skipping"
        return 0
    fi

    local name="delta-${tag}-${arch}"
    local url="https://github.com/$DELTA_REPO/releases/download/${tag}/${name}.tar.gz"
    local tmp="${TMPDIR:-/tmp}/${name}.tar.gz"

    echo "[INFO] bookworm has no git-delta package — installing delta $tag from the official release..."
    if ! curl -fsSL -o "$tmp" "$url"; then
        echo "[WARN] could not download $url — git will page without styling"
        return 0
    fi

    local unpack="${TMPDIR:-/tmp}/delta-unpack.$$"
    mkdir -p "$unpack" "$HOME/.local/bin"
    if tar -xzf "$tmp" -C "$unpack" --strip-components=1 && [ -f "$unpack/delta" ]; then
        install -m 755 "$unpack/delta" "$HOME/.local/bin/delta"
        echo "[OK] Installed delta $tag -> ~/.local/bin/delta"
        export PATH="$HOME/.local/bin:$PATH"
        hash -r 2>/dev/null || true
    else
        echo "[WARN] could not unpack the delta tarball"
    fi
    rm -rf "$unpack" "$tmp"
}

install_pagers_linux() {
    echo "[STEP] Installing pagers (bat, delta)..."
    _install_bat_linux
    _install_delta_linux
    echo "[OK] Pagers ready"
}
