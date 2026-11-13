# Story 001: Godot project scaffold at the repo root

> **Epic**: M0 — Setup
> **Status**: Done (2026-11-13)
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: S
> **Last Updated**: 2026-11-13

## Context

**Design**: `docs/design/design-addendum-v1.md` §"Purpose and tech stack", §"Performance budget";
`docs/design/game-design-bible.md` §1. **Decisions**: D-001, D-002, D-009 in `docs/design/decision-log.md`.
**Engine**: Godot 4.7.2-stable, GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] `project.godot` at the repo root: name "Soul Vessels", renderer `mobile`, `physics/3d/physics_engine = "Jolt Physics"`, 60 physics ticks, physics interpolation on, viewport 1920x1080, stretch `canvas_items`/`expand`, landscape orientation, GDScript `untyped_declaration` warnings on, ETC2/ASTC import on.
- [ ] A boot scene (`src/main.tscn`) loads with no errors: `godot --headless --path . --quit-after 5` exits 0 with no `SCRIPT ERROR`.
- [ ] `.gdignore` in every non-game folder (`.claude`, `.github`, `docs`, `design`, `engine`, `production`, `studio-tests`, `tools`, `vendor`, `_to_delete`) so the importer never scans them.
- [ ] `tests/smoke.sh` runs the headless boot and fails on any script error.
- [ ] `.gitignore` keeps `export_presets.cfg` and `.godot/global_script_class_cache.cfg`; git repo initialised with the first commit.
- [ ] `tools/python.sh` resolves the real Python 3.12 interpreter (D-009).

## Implementation Notes

Project settings are written by hand into `project.godot` (text format). Translation table
`assets/locale/strings.csv` registered from day one (`internationalization/locale/translations`).
Autoloads registered here: `Balance`, `MusicDirector`, `GameEvents`, `DebugBridge` (scripts may be
stubs that later stories fill).

## Out of Scope

- Story 002: input actions. Story 003: export preset.

## Files

- `project.godot`, `src/main.tscn`, `src/main.gd`, `src/core/game_events.gd`
- `assets/locale/strings.csv`, `*/.gdignore`, `tests/smoke.sh`, `tools/python.sh`, `.gitignore`

## Test Evidence

**Story Type**: Config/Data. **Required**: smoke check pass → `production/qa/smoke-2026-11-13.md`.

## Dependencies

- Depends on: None
- Unlocks: `story-002-input-map.md`, `story-003-android-export.md`

---

## Completion

Boot scene became the sandbox in story 013. Smoke: `bash tests/smoke.sh` passes (production/qa/smoke-2026-11-13.md).
