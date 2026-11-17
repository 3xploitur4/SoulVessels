# Evidence — Story 023: Gates

Run result: VERIFIED in the running game (bridge, `run-output.txt`) and by tests.

| Check | Observed |
| --- | --- |
| Ward beam, unguarded | HP 460 -> 400 after about 1.2 s in the beam. |
| Ward, guarded in the right spot | Reflected ray climbs onto the crystal above the statue; the bars open; `opened_gates` = `z1_08:ward`; walked through to x 26. |
| Shadow veil | Walking left stops at x 10.35 (curtain at 9-10); Nyra's Shadowstep lands at x 4.5, past it. |
| Sealed rune door | Examine: "A circle of dead runes. It wants light, not force." |

Screenshots: `01-ward-beam-burns`, `02-deflect-misses`, `03-deflect-charges-crystal`,
`04-ward-open`, `05-veil-blocks`, `06-through-the-veil`, `07-rune-door-examined`.

Tests: `tests/integration/world/gates_test.gd` (6): the beam burns; guarding from the right spot
opens the bars, costs no HP and saves; the wrong spot does not charge; too close, the ray passes
under the crystal; an opened ward stays open; the veil stops a walk and passes a Shadowstep.
`tests/unit/world/ward_math_test.gd` (8, written by the codex helper and reviewed): reflection,
beam end against blockers, ray against the crystal.

Found while looking: (1) the reflected beam was drawn almost flat (scaled in world space instead
of along the beam); (2) the crystal sat high on the far wall, out of view and under the swap
wheel. It now sits above the statue's head, mid-screen (decision D-030).
