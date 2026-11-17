# Story 040 evidence: the M3 playtest and APK

## The M3 playtest
Run: `bash tools/python.sh tools/playtest/drive_m3.py`. Log: `run-output.txt`, 17 checks, 0 failed.

The run goes from the end of Zone 2 to the Sovereign's fall:
1. The flooded stair leads into the palace, where Track 05 plays.
2. Seris is broken out of her crystal and freed.
3. One puzzle of each kind is solved with real input: sequence, mirror, tide.
4. The Prelate's aura buffs its Crawlers.
5. At the Cloister altar, Seris's weapon is reforged to +1 and King's Judgment goes to rank 2.
6. The throne hall locks and her music plays. The bridge walks her three phases; she falls.
7. The flag is saved, Caelan gets +1 Affinity and his goodbye line, and the Crown Fragment is picked up.
8. Quit to the title and Continue keeps Seris, the opened doors, the reforge and the win.

Shots: `01-palace` .. `09-continued`.

## Every earlier playtest still passes
- `drive.py`: 44/44.
- `drive_m2.py`: 0 failed.
- `zone1_walk.py`: 0 failed.
- `zone2_walk.py`: 0 failed.
- `zone3_walk.py`: 12/12.
- Story checks: Seris, water, runes, Prelate and Courtier, Sovereign, reforge, upgrade.

Full test suite: 343 pass. Smoke: ok.

## Zone 3 room atlas
`atlas/room-z3_01.png` .. `room-z3_18.png`, every room entered through its west door.

## APK on the emulator
The debug APK (`builds/android/soulvessels-debug.apk`, 46 MB, signature verified) installs and boots on the Android 16 emulator `Medium_Phone_API_36.1`. `android_check.py --out production/qa/evidence/story-040-m3` passes 9/9:
- the title, room 1 and the Warden's hall;
- Zone 3's throne hall with the Weeping Sovereign.

Shots: `android-01..04`; log: `android-run-output.txt`.

## Not measured
**Frame rate on a real phone.** The emulator draws in software (3 FPS), which says nothing about a phone. No phone has been named to test on.
