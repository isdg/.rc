#!/usr/bin/env bash
# Component: Keyboard remap (via hidutil UserKeyMapping)
#   Right Command -> Return
#   Caps Lock     <-> Backspace  (swap)
# Requires: DOTFILES_DIR to be set

_keyremap_plist() { echo "${DOTFILES_DIR:-$HOME/.rc}/darwin/keyremap/com.local.KeyRemap.plist"; }
_keyremap_dst()   { echo "$HOME/Library/LaunchAgents/com.local.KeyRemap.plist"; }

# The mappings the plist asks for, as sorted "src dst" decimal pairs. The plist
# spells them in hex and always writes Src before Dst within each object, so
# pairing consecutive hex literals is enough.
_keyremap_expected_pairs() {
    grep -o '0x[0-9A-Fa-f]\{1,\}' "$1" \
        | while read -r hex; do printf '%d\n' "$hex"; done \
        | paste -d' ' - - | sort
}

# The mappings actually in effect, same shape. hidutil prints decimal and orders
# the keys alphabetically — Dst before Src — so each object is taken apart by
# name, not by position. With no mapping set it prints "(null)", which yields no
# objects and so an empty list. Done in awk rather than a read loop so that
# sourcing this file from a non-bash shell cannot change the result.
_keyremap_live_pairs() {
    hidutil property --get "UserKeyMapping" 2>/dev/null \
        | tr -d ' \n' | grep -o '{[^}]*}' \
        | awk '{
              src = ""; dst = ""
              if (match($0, /Src=[0-9]+/)) src = substr($0, RSTART + 4, RLENGTH - 4)
              if (match($0, /Dst=[0-9]+/)) dst = substr($0, RSTART + 4, RLENGTH - 4)
              if (src != "" && dst != "") print src, dst
          }' \
        | sort
}

ensure_keyremap_darwin() {
    local src dst failed=0
    src="$(_keyremap_plist)"
    dst="$(_keyremap_dst)"
    echo "[STEP] Verifying keyboard remap..."

    if [ ! -f "$src" ]; then
        echo "[SKIP] $src not found in dotfiles"
        return 0
    fi

    _check_link "com.local.KeyRemap.plist" "$dst" "$src" || failed=1

    # A correct symlink says nothing about whether the remap is in effect: the
    # agent still has to be registered, and hidutil state is per-boot. Checking
    # only the link is how a dead remap sat here reporting [OK].
    if launchctl print "gui/$(id -u)/com.local.KeyRemap" >/dev/null 2>&1; then
        echo "[OK] LaunchAgent registered"
    else
        echo "[FAIL] LaunchAgent not registered (launchctl bootstrap gui/$(id -u) $dst)"
        failed=1
    fi

    local expected live
    expected="$(_keyremap_expected_pairs "$src")"
    live="$(_keyremap_live_pairs)"
    if [ -z "$live" ]; then
        echo "[FAIL] No key mapping active (hidutil UserKeyMapping is empty)"
        failed=1
    elif [ "$expected" = "$live" ]; then
        echo "[OK] Key mapping active ($(printf '%s\n' "$expected" | wc -l | tr -d ' ') mappings)"
    else
        echo "[FAIL] Active key mapping does not match the plist (want / live):"
        diff <(printf '%s\n' "$expected") <(printf '%s\n' "$live") | sed 's/^/       /'
        failed=1
    fi

    return $failed
}

install_keyremap_darwin() {
    local src dst dst_dir domain
    src="$(_keyremap_plist)"
    dst="$(_keyremap_dst)"
    dst_dir="$(dirname "$dst")"

    echo "[STEP] Installing keyboard remap LaunchAgent..."

    if [ ! -f "$src" ]; then
        echo "[SKIP] $src not found"
        return 0
    fi

    mkdir -p "$dst_dir"
    ln -sf "$src" "$dst"
    echo "[OK] Linked com.local.KeyRemap.plist"

    domain="gui/$(id -u)"
    launchctl bootout "$domain/com.local.KeyRemap" 2>/dev/null || true
    if launchctl bootstrap "$domain" "$dst" 2>/dev/null; then
        echo "[OK] LaunchAgent loaded"
    else
        echo "[WARN] Could not load LaunchAgent (will run on next login)"
    fi

    # RunAtLoad fires hidutil asynchronously, so confirm the mapping actually
    # landed rather than trusting bootstrap's exit code. Reported, never fatal:
    # darwin.sh runs install mode under `set -e`, and a remap that needs a
    # re-login should not abort the rest of a bootstrap.
    local expected live
    expected="$(_keyremap_expected_pairs "$src")"
    live="$(_keyremap_live_pairs)"
    if [ "$expected" = "$live" ]; then
        echo "[OK] Key mapping active (right-cmd -> return, caps <-> backspace)"
    elif [ -z "$live" ]; then
        echo "[WARN] Key mapping not active yet — log out and back in, or run:"
        echo "       launchctl kickstart -k $domain/com.local.KeyRemap"
    else
        echo "[WARN] Active key mapping differs from the plist; run ./bootstrap/darwin.sh --ensure"
    fi

    return 0
}
