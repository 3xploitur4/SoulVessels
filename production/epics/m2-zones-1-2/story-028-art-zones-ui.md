# Story 028: Art pass — zones, gates, altars and UI after the zone paintings

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Presentation · **Type**: Visual/Feel · **Estimate**: L

## Context

**Request**: as story 027. **Design**: `docs/design/art-direction.md`; the zone paintings in
`docs/design/concept-art/zones.webp`; addendum gate table (each gate reads at a glance) and
performance budget (at most 3 dynamic lights, draw calls under 150). Decision D-033.

## Acceptance Criteria

- [x] Each zone painting is cut to a mirror-tiled backdrop and stands behind its rooms.
- [x] Rooms use generated tileable textures in world space: cave rock, ashlar ledges and worn slabs (Zone 1); violet rock, bark and glowing moss (Zone 2). Every walkable top carries the brightest surface.
- [x] Zone 1 dressing: stone arches, broken columns, rubble, teal pools, stalactites, dust, light shafts, blue mist. Zone 2: spotted teal and violet mushrooms, vines, glowing sprouts, spores, teal mist.
- [x] Gates each have their own shape and colour (portcullis, gold light bars, black mist, rune door, veined masonry, dark water); altars are stepped stone with a soul flame.
- [x] Menus and HUD restyled (gold-edged plates, serif display face, ornate HP frame, slanted gauge); the title shows the Vessel line-up; a vignette frames the view.
- [x] Budget held: 13-27 draw calls per room in the room viewer, room build under 0.7 s on the dev PC; enemies can no longer walk out through room exits.
- [x] Screenshots retained.

## Files

- `tools/art/make_textures.gd`, `assets/art/textures/`, `assets/art/backdrops/`
- `src/world/room_decor.gd`, `room_builder.gd`, `gate_look.gd`, `altar.gd`, `data/world/themes.json`, `src/arenas/arena_materials.gd`
- `src/vfx/spatial_env_mist.gdshader`, `spatial_env_shaft.gdshader`, `spatial_env_veil.gdshader`, `canvas_post_vignette.gdshader`, `vignette.gd`
- `src/ui/ui_kit.gd`, `title_screen.gd`, `hud.gd`, `altar_menu.gd`, `pause_menu.gd`, `prompts.gd`

---

## Completion

Evidence: `production/qa/evidence/story-027-art-pass/` (shots 03-04, 07-16). Room build time rose
from about 60 ms to 100-670 ms (more decor to merge); it happens behind the room fade. Not checked
on a phone: frame rate with the mist and vignette layers (story 026 device check).
