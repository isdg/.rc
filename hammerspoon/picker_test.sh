#!/usr/bin/env bash
# Exercises picker.rows (picker.lua) in nvim's Lua; Hammerspoon is not needed,
# since the module only touches `hs` inside its functions.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/test.lua" <<'EOF'
package.path = arg[1] .. "/?.lua;" .. package.path
local picker = require("picker")
local fails = 0

local function check(what, want, got)
    if want == got then
        io.write("ok   ", what, "\n")
    else
        io.write("FAIL ", what, ": want ", want, ", got ", got, "\n")
        fails = fails + 1
    end
end

local function ids(rows)
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = tostring(r.id) end
    return table.concat(out, " ")
end

local function win(id, title, app)
    return { id = id, title = title or "t" .. id, app = app or "App" }
end

local a, b, c = win(1), win(2), win(3)

check("front to back without a focused window", "1 2 3",
    ids(picker.rows({ a, b, c }, nil)))
check("focused window goes last", "2 3 1",
    ids(picker.rows({ a, b, c }, 1)))
check("repeats keep their first place", "2 3 1",
    ids(picker.rows({ a, b, c, b, a }, 1)))
check("focused window absent from the list", "1 2",
    ids(picker.rows({ a, b }, 9)))
check("no windows", "", ids(picker.rows({}, nil)))

local row = picker.rows({ win(4, "", "Finder") }, nil)[1]
check("empty title falls back to the app", "Finder", row.text)
check("app is the subtext", "Finder", row.subText)

os.exit(fails == 0 and 0 or 1)
EOF

if nvim --clean --headless -l "$tmp/test.lua" "$dir"; then
    echo "all passed"
else
    exit 1
fi
