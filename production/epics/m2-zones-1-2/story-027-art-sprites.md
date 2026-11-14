# Story 027: Art pass — painted Vessels and enemies from the concept sheets

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Presentation · **Type**: Visual/Feel · **Estimate**: L

## Context

**Request** (2026-11-14): the user disliked the primitive placeholder look and supplied three
concept sheets (Vessels, enemies and bosses, four zone paintings): "use these designs and make
them better". **Design**: `docs/design/art-direction.md`; addendum "Rendering approach" (characters
start as placeholders, then get swapped for final art). Decision D-032.

## Acceptance Criteria

- [x] The sheets live in `docs/design/concept-art/`; a rerunnable tool cuts each figure to a sprite (13 figures) and writes a contact sheet for checking.
- [x] Vessels and enemies draw from those sprites behind the existing visual interfaces (no gameplay code changed); a Vessel or enemy without a sprite still falls back to the primitive body.
- [x] A single pose reads in motion: stepping legs, lean, squash, roll, breath, cape sway; weapon arc on strikes, guard glow on block, afterimages on dashes, dust on landing, soul-burn on death; hit and telegraph flashes; the enemy's own tell glows on the painting.
- [x] Facing is right for every figure (the Warden's shield leads); overlapping sprites never flicker.
- [x] Swap wheel shows the Vessels' painted faces; the camera frames a Vessel at about a quarter of the screen height.
- [x] All tests and the M1 combat playtest still pass; screenshots retained.

## Files

- `tools/art/slice_concepts.gd`, `tools/art/slices.json`, `assets/art/sprites/`, `data/art/sprites.json`
- `src/vfx/spatial_char_sprite_body.gdshader`, `sprite_body.gd`, `sprite_art.gd`, `tex_bank.gd`, `slash_arc.gd`
- `src/vessels/vessel_sprite_visual.gd`, `src/enemies/enemy_sprite_visual.gd`

---

## Completion

Evidence: `production/qa/evidence/story-027-art-pass/` (shots 01-05, 17). 142 tests, smoke and the
M1 playtest (44/44) pass. Stand-ins listed in `docs/design/art-direction.md`: the Fungal Stalker
has no painting yet; figures have one pose each.
