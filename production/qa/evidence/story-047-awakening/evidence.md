# Story 047 evidence: Ilyr's awakening, the chapter's end, Abyssal

Run: `bash tools/python.sh tools/playtest/awakening_check.py`. A stand-in room is entered through the bridge; Zone 4's rift leads into the real one in story 049. Log: `run-output.txt`, 7 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-ilyr-wakes.png | The Intruder is Ilyr alone (one portrait on the wheel); his waking line |
| 02-05 echo_*.png | The erased echoes in order: Caelan, Nyra, Seris, Darius. Each is the Vessel's own painting, pale and stuttering, fought with Ilyr's blade, Fracture and Distortion |
| 06-ilyr-line.png | "You've worn this face before." |
| 07-chapter-end.png | Black, "End of Chapter I", the run's stats, the Chapter II line, Abyssal unlocked, a button back to the title |
| 08-abyssal-open.png | The title's difficulty page now offers Abyssal |

Tests:
- `tests/unit/vessels/ilyr_kit_test.gd` (6): the kit; Echo every 5th hit at 70 %; Fracture ticking for 3 s; Distortion pulling the nearest enemy in; Null Space erasing projectiles.
- `tests/integration/world/ilyr_awakening_test.gd` (2):
  - The whole segment through the game: Ilyr alone, the four echoes in order, the chapter flag, the chapter-end screen, the profile unlock, and the save keeping the real loadout.
  - The title offers Abyssal only after Chapter I.

These tests were written before the code but first run after it, so I did not watch them fail.

Found in play and fixed:
- The fade to black covered the chapter-end screen.
- The stats line wrapped mid-phrase.

Abyssal: 140 % enemy damage and 80 % windows (already in the table), plus enemy attack cooldowns x0.75. That last one stands in for the addendum's "extra attack per combo" (decision D-054).

Not covered:
- How long the segment takes by hand. The echoes are tuned for about 90 s; the script dispatches them early.
- Track 14's short version (story 048).
