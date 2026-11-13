# Story 026: M2 playtest, evidence and APK

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: QA · **Type**: Integration · **Estimate**: M

## Acceptance Criteria

- [ ] `tools/playtest/drive_m2.py` plays a new game from the title through both zones over the bridge: possession, tutorials, altar rest and save, death and echo recovery, loot, a Soul Core purchase, the shield ward, Nyra, the veil, the gauntlet, save and reload.
- [ ] A room atlas: one screenshot per room (30).
- [ ] All unit and integration tests pass; smoke passes; the M1 combat playtest still passes.
- [ ] The debug APK exports and boots to the title on the Android emulator, and a room loads there.

## Files

- `tools/playtest/drive_m2.py`, `production/qa/evidence/story-026-m2/`
