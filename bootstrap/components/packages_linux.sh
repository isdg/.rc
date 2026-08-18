#!/usr/bin/env bash
# Component: Package installation (Linux)

ensure_packages_linux() {
    echo "[STEP] Verifying packages..."
    local failed=0 cmd
    # Split required from optional: nom and glow are not packaged on most
    # distros and prettier needs npm, so a single flat list reported [FAIL]
    # forever on a box that was in fact fine.
    local required=(zsh git curl wget tmux vim nvim fzf rg)
    local optional=(gh jq tree htop w3m sd prettier nom glow go cargo)

    for cmd in "${required[@]}"; do
        if command -v "$cmd" > /dev/null 2>&1; then
            echo "[OK] $cmd"
        else
            echo "[FAIL] $cmd not found"
            failed=1
        fi
    done
    for cmd in "${optional[@]}"; do
        command -v "$cmd" > /dev/null 2>&1 \
            && echo "[OK] $cmd" \
            || echo "[SKIP] $cmd not found (optional)"
    done
    return $failed
}

# apt aborts the WHOLE transaction when a single name is unknown to it —
# "E: Unable to locate package glow" and nothing else on the line gets
# installed either. On Debian bookworm that one optional package silently took
# zsh, tmux, neovim, fzf and ripgrep down with it, and `|| echo "[WARN] …"`
# made it look like a partial success. So: split the list, install what this
# release actually ships, and name the rest instead of failing the batch.
_apt_install() {
    local label="$1"; shift
    local available=() missing=() pkg

    for pkg in "$@"; do
        if apt-cache show "$pkg" 2>/dev/null | grep -q '^Package:'; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done

    if [ ${#available[@]} -gt 0 ]; then
        sudo apt-get install -y "${available[@]}" \
            || echo "[WARN] $label: apt-get returned an error"
    fi
    if [ ${#missing[@]} -gt 0 ]; then
        echo "[WARN] $label: not packaged in this release — skipped: ${missing[*]}"
    fi
}

detect_package_manager() {
    if command -v apt-get > /dev/null 2>&1; then
        echo "apt"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v yum > /dev/null 2>&1; then
        echo "yum"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper > /dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

install_packages_linux() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)
    echo "[INFO] Detected package manager: $pkg_manager"
    echo "[STEP] Installing required packages..."

    case "$pkg_manager" in
        apt)
            sudo apt-get update || echo "[WARN] apt-get update had warnings, continuing..."
            # Boring essentials. glow is optional (nothing in this repo calls
            # it) and absent from bookworm — _apt_install drops it rather than
            # letting it veto the shell itself.
            _apt_install "base" \
                zsh git gh curl wget jq tree htop tmux vim neovim fzf ripgrep \
                nodejs npm python3 \
                w3m glow
            # Docs
            _apt_install "man pages" man-db manpages-dev
            # Build toolchain
            _apt_install "build toolchain" build-essential pkg-config
            # Kernel module + full kernel build deps
            _apt_install "kernel build deps" \
                "linux-headers-$(uname -r)" \
                bc bison flex rsync kmod \
                libssl-dev libelf-dev libncurses-dev
            # USB userspace + headers
            _apt_install "USB tools" usbutils libusb-1.0-0-dev
            # Tracing & debugging (ltrace is x86-only in Debian, so it drops out
            # on an arm64 VM — without the split it took strace and gdb with it)
            _apt_install "tracing tools" strace ltrace gdb linux-perf
            # Zig (compiler from apt; zls usually not packaged — install manually
            # from https://github.com/zigtools/zls/releases or via `zigup`)
            _apt_install "zig" zig
            ;;
        dnf)
            sudo dnf install -y zsh git gh curl vim neovim fzf ripgrep nodejs npm w3m glow || echo "[WARN] Some packages may have failed"
            ;;
        yum)
            sudo yum install -y zsh git gh curl vim neovim fzf nodejs npm w3m || echo "[WARN] Some packages may have failed"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm zsh git github-cli curl vim neovim fzf ripgrep nodejs npm w3m glow || echo "[WARN] Some packages may have failed"
            ;;
        zypper)
            sudo zypper install -y zsh git gh curl vim neovim fzf ripgrep nodejs npm w3m glow || echo "[WARN] Some packages may have failed"
            ;;
        *)
            echo "[WARN] Unknown package manager. Please install manually: zsh git gh curl vim neovim fzf ripgrep w3m glow"
            ;;
    esac

    # prettier (markdown formatter used by conform.nvim)
    if command -v npm > /dev/null 2>&1; then
        sudo npm install -g prettier || echo "[WARN] prettier install failed"
    else
        echo "[WARN] npm not found, skipping prettier"
    fi

    # nom (terminal RSS reader) — not in apt/dnf/pacman, install via Go
    if command -v nom > /dev/null 2>&1; then
        echo "[SKIP] nom already installed"
    elif command -v go > /dev/null 2>&1; then
        go install github.com/guyfedwards/nom@latest \
            || echo "[WARN] nom install via 'go install' failed"
    else
        echo "[WARN] go not found, skipping nom (install from https://github.com/guyfedwards/nom/releases)"
    fi

    # sd (find & replace CLI, sed alternative) — newer tool, not in every distro,
    # so keep it out of the bundled line above (a missing package would abort the
    # whole install). Try the package manager, then fall back to cargo if present.
    if command -v sd > /dev/null 2>&1; then
        echo "[SKIP] sd already installed"
    else
        case "$pkg_manager" in
            apt)    sudo apt-get install -y sd || true ;;
            dnf)    sudo dnf install -y sd || true ;;
            yum)    sudo yum install -y sd || true ;;
            pacman) sudo pacman -S --noconfirm sd || true ;;
            zypper) sudo zypper install -y sd || true ;;
        esac
        command -v sd > /dev/null 2>&1 \
            || { command -v cargo > /dev/null 2>&1 && cargo install sd; } \
            || echo "[WARN] sd install failed (install via 'cargo install sd' or see https://github.com/chmln/sd)"
    fi

    echo "[OK] Packages installed"
}
