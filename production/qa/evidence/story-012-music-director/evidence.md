# Evidence — Story 012: Music director with placeholder stems

Run result: VERIFIED by measurement (audio rendered by Movie Maker, analysed by
`tools/audio/analyse_probe.py`).

## Stems

`bash tools/python.sh tools/audio/synth_stems.py` wrote nine stems, every one exactly 604,800 frames
(8 bars at 70 BPM = 27.429 s at 22.05 kHz), so they loop in lockstep inside one
`AudioStreamSynchronized`: `bed, pulse, combat, elite, lead_caelan, lead_nyra, lead_seris, lead_darius,
lead_ilyr`. The three telegraph cues are 140 ms each (addendum: under 150 ms).

## Boundary scheduling and live stem volumes

`tests/manual/music_probe.tscn` plays zone 1 in `explore` and asks for `elite` at 1 s. A control run
(`-- --control`) stays in `explore`. Both were recorded with Movie Maker (game-time audio).

```
PROBE asked elite at song 1.165, pending at 13.714
PROBE elite applied at song 13.717
```

Loudness, probe vs control (`probe-vs-control.txt`, 0.5 s windows):

- 0.0 – 14.0 s: ratio **1.00** in every window (identical audio until the boundary).
- 14.5 – 20.0 s: ratio **1.06 → 1.56** as Pulse, Combat and Elite fade in over two beats from 13.714 s.

This shows (1) the change waits for the 4-bar boundary (16 beats at 70 BPM = 13.714 s), and
(2) `AudioStreamSynchronized.set_sync_stream_volume` changes take effect live during playback.

## In the game (bridge playtest, `../story-013-sandbox/playtest-output.txt`)

```
PASS  music: director clock matches audio playback   drift 0.046 s
PASS  music: an elite in range asks for the elite layer
PASS  music: change lands on a 4-bar boundary        at 54.867 s, 4 bars = 13.714 s, off 0.010
PASS  music: elite stem audible, others per state    bed -4, pulse -6, combat -5, elite -5, lead_caelan -6, lead_nyra -60
PASS  swap: music lead follows the Vessel
```

Not verified: how it sounds. These are synthesised placeholders; listen in the sandbox and judge the
mix by ear. Real recordings replace the WAVs under the same names (decision D-006).
