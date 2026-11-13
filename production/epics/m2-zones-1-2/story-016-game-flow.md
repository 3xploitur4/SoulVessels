# Story 016: Game flow: title, slots, difficulty, pause, map, inventory

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Presentation · **Type**: UI · **Estimate**: M

## Context

**Design**: addendum "UI, controls and localisation" (menus: Title; Pause with Map, Vessels,
Inventory, Lore, Settings), "Difficulty" (Story and Normal; Abyssal unlocks after Chapter I),
Track 02 on the title. All text through translation tables.

## Acceptance Criteria

- [x] The main scene is the game: a title screen with 3 slot cards (empty, or zone, room, play time and Essence), New Game with a difficulty choice, Continue, Delete with a confirm.
- [x] Pause (Esc, Menu, Android back): Resume, Map (visited rooms of the current zone, altars, you-are-here), Inventory (items with rarity colour and description), Lore, Quit to title (saves first).
- [x] Every menu works with touch, mouse, keyboard and gamepad (focus navigation).
- [x] Interact action for altars, bodies and signs: W or Up, left stick up, and a contextual touch button.
- [x] HUD additions: Essence counter, interact prompt, tutorial banner with the current device's button names, item toasts, zone title card, fade.
- [x] The M1 sandbox stays runnable as its own scene for the combat playtest.
- [x] Screenshot evidence of each screen.

## Files

- `src/game/game.gd`, `src/game/game.tscn`, `src/ui/title_screen.gd`, `pause_menu.gd`, `map_view.gd`, `prompts.gd`, `ui_kit.gd`
- `src/sandbox/sandbox.tscn` (the M1 scene)

---

## Completion

The game scene (`src/game/game.gd`) owns the run; menus emit requests only. Suspend-save (story
014's last criterion) lives here: `NOTIFICATION_APPLICATION_PAUSED` and window close save a resume
point. The interact action is W / Up / left stick up plus a contextual touch button. Evidence:
`production/qa/evidence/story-016-game-flow/`.
