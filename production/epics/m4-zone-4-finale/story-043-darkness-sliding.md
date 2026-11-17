# Story 043: Darkness (a light radius) and sliding floors

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum zone table, Zone 4: "Darkness (light radius), sliding floors". Addendum
budget: at most 3 dynamic lights per screen. The Leviathan's phase 2 plunges its arena into
darkness with only its 12 eyes visible (bible), and the Guardian's phase 2 tilts its arena 15
degrees with rocks sliding (addendum boss table).

## Acceptance Criteria

- [ ] A room `dark` setting: the scene drops to near black outside a light radius around the player (the soul's glow); the radius is data and shrinks or grows with the Soul Gauge.
- [ ] Light sources in dark rooms (braziers or glowing fungus) light their own radius; at most 3 dynamic lights on screen.
- [ ] Enemies and telegraph cues stay readable in the dark (cues are never hidden by darkness).
- [ ] Sliding floors: a surface flag that makes the player slide downhill at a data speed and limits running uphill; a tilt can be set over time (for the Guardian's elevator).
- [ ] Unit tests: the light radius from the gauge, slide velocity on a slope, a tilt applied over time. Each seen failing first.
- [ ] Screenshots of a dark room and a sliding slope.

## Files

- `src/world/darkness.gd`, `src/world/room_builder.gd`, `src/player/player.gd`, `data/balance/combat.json`
- `tests/unit/world/darkness_slide_test.gd`
