#!/usr/bin/env bash
# Component: Package installation (Linux)

ensure_packages_linux() {
    echo "[STEP] Verifying packages..."
    local failed=0
    local cmds=(zsh git gh curl wget tmux vim nvim fzf rg tree prettier nom zoxide sd)
    for cmd in "${cmds[@]}"; do
        if command -v "$cmd" > /dev/null 2>&1; then
            echo "[OK] $cmd"
        else
            echo "[FAIL] $cmd not found"
            failed=1
        fi
    done
    return $failed
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
            # Boring essentials
            sudo apt-get install -y \
                zsh git gh curl wget jq tree htop tmux vim neovim fzf ripgrep \
                nodejs npm python3 \
                w3m glow \
                || echo "[WARN] Some base packages may have failed"
            # Docs
            sudo apt-get install -y man-db manpages-dev \
                || echo "[WARN] man pages install failed"
            # Build toolchain
            sudo apt-get install -y build-essential pkg-config \
                || echo "[WARN] build toolchain install failed"
            # Kernel module + full kernel build deps
            sudo apt-get install -y \
                "linux-headers-$(uname -r)" \
                bc bison flex rsync kmod \
                libssl-dev libelf-dev libncurses-dev \
                || echo "[WARN] kernel build deps install failed (linux-headers may not match running kernel)"
            # USB userspace + headers
            sudo apt-get install -y usbutils libusb-1.0-0-dev \
                || echo "[WARN] USB tools install failed"
            # Tracing & debugging
            sudo apt-get install -y strace ltrace gdb linux-perf \
                || echo "[WARN] tracing tools install failed"
            # Zig (compiler from apt; zls usually not packaged — install manually
            # from https://github.com/zigtools/zls/releases or via `zigup`)
            sudo apt-get install -y zig \
                || echo "[WARN] zig install failed (not all apt repos ship it)"
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

    # zoxide (frecency cd) — separate install so a distro without the package
    # doesn't break the bundled line above. Try the package manager, then fall
    # back to the official installer (lands in ~/.local/bin, already on PATH).
    if command -v zoxide > /dev/null 2>&1; then
        echo "[SKIP] zoxide already installed"
    else
        case "$pkg_manager" in
            apt)    sudo apt-get install -y zoxide || true ;;
            dnf)    sudo dnf install -y zoxide || true ;;
            yum)    sudo yum install -y zoxide || true ;;
            pacman) sudo pacman -S --noconfirm zoxide || true ;;
            zypper) sudo zypper install -y zoxide || true ;;
        esac
        command -v zoxide > /dev/null 2>&1 || \
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh \
            || echo "[WARN] zoxide install failed (see https://github.com/ajeetdsouza/zoxide)"
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
