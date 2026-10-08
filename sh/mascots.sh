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
#     \n-separated lines, laid out in two columns below it. The
#     mascot is followed by the date, with the law beside it.

SPLASH_WIDTH=23
SPLASH_CELL=19
SPLASH_DARK=$'\e[90m'    # grey, like the banner's dark-mode logs
SPLASH_LIGHT=$'\e[33m'   # yellow, the banner accent

# s left-aligned (pad=-1: centred) in a field of width columns; ${#s} counts
# characters, and every glyph used here is one cell wide.
splash_field() {
    local s="$1" pad="$2" width="$3"
    (( pad < 0 )) && pad=$(( (width - ${#s}) / 2 ))
    printf '%*s%s%*s' "$pad" '' "$s" $(( width - pad - ${#s} )) ''
}

# The first word of s (a status line's app name) in ls's directory blue.
splash_app() {
    local s="$1" name="${1%% *}"
    printf '\e[34m%s\e[0m%s' "$name" "${s#"$name"}"
}

splash_render() {
    local mode="$1" title="$2" status="$3"
    local accent law reset=$'\e[0m'
    local m line
    local -a art st right
    local -i i half rows right_top art_top pad art_w=0

    if [ "$mode" = "dark" ]; then
        accent=$SPLASH_DARK
        law='k = ½(1 + cos ψ)'
        art=(
            '      ░'
            '     ░▓▓'
            '    ░▓▓▓▓'
            '   ░▓▓▓▓▓'
            '  ░▓▓▓▓'
            ' ░▓▓'
            '░▓'
        )
    else
        accent=$SPLASH_LIGHT
        law='4p → ⁴He + 2e⁺ + 2ν + γ'
        art=(
            ' ▗▄▄▓▓▓▄▄▖'
            ' ▐▓▓▓███▓▓▓▌'
            '▐▓▓█████▓▓▌'
            ' ▐▓▓▓███▓▓▓▌'
            ' ▝▀▀▓▓▓▀▀▘'
        )
    fi

    st=()
    while IFS= read -r line; do
        [ -n "$line" ] && st+=("$line")
    done <<< "$(echo -e "$status")"

    # right block: title, gap, status filled down the first column first
    right=("$title" '')
    half=$(( (${#st[@]} + 1) / 2 ))
    for (( i = 0; i < half; i++ )); do
        line="$(splash_app "$(splash_field "${st[$i]}" 0 $SPLASH_CELL)")"
        [ -n "${st[$((i + half))]}" ] &&
            line+="$(splash_app "${st[$((i + half))]}")"
        right+=("$line")
    done

    # an empty row above the date; the right block ends on the row before it,
    # the art centred beside it
    rows=${#right[@]}
    (( ${#art[@]} > rows )) && rows=${#art[@]}
    rows+=1
    right_top=$(( rows - ${#right[@]} - 1 ))
    art_top=$(( (rows - 1 - ${#art[@]}) / 2 ))
    for m in "${art[@]}"; do (( ${#m} > art_w )) && art_w=${#m}; done
    pad=$(( (SPLASH_WIDTH - art_w) / 2 ))

    echo
    for (( i = 0; i < rows; i++ )); do
        m='' line=''
        (( i >= art_top && i - art_top < ${#art[@]} )) &&
            m="${art[$((i - art_top))]}"
        (( i >= right_top && i - right_top < ${#right[@]} )) &&
            line="${right[$((i - right_top))]}"
        printf '  %s%s%s   %s\n' "$accent" \
            "$(splash_field "$m" $pad $SPLASH_WIDTH)" "$reset" "$line"
    done
    printf '  %s%s   %s%s\n' "$accent" \
        "$(splash_field "$(date '+%a %d %b %Y · %H:%M')" -1 $SPLASH_WIDTH)" \
        "$law" "$reset"
    echo
}
