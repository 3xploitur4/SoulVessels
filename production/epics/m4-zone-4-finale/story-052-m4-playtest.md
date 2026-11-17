# Story 052: M4 playtest: Chapter I end to end, evidence and APK

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Ready · **Layer**: QA · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum "Production milestones": each milestone ends with an installable Android
build. M4 closes Chapter I, so its playtest walks the whole chapter.

## Acceptance Criteria

- [ ] `tools/playtest/drive_m4.py`: from a save after the Sovereign through Zone 4: Darius, a masonry wall, a dark room, the Guardian's three phases, the Leviathan's three phases, Overdrive, Ilyr's awakening to the chapter-end screen, and the Abyssal unlock on the title.
- [ ] A full-chapter run that strings the M2, M3 and M4 drives together from a new game, and every earlier playtest still passes; the test suite is green.
- [ ] A room atlas for Zone 4.
- [ ] The debug APK builds, installs and boots on the emulator and loads both Zone 4 boss arenas.
- [ ] Frame rate on a real phone is still unmeasured unless the user names a phone; say so in the report.

## Files

- `tools/playtest/drive_m4.py`, `tools/playtest/android_check.py`, `production/qa/evidence/story-052-m4/`
