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
-- ticker posts the scroll, scaling by the LIVE Shift state. A colored border is
-- drawn around the screen under the pointer as the mode indicator (like
-- Homerow), click/scroll-through so it never eats events.

local M = {}

-- Tunables -----------------------------------------------------------------
local STEP = 7           -- px/frame for j/k/h/l — a very mild, readable pace
local FASTMUL = 4        -- hold SHIFT for this much faster
local PAGE = 26          -- px/frame for d/u (brisk page-ish)
local INTERVAL = 1 / 60  -- ~60 fps => STEP*60 px/s (default ~420 px/s)
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

local function scroll(dx, dy)
   -- offsets are {horizontal, vertical}; negative vertical scrolls down.
   hs.eventtap.event.newScrollEvent({ dx, dy }, {}, "pixel"):post()
end

-- One frame: sum every held direction, scaled by live Shift, and post it.
local function tick()
   local mult = hs.eventtap.checkKeyboardModifiers().shift and FASTMUL or 1
   local dx, dy = 0, 0
   for name in pairs(held) do
      local d = DIRS[name]
      local base = (d[3] and PAGE or STEP) * mult
      dx = dx + d[1] * base
      dy = dy + d[2] * base
   end
   if dx ~= 0 or dy ~= 0 then scroll(dx, dy) end
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
