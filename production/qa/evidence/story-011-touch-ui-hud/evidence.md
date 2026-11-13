# Evidence — Story 011: Touch UI, HUD and gamepad auto-hide

Run result: VERIFIED (real input events injected through `Input.parse_input_event` via the bridge).

| Shot | Shows |
| --- | --- |
| `01-touch-joystick.png` | A thumb down on the left 40 % and dragged right: the floating joystick appears where it landed, knob deflected; the player runs at 4.5 m/s (75 % of Caelan's 6 m/s). HUD corners: HP, flasks, Soul Gauge 3 segments; swap wheel top-right; button arc bottom-right with shape icons and `tr()` labels. |
| `02-gamepad-touch-hidden.png` | One gamepad button press: the touch arc and joystick hide, the HUD stays. One touch afterwards brings them back (`touch_visible` true). |

Button taps through the touch layer (empty arena):

```
tap attack -> state primary_0  y 0.00
tap jump   -> state jump       y 1.35
tap dodge  -> state dodge      y 0.00
```

Acceptance criteria:

- [x] Floating joystick on the left 40 %, button arc (Attack, Jump, Dodge, Ability 1, Ability 2, Ultimate) with cooldown sweeps, hold detection for Ability 1, swap wheel tappable top-right.
- [x] HUD: HP, flask pips, Soul Gauge 3 segments; wheel shows stamina ring, swap cooldown arc, Sync-Guard-ready glow; HP and posture bars over elites, HP over hurt commons, Riposte prompt over a staggered enemy in reach.
- [x] Touch UI hides on gamepad input and returns on touch.
- [x] Drawn in code, no emoji or glyph icons; labels through `tr()` (`assets/locale/strings.csv`).
- [x] Safe-area aware on mobile (`DisplayServer.get_display_safe_area`).
- [x] Same layout on Android at 2400x1080 (`../story-013-sandbox/08-android-emulator.png`).

Open (later stories): size and opacity sliders and the left-handed layout exist as variables (`ui_scale`, `opacity`) but have no settings screen yet; colour-blind palettes are a data swap in `combat.json` `telegraph` but no menu yet.
