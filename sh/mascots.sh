#!/bin/bash
# Mascots + splash renderer for toggle_theme.sh — mascot left · status
# right, like banner_render in zsh/isg.zsh-theme. Mascots are
# shade-block bodies (░ rim, ▓ body, █ core) with half-cell edges
# (▗ ▄ ▐ ▌ ▀ ▝ ▘), each signed by its governing law instead of a
# caption —
#   MURK: k = ½(1 + cos ψ)         illuminated fraction, the law of phase
#   LUMA: 4p → ⁴He + 2e⁺ + 2ν + γ  pp-chain, why it shines
#
# Interface
#   splash_render mode title status
#     mode: dark|light; title: first line on the right; status:
#     \n-separated lines below it, then the mascot's law. The mascot's
#     name and the date close the left column.

SPLASH_WIDTH=23

# s centred in SPLASH_WIDTH columns; ${#s} counts characters, and every
# glyph used here is one cell wide.
splash_center() {
    local s="$1"
    local -i left=$(( (SPLASH_WIDTH - ${#s}) / 2 ))
    printf '%*s%s%*s' $left '' "$s" $(( SPLASH_WIDTH - left - ${#s} )) ''
}

splash_render() {
    local mode="$1" title="$2" status="$3"
    local accent name law reset=$'\e[0m'
    local m line
    local -a art info left
    local -i i top pad rows body_w=0

    if [ "$mode" = "dark" ]; then
        accent=$'\e[90m'   # grey, like the banner's dark-mode logs
        name='M U R K'
        law='k = ½(1 + cos ψ)'
        art=(
            '        ░'
            '       ░▓'
            '      ░▓▓'
            '     ░▓▓▓'
            '    ░▓▓▓▓'
            '   ░▓▓▓'
            '  ░▓▓'
            ' ░▓'
            '░'
        )
    else
        accent=$'\e[33m'   # yellow, the banner accent
        name='L U M A'
        law='4p → ⁴He + 2e⁺ + 2ν + γ'
        art=(
            ' ▗▄▄▓▓▓▄▄▖'
            ' ▐▓▓▓███▓▓▓▌'
            '▐▓▓█████▓▓▌'
            ' ▐▓▓▓███▓▓▓▌'
            ' ▝▀▀▓▓▓▀▀▘'
        )
    fi

    # right column: title, gap, status, gap, law
    info=("$title" '')
    while IFS= read -r line; do
        [ -n "$line" ] && info+=("$line")
    done <<< "$(echo -e "$status")"
    info+=('' "$law")

    # left column: the art centred as one block above a gap, name, date
    rows=$(( ${#info[@]} - 3 ))
    for m in "${art[@]}"; do (( ${#m} > body_w )) && body_w=${#m}; done
    top=$(( (rows - ${#art[@]}) / 2 ))
    pad=$(( (SPLASH_WIDTH - body_w) / 2 ))
    left=()
    for (( i = 0; i < rows; i++ )); do
        m=''
        (( i >= top && i - top < ${#art[@]} )) && m="${art[$((i - top))]}"
        left+=("$(printf '%*s%s%*s' $pad '' "$m" \
            $(( SPLASH_WIDTH - pad - ${#m} )) '')")
    done
    left+=("$(splash_center '')" "$(splash_center "$name")")
    left+=("$(splash_center "$(date '+%a %d %b %Y · %H:%M')")")

    echo
    for (( i = 0; i < ${#info[@]}; i++ )); do
        printf '  %s%s%s   %s\n' "$accent" "${left[$i]}" "$reset" "${info[$i]}"
    done
    echo
}
