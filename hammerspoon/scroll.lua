-- ============================================================
--  scroll.lua — Homerow-style keyboard scrolling, any macOS GUI app
-- ============================================================
-- Enter "scroll mode" with a hotkey, then use bare vim keys to scroll; esc/q/i
-- exits. Scrolling uses synthetic scroll-wheel events (hs.eventtap), which the
-- OS routes to whatever is under the mouse pointer — the same universal
-- mechanism Homerow uses, so it works in EVERY GUI app that takes a scroll
-- wheel (native, browser, Electron, Finder, …). Hold a key to scroll smoothly;
-- release to stop. Hold SHIFT for fast.
--
-- Mechanism: while active, one eventtap tracks which direction keys are down
-- (by physical keycode, so Shift doesn't change matching) and a single ~60fps
-- ticker posts the scroll. Two pacings, because the two kinds of target measure
-- scrolling in different units — lines in a terminal, pixels everywhere else;
-- see the tunables. A colored border around the screen under the pointer is the
-- mode indicator (like Homerow), click/scroll-through so it never eats events.

local M = {}

-- Tunables -----------------------------------------------------------------
-- Pixel apps: a per-frame offset, and SHIFT posts the frame's scroll several
-- times over. Magnitude and event count both register here, so either works.
local STEP = 12          -- px/frame for j/k/h/l (base pace)
local PAGE = 30          -- px/frame for d/u (brisk dash)
local FASTMUL = 6        -- hold SHIFT: post this many events/frame

-- Terminals: a rate in LINES PER SECOND. Two things force the separate set.
-- One, a terminal discards the pixel magnitude — one event is one notch however
-- big it claims to be — but it does honour the count on a line-unit event, so
-- N lines go in ONE event rather than N events. Two, per-frame counts are
-- useless as a knob at 60fps: the smallest possible step, 1 line/frame, is 60
-- lines a second, which overshoots a screen before you can lift the key. Rates
-- are the number worth reasoning about; tick() carries the fractional remainder
-- between frames so a slow rate still comes out smooth instead of stepping.
local LINE_RATE = 22      -- lines/second in a terminal, holding a key
local LINE_RATE_PAGE = 55 -- ... for d/u
local LINEMUL = 3         -- ... multiplier while SHIFT is held
local INTERVAL = 1 / 60  -- ~60 fps
local BORDER = 5         -- indicator border thickness (px)
local COLOR = { red = 0.55, green = 0.45, blue = 1.0, alpha = 0.95 } -- accent
-- --------------------------------------------------------------------------

-- Direction key -> { dx, dy, isPage }. Negative dy scrolls down.
local DIRS = {
    j = { 0, -1, false }, -- down
    k = { 0, 1, false },  -- up
    h = { 1, 0, false },  -- left
    l = { -1, 0, false }, -- right
    d = { 0, -1, true },  -- half-page down
    u = { 0, 1, true },   -- half-page up
}

local mode          -- hs.hotkey.modal used only to ENTER + exit the mode
local tap           -- eventtap tracking held direction keys while active
local ticker        -- the ~60fps scroll pump
local held = {}     -- direction-key name -> true while down
local border        -- hs.canvas indicator
local savedPos      -- pointer position to put back on exit
local lineMode      -- true while the target scrolls by lines (a terminal)
local lineDebt = {} -- direction -> fractional line carried to the next frame

-- Aiming the pointer ---------------------------------------------------------
-- Scroll events land on whatever is under the POINTER, which made this mode a
-- coin flip: it scrolled whichever window the mouse happened to be parked over,
-- and nothing at all when the mouse sat on another screen. Worse inside tmux,
-- where the pointer picks the *pane* — so in a split it scrolled a neighbour
-- rather than the pane being typed in. Entering the mode now warps the pointer
-- onto the focused window first, and in Ghostty onto the focused tmux pane, so
-- the keys always drive what is actually being looked at. Restored on exit.

local GHOSTTY = "com.mitchellh.ghostty"
local tmuxBin  -- false once we know there is none; nil until first look

local function tmux()
    if tmuxBin == nil then
        tmuxBin = false
        for _, p in ipairs({ "/opt/homebrew/bin/tmux", "/usr/local/bin/tmux" }) do
            if hs.fs.attributes(p) then tmuxBin = p break end
        end
    end
    return tmuxBin
end

-- Which server to ask. NOT the default socket: Hammerspoon is launched by
-- LaunchServices, not from a pane, so it has no $TMUX to inherit and a bare
-- `tmux` resolves to `-L default` — while the terminal actually being looked at
-- here runs `tmux -L misc`. Asking the wrong server is silent and plausible: it
-- answers with a real pane rect, just one belonging to another window.
-- So pick by attachment. A socket with an attached client is a terminal someone
-- is sitting in front of, and the most recently active of those is the front
-- window. Sockets with no client (stale servers, the -L probe leftovers of a
-- debugging session) score nothing and drop out.
local function tmuxSocket(bin)
    local out = hs.execute(([[
        for s in "${TMUX_TMPDIR:-/tmp}"/tmux-$(id -u)/*; do
            [ -S "$s" ] || continue
            a=$(%s -S "$s" list-clients -F '#{client_activity}' 2>/dev/null | sort -rn | head -1)
            [ -n "$a" ] && echo "$a $s"
        done | sort -rn | head -1 | cut -d' ' -f2-
    ]]):format(bin))
    local sock = out and out:match("^%s*(.-)%s*$")
    return (sock ~= "" and sock) or nil
end

-- Repo root, from ~/.hammerspoon's own symlink target — the trick .tmux.conf
-- uses to find the same root. Resolved rather than joined with "..": open(2)
-- would expand the link first and land correctly, but a *lexical* join yields
-- ~/ghostty, which exists on this machine as an unrelated Ghostty checkout. A
-- wrong answer that reads like a right one is worth the four extra lines.
local function repoDir()
    local link = hs.fs.symlinkAttributes(hs.configdir, "target") or hs.configdir
    return (link:gsub("/[^/]+/?$", "")) .. "/"
end

-- Ghostty insets its grid by window-padding-{x,y}, so the window frame is NOT
-- the terminal grid. That inset is not a rounding detail here: width.sh writes
-- window-padding-x for the `ww` alias and it runs to hundreds of points — a
-- quarter of the window on each side — so treating the frame as the grid would
-- aim the pointer outside the terminal entirely.
local function ghosttyPadding()
    local dir = repoDir() .. "ghostty/"
    local px, py = 0, 0
    for _, name in ipairs({ "config", "width-active.conf" }) do
        local f = io.open(dir .. name)
        if f then
            for line in f:lines() do
                px = tonumber(line:match("^%s*window%-padding%-x%s*=%s*(%d+)")) or px
                py = tonumber(line:match("^%s*window%-padding%-y%s*=%s*(%d+)")) or py
            end
            f:close()
        end
    end
    return px, py
end

-- Active pane rect and the whole grid, in cells. window_* rather than client_*:
-- the client formats resolve to empty for a command run outside a client, which
-- is exactly what we are. status is a row the window does not cover, so add it
-- back to get the client's row count (status-position is tmux's default bottom,
-- so pane_top still counts from the top of the terminal either way).
-- Which client this answers for is tmux's "most recently used", i.e. the window
-- just typed in — the front one, in every case that matters here. Two Ghostty
-- windows on different sessions can disagree; the aim then stays inside the
-- front window, so the scroll still lands on it, just possibly the wrong pane.
local function tmuxPaneCells()
    local bin = tmux()
    if not bin then return nil end
    local sock = tmuxSocket(bin)
    if not sock then return nil end
    local fmt = "#{pane_left} #{pane_top} #{pane_width} #{pane_height} " ..
                "#{window_width} #{window_height} #{status}"
    local out = hs.execute(bin .. " -S '" .. sock .. "' display -p '" .. fmt .. "' 2>/dev/null")
    if not out then return nil end
    local l, t, w, h, gw, gh, status =
        out:match("(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%a+)")
    if not l then return nil end
    local rows = tonumber(gh) + (status == "on" and 1 or 0)
    return tonumber(l), tonumber(t), tonumber(w), tonumber(h), tonumber(gw), rows
end

local function warpToFocus()
    local win = hs.window.frontmostWindow()
    if not win then return end
    local f = win:frame()
    local x, y = f.x + f.w / 2, f.y + f.h / 2 -- any other app: centre of window

    local app = win:application()
    lineMode = app and app:bundleID() == GHOSTTY
    if lineMode then
        local l, t, w, h, cols, rows = tmuxPaneCells()
        if l then
            local px, py = ghosttyPadding()
            -- Cell size from the padded content box. cols = floor(usable/cell),
            -- so usable/cols overshoots by under one cell; harmless when the aim
            -- point is the pane's CENTRE, which leaves half a pane of slack.
            local cw, ch = (f.w - 2 * px) / cols, (f.h - 2 * py) / rows
            x = f.x + px + (l + w / 2) * cw
            y = f.y + py + (t + h / 2) * ch
        end
    end

    savedPos = hs.mouse.absolutePosition()
    hs.mouse.absolutePosition({ x = x, y = y })
end

local function restorePointer()
    if savedPos then hs.mouse.absolutePosition(savedPos) savedPos = nil end
end

local function scroll(dx, dy)
    -- offsets are {horizontal, vertical}; negative vertical scrolls down.
    hs.eventtap.event.newScrollEvent({ dx, dy }, {}, "pixel"):post()
end

-- One frame: for each held direction post its scroll. Two pacings, because the
-- two kinds of target measure scrolling differently — lines in a terminal (see
-- LINE_RATE above), pixels everywhere else. Shift is "fast" in both.
local function tick()
    local fast = hs.eventtap.checkKeyboardModifiers().shift
    for name in pairs(held) do
        local d = DIRS[name]
        if lineMode then
            local rate = (d[3] and LINE_RATE_PAGE or LINE_RATE) * (fast and LINEMUL or 1)
            local owed = (lineDebt[name] or 0) + rate * INTERVAL
            local n = math.floor(owed)
            lineDebt[name] = owed - n -- keep the remainder; it is most of a slow rate
            if n > 0 then
                hs.eventtap.event.newScrollEvent({ d[1] * n, d[2] * n }, {}, "line"):post()
            end
        else
            local base = d[3] and PAGE or STEP
            for _ = 1, (fast and FASTMUL or 1) do
                scroll(d[1] * base, d[2] * base)
            end
        end
    end
end

-- Border indicator on the screen under the pointer; no mouse callbacks, so it's
-- transparent to hit-testing and lets scroll events fall through to the app.
local function showBorder()
    local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local f = screen:fullFrame()
    border = hs.canvas.new(f)
    border[1] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = COLOR,
        strokeWidth = BORDER,
        roundedRectRadii = { xRadius = 10, yRadius = 10 },
        frame = { x = BORDER / 2, y = BORDER / 2, w = f.w - BORDER, h = f.h - BORDER },
    }
    border:level(hs.canvas.windowLevels.overlay)
    border:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
    border:clickActivating(false)
    border:canvasMouseEvents(false, false, false, false)
    border:show()
end

local function hideBorder()
    if border then border:delete(); border = nil end
end

local function start()
    held = {}
    lineDebt = {}
    -- Before anything else: the pointer decides where the scrolling lands, and
    -- showBorder() reads it too, so the indicator follows the same window.
    warpToFocus()
    tap = hs.eventtap.new(
        { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
        function(e)
            local name = hs.keycodes.map[e:getKeyCode()] -- physical key, Shift-agnostic
            if name and DIRS[name] then
                held[name] = (e:getType() == hs.eventtap.event.types.keyDown) or nil
                return true -- swallow direction keys so they don't type
            end
            return false -- pass everything else through (esc/q/i handled by modal)
        end)
    tap:start()
    ticker = hs.timer.doEvery(INTERVAL, tick)
    showBorder()
end

local function stop()
    if tap then tap:stop(); tap = nil end
    if ticker then ticker:stop(); ticker = nil end
    held = {}
    hideBorder()
    restorePointer()
end

-- Set up scroll mode, entered via mods+key. Mirrors translate.bind's shape.
function M.bind(mods, key)
    mode = hs.hotkey.modal.new(mods, key)
    for _, k in ipairs({ "escape", "q", "i" }) do
        mode:bind({}, k, function() mode:exit() end)
    end
    function mode:entered() start() end
    function mode:exited() stop() end
    return M
end

return M
