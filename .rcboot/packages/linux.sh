#!/usr/bin/env bash
# Component: Package installation (Linux)

# True when the bootstrap level includes level $1.
_level() { [ "${RC_LEVEL:-3}" -ge "$1" ]; }

ensure_packages_linux() {
    echo "[STEP] Verifying packages..."
    local failed=0 cmd
    # Split required from optional: nom and glow are not packaged on most
    # distros and prettier needs npm, so a single flat list reported [FAIL]
    # forever on a box that was in fact fine.
    local required=() optional=()
    if _level 1; then required+=(zsh git curl wget tmux vim); fi
    if _level 2; then
        required+=(fzf rg tig)
        optional+=(gh zoxide jq tree htop)
    fi
    if _level 3; then
        required+=(nvim)
        optional+=(w3m sd prettier nom glow go cargo qemu-img)
    fi

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

# Names for dnf, yum, pacman and zypper up to the bootstrap level. yum has no
# ripgrep, zoxide or glow; pacman calls gh github-cli.
_dist_pkgs() {
    local pm="$1" p
    local pkgs=()
    if _level 1; then pkgs+=(zsh git curl wget tmux vim); fi
    if _level 2; then pkgs+=(fzf ripgrep tig gh zoxide); fi
    if _level 3; then pkgs+=(neovim nodejs npm w3m glow); fi
    for p in ${pkgs[@]+"${pkgs[@]}"}; do
        case "$pm:$p" in
            yum:ripgrep|yum:zoxide|yum:glow) ;;
            pacman:gh) echo github-cli ;;
            *) echo "$p" ;;
        esac
    done
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
            if _level 1; then
                _apt_install "core" zsh git curl wget tmux vim man-db
            fi
            if _level 2; then
                _apt_install "tools" fzf ripgrep tig gh zoxide jq tree htop
            fi
            if _level 3; then
                # glow is optional (nothing in this repo calls it) and absent
                # from bookworm — _apt_install drops it rather than letting it
                # veto the rest.
                _apt_install "base" neovim nodejs npm python3 w3m glow
                _apt_install "man pages" manpages-dev
                # Build toolchain
                _apt_install "build toolchain" build-essential pkg-config
                # Kernel module + full kernel build deps
                _apt_install "kernel build deps" \
                    "linux-headers-$(uname -r)" \
                    bc bison flex rsync kmod \
                    libssl-dev libelf-dev libncurses-dev
                # USB userspace + headers
                _apt_install "USB tools" usbutils libusb-1.0-0-dev
                # Tracing & debugging (ltrace is x86-only in Debian, so it
                # drops out on an arm64 VM — without the split it took strace
                # and gdb with it)
                _apt_install "tracing tools" strace ltrace gdb linux-perf
                # Zig (compiler from apt; zls usually not packaged — install
                # manually from https://github.com/zigtools/zls/releases or
                # via `zigup`)
                _apt_install "zig" zig
                # VMs: every system emulator plus qemu-img
                _apt_install "qemu" qemu-system qemu-utils
            fi
            ;;
        dnf|yum|pacman|zypper)
            local pkgs
            pkgs=($(_dist_pkgs "$pkg_manager"))
            if [ ${#pkgs[@]} -gt 0 ]; then
                if [ "$pkg_manager" = pacman ]; then
                    sudo pacman -Sy --noconfirm "${pkgs[@]}"
                else
                    sudo "$pkg_manager" install -y "${pkgs[@]}"
                fi || echo "[WARN] Some packages may have failed"
            fi
            ;;
        *)
            echo "[WARN] Unknown package manager. Please install manually:" \
                $(_dist_pkgs unknown)
            ;;
    esac

    # The rest is level 3 only: none of it is packaged everywhere.
    if ! _level 3; then
        echo "[OK] Packages installed"
        return 0
    fi

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

    # qemu names differ per distro and one unknown name aborts the whole
    # transaction, so it stays off the base lines (apt handles it above).
    local qemu_ok=0
    case "$pkg_manager" in
        dnf)    sudo dnf install -y qemu qemu-img && qemu_ok=1 ;;
        yum)    sudo yum install -y qemu-kvm qemu-img && qemu_ok=1 ;;
        pacman) sudo pacman -S --noconfirm qemu-full && qemu_ok=1 ;;
        zypper) sudo zypper install -y qemu qemu-tools && qemu_ok=1 ;;
        *)      qemu_ok=1 ;;
    esac
    [ "$qemu_ok" = 1 ] || echo "[WARN] qemu install failed"

    echo "[OK] Packages installed"
}
