# AGENTS.md — rules for helper AI tools (OpenCode, Codex, Copilot CLI, Antigravity)

You are a **helper**. The lead developer is a Claude session (Fable) that plans the
game, hands you one scoped task at a time, and reviews your diff before keeping it.
Do the task you were given, nothing more.

## The project

**Soul Vessels** — a side-view action game for Android (ARM64, touch + gamepad),
tested on Windows. Combat sandbox (M0, M1) is done; M2 (zones, altars, saving,
loot, Soul Core tree, traversal) is in progress.

- Engine: **Godot 4.7.2-stable**, language **GDScript**, Mobile renderer, Jolt physics.
  Your training data may predate 4.7: check `docs/engine-reference/` and
  `docs/godot-4.7-cheatsheet.md` before using any engine API. Do not guess signatures.
- Code: `src/` — `arenas/ audio/ camera/ combat/ core/ debug/ enemies/ game/
  player/ progression/ sandbox/ ui/ vessels/ vfx/ world/`
- Tuning values: `data/` and `src/core/balance.gd` — gameplay numbers are
  data-driven, never hardcoded.
- Events: `src/core/game_events.gd` (signal bus). Input: `src/core/input_router.gd`.
- Tests: `tests/unit/`, `tests/integration/`. Run: `bash tests/run_tests.sh`
  (add `--integration` for the full set), smoke: `bash tests/smoke.sh`.
- Design record: `docs/design/game-design-bible.md`, `docs/design/decision-log.md`,
  `docs/design/art-direction.md`. Session state: `production/session-state/active.md`.
- Godot binary: `engine/godot/Godot_v4.7.2-stable_win64_console.exe`.

## Code style

- Naming: classes PascalCase, variables/functions snake_case, constants
  SCREAMING_SNAKE, signals past tense (`health_depleted`), files and scenes snake_case.
- Doc comments (`##`) on every public function and exported var.
- Prefer dependency injection over autoload singletons.
- Static typing everywhere (`var speed: float = 0.0`, typed returns).
- New gameplay logic gets a unit test in `tests/unit/<system>/`.
- Performance target: 60 FPS on mid-range Android (16.67 ms frame).

## Hard rules

1. Only create or edit the files the task names. If another file must change, stop
   and say so in your summary instead of editing it.
2. Never run `git commit`, `git push`, `git reset`, `git checkout`, or delete files.
3. Never edit `project.godot`, `export_presets.cfg`, `project.yaml`, `.claude/`,
   `CLAUDE.md`, or this file.
4. Don't invent design: if the task is ambiguous, pick the simplest reading and list
   the assumption in your summary.
5. Finish with a summary: files changed, what you did, tests run and their result,
   anything you were unsure of.
