# Story 047: Ilyr's awakening, the chapter's end, and Abyssal difficulty

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done (2026-11-17) · **Layer**: Content · **Type**: Integration · **Estimate**: L

## Context

**Design**: Narrative 6: "a playable 90-second segment: the Intruder briefly inhabits Ilyr, fighting
erased echoes of the other four Vessels. Ilyr: 'You've worn this face before.' Cut to black. Ilyr
joins in Chapter II." Ilyr's table row:
- dimensional blade, 4 hits;
- Fracture (spatial tear, 3 s DoT);
- Distortion (pull or push 6 m);
- Null Space (a blink that erases projectiles);
- passive Echo (every 5th attack repeats at 70 %).
Track 14's short version plays. The Abyssal difficulty unlocks after Chapter I (Death table).

## Acceptance Criteria

- [x] After the Leviathan the rift opens and a scene moves into a closed arena where the player is Ilyr only (the loadout is set aside and restored after).
- [x] A Chapter I Ilyr kit: the 4-hit blade, Fracture, Distortion, Null Space, Echo. No ranks or passives.
- [x] Four erased echoes, one after another (Caelan, Nyra, Seris, Darius): pale, glitching versions using their Vessel's attacks, tuned so the segment runs about 90 s.
- [x] Ilyr's line, then a cut to black, a chapter-end screen (title, play time, deaths, lore found) and a return to the title.
- [x] The save is marked Chapter I complete; Abyssal difficulty becomes selectable for new games (140 % enemy damage, windows -20 %, an extra attack per combo).
- [x] Integration test of the whole segment through the game, and of the Abyssal unlock; screenshots of each echo and the end screen.

## Files

- `src/vessels/ilyr_kit.gd`, `data/balance/vessels/ilyr.json`, `src/enemies/erased_echo.gd`, `src/ui/chapter_end.gd`
- `src/progression/game_state.gd` (chapter flag), `src/ui/title_screen.gd` (Abyssal), `tests/integration/world/ilyr_awakening_test.gd`

---

## Completion

Decision D-054. Evidence: `production/qa/evidence/story-047-awakening/`.
- New code: `src/vessels/ilyr_kit.gd` and `fracture_tear.gd`; `src/enemies/erased_echo.gd` with four `echo_*` data files and sprites; `src/world/ilyr_awakening.gd` (a room feature, `awakening`); `src/ui/chapter_end.gd`.
- `SaveSystem.chapter_complete()` and `mark_chapter_complete()` (a `profile.json` beside the slots); the title's Abyssal button; `EnemyBase.cooldown_scale`.
- Bridge command `awakening`. Zone 4 links its rift to the awakening room in story 049.
