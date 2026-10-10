#!/usr/bin/env bash
# Module: isg — ~/.config/isg, this machine's own state, never in a repo:
# theme (light|dark, read by every tool, flipped by sh/toggle_theme.sh),
# machine_id (~/.rcstate's per-machine slot) and postfix (the hostname's last
# word). Created once, then left alone; edit a file to change it.

RC_ISG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/isg"

# One DNS label: what hostnames, Bonjour and Tailscale all accept.
_isg_label() {
    printf '%s' "$1" | grep -qE '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'
}

# A random name from postfix/machine/*.txt; blank and # lines are skipped.
_isg_pick_postfix() {
    local pool n i
    pool="$(cat "$DOTFILES_DIR"/postfix/machine/*.txt 2>/dev/null |
        grep -vE '^[[:space:]]*(#|$)')"
    n="$(printf '%s\n' "$pool" | grep -c .)"
    [ "$n" -gt 0 ] || return 1
    i="$(od -An -tu4 -N4 /dev/urandom | tr -d ' ')"
    printf '%s\n' "$pool" | sed -n "$((i % n + 1))p"
}

# darwin, or the distribution's os-release ID (ubuntu, fedora, arch), with
# the . and _ it may hold made hostname-safe; linux when there is none.
_isg_os_word() {
    local f id=""
    if [ "$RC_OS" = darwin ]; then echo darwin; return; fi
    for f in ${RC_OS_RELEASE:-/etc/os-release /usr/lib/os-release}; do
        [ -r "$f" ] || continue
        id="$(sed -n 's/^ID=//p' "$f" | tr -d "\"'" | tr '._' '--')"
        break
    done
    echo "${id:-linux}"
}

_isg_hostname() {
    echo "$(id -un)-$(_isg_os_word)-$(cat "$RC_ISG_DIR/postfix")"
}

install_isg_state() {
    local postfix
    mkdir -p "$RC_ISG_DIR"
    if [ ! -f "$RC_ISG_DIR/theme" ]; then
        echo light > "$RC_ISG_DIR/theme"
        echo "[OK] Seeded $RC_ISG_DIR/theme = light"
    fi
    # Same shape as ~/.rcstate/sync.sh makes, so either may create it first.
    if [ ! -f "$RC_ISG_DIR/machine_id" ]; then
        od -An -tx1 -N4 /dev/urandom | tr -d ' \n' > "$RC_ISG_DIR/machine_id"
        echo "[OK] Created $RC_ISG_DIR/machine_id"
    fi
    if [ ! -f "$RC_ISG_DIR/postfix" ]; then
        if ! postfix="$(_isg_pick_postfix)"; then
            echo "[FAIL] No names in $DOTFILES_DIR/postfix/machine/*.txt"
            return 1
        fi
        echo "$postfix" > "$RC_ISG_DIR/postfix"
        echo "[OK] Picked $RC_ISG_DIR/postfix = $postfix"
    fi
}

ensure_isg_state() {
    local rc=0 mode postfix
    mode="$(cat "$RC_ISG_DIR/theme" 2>/dev/null)"
    case "$mode" in
        light|dark) echo "[OK] Theme mode: $mode" ;;
        *) echo "[FAIL] $RC_ISG_DIR/theme is not light or dark"; rc=1 ;;
    esac
    if [ -s "$RC_ISG_DIR/machine_id" ]; then
        echo "[OK] Machine id: $(cat "$RC_ISG_DIR/machine_id")"
    else
        echo "[FAIL] $RC_ISG_DIR/machine_id is missing"
        rc=1
    fi
    postfix="$(cat "$RC_ISG_DIR/postfix" 2>/dev/null)"
    if _isg_label "$postfix"; then
        echo "[OK] Postfix: $postfix"
    else
        echo "[FAIL] $RC_ISG_DIR/postfix is missing or not a hostname word"
        rc=1
    fi
    return "$rc"
}

step install_isg_state ensure_isg_state

# The hostname: isg-<os>-<postfix>. Each name is set only when it differs, so
# a rerun never asks for sudo; a failure (declined sudo) does not stop the run.
_isg_darwin_names="ComputerName LocalHostName HostName"

set_hostname() {
    local want key
    want="$(_isg_hostname)"
    _isg_label "$want" ||
        { echo "[FAIL] Not a valid hostname: $want"; return 1; }
    if [ "$RC_OS" = darwin ]; then
        for key in $_isg_darwin_names; do
            [ "$(scutil --get "$key" 2>/dev/null)" != "$want" ] || continue
            sudo scutil --set "$key" "$want" ||
                { echo "[FAIL] Could not set $key to $want"; return 1; }
            echo "[OK] $key = $want"
        done
    elif [ "$(hostname)" != "$want" ]; then
        if ! command -v hostnamectl >/dev/null; then
            echo "[WARN] No hostnamectl; set the hostname to $want by hand"
            return 1
        fi
        sudo hostnamectl set-hostname "$want" ||
            { echo "[FAIL] Could not set the hostname to $want"; return 1; }
        echo "[OK] Hostname = $want"
    fi
}

ensure_hostname() {
    local want key cur rc=0
    [ -f "$RC_ISG_DIR/postfix" ] ||
        { echo "[FAIL] Hostname: no postfix to build it from"; return 1; }
    want="$(_isg_hostname)"
    if [ "$RC_OS" = darwin ]; then
        for key in $_isg_darwin_names; do
            cur="$(scutil --get "$key" 2>/dev/null)"
            [ "$cur" = "$want" ] && continue
            echo "[FAIL] $key is '$cur', expected $want"
            rc=1
        done
    else
        cur="$(hostname)"
        [ "$cur" = "$want" ] ||
            { echo "[FAIL] Hostname is '$cur', expected $want"; rc=1; }
    fi
    [ "$rc" -ne 0 ] || echo "[OK] Hostname: $want"
    return "$rc"
}

hook set_hostname ensure_hostname
