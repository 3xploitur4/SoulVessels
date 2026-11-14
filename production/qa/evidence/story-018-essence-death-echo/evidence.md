# Evidence — Story 018: Soul Essence, death and Soul Echo

Run result: VERIFIED in the running game (bridge, `run-output.txt`) and by tests.

In the game: rested at the Altar of the Fallen Aqueduct, killed the three Crawlers of the Broken
Channel (Essence 0 -> 36, 12 each from `echo_crawler.json`), died at x = 30: woke at the altar with
Essence 0, the echo `{room z1_05, x 30, essence 36}` saved, the Crawlers back (`killed_commons`
empty). Walking back and touching the echo: Essence 36, echo gone, toast "36 Essence recovered".

| Shot | Shows |
| --- | --- |
| `01-essence-popup.png` | Mid-fight in the Broken Channel. |
| `02-soul-lost.png` | "Soul lost" over the fallen body. |
| `03-soul-echo.png` | The Soul Echo (pale figure of light, "36") where the player fell; the Crawlers are back. |
| `04-recovered.png` | After touching it: Essence on the HUD, toast. |

Tests: `tests/unit/progression/death_rules_test.gd` (7: first death, second death loses the old
echo, Story merges, recovery once, zero Essence makes no echo and keeps shards and Affinity, death
brings back commons, respawn point prefers the rested altar) and
`tests/integration/progression/death_echo_test.gd` (2: wake at the altar with the echo saved; touch
recovers).

Values: Essence per kill Crawler 12, Watcher 18, Warden 150 (story 019 adds Husk and Stalker);
the respawn delay is `combat.death.respawn_delay_s` (2.5 s).
