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
#   splash_render mode status   mode: dark|light; status: \n-separated
#                               lines, shown right of the mascot

splash_render() {
    local mode="$1" status="$2"
    local accent reset=$'\e[0m'
    local m line
    local -a mascot info
    local -i width rows i

    if [ "$mode" = "dark" ]; then
        accent=$'\e[90m'   # grey, like the banner's dark-mode logs
        width=23
        mascot=(
            '               ░'
            '              ░▓'
            '             ░▓▓'
            '            ░▓▓▓'
            '           ░▓▓▓▓'
            '          ░▓▓▓'
            '         ░▓▓'
            '        ░▓'
            '       ░'
            ''
            '        M U R K'
            '    k = ½(1 + cos ψ)'
        )
    else
        accent=$'\e[33m'   # yellow, the banner accent
        width=23
        mascot=(
            '      ▗▄▄▓▓▓▄▄▖'
            '      ▐▓▓▓███▓▓▓▌'
            '     ▐▓▓█████▓▓▌'
            '      ▐▓▓▓███▓▓▓▌'
            '      ▝▀▀▓▓▓▀▀▘'
            ''
            '       L U M A'
            '4p → ⁴He + 2e⁺ + 2ν + γ'
        )
    fi

    # status lines become the info column, date stamped last
    info=()
    while IFS= read -r line; do
        [ -n "$line" ] && info+=("$line")
    done <<< "$(echo -e "$status")"
    info+=("$(date '+%a %d %b %Y · %H:%M')")

    rows=${#mascot[@]}
    [ ${#info[@]} -gt "$rows" ] && rows=${#info[@]}

    echo
    for (( i = 0; i < rows; i++ )); do
        m="${mascot[$i]}"
        printf '  %s%s%*s%s   %s\n' \
            "$accent" "$m" $(( width - ${#m} )) '' "$reset" "${info[$i]}"
    done
    echo
}
