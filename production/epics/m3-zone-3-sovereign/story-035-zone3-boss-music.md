# Story 035: Track 05 and boss Track 08

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum "Audio implementation": Track 05 "Drowned Court" (Zone 3, 72 BPM 4/4) with
the shared stems and one lead per Vessel; Track 08 "Tears of the Sovereign" (boss 1: solo cello,
then strings and choir; 76 → 152 BPM). Bosses use AudioStreamInteractive with three phase clips;
intensity changes wait for the next 4-bar boundary. Placeholder stems come from
`tools/audio/synth_stems.py` with the final file names (decision D-006).

## Acceptance Criteria

- [x] Track 05 stems synthesised (bed, pulse, combat, elite, a lead for each of Caelan, Nyra and Seris) and listed in `data/audio/music.json`.
- [x] Track 08: three phase clips, with the tempo doubling in phase 3; `music.json` gains a `bosses` section.
- [x] The music director plays the boss track when a boss fight starts, moves to the next clip on `phase_changed` at the next 4-bar boundary, and returns to the zone track after the win.
- [x] Seris's lead stem crossfades in on swap in every zone (Tracks 01 and 03 gain a Seris lead).
- [x] Unit tests: the next-boundary time at both tempos, the clip order. Each seen failing first.

## Files

- `tools/audio/synth_stems.py`, `assets/audio/music/zone3/`, `assets/audio/music/boss_sovereign/`
- `data/audio/music.json`, `src/audio/music_director.gd`
- `tests/unit/audio/boss_music_test.gd`

---

## Completion

Decision D-044. Evidence: `production/qa/evidence/story-035-music/`. The boss track is a music.json entry
with `"boss": true` and one stem per phase, played through the same synchronized-stem player as the
zones (not AudioStreamInteractive; see D-044). `MusicDirector.boss_begin/boss_phase/boss_end` answer the
GameEvents boss signals; a boss's data names its track (`"music"`). The Seris lead in Tracks 01 and 03
already existed.
