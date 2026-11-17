# Story 040: M3 playtest, evidence and APK

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Ready · **Layer**: QA · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum "Production milestones": each milestone ends with an installable Android
build. Same shape as story 026 (M2): one bridge script from the title through the milestone's
content, a room atlas, the APK on the emulator.

## Acceptance Criteria

- [ ] `tools/playtest/drive_m3.py`: from a save at the end of Zone 2, through the flooded stair, freeing Seris, one puzzle of each kind, a Prelate, a reforge to +1, an ability rank, the Sovereign's three phases, the win, and quit-then-continue keeping it all.
- [ ] Every earlier playtest still passes (`drive.py`, `drive_m2.py`, the zone walks) and the full test suite is green.
- [ ] A room atlas for Zone 3 in `production/qa/evidence/story-040-m3/`.
- [ ] The debug APK builds, installs and boots on the emulator and loads the throne hall (`tools/playtest/android_check.py` extended).
- [ ] Frame rate on a real phone is still unmeasured unless the user names a phone; say so in the report.

## Files

- `tools/playtest/drive_m3.py`, `tools/playtest/android_check.py`, `production/qa/evidence/story-040-m3/`
