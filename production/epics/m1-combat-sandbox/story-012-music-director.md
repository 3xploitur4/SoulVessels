# Story 012: Music director with placeholder stems and telegraph SFX

> **Epic**: M1 — Combat Sandbox · **Status**: Ready · **Layer**: Presentation · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum "Audio implementation" (Bed / Pulse / Combat / Elite plus 5 Lead stems; lead
crossfade in 1 beat on swap; intensity changes on the next 4-bar boundary; states Explore, Alert,
Combat, Elite, calm-down after 6 s; Track 01 at 70 BPM 4/4; telegraph SFX chime / boom /
harmonic under 150 ms); bible section 4 leitmotif per Vessel. **Decision**: D-006.

## Acceptance Criteria

- [ ] `tools/audio/synth_stems.py` writes `assets/audio/music/zone1/{bed,pulse,combat,elite,lead_caelan,lead_nyra,lead_seris,lead_darius,lead_ilyr}.wav`, each exactly 8 bars at 70 BPM (27.43 s), loop-clean, and `assets/audio/sfx/{telegraph_chime,telegraph_boom,telegraph_harmonic,hit,parry,swap}.wav`; the leads share one 8-note piano motif voiced per Vessel (horns, plucked, choir pad, cello, reversed 7/8).
- [ ] `MusicDirector` autoload: loads the zone's stems into one `AudioStreamSynchronized`, keeps a beat clock from the playback position and BPM, and schedules stem volume ramps on the next 4-bar boundary; `set_state(EXPLORE|ALERT|COMBAT|ELITE)`, `set_vessel(id)` crossfades leads over 1 beat; calm-down 6 s after `aggro_count` reaches 0.
- [ ] Boundary math is pure and unit-tested (`next_boundary_time(now, bpm, bars)`).
- [ ] `Sfx` autoload plays telegraph cues on a dedicated bus; the Telegraph bus ducks music by 3 dB for 150 ms.
- [ ] A headless integration run flips states and asserts the scheduled ramp times land on 4-bar boundaries (within 1 ms).

## Files

- `tools/audio/synth_stems.py`, `assets/audio/**`, `src/audio/music_director.gd`, `src/audio/sfx.gd`, `default_bus_layout.tres`
- `tests/unit/audio/beat_math_test.gd`, `tests/integration/audio/music_states_test.gd`

## Dependencies

- Depends on: 010 (aggro signals) · Unlocks: 013
