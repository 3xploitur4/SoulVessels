# Story 051: Art: Darius, the Guardian, the Leviathan, Ilyr, the rift's look

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done (awaiting the user's look sign-off) · **Layer**: Presentation · **Type**: Visual/Feel · **Estimate**: L

## Context

**Design**: the concept sheets in `docs/design/concept-art/` (vessels: Darius and Ilyr; enemies:
the Guardian Below and the Abyssal Leviathan; zones: Zone 4). Rigs exist for all four (story
029). They need clips for their new actions, the Zone 4 themes after the zone painting, and the
erased-echo look. The art-direction rule stands: no primitive-looking visuals.

## Acceptance Criteria

- [x] Darius clips: the 3-hit hammer combo, Crushing Blow, Groundbreaker, the shoulder charge, Meteor Drop, Worldbreaker.
- [x] Guardian clips: fist slams, the laser, the chain smash, the core open; Leviathan clips: tail-whip, lunge bite, submerge and surface, roar; eye targets that glow.
- [x] Ilyr clips for his kit; the erased-echo shader or tint (pale, glitching) on the four Vessel rigs.
- [x] Zone 4 themes after the zone painting (the Sealed Rift and the Starless Shore), darkness that still reads, the elevator, the shore.
- [x] VFX: masonry crumbling, the light radius, Overdrive, rift beams, Ilyr's tears.
- [ ] Retained screenshots of each (done), with lead sign-off by the user (pending).

## Files

- `data/art/rigs/`, `assets/art/rigs/`, `data/world/themes.json`, `src/arenas/arena_materials.gd`, `src/vfx/`

---

## Completion

Evidence: `production/qa/evidence/story-051-art/` (`art_m4_check.py`, 6 checks; in-game shots and rig pose sheets).
- `tools/art/author_m4_clips.py` writes the clips: Darius 8 (three hammer swings, Crushing Blow, Groundbreaker, shoulder charge, Meteor Drop, Worldbreaker), Ilyr 3 (Null Space blink, Dislocation, Absolute Rupture), the Guardian 14 and the Leviathan 18 (a telegraph and a strike pose per attack).
- A Vessel's clip named after its action is played first (`VesselSpriteVisual.clip_for_rig`); an enemy plays `telegraph_<attack>` / `attack_<attack>` when its rig has one (`EnemyVisual.move_id`).
- The boss ground wave (`VfxShapes.shockwave`) is now a soft additive crest in the attack's colour, not a solid white wedge.
- Already in place from earlier stories: the echo look (047), the Zone 4 themes and backdrop (049), masonry crumble (042), the light radius (043), Overdrive (046), the rift tear (049) and Ilyr's tears (047).
- Not done: Fracture and Distortion are instant (no action), so Ilyr has no clip for them; the second weapons keep the first weapon's art. Lead sign-off pending.
