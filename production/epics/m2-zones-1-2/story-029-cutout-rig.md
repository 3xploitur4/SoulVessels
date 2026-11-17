# Story 029: Cut-out rigs — every Vessel and enemy moves limb by limb

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-17) · **Layer**: Presentation · **Type**: Visual/Feel · **Estimate**: M

## Context

**Request** (user, 2026-11-17): "whenever you open godot i see a static character getting
translated and i don't like that"; chose route B (cut-out parts rigged in Godot) and asked to
work only with what is on the PC (no installs, no driver update). **Design**:
`docs/design/art-direction.md`; decision D-034. Pilot on two figures so the user can judge before
the rest of the cast is cut.

## Acceptance Criteria

- [x] A tool cuts a painted sprite into parts from outline polygons, paints in what each part hid behind the parts in front of it, and keeps overlap at the joints (`tools/art/cut_rig.gd`); reassembled, the parts match the painting (under 0.3 % of pixels differ).
- [x] Caelan: 11 picture parts and a pelvis bone (head, torso, cape, upper arm, forearm, sword, shield arm, two thighs, two shins).
- [x] Echo Crawler: abdomen, head and six legs.
- [x] Clips in data (`data/art/rigs/<id>.json`): Caelan idle, run, jump, fall, wall slide, four attacks, lunge, cast, block, hurt, dodge, dash, rooted, dead; Crawler idle, run, telegraph, attack, hurt, staggered, knockdown. The body blends between clips.
- [x] Drop-in: `SpriteBody.create` returns the rig when one exists; flash, dissolve, stealth, afterimages, dust and the tell glow still work. Characters without a rig keep the whole painting.
- [x] Facing left keeps the part order (sword in front of the body).
- [x] Seen in the running game; screenshots retained.
- [x] After two tweak passes on the pilot (user asked), the other 11 figures are cut and rigged: shared clips with per-rig aliases, own clips where a body differs (staff caster, mirrored Warden, sphere, serpent).

## Files

- `tools/art/cut_rig.gd`, `tools/art/rig_preview.gd`, `tools/playtest/rig_check.py`
- `data/art/rigs/caelan.json`, `data/art/rigs/echo_crawler.json`, `assets/art/rigs/`
- `src/vfx/rig_body.gd`, `src/vfx/sprite_body.gd`, `src/vessels/vessel_sprite_visual.gd`, `src/enemies/enemy_sprite_visual.gd`
- `tests/unit/vfx/rig_body_test.gd` (8)

---

## Completion

Evidence: `production/qa/evidence/story-029-cutout-rig/`. Known limits: the painting is a 3/4 front view, so a limb
turned far from its painted angle shows its flat cut edge; hidden areas are painted in as smooth
shadow, not detail.
