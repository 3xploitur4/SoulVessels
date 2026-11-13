#!/usr/bin/env python3
"""Synthesise the placeholder music stems and SFX for Soul Vessels (story 012, decision D-006).

Pure standard library (no numpy, no ffmpeg on this PC). Writes 22.05 kHz mono 16-bit WAVs with the
exact stem names the MusicDirector expects (data/audio/music.json), so recorded OGG/WAV stems drop
in later under the same names with no code change.

Zone 1, "Track 01 - Beneath the Forgotten": 70 BPM, 4/4, 8 bars (27.43 s), A minor, chords
Am | G | F | E twice (an Andalusian cadence: dark, falling). Every stem is exactly 8 bars and
notes that ring past the end wrap to the start, so each loop is seamless and all stems stay
locked in AudioStreamSynchronized.

The protagonist leitmotif (bible section 4) is one 16-note melody voiced per Vessel:
  caelan  noble horns + soft strings      nyra   plucked strings + light shaker
  seris   ethereal piano + choir pad      darius cello an octave down + deep drums
  ilyr    reversed piano, accents grouped in 7/8 (2+2+3) across the 4/4 bar

Usage: bash tools/python.sh tools/audio/synth_stems.py [--out assets/audio]
"""
import argparse
import math
import os
import random
import struct
import sys
import wave
from array import array

SR = 22050
BPM = 70.0
BEAT = 60.0 / BPM
BARS = 8
BEATS_PER_BAR = 4
LOOP_S = BARS * BEATS_PER_BAR * BEAT
N = int(round(LOOP_S * SR))

TABLE = 4096
SINE = array("f", [math.sin(2.0 * math.pi * i / TABLE) for i in range(TABLE)])

A4 = 440.0


def hz(note):
    """Note name like 'A4', 'G#3', 'Bb2' to Hz."""
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    letter = note[0]
    rest = note[1:]
    shift = 0
    while rest and rest[0] in "#b":
        shift += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    octave = int(rest)
    semis = names[letter] + shift + (octave - 4) * 12
    return A4 * (2.0 ** (semis / 12.0))


# Chords per bar (8 bars): Am G F E Am G F E
CHORDS = [
    ["A2", "E3", "A3", "C4", "E4"],
    ["G2", "D3", "G3", "B3", "D4"],
    ["F2", "C3", "F3", "A3", "C4"],
    ["E2", "B2", "E3", "G#3", "B3"],
] * 2
ROOTS = ["A1", "G1", "F1", "E1"] * 2

# Leitmotif: (beat_offset, beats, note). 2 phrases of 4 bars.
MOTIF = [
    (0, 1, "A4"), (1, 1, "C5"), (2, 1, "E5"), (3, 1, "C5"),
    (4, 1, "B4"), (5, 1, "D5"), (6, 1, "G4"), (7, 1, "B4"),
    (8, 1, "A4"), (9, 1, "C5"), (10, 1, "F4"), (11, 1, "A4"),
    (12, 1, "G#4"), (13, 1, "B4"), (14, 2, "E4"),
    (16, 1, "A5"), (17, 1, "E5"), (18, 1, "C5"), (19, 1, "E5"),
    (20, 1, "D5"), (21, 1, "B4"), (22, 1, "G4"), (23, 1, "D5"),
    (24, 1, "C5"), (25, 1, "A4"), (26, 1, "F4"), (27, 1, "C5"),
    (28, 1, "B4"), (29, 1, "G#4"), (30, 2, "A4"),
]


def blank():
    return array("f", bytes(4 * N))


def mix(buf, start_s, samples, gain=1.0):
    """Add samples into the loop buffer at start_s, wrapping past the end."""
    i0 = int(round(start_s * SR)) % N
    n = len(samples)
    end = i0 + n
    if end <= N:
        for k in range(n):
            buf[i0 + k] += samples[k] * gain
    else:
        first = N - i0
        for k in range(first):
            buf[i0 + k] += samples[k] * gain
        for k in range(first, n):
            buf[(i0 + k) % N] += samples[k] * gain


def env_adsr(n, attack, release, sustain_level=1.0):
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    out = array("f", [sustain_level]) * n
    for i in range(min(a, n)):
        out[i] = sustain_level * i / a
    for i in range(max(0, n - r), n):
        out[i] *= max(0.0, (n - i) / r)
    return out


def additive(freq, dur, partials, attack=0.01, release=0.1, vibrato=0.0, vib_rate=5.0, decay=None,
             detune=None):
    """Sum of sine partials [(ratio, amp)], optional per-partial exponential decay and vibrato."""
    n = int(dur * SR)
    out = array("f", bytes(4 * n))
    env = env_adsr(n, attack, release)
    detunes = detune or [1.0]
    for ratio, amp in partials:
        for dt in detunes:
            f = freq * ratio * dt
            if f >= SR * 0.45:
                continue
            step = f * TABLE / SR
            phase = random.random() * TABLE
            vstep = vib_rate * TABLE / SR
            vphase = 0.0
            dk = (decay * ratio) if decay else 0.0
            a = amp / len(detunes)
            for i in range(n):
                s = SINE[int(phase) & (TABLE - 1)]
                if dk:
                    s *= math.exp(-dk * i / SR)
                out[i] += s * a
                if vibrato:
                    phase += step * (1.0 + vibrato * SINE[int(vphase) & (TABLE - 1)])
                    vphase += vstep
                else:
                    phase += step
    for i in range(n):
        out[i] *= env[i]
    return out


def pluck(freq, dur, brightness=0.5):
    """Karplus-Strong plucked string."""
    n = int(dur * SR)
    period = max(2, int(SR / freq))
    ring = array("f", [random.uniform(-1, 1) for _ in range(period)])
    out = array("f", bytes(4 * n))
    idx = 0
    damp = 0.496 + 0.003 * brightness
    for i in range(n):
        nxt = (idx + 1) % period
        v = ring[idx]
        out[i] = v
        ring[idx] = damp * (v + ring[nxt])
        idx = nxt
    return out


def noise(dur, decay, highpass=False, gain=1.0):
    n = int(dur * SR)
    out = array("f", bytes(4 * n))
    prev = 0.0
    for i in range(n):
        x = random.uniform(-1, 1)
        if highpass:
            x, prev = x - prev, x
        out[i] = x * math.exp(-decay * i / SR) * gain
    return out


def sweep(f0, f1, dur, decay, gain=1.0):
    """Sine with an exponential pitch sweep (kicks, drums, booms)."""
    n = int(dur * SR)
    out = array("f", bytes(4 * n))
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f1 + (f0 - f1) * math.exp(-t * 18.0)
        phase += f * TABLE / SR
        out[i] = SINE[int(phase) & (TABLE - 1)] * math.exp(-decay * t) * gain
    return out


def lowpass(buf, alpha):
    """One-pole low-pass in place (alpha 0..1, lower = darker)."""
    y = 0.0
    for i in range(len(buf)):
        y += alpha * (buf[i] - y)
        buf[i] = y
    return buf


PIANO = [(1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5.02, 0.05)]
HORN = [(1, 1.0), (2, 0.65), (3, 0.42), (4, 0.22), (5, 0.12), (6, 0.06)]
CELLO = [(k, 1.0 / k) for k in range(1, 9)]
BRASS = [(k, 1.0 / k) for k in range(1, 7)]
STRING = [(k, 0.8 / k) for k in range(1, 6)]
CHOIR = [(1, 1.0), (2, 0.3), (3, 0.12)]


def piano(freq, dur, gain=1.0):
    s = additive(freq, dur, PIANO, attack=0.004, release=0.25, decay=1.6)
    if gain != 1.0:
        for i in range(len(s)):
            s[i] *= gain
    return s


def pad_chord(buf, bar, notes, voice, gain, dur_beats=4.0):
    for nm in notes:
        s = voice(hz(nm), dur_beats * BEAT)
        mix(buf, bar * BEATS_PER_BAR * BEAT, s, gain)


def normalise(buf, peak=0.8):
    m = max(1e-9, max(abs(x) for x in buf))
    k = peak / m
    for i in range(len(buf)):
        buf[i] *= k
    return buf


def write_wav(path, buf):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = array("h", [max(-32767, min(32767, int(x * 32767))) for x in buf])
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        if sys.byteorder != "little":
            data.byteswap()
        w.writeframes(data.tobytes())


# ---- Stems -------------------------------------------------------------------------------

def stem_bed():
    buf = blank()
    soft_pad = lambda f, d: additive(f, d, [(1, 1.0), (2, 0.25)], attack=1.2, release=1.6,
                                     detune=[0.997, 1.0, 1.003])
    for bar in range(BARS):
        pad_chord(buf, bar, CHORDS[bar][:3], soft_pad, 0.22, 4.6)
        # A soft piano chord on beat 1 and a single high note on beat 3.
        for nm in CHORDS[bar][2:]:
            mix(buf, bar * 4 * BEAT, piano(hz(nm), 3.0), 0.12)
        mix(buf, (bar * 4 + 2) * BEAT, piano(hz(CHORDS[bar][-1]) * 2.0, 2.0), 0.07)
    # Cavern ambience: dark noise bed and sparse water drips.
    amb = lowpass(noise(LOOP_S, 0.0, gain=0.05), 0.02)
    mix(buf, 0.0, amb, 1.0)
    rnd = random.Random(11)
    for _ in range(14):
        t = rnd.uniform(0, LOOP_S)
        mix(buf, t, sweep(rnd.uniform(1400, 2200), 900, 0.12, 30.0), 0.08)
    return normalise(buf, 0.7)


def stem_pulse():
    buf = blank()
    for b in range(BARS * BEATS_PER_BAR):
        mix(buf, b * BEAT, sweep(90, 48, 0.35, 9.0), 0.8)
        mix(buf, (b + 0.5) * BEAT, noise(0.04, 80.0, highpass=True), 0.12)
    return normalise(buf, 0.7)


def stem_combat():
    buf = blank()
    stacc = lambda f: additive(f, 0.11, STRING, attack=0.004, release=0.05)
    sixteenth = BEAT / 4.0
    for bar in range(BARS):
        root = hz(CHORDS[bar][1])
        fifth = hz(CHORDS[bar][2])
        for k in range(16):
            f = root if k % 4 in (0, 3) else fifth
            if k % 8 == 6:
                f = root * 2.0
            mix(buf, bar * 4 * BEAT + k * sixteenth, stacc(f), 0.32 if k % 4 == 0 else 0.22)
        for b in range(4):
            t = (bar * 4 + b) * BEAT
            mix(buf, t, sweep(140, 45, 0.3, 10.0), 0.9)
            mix(buf, t + BEAT * 0.5, sweep(140, 45, 0.25, 12.0), 0.45)
            if b in (1, 3):
                mix(buf, t, noise(0.18, 22.0), 0.35)
                mix(buf, t, sweep(220, 180, 0.12, 25.0), 0.25)
    # Tom fill in the last bar.
    for k in range(8):
        mix(buf, (31 + k / 8.0) * BEAT, sweep(160 - k * 10, 70, 0.2, 14.0), 0.5)
    return normalise(buf, 0.75)


def stem_elite():
    buf = blank()
    for bar in range(BARS):
        t0 = bar * 4 * BEAT
        for nm in (ROOTS[bar], CHORDS[bar][0]):
            s = additive(hz(nm), 4 * BEAT, BRASS, attack=0.6, release=0.5, vibrato=0.002)
            mix(buf, t0, lowpass(s, 0.25), 0.4)
        for k in range(8):
            f = hz(CHORDS[bar][0]) * (2.0 if k % 2 else 1.0)
            mix(buf, t0 + k * BEAT / 2.0, additive(f, 0.14, CELLO, attack=0.005, release=0.06), 0.22)
    return normalise(buf, 0.75)


def _motif_notes(octave_shift=0):
    for beat, length, nm in MOTIF:
        f = hz(nm) * (2.0 ** octave_shift)
        yield beat * BEAT, length * BEAT, f


def stem_lead_caelan():
    buf = blank()
    for t, d, f in _motif_notes(-1):
        mix(buf, t, additive(f, d * 1.05, HORN, attack=0.09, release=0.15, vibrato=0.003), 0.35)
    strings = lambda f, d: additive(f, d, STRING, attack=0.5, release=0.8, vibrato=0.003, detune=[0.998, 1.002])
    for bar in range(BARS):
        pad_chord(buf, bar, CHORDS[bar][2:4], strings, 0.1, 4.2)
    return normalise(buf, 0.7)


def stem_lead_nyra():
    buf = blank()
    for t, d, f in _motif_notes(0):
        mix(buf, t, pluck(f, 0.6), 0.5)
        mix(buf, t + BEAT * 0.5, pluck(f * 2.0, 0.35, 0.8), 0.25)
    for k in range(BARS * 8):
        mix(buf, k * BEAT / 2.0, noise(0.05, 70.0, highpass=True), 0.18 if k % 2 else 0.1)
    return normalise(buf, 0.7)


def stem_lead_seris():
    buf = blank()
    for t, d, f in _motif_notes(1):
        mix(buf, t, piano(f, d + 1.2), 0.4)
    choir = lambda f, d: additive(f, d, CHOIR, attack=0.7, release=1.0, vibrato=0.004,
                                  detune=[0.995, 1.0, 1.005])
    for bar in range(BARS):
        pad_chord(buf, bar, CHORDS[bar][2:5], choir, 0.1, 4.4)
    return normalise(buf, 0.7)


def stem_lead_darius():
    buf = blank()
    for t, d, f in _motif_notes(-2):
        mix(buf, t, additive(f, d * 1.1, CELLO, attack=0.06, release=0.15, vibrato=0.004), 0.4)
    for bar in range(BARS):
        for b in (0, 2):
            mix(buf, (bar * 4 + b) * BEAT, sweep(75, 38, 0.8, 4.0), 0.8)
    return normalise(buf, 0.7)


def stem_lead_ilyr():
    buf = blank()
    for t, d, f in _motif_notes(0):
        s = piano(f, d * 1.5)
        s.reverse()
        mix(buf, t - (len(s) / SR - d), s, 0.4)
    # 7/8 accent grouping (2+2+3 eighths) running across the 4/4 grid.
    groups = [2, 2, 3]
    eighth = BEAT / 2.0
    k = 0
    g = 0
    while k < BARS * 8:
        mix(buf, k * eighth, sweep(400, 250, 0.08, 30.0), 0.25)
        k += groups[g % 3]
        g += 1
    # Dissonant string ghost: a minor second above the chord root.
    for bar in range(BARS):
        f = hz(CHORDS[bar][2]) * (2.0 ** (1 / 12))
        mix(buf, bar * 4 * BEAT, additive(f, 4 * BEAT, STRING, attack=1.0, release=1.0, vibrato=0.01), 0.07)
    return normalise(buf, 0.7)


# ---- SFX ---------------------------------------------------------------------------------

def sfx_bank():
    s = {}
    # Telegraphs: each under 150 ms (addendum).
    chime = additive(1320.0, 0.14, [(1, 1.0), (2.76, 0.6), (5.4, 0.35), (8.9, 0.2)], attack=0.002, release=0.08,
                     decay=4.0)
    s["telegraph_chime"] = chime
    boom = sweep(110, 42, 0.14, 12.0)
    nz = lowpass(noise(0.14, 25.0), 0.08)
    for i in range(len(boom)):
        boom[i] += nz[i] * 0.6
    s["telegraph_boom"] = boom
    s["telegraph_harmonic"] = additive(880.0, 0.14, [(1, 1.0), (1.5, 0.8), (2.0, 0.4)], attack=0.01, release=0.06,
                                       vibrato=0.02, vib_rate=28.0)
    hit = noise(0.08, 45.0)
    click = sweep(900, 200, 0.08, 40.0)
    for i in range(len(hit)):
        hit[i] = hit[i] * 0.6 + click[i] * 0.7
    s["hit"] = hit
    s["parry"] = additive(1800.0, 0.25, [(1, 1.0), (2.4, 0.5), (4.1, 0.3)], attack=0.001, release=0.15, decay=3.0)
    s["block"] = lowpass(noise(0.1, 35.0), 0.15)
    sw = noise(0.22, 0.0, highpass=True)
    for i in range(len(sw)):
        sw[i] *= math.sin(math.pi * i / len(sw)) * 0.6
    s["swap"] = sw
    s["hurt"] = sweep(300, 110, 0.18, 14.0)
    s["jump"] = lowpass(noise(0.09, 40.0), 0.3)
    s["shockwave"] = sweep(180, 40, 0.45, 5.0)
    s["knives"] = noise(0.12, 30.0, highpass=True)
    s["shadowstep"] = lowpass(noise(0.18, 15.0, highpass=True), 0.5)
    s["vanish"] = additive(600.0, 0.4, [(1, 1.0), (1.01, 1.0)], attack=0.05, release=0.3, vibrato=0.05, vib_rate=9.0)
    s["beam"] = additive(220.0, 0.5, [(1, 1.0), (2, 0.5), (3.01, 0.4)], attack=0.02, release=0.2, vibrato=0.01,
                         vib_rate=40.0)
    s["posture_break"] = sweep(500, 90, 0.35, 7.0)
    s["guard_break"] = sweep(260, 70, 0.3, 8.0)
    s["enemy_death"] = lowpass(noise(0.4, 7.0), 0.12)
    s["ultimate"] = additive(220.0, 0.9, CHOIR + [(4, 0.2)], attack=0.05, release=0.5, vibrato=0.006,
                             detune=[0.99, 1.0, 1.01])
    s["sync_guard"] = additive(660.0, 0.35, [(1, 1.0), (1.5, 0.6)], attack=0.005, release=0.2, decay=2.0)
    s["perfect_dodge"] = additive(1100.0, 0.18, [(1, 1.0), (2, 0.3)], attack=0.003, release=0.1, decay=5.0)
    return s


STEMS = {
    "bed": stem_bed,
    "pulse": stem_pulse,
    "combat": stem_combat,
    "elite": stem_elite,
    "lead_caelan": stem_lead_caelan,
    "lead_nyra": stem_lead_nyra,
    "lead_seris": stem_lead_seris,
    "lead_darius": stem_lead_darius,
    "lead_ilyr": stem_lead_ilyr,
}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default="assets/audio")
    ap.add_argument("--only", default="", help="comma list of stem or sfx names")
    args = ap.parse_args()
    only = set(x for x in args.only.split(",") if x)
    random.seed(1234)
    music_dir = os.path.join(args.out, "music", "zone1")
    for name, fn in STEMS.items():
        if only and name not in only:
            continue
        buf = fn()
        assert len(buf) == N, (name, len(buf), N)
        write_wav(os.path.join(music_dir, name + ".wav"), buf)
        print("stem %-12s %d frames  %.3f s" % (name, len(buf), len(buf) / SR))
    for name, buf in sfx_bank().items():
        if only and name not in only:
            continue
        normalise(buf, 0.85)
        write_wav(os.path.join(args.out, "sfx", name + ".wav"), buf)
        print("sfx  %-18s %.3f s" % (name, len(buf) / SR))


if __name__ == "__main__":
    main()
