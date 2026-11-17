# Story 040: M3 playtest, evidence and APK

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: QA · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum "Production milestones": each milestone ends with an installable Android
build. Same shape as story 026 (M2): one bridge script from the title through the milestone's
content, a room atlas, the APK on the emulator.

## Acceptance Criteria

- [x] `tools/playtest/drive_m3.py`: from a save at the end of Zone 2, through the flooded stair, freeing Seris, one puzzle of each kind, a Prelate, a reforge to +1, an ability rank, the Sovereign's three phases, the win, and quit-then-continue keeping it all.
- [x] Every earlier playtest still passes (`drive.py`, `drive_m2.py`, the zone walks) and the full test suite is green.
- [x] A room atlas for Zone 3 in `production/qa/evidence/story-040-m3/`.
- [x] The debug APK builds, installs and boots on the emulator and loads the throne hall (`tools/playtest/android_check.py` extended).
- [x] Frame rate on a real phone is still unmeasured unless the user names a phone; say so in the report.

## Files

- `tools/playtest/drive_m3.py`, `tools/playtest/android_check.py`, `production/qa/evidence/story-040-m3/`

---

## Completion

Evidence: `production/qa/evidence/story-040-m3/`. `tools/playtest/drive_m3.py` 17/17; every earlier
playtest passes; the APK runs on the emulator, throne hall included. Real-phone frame rate is not measured.
