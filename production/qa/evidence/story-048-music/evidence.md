# Story 048 evidence: Zone 4, boss and finale music

Audio, so no screenshot: the evidence is the files, the synth log and the test.

| Track | Folder | Clips | Length |
| --- | --- | --- | --- |
| Track 09 - The Sealed Rift | `zone4/` | bed, pulse, combat, elite, 5 leads | 32 s |
| Track 12 - The Starless Shore | `zone4_shore/` | bed, pulse, combat, elite, 5 leads | 32 s |
| Track 10 - The Guardian Below | `boss_guardian/` | p1, p2, p3 | 29.5 s (8 bars at 65 BPM) |
| Track 13 - Leviathan | `boss_leviathan/` | p1, p2, p3 | 25.0 s (8 bars of 5 at 96 BPM) |
| Track 14 - short | `finale_short/` | bed | 32 s |

- `bash tests/run_tests.sh --filter music`: 9 passed (includes `music_files_test.gd`).
- `bash tests/run_tests.sh --integration`: 400 passed. Smoke ok.
- Not checked by ear on a phone.
