# Epic M3 — Zone 3 and the Weeping Sovereign

**Status: Done (2026-11-17).** All 11 stories closed; the M3 playtest (`tools/playtest/drive_m3.py`) passes end to end and the APK runs on the Android emulator. Open: your sign-off on the M3 look (story 039), concept art for the Drowned Courtier, a clip per Sovereign attack, frame rate on a real phone, and hand-play of puzzles 4-6 and a full Sovereign fight.

> Milestone: M3 (addendum "Production milestones" #4). Seris, light-rune puzzles, water, Choir
> Prelate, the first boss with 3 music phases, reforging. Content: Zone 3 Sunken Palace (18 rooms,
> 2 altars, Seris frozen in crystal in room 4, water levels, 6 light-rune puzzles, the Weeping
> Sovereign as Zone Boss, Track 05 "Drowned Court", boss Track 08 "Tears of the Sovereign").
> Also from M2's "out of scope" list: Vessel ability ranks, Sync passives, Standard and Greater
> Shards as currency.

| Story | Title | Type | Est. |
| --- | --- | --- | --- |
| 030 | Seris's kit: Arcane Bolt, Frost Binding, Aether Shield, Rift Step, passive | Logic | L |
| 031 | Water: pools, rising water, swimming, Frost freezes the surface | Logic | M |
| 032 | Light-rune doors and puzzles: sequence, mirror-shield reflection, tide | Integration | L |
| 033 | Enemies: Drowned Courtier and Choir Prelate | Logic | M |
| 034 | Boss framework and the Weeping Sovereign | Integration | L |
| 035 | Track 05 and boss Track 08 with three phase clips | Integration | M |
| 036 | Reforging and Censer Core crafting at the altar | Logic | M |
| 037 | Vessel ability ranks and Sync passives | Logic | M |
| 038 | Zone 3 — Sunken Palace | Integration | L |
| 039 | Art: Seris casting, Courtier, Prelate and Sovereign rigs, palace look | Visual/Feel | M |
| 040 | M3 playtest, evidence and APK | Integration | M |

Build order is the story order, with two exceptions: 036 and 037 need only M2's altar and items,
so they can be built at any point; 039 runs alongside 033 and 034, since each new enemy needs its
rig before it can be screenshotted.

Dependencies: 032 needs 030 (Arcane Bolt lights runes) and 031 (the tide puzzle). 034 needs 031
(water rises in phase 2) and 035 for the phase music, but 035 can land second; the boss then
plays the zone track until it does. 038 needs 030–035.

Out of M3 (later milestones): Darius and cracked masonry, the darkness light radius, Overdrive,
the Guardian Below and the Leviathan (M4); the settings screen and colour-blind palettes (M5).
Seris's second weapon (Floating Focus) waits for the Deep-Realm Rune, which drops in Zone 4.
