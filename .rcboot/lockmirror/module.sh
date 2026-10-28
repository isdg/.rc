#!/usr/bin/env bash
# Module: lockmirror — a screen saver that shows the screen as it was left,
# started locked by a Hammerspoon hotkey (hammerspoon/lockmirror.lua).

[ "$RC_OS" = darwin ] || return 0

LOCKMIRROR_SAVER="$HOME/Library/Screen Savers/LockMirror.saver"
LOCKMIRROR_BIN="$LOCKMIRROR_SAVER/Contents/MacOS/LockMirror"

_lockmirror_stale() {
    local f
    [ -f "$LOCKMIRROR_BIN" ] || return 0
    for f in "$DOTFILES_DIR"/lockmirror/{LockMirrorView.swift,Info.plist}; do
        [ "$f" -nt "$LOCKMIRROR_BIN" ] && return 0
    done
    return 1
}

# The selection and the lock delay need System Settings or a password, so
# they are only reported.
ensure_lockmirror() {
    local store module delay
    store="$HOME/Library/Application Support/com.apple.wallpaper/Store"
    store="$store/Index.plist"
    if _lockmirror_stale; then
        echo "[FAIL] LockMirror.saver missing or older than lockmirror/"
        return 1
    fi
    echo "[OK] LockMirror.saver installed"
    module="$(plutil -extract \
        AllSpacesAndDisplays.Idle.Content.Choices.0.Configuration \
        raw -o - "$store" 2> /dev/null | base64 -D 2> /dev/null \
        | plutil -extract module.relative raw -o - - 2> /dev/null)"
    case "$module" in
        */LockMirror.saver | */LockMirror.saver/)
            echo "[OK] LockMirror is the screen saver" ;;
        *)
            echo "[FAIL] Screen saver is not LockMirror" \
                "(System Settings > Wallpaper > Screen Saver > Other)"
            return 1 ;;
    esac
    delay="$(sysadminctl -screenLock status 2>&1)"
    case "$delay" in
        *immediate*) echo "[OK] Screen saver locks immediately" ;;
        *)
            echo "[FAIL] Screen saver does not lock at once" \
                "(sysadminctl -screenLock immediate -password -)"
            return 1 ;;
    esac
}

# The extension lists savers once per launch and the host keeps old code
# loaded; both relaunch on demand.
install_lockmirror() {
    if ! command -v swiftc > /dev/null 2>&1; then
        echo "[SKIP] swiftc not found (xcode-select --install)"
        return 0
    fi
    _lockmirror_stale || { echo "[OK] LockMirror.saver up to date"; return 0; }
    if "$DOTFILES_DIR/lockmirror/build.sh"; then
        killall WallpaperLegacyExtension legacyScreenSaver 2> /dev/null || true
        echo "[OK] Built LockMirror.saver"
    else
        echo "[FAIL] Could not build LockMirror.saver"
        return 1
    fi
}
hook install_lockmirror ensure_lockmirror
