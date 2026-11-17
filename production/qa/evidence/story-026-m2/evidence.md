# Evidence — Story 026: M2 playtest, room atlas and APK

Run result: VERIFIED. Every check below was run on 2026-11-17 against commit 66220eb plus the
fixes in this story's commit.

## The M2 playtest (`tools/playtest/drive_m2.py`, 23 checks, `run-output.txt`)

A new game from the title over the bridge: the title offers three slots; a new game starts as the
wisp in room 1 with the move tutorial; the wisp possesses Caelan; an altar is kindled and rested
at (checkpoint set, saved); a Lesser Soul Shard buys the Core Heart; a kill gives Soul Essence and
drops loot; Caelan's block opens the shield ward; death leaves a Soul Echo holding the Essence and
returns the player to the altar; touching the echo returns it; Nyra is cut free and joins; her
Shadowstep crosses the veil; the gauntlet is cleared; quit to title and Continue keep the loadout,
Soul Core, opened gates, cleared arenas, unlocked Vessels and story flags, and resume in the room
the player stood in. 0 failed.

Shots: `01-title.png` … `11-continued.png`.

## Room atlas

`atlas_zone1.png` (14 rooms) and `atlas_zone2.png` (16 rooms): one screenshot per room, 30 in all,
taken by the zone walks (`story-024-zone1/room-*.png`, `story-025-zone2/room-*.png`).

## Tests

All unit and integration tests: 233 pass. Smoke: boots (`SOULVESSELS_BOOT_OK`, Mobile renderer,
Jolt). M1 combat playtest (`tools/playtest/drive.py`): 44/44.

## Android (`tools/playtest/android_check.py`, `android-run-output.txt`)

The debug APK (`tools/build/export_android.sh`, signed, arm64) installs on the Android 16
emulator (Medium Phone API 36.1), boots in about 30 s, the bridge answers over `adb forward`,
the title shows its slots, a new game builds room 1, and the Warden's hall loads with the Warden.
Shots from the device: `android-01-title.png`, `android-02-room1.png`,
`android-03-warden-hall.png`.

Found and fixed on the emulator: on touch the move tutorial read "the UI_MOVE_LEFT button / the
UI_MOVE_RIGHT button to drift". There is now a `{move}` placeholder (keyboard: the two keys;
touch: "the stick on the left"; gamepad: "the left stick"), every placeholder used in the strings
has a touch name (the swap reads "the Vessel wheel button"), and a sentence that opens with a
control name starts upper-case. `tests/unit/ui/control_names_test.gd` (4) was seen failing on the
old text before the fix. Seen fixed on the device after re-export.

Not verified: frame rate on a real phone. The emulator renders in software (SwiftShader) and
shows 3-5 FPS, which says nothing about a Snapdragon 778-class phone (same caveat as stories 005
and 013).
