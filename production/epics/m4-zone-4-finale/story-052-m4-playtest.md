# Story 052: M4 playtest: Chapter I end to end, evidence and APK

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done · **Layer**: QA · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum "Production milestones": each milestone ends with an installable Android
build. M4 closes Chapter I, so its playtest walks the whole chapter.

## Acceptance Criteria

- [x] `tools/playtest/drive_m4.py`: from a save after the Sovereign through Zone 4: Darius, a masonry wall, a dark room, the Guardian's three phases, the Leviathan's three phases, Overdrive, Ilyr's awakening to the chapter-end screen, and the Abyssal unlock on the title.
- [x] A full-chapter run that strings the M2, M3 and M4 drives together from a new game, and every earlier playtest still passes; the test suite is green.
- [x] A room atlas for Zone 4.
- [x] The debug APK builds, installs and boots on the emulator and loads both Zone 4 boss arenas.
- [x] Frame rate on a real phone is still unmeasured unless the user names a phone; say so in the report.

## Files

- `tools/playtest/drive_m4.py`, `tools/playtest/android_check.py`, `production/qa/evidence/story-052-m4/`

---

## Completion

Evidence: `production/qa/evidence/story-052-m4/`.
- `tools/playtest/drive_m4.py`: 23/23 from the Breach through Darius, masonry, dark and sliding rooms, the Guardian's and the Leviathan's three phases on the real arenas, the Primeval Truth, Overdrive, the rift, the four echoes, the chapter-end screen and Abyssal on the title.
- Regression: `drive.py` 44/44, `drive_m2.py` and `drive_m3.py` 0 failed (logs in `regression/`); 422 tests pass; smoke ok.
- Found and fixed: reaching the title any way but the chapter-end button left that screen drawn over the title (`show_title` now closes it; test added).
- Atlas: `atlas/` (27 shots, Zone 4 rooms via `tests/manual/room_viewer.tscn`).
- APK: `bash tools/build/export_android.sh` (51.6 MB) installs and boots on the `Medium_Phone_API_36.1` emulator and loads both Zone 4 boss arenas (`android/`, `android_check.py` 13/13). The emulator renders in software (1-3 FPS): frame rate on a real phone is still unmeasured.
