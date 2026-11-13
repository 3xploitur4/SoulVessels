# Story 011: Touch UI, HUD and gamepad auto-hide

> **Epic**: M1 — Combat Sandbox · **Status**: Done (2026-11-13) · **Layer**: Presentation · **Type**: UI · **Estimate**: M

## Context

**Design**: addendum "UI, controls and localisation" (HUD in the corners, centre 60 % clear,
top-left HP + flasks + Soul Gauge 3 segments, top-right swap wheel with stamina ring / cooldown /
Sync-Guard glow, bottom-right button arc with cooldown sweeps, bottom-left floating joystick on the
left 40 %, controller hides touch UI); bible section 1 Touch UI. Size/opacity sliders come later.

## Acceptance Criteria

- [ ] `TouchControls` (CanvasLayer): floating joystick appears where the thumb lands on the left 40 % and feeds a `Vector2` axis to `InputRouter`; button arc (Attack, Jump, Dodge, Ability 1, Ability 2, Ultimate) with radial cooldown sweeps; hold detection for Ability 1 (Royal Guard / Vanishing Act); 3-portrait swap wheel top-right.
- [ ] HUD: HP bar, flask pips (3), Soul Gauge with 3 segments; active Vessel portrait ring = stamina, swap cooldown arc, Sync-Guard-ready glow; enemy posture bars above elites.
- [ ] Touch UI hides on the first gamepad input and returns on the first touch (`InputRouter.device_changed`).
- [ ] Everything drawn in-engine (Control `_draw` or generated textures); no emoji, no glyph icons; all labels via `tr()`.
- [ ] Safe-area aware (`DisplayServer.get_display_safe_area()`), 1920x1080 reference layout scaled by `canvas_items`.
- [ ] Retained screenshots: `production/qa/evidence/story-011-touch-ui-hud/01-touch.png` (touch layout) and `02-gamepad.png` (touch hidden).

## Files

- `src/ui/hud.tscn/.gd`, `src/ui/touch_controls.tscn/.gd`, `src/ui/floating_joystick.gd`, `src/ui/action_button.gd`, `src/ui/swap_wheel.gd`

## Dependencies

- Depends on: 009, `../m0-setup/story-002-input-map.md` · Unlocks: 013

---

## Completion

Evidence: production/qa/evidence/story-011-touch-ui-hud/evidence.md. Size/opacity are variables, no settings screen yet.
