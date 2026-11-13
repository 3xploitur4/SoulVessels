# Story 005: Test arena — 2.5D set, parallax, lights, camera

> **Epic**: M1 — Combat Sandbox · **Status**: Done (2026-11-13) · **Layer**: Presentation · **Type**: Visual/Feel · **Estimate**: M

## Context

**Design**: addendum "Rendering approach (2.5D)" (3D environments, real lights and fog, side-on
camera, parallax depth layers, procedural placeholders), "Performance budget" (at most 3 dynamic
lights per screen); bible section 5 Zone 1 look (collapsed marble aqueducts, Whispering Cavern).
**Decision**: D-004.

## Acceptance Criteria

- [ ] `src/arenas/sandbox_arena.tscn`: a 40 m wide floor at z = 0 with two ledges (jump height about 2.2 m) and side walls; parallax layers at z = -6 (broken columns), z = -14 (aqueduct arches), z = -30 (cavern wall); all meshes are in-engine primitives with `StandardMaterial3D` in a slate/marble/teal-glow palette; every material comes from `src/arenas/arena_materials.gd` so it can be swapped.
- [ ] `WorldEnvironment`: depth fog, AgX tonemap, low ambient; one `DirectionalLight3D` (cool key) plus up to two `OmniLight3D` (warm torch, cyan rune), shadows only on the key light.
- [ ] `SideCamera` (`Camera3D`, perspective FOV 35 deg, 14 m back) follows a target with look-ahead and a vertical dead zone, reads `get_global_transform_interpolated()`, clamps to arena bounds; a camera shake hook with a 0-100 % amplitude setting.
- [ ] 60 FPS on the Windows dev machine at 1920x1080 with the debug HUD showing draw calls under 150.
- [ ] Retained screenshot `production/qa/evidence/story-005-test-arena/01-arena.png` shows depth layers and the lit floor.

## Files

- `src/arenas/sandbox_arena.tscn`, `src/arenas/arena_materials.gd`, `src/camera/side_camera.gd`

## Test Evidence

Visual/Feel: retained screenshot plus `production/qa/evidence/story-005-test-arena/evidence.md`.

## Dependencies

- Depends on: `../m0-setup/story-001-godot-project-scaffold.md` · Unlocks: 006, 013

---

## Completion

Meshes are merged per material at load (draw calls 119 in the busiest wave). Evidence: production/qa/evidence/story-005-test-arena/evidence.md.
