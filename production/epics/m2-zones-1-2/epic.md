# Epic M2 — Zones 1–2

**Status: Done (2026-11-17).** All 16 stories closed; the M2 playtest (`tools/playtest/drive_m2.py`) passes end to end and the APK runs on the Android emulator. Not verified: frame rate on a real phone.

> Milestone: M2 (addendum "Production milestones" #3). Rooms, Soul Altars, saving, Soul Essence
> and death, loot, Soul Core tree, Caelan/Nyra gates. Content: Zone 1 Whispering Cavern (14 rooms,
> 2 altars, Caelan in room 2, attack/dodge/parry tutorial, Branded Warden set-piece) and Zone 2
> Luminous Mycelium Forest (16 rooms, 2 altars, Nyra in room 8, swap tutorial, vertical climbing,
> bounce mushrooms, wall-jump, Husk ambush gauntlet, Track 03).

| Story | Title | Type | Est. |
| --- | --- | --- | --- |
| 014 | Game state and save slots | Logic | M |
| 015 | Room format, room builder and transitions | Integration | L |
| 016 | Game flow: title, slots, difficulty, pause, map, inventory | UI | M |
| 017 | Soul Altars: rest, respawn rules, save, loadout, lore | Integration | M |
| 018 | Soul Essence, death and Soul Echo | Logic | M |
| 019 | Loot: items, rarity rolls, pity, pickups | Logic | M |
| 020 | Soul Core tree and Affinity progression | Logic | M |
| 021 | Traversal: wall-jump, bounce mushrooms, one-way platforms, void falls | Logic | M |
| 022 | Enemies: Calcified Husk and Fungal Stalker | Logic | M |
| 023 | Gates: shield ward, shadow veil, sealed gates | Integration | M |
| 024 | Zone 1 — Whispering Cavern | Integration | L |
| 025 | Zone 2 — Luminous Mycelium Forest, Track 03 | Integration | L |
| 026 | M2 playtest, evidence and APK | Integration | M |
| 027 | Art pass: painted Vessels and enemies from the concept sheets | Visual/Feel | L |
| 028 | Art pass: zones, gates, altars and UI after the zone paintings | Visual/Feel | L |
| 029 | Cut-out rig pilot: Caelan and the Echo Crawler move limb by limb | Visual/Feel | M |

Build order is the story order. 019-022 only need 014-015. 027 and 028 were added on 2026-11-14,
when the user supplied concept sheets and asked for the look to follow them; they were built
between 019 and 020. 029 was added on 2026-11-17 when the user asked for real limb animation
(route B, cut-out parts) using only what is on the PC.

Out of M2 (later milestones, per the addendum): Vessel ability ranks, Sync passives and reforging
(M3, with Standard and Greater Shards and Essence as their currency), fast travel (needs all 7
altars), the settings screen (M5), Abyssal difficulty (unlocks after Chapter I).
