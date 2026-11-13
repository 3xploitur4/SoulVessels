# Story 016: Game flow: title, slots, difficulty, pause, map, inventory

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: Presentation · **Type**: UI · **Estimate**: M

## Context

**Design**: addendum "UI, controls and localisation" (menus: Title; Pause with Map, Vessels,
Inventory, Lore, Settings), "Difficulty" (Story and Normal; Abyssal unlocks after Chapter I),
Track 02 on the title. All text through translation tables.

## Acceptance Criteria

- [ ] The main scene is the game: a title screen with 3 slot cards (empty, or zone, room, play time and Essence), New Game with a difficulty choice, Continue, Delete with a confirm.
- [ ] Pause (Esc, Menu, Android back): Resume, Map (visited rooms of the current zone, altars, you-are-here), Inventory (items with rarity colour and description), Lore, Quit to title (saves first).
- [ ] Every menu works with touch, mouse, keyboard and gamepad (focus navigation).
- [ ] Interact action for altars, bodies and signs: W or Up, left stick up, and a contextual touch button.
- [ ] HUD additions: Essence counter, interact prompt, tutorial banner with the current device's button names, item toasts, zone title card, fade.
- [ ] The M1 sandbox stays runnable as its own scene for the combat playtest.
- [ ] Screenshot evidence of each screen.

## Files

- `src/game/game.gd`, `src/game/game.tscn`, `src/ui/title_screen.gd`, `pause_menu.gd`, `map_view.gd`, `prompts.gd`, `ui_kit.gd`
- `src/sandbox/sandbox.tscn` (the M1 scene)
