# Story 039: Art — Seris casting, Courtier, Prelate and Sovereign, palace look

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17), awaiting lead sign-off · **Layer**: Presentation · **Type**: Visual/Feel · **Estimate**: M

## Context

**Design**: the concept sheets in `docs/design/concept-art/` (vessels, enemies, zones) and the
art-direction rule that primitive shapes are not acceptable. The cut-out rig system (story 029,
decision D-034) already has rigs for Seris, the Choir Prelate and the Weeping Sovereign; it needs
clips for their new actions. The Drowned Courtier has no rig yet; if the enemy sheet has no
painting of it, its parts come from the closest existing figure and the gap is recorded.

## Acceptance Criteria

- [x] Seris clips: Arcane Bolt cast (3 beats), Frost Binding, Aether Shield, swim.
- [x] Choir Prelate clips: orb cast, teleport out and in, aura idle. Sovereign clips for every attack and each phase change.
- [ ] A Drowned Courtier rig with surface, slash and dive clips.
- [x] Zone 3 palace theme after the zone painting: marble, gold, water light on walls.
- [x] VFX: Arcane Bolt trail, Frost field, the shield, rune glow, the Prelate's aura.
- [ ] Retained screenshots of each, with lead sign-off by the user.

## Files

- `data/art/rigs/`, `assets/art/rigs/`, `data/world/themes.json`, `src/arenas/arena_materials.gd`, `src/vfx/`

---

## Completion

Evidence: `production/qa/evidence/story-039-art-m3/`.
- Seris: bolt, frost and swim clips, plus a "swim" player state.
- The Prelate: telegraph, attack and hurt clips.
- The Sovereign: a phase 3 tint from data.
- Open:
  - The Drowned Courtier has no concept painting, so it keeps the tinted Husk figure; its rig criterion is left unchecked.
  - The Sovereign uses one telegraph and attack pose for every attack.
  - The user's sign-off on the look.
