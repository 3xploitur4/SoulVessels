# Soul Vessels — Project Setup

Project root: `Documents\SoulVessels`

## What's in this folder

| Path | What it is |
| --- | --- |
| `CLAUDE.md`, `.claude/`, `project.yaml`, `design/`, `production/`, `src/` | The **claude-code-game-studios** template (agents, skills, hooks, workflow). The engine is set to Godot 4.7.2 / GDScript in `CLAUDE.md`. |
| `.claude/skills/{big-feature, feature-breaker, game-manager, playtest-bot, look-critic, asset-forge}` | Skills from **ai-gamedev-kit**, added next to the template's own skills. Each `config.json` still has `<placeholder>` values to fill once the Godot project exists. |
| `tools/gamedev-kit/` | `godot_api.py` (Godot 4.7.2 API lookup), `hooks/gd_guard.py` (blocks outdated Godot 3 syntax), `bridge/bridge.gd` (in-game TCP bridge for AI playtesting) |
| `tools/mcp/` | The kit's Python MCP server for the game bridge |
| `docs/design/game-design-bible.md` | Your original Master Game Design Bible |
| `docs/godot-4.7-cheatsheet.md` | Kit's Godot 4.7 cheat sheet |
| `engine/godot/` | Portable Godot 4.7.2 editor in **self-contained mode** (the `_sc_` file). Settings, cache and export templates live in `engine/godot/editor_data/`; your older Godot setup in `%APPDATA%\Godot` is never touched. |
| `engine/godot/editor_data/export_templates/4.7.2.stable/` | Android export templates (debug, release, Gradle source), checksum-verified |
| `engine/jdk-17/` | Portable Temurin JDK 17.0.21 for Godot's Android export (sources zip omitted). Your installed JDK 25 is untouched. |
| `vendor/` | Untouched reference copies of ai-gamedev-kit and ai-game-dev-plugin |

The design addendum (numbers, systems, fixes) lives online:
https://claude.ai/artifact/RSA5fXj2ZHCMcgCHoxH8iY. It wins over the bible where they disagree.

## Already on this PC (left untouched)

- Git for Windows, Node.js, Python 3.12 / 3.14, Anaconda
- Eclipse Adoptium JDK 25
- Android Studio + Android SDK: build-tools 36.0.0 / 36.1.0, platform android-36.1, platform-tools 36.0.2 (adb), emulator
- Added on 2026-11-13 (with your approval): **Android SDK Command-line Tools (latest)**

## Godot Android settings

`engine/godot/editor_data/editor_settings-4.7.tres` pre-sets:
- Java SDK Path → `engine\jdk-17`
- Android SDK Path → `C:\Users\ACHRAF CHARKAM\AppData\Local\Android\Sdk`

If Godot shows those fields empty, set them in Editor > Editor Settings > Export > Android.

## Known caveat

Your Android SDK path contains a space ("ACHRAF CHARKAM"). Android Studio warns this can break **NDK** builds. Godot's standard export doesn't use the NDK, so this only matters if we later need a custom Gradle build with native plugins.

## Start production

Open the Claude desktop app's **Code** tab with this folder as the working directory, choose **Fable 5.2**, then run `/start` and `/setup-engine` (Godot 4.7.2). Hooks and skills load only when Claude Code starts in this folder.

Optional, later:
- Merge `tools/gamedev-kit/hooks/settings.example.json` into `.claude/settings.json` (paths → `tools/gamedev-kit/hooks/`; on Windows call `python`, not `python3`).
- ai-game-dev-plugin isn't wired in (Godot path needs C#/.NET + an ai-game.dev account).
