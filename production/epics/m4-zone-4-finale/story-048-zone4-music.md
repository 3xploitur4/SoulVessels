# Story 048: Music: Tracks 10, 12, 13 and the short Track 14

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done · **Layer**: Feature · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum track list:
- Track 10, The Guardian Below: war drums, sub-bass brass, male choir, 65 BPM (P3 at 130).
- Track 12, Starless Shore: Zone 4b, 60 BPM ambient.
- Track 13, Leviathan: a 5/4 + 7/8 hybrid with distorted cellos and sonar, 96 BPM.
- Track 14, The End of Everything: all leitmotifs merged; its short version plays in Ilyr's awakening.

The Sealed Rift (Zone 4a) needs a zone track too; it reuses the zone stem set over Track 12's harmony.
Placeholders are synthesised with the final file names (D-006); bosses use the story-035 boss-track path.

## Acceptance Criteria

- [x] Zone 4 stems (bed, pulse, combat, elite, five leads) for the Sealed Rift and the Starless Shore.
- [x] Boss tracks for the Guardian (three phase clips, P3 in double time) and the Leviathan (three phase clips in the 5/4 + 7/8 feel, within one boundary grid).
- [x] Track 14 short for the awakening, with all five leitmotifs layered.
- [x] music.json entries; the boss data name their tracks; a test that every track listed exists and has the stems its entry names.

## Files

- `tools/audio/synth_stems.py`, `assets/audio/music/`, `data/audio/music.json`, `tests/unit/audio/music_files_test.gd`

---

## Completion

Evidence: `production/qa/evidence/story-048-music/evidence.md`.
- `tools/audio/synth_stems.py`: Z4 and shore harmony, `guardian_p1..p3` (65 BPM, P3 drums at double time), `leviathan_p1..p3` (5 beats a bar, 3+2+2 accents, sonar pings, clipped cellos), `finale_bed` (all five leads over one pad).
- `data/audio/music.json`: `zone4`, `zone4_shore`, `boss_guardian`, `boss_leviathan`, `finale_short`. The Guardian and Leviathan data already name their tracks; `IlyrAwakening` starts `finale_short`.
- `tests/unit/audio/music_files_test.gd`: every file of every listed track exists; the M4 tracks are listed; the boss tracks have three clips.
- Not verified: by ear. Placeholders, replaced by recordings with the same names (D-006).
