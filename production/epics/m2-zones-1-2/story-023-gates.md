# Story 023: Gates: shield ward, shadow veil, sealed gates

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: Feature · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum gate table. Shield ward: a golden statue firing a steady beam; Caelan blocks
and deflects it onto a receiver crystal (Zone 1). Shadow veil: a 6 m+ gap or a black mist curtain,
opened by Nyra's Shadowstep (Zone 2, plus 4 Zone 1 secrets). Light-rune door (Seris), cracked
masonry (Darius) and rift scar (Ilyr) appear sealed in Zones 1–2. Decision D-030.

## Acceptance Criteria

- [ ] Shield ward: a beam at a data angle hurts on contact; Caelan's block reflects it (mirror on the shield), and the reflected ray charging the crystal for 1 s opens the golden bars; saved.
- [ ] Shadow veil curtain: solid to everything except a Shadowstep. Veil gaps are 11 m: Caelan cannot cross them and Nyra can.
- [ ] Sealed gates: light-rune, cracked masonry and rift scar, each with a hint line.
- [ ] Integration test: the reflect math opens the ward; walking into a veil stops you, a Shadowstep passes.

## Files

- `src/world/shield_ward.gd`, `shadow_veil.gd`, `sealed_gate.gd`
- `tests/integration/world/gates_test.gd`
