# Soul Vessels — Decision Log

Decisions made while building, logged so the design docs and the code agree. The addendum
(`design-addendum-v1.md`) wins over the bible; this log wins over both for *implementation*
choices, never for game rules. Each entry: what, why, how to undo.

| ID | Date | Decision | Why | Undo cost |
| --- | --- | --- | --- | --- |
| D-001 | 2026-11-13 | Godot project lives at the repo root (`project.godot`), code in `src/`, data in `data/`, assets in `assets/`, tests in `tests/`. Non-game folders get a `.gdignore`. | The studio template's Godot row (`engine.code_root: src`) and its `commands.run` (`godot --path .`) assume a root project. | Low: move files, fix `res://` paths. |
| D-002 | 2026-11-13 | Renderer `mobile`, physics `Jolt Physics` set explicitly, physics 60 Hz, physics interpolation on. | User asked for the Mobile renderer. Jolt is the 4.6+ default and faster; `DEFAULT` may change. Interpolation removes camera jitter on 90/120 Hz phones. | Low. |
| D-003 | 2026-11-13 | Every tuning number lives in JSON under `data/balance/` (`combat.json`, `vessels/*.json`, `enemies/*.json`), loaded by a `Balance` autoload into typed dictionaries. | Coding standard: data-driven, never hardcoded. The kit skills (`playtest-bot`, `feature-breaker`) already point at `data/balance/`. | Low. |
| D-004 | 2026-11-13 | 2.5D = 3D scene, perspective `Camera3D` (FOV 35°, ~14 m back) looking down -Z, player locked to the X/Y plane at z = 0, parallax from real depth layers at z = -6/-14/-30. | Perspective gives free parallax and real lights; the addendum asks for 3D environments with a side-on camera. | Medium: an orthographic swap changes layer spacing. |
| D-005 | 2026-11-13 | Unit tests run on a small in-repo runner (`tests/run_tests.sh` → `tests/runner/test_runner.gd`), not gdUnit4. | gdUnit4 is a download; the user did not ask for it and the runner needs ~100 lines. Switch to gdUnit4 any time: tests are plain `assert`-style functions. | Low. |
| D-006 | 2026-11-13 | Placeholder music stems are synthesised offline to WAV by `tools/audio/synth_stems.py` (pure Python, no numpy) with the addendum's exact stem names; Godot imports them (QOA compression). Real OGG stems replace the files, same names. | No ffmpeg or numpy on this machine; the code must not change when real audio arrives. | None: drop in OGGs with the same names. |
| D-007 | 2026-11-13 | Android package `com.soulvessels.chapter1`, debug keystore generated with the bundled JDK into `engine/godot/editor_data/keystores/debug.keystore` (gitignored). `export_presets.cfg` is committed (no secrets; Godot keeps credentials in `export_credentials.cfg`). | Headless export needs a keystore it can find without the editor UI. | Low: rename package before any store upload. |
| D-008 | 2026-11-13 | The Branded Warden's "flanked by Nyra" and "shattered by Darius" shield rules are implemented as data: the shield blocks 80 % of damage from the front arc (±60°); any attack from behind ignores it; `Crushing Blow` sets `shield_broken`. Caelan's Counterstrike opens a 2 s guard break (addendum). | M1 has Caelan and Nyra only; the rules must already be the real ones. | None. |
| D-009 | 2026-11-13 | The bare `python` on this PC is Microsoft's Store alias stub. Scripts call the real interpreter at `C:/Users/ACHRAF CHARKAM/AppData/Local/Programs/Python/Python312/python.exe` via `tools/python.sh`. | `python`, `python3` and `py` all fail in Git Bash; the template's yaml-helper hooks degrade to defaults. | None: turn off the alias in Windows Settings > Apps > App execution aliases and the plain name works. |
| D-010 | 2026-11-13 | Gamepad mapping follows the addendum: X attack, A jump, B dodge, Y ability 1, RT ability 2, LT+RT ultimate, LB/RB swap, D-pad up flask. Keyboard for desktop testing: WASD/arrows, J attack, Space jump, K dodge, U/I abilities, O ultimate, Q/E swap, F flask, F3 debug HUD. | Desktop testing needs a keyboard layer the design never specified. | None. |

## Open questions for the user (batched)

None blocking. Noted for later:
1. Store package name (`com.soulvessels.chapter1`) before the first Play Console upload.
2. gdUnit4 instead of the in-repo test runner, if you prefer the template's CI command.
3. Windows "App execution aliases" for `python` (D-009).
