#!/usr/bin/env bash
# Component: omni + orchbus — tmux plugin binaries (Rust, shared)
#
# The omni and orchbus tmux plugins are served by small Rust binaries. TPM clones
# the plugins into ~/.tmux/plugins, but the binaries have to be built; we clone
# each source repo and `cargo install` it into ~/.cargo/bin (same pattern as plc,
# see plc.sh). The plugins' .tmux entrypoints resolve the binary from PATH, and
# self-heal with a background build if it's missing — this component just makes
# the build deterministic at setup time.
#
# Registry: one "name|repo|src[|crate]" per binary, crate being the package's
# path inside src when it isn't the root (orchbus's root is a virtual
# workspace, which cargo install refuses). Add a line to ship another.
_TMUX_PLUGIN_BINS=(
    "omni|https://github.com/isdg/omni.git|$HOME/omni"
    "orchbus|https://github.com/isdg/orchbus.git|$HOME/orchbus|crates/orchbus"
)

ensure_tmux_plugins() {
    echo "[STEP] Verifying tmux plugin binaries (omni, orchbus)..."
    local rc=0 entry name
    for entry in "${_TMUX_PLUGIN_BINS[@]}"; do
        name="${entry%%|*}"
        if command -v "$name" >/dev/null 2>&1; then
            echo "[OK] $name installed ($(command -v "$name"))"
        else
            echo "[FAIL] $name not found on PATH (expected ~/.cargo/bin/$name)"
            rc=1
        fi
    done
    return "$rc"
}

install_tmux_plugins() {
    echo "[STEP] Installing tmux plugin binaries (omni, orchbus)..."

    if ! command -v cargo >/dev/null 2>&1; then
        echo "[WARN] cargo not found — install rust first (Brewfile: brew \"rust\"). Skipping omni/orchbus."
        return 0
    fi

    _export_buildable_sdk

    local entry name repo src crate pkg
    for entry in "${_TMUX_PLUGIN_BINS[@]}"; do
        IFS='|' read -r name repo src crate <<< "$entry"
        pkg="$src${crate:+/$crate}"

        if [ ! -d "$src/.git" ]; then
            echo "[INFO] Cloning $name into $src..."
            git clone "$repo" "$src" || {
                echo "[WARN] git clone $name failed — skipping."
                continue
            }
        else
            echo "[INFO] $name source already present at $src — pulling latest..."
            git -C "$src" pull --ff-only || echo "[WARN] git pull $name failed — building existing checkout as-is."
        fi

        echo "[INFO] cargo install --path $pkg..."
        if cargo install --path "$pkg"; then
            echo "[OK] $name installed to ~/.cargo/bin/$name"
        else
            echo "[WARN] cargo install $name failed — see output above."
        fi
    done
    return 0
}
