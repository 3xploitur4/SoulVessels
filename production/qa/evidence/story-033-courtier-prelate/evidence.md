# Story 033 evidence: Drowned Courtier and Choir Prelate

Run: `bash tools/python.sh tools/playtest/prelate_courtier_check.py` (room z1_03; Zone 3 places both
enemies in story 038). Log: `run-output.txt`, 7 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-prelate-aura.png | The Prelate's aura (a gold ellipse on the walkway, 8 m each way); the Crawler inside wears a gold ring (buffed). Violet orb volley in flight |
| 02-orbs-vs-shield.png | Seris's Aether Shield up against the volley |
| 03-unraveled.png | After Aether bolts Unravel the Prelate: its aura is gone and the Crawler's ring with it |
| 04-teleported.png | Walking up to the Prelate makes it vanish and reappear 7 m away on the far side |
| 05-courtier-submerged.png | A Courtier waiting under the surface of a pool poured by the bridge |
| 06-courtier-rises.png | It rises with the gold parry ring as Seris swims close |
| 07-courtier-frozen.png | One Frost Binding freezes it in the water |

Unit tests: `tests/unit/enemies/courtier_prelate_test.gd` (12). They first failed to load because the classes did not exist.

Two problems were found in play, and each is fixed:
1. One Frost Binding (60 build-up) never froze a Courtier. In water, Frost now builds 2x on it. A test for this was seen failing first.
2. Arcane Bolts built Aether too slowly to ever Unravel the Prelate. Build-up went from 12/12/20 to 20/20/30.

Also fixed: enemies ignored Freeze. A frozen enemy now stops and cancels its attack until the ice breaks; this applies to every enemy.

The Courtier uses the Husk painting, tinted sea-green, until story 039 gives it its own figure.
