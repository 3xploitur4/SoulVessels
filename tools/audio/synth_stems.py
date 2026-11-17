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
# Pulses per beat: 2 eighths in 4/4, 3 eighths per dotted quarter in 6/8.
SUBDIV = 2
# Semitones the leitmotif is moved for this track's key (0 = A minor).
MOTIF_SHIFT = 0


def configure(bpm, beats_per_bar, bars, subdiv, chords, roots, motif, motif_shift=0):
    """Switch the module to another track's meter, harmony and motif (stems read these globals)."""
    global BPM, BEAT, BARS, BEATS_PER_BAR, LOOP_S, N, SUBDIV, CHORDS, ROOTS, MOTIF, MOTIF_SHIFT
    BPM = float(bpm)
    BEAT = 60.0 / BPM
    BARS = bars
    BEATS_PER_BAR = beats_per_bar
    LOOP_S = BARS * BEATS_PER_BAR * BEAT
    N = int(round(LOOP_S * SR))
    SUBDIV = subdiv
    CHORDS = chords
    ROOTS = roots
    MOTIF = motif
    MOTIF_SHIFT = motif_shift

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
        f = hz(nm) * (2.0 ** octave_shift) * (2.0 ** (MOTIF_SHIFT / 12.0))
        yield beat * BEAT, length * BEAT, f


def stem_lead_caelan():
    buf = blank()
    for t, d, f in _motif_notes(-1):
        mix(buf, t, additive(f, d * 1.05, HORN, attack=0.09, release=0.15, vibrato=0.003), 0.35)
    strings = lambda f, d: additive(f, d, STRING, attack=0.5, release=0.8, vibrato=0.003, detune=[0.998, 1.002])
    for bar in range(BARS):
        pad_chord(buf, bar, CHORDS[bar][2:4], strings, 0.1, BEATS_PER_BAR + 0.2)
    return normalise(buf, 0.7)


def stem_lead_nyra():
    buf = blank()
    for t, d, f in _motif_notes(0):
        mix(buf, t, pluck(f, 0.6), 0.5)
        mix(buf, t + BEAT * (1.0 / SUBDIV) * (SUBDIV // 2 if SUBDIV > 2 else 1), pluck(f * 2.0, 0.35, 0.8), 0.25)
    for k in range(BARS * BEATS_PER_BAR * SUBDIV):
        mix(buf, k * BEAT / SUBDIV, noise(0.05, 70.0, highpass=True), 0.18 if k % SUBDIV else 0.1)
    return normalise(buf, 0.7)


def stem_lead_seris():
    buf = blank()
    for t, d, f in _motif_notes(1):
        mix(buf, t, piano(f, d + 1.2), 0.4)
    choir = lambda f, d: additive(f, d, CHOIR, attack=0.7, release=1.0, vibrato=0.004,
                                  detune=[0.995, 1.0, 1.005])
    for bar in range(BARS):
        pad_chord(buf, bar, CHORDS[bar][2:5], choir, 0.1, BEATS_PER_BAR + 0.4)
    return normalise(buf, 0.7)


def stem_lead_darius():
    buf = blank()
    for t, d, f in _motif_notes(-2):
        mix(buf, t, additive(f, d * 1.1, CELLO, attack=0.06, release=0.15, vibrato=0.004), 0.4)
    for bar in range(BARS):
        for b in range(0, BEATS_PER_BAR, 2 if BEATS_PER_BAR % 2 == 0 and BEATS_PER_BAR > 2 else 1):
            mix(buf, (bar * BEATS_PER_BAR + b) * BEAT, sweep(75, 38, 0.8, 4.0), 0.8)
    return normalise(buf, 0.7)


def stem_lead_ilyr():
    buf = blank()
    for t, d, f in _motif_notes(0):
        s = piano(f, d * 1.5)
        s.reverse()
        mix(buf, t - (len(s) / SR - d), s, 0.4)
    # 7/8 accent grouping (2+2+3 eighths) running across the 4/4 grid.
    groups = [2, 2, 3]
    eighth = BEAT / SUBDIV
    k = 0
    g = 0
    while k < BARS * BEATS_PER_BAR * SUBDIV:
        mix(buf, k * eighth, sweep(400, 250, 0.08, 30.0), 0.25)
        k += groups[g % 3]
        g += 1
    # Dissonant string ghost: a minor second above the chord root.
    for bar in range(BARS):
        f = hz(CHORDS[bar][2]) * (2.0 ** (1 / 12))
        mix(buf, bar * BEATS_PER_BAR * BEAT, additive(f, BEATS_PER_BAR * BEAT, STRING, attack=1.0, release=1.0, vibrato=0.01), 0.07)
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
    # M2 (stories 017-023).
    s["pickup"] = additive(1480.0, 0.16, [(1, 1.0), (1.5, 0.5), (2, 0.25)], attack=0.002, release=0.1, decay=6.0)
    s["altar_kindle"] = additive(330.0, 1.2, PIANO + [(3.01, 0.2)], attack=0.01, release=0.8, decay=1.2)
    s["echo_recover"] = additive(880.0, 0.6, [(1, 1.0), (1.25, 0.6), (1.5, 0.5)], attack=0.01, release=0.4, decay=2.5)
    s["bounce"] = sweep(180, 520, 0.22, 6.0)
    s["wall_jump"] = lowpass(noise(0.07, 50.0), 0.35)
    s["spore"] = lowpass(noise(0.3, 9.0, highpass=True), 0.4)
    s["root_snare"] = sweep(140, 70, 0.35, 6.0)
    s["root_break"] = lowpass(noise(0.2, 18.0), 0.2)
    s["gate_open"] = sweep(70, 160, 0.7, 2.5)
    s["ward_hum"] = additive(196.0, 0.5, [(1, 1.0), (2, 0.6), (3, 0.3)], attack=0.05, release=0.2, vibrato=0.01,
                             vib_rate=12.0)
    # M3 (story 030): Seris.
    s["bolt"] = additive(1320.0, 0.22, [(1, 1.0), (1.5, 0.5), (2.01, 0.35)], attack=0.004, release=0.12, decay=6.0,
                         vibrato=0.02, vib_rate=30.0)
    fr = noise(0.5, 6.0, highpass=True)
    tone = additive(1760.0, 0.5, [(1, 1.0), (2.76, 0.4)], attack=0.01, release=0.3, decay=4.0)
    for i in range(len(fr)):
        fr[i] = fr[i] * 0.35 + tone[i] * 0.6
    s["frost"] = fr
    s["shield"] = additive(440.0, 0.45, [(1, 1.0), (1.5, 0.7), (2, 0.5), (3, 0.25)], attack=0.03, release=0.3,
                           vibrato=0.01, vib_rate=7.0)
    sp = lowpass(noise(0.45, 7.0), 0.25)
    blip = sweep(420, 160, 0.45, 9.0)
    for i in range(len(sp)):
        sp[i] = sp[i] * 0.8 + blip[i] * 0.3
    s["splash"] = sp
    s["rune_lit"] = additive(990.0, 0.6, [(1, 1.0), (1.5, 0.6), (2.0, 0.4), (3.0, 0.2)], attack=0.01, release=0.4,
                             decay=2.5)
    s["rune_wrong"] = additive(185.0, 0.45, [(1, 1.0), (1.06, 0.8), (2.0, 0.3)], attack=0.005, release=0.25, decay=4.0)
    return s


# ---- Zone 2: "Track 03 - Spore Light", 84 BPM in 6/8 (decision D-031) ---------------------
# The beat is the dotted quarter (2 per bar, 3 eighths each), so the director's 4-bar boundary is
# 8 beats = 5.71 s. D minor, the same falling cadence as Zone 1 a fourth up (Dm | C | Bb | A, two
# bars each), so the leitmotif sits over the harmony it was written for.

Z2_CHORDS = ([["D2", "A2", "D3", "F3", "A3"]] * 2 + [["C2", "G2", "C3", "E3", "G3"]] * 2 +
             [["Bb1", "F2", "Bb2", "D3", "F3"]] * 2 + [["A1", "E2", "A2", "C#3", "E3"]] * 2) * 2
Z2_ROOTS = (["D2"] * 2 + ["C2"] * 2 + ["Bb1"] * 2 + ["A1"] * 2) * 2


def z2_bed():
    buf = blank()
    pad = lambda f, d: additive(f, d, [(1, 1.0), (2, 0.3), (3, 0.1)], attack=0.9, release=1.4,
                                detune=[0.996, 1.0, 1.004])
    eighth = BEAT / SUBDIV
    pattern = [2, 4, 3, 4, 2, 4]
    for bar in range(BARS):
        if bar % 2 == 0:
            pad_chord(buf, bar, CHORDS[bar][1:4], pad, 0.2, 2 * BEATS_PER_BAR + 0.3)
        # The lilting 6/8 piano arpeggio of the glowing forest.
        for k in range(BEATS_PER_BAR * SUBDIV):
            nm = CHORDS[bar][pattern[k % len(pattern)]]
            mix(buf, bar * BEATS_PER_BAR * BEAT + k * eighth, piano(hz(nm) * 2.0, 0.9), 0.1 if k == 0 else 0.065)
    # Spores: soft high blips drifting through.
    rnd = random.Random(23)
    for _ in range(26):
        t = rnd.uniform(0, LOOP_S)
        f = hz(rnd.choice(["D6", "A6", "F6", "E6", "C6"]))
        mix(buf, t, additive(f, 0.5, [(1, 1.0), (3, 0.1)], attack=0.01, release=0.4, decay=4.0), 0.05)
    mix(buf, 0.0, lowpass(noise(LOOP_S, 0.0, gain=0.04), 0.03), 1.0)
    return normalise(buf, 0.7)


def z2_pulse():
    buf = blank()
    eighth = BEAT / SUBDIV
    for b in range(BARS * BEATS_PER_BAR):
        mix(buf, b * BEAT, sweep(85, 45, 0.35, 9.0), 0.8)
        for k in range(1, SUBDIV):
            mix(buf, b * BEAT + k * eighth, noise(0.04, 80.0, highpass=True), 0.1)
    return normalise(buf, 0.7)


def z2_combat():
    buf = blank()
    eighth = BEAT / SUBDIV
    stacc = lambda f: additive(f, 0.12, STRING, attack=0.004, release=0.05)
    for bar in range(BARS):
        t0 = bar * BEATS_PER_BAR * BEAT
        root = hz(CHORDS[bar][1])
        fifth = hz(CHORDS[bar][2])
        for k in range(BEATS_PER_BAR * SUBDIV):
            f = [root, fifth, root * 2.0][k % 3]
            mix(buf, t0 + k * eighth, stacc(f), 0.32 if k % 3 == 0 else 0.22)
        for b in range(BEATS_PER_BAR):
            t = t0 + b * BEAT
            mix(buf, t, sweep(140, 45, 0.3, 10.0), 0.9)
            if b == 1:
                mix(buf, t, noise(0.18, 22.0), 0.35)
            mix(buf, t + 2 * eighth, sweep(140, 45, 0.2, 12.0), 0.35)
    for k in range(6):
        mix(buf, LOOP_S - BEAT * 2 + k * eighth, sweep(160 - k * 12, 70, 0.2, 14.0), 0.5)
    return normalise(buf, 0.75)


def z2_elite():
    buf = blank()
    eighth = BEAT / SUBDIV
    for bar in range(0, BARS, 2):
        t0 = bar * BEATS_PER_BAR * BEAT
        for nm in (ROOTS[bar], CHORDS[bar][0]):
            s = additive(hz(nm), 2 * BEATS_PER_BAR * BEAT, BRASS, attack=0.6, release=0.5, vibrato=0.002)
            mix(buf, t0, lowpass(s, 0.25), 0.4)
    for k in range(BARS * BEATS_PER_BAR * SUBDIV):
        bar = k // (BEATS_PER_BAR * SUBDIV)
        f = hz(CHORDS[bar][0]) * (2.0 if k % 2 else 1.0)
        mix(buf, k * eighth, additive(f, 0.14, CELLO, attack=0.005, release=0.06), 0.2)
    return normalise(buf, 0.75)


# ---- Title and altars: "Track 02 - The Intruder", solo piano, 60 BPM 3/4 --------------------
# The leitmotif bare: the right hand plays the first 24 notes of the motif, one per beat; the
# left hand a slow waltz (bass on 1, chord on 2 and 3) under Am | F | C | E.

ALTAR_CHORDS = [["A2", "E3", "A3", "C4", "E4"], ["F2", "C3", "F3", "A3", "C4"],
                ["C3", "G3", "C4", "E4", "G4"], ["E2", "B2", "E3", "G#3", "B3"]] * 2


def altar_bed():
    buf = blank()
    melody = [nm for _b, _l, nm in MOTIF][:BARS * BEATS_PER_BAR]
    for i, nm in enumerate(melody):
        mix(buf, i * BEAT, piano(hz(nm), 1.6), 0.32)
    for bar in range(BARS):
        t0 = bar * BEATS_PER_BAR * BEAT
        mix(buf, t0, piano(hz(CHORDS[bar][0]), 2.6), 0.28)
        for b in (1, 2):
            for nm in CHORDS[bar][2:4]:
                mix(buf, t0 + b * BEAT, piano(hz(nm), 0.9), 0.1)
    mix(buf, 0.0, lowpass(noise(LOOP_S, 0.0, gain=0.02), 0.02), 1.0)
    return normalise(buf, 0.7)


# ---- Zone 3: "Track 05 - Drowned Court", 72 BPM 4/4 (story 035) -------------------------
# E minor, drowned and stately: the zone 1 stems played over this harmony and tempo, with the
# motif up a fifth. Real recordings replace these files by name (decision D-006).
Z3_CHORDS = [["E2", "B2", "E3", "G3", "B3"], ["C2", "G2", "C3", "E3", "B3"],
             ["A1", "E2", "A2", "C3", "E3"], ["B1", "F#2", "B2", "D#3", "F#3"]] * 2
Z3_ROOTS = ["E1", "C1", "A1", "B1"] * 2


# ---- Boss 1: "Track 08 - Tears of the Sovereign", 76 BPM, three phase clips (story 035) -----
# One clip per phase, all the same 8-bar length so the director swaps them on a 4-bar boundary:
# p1 a solo cello over a held drone; p2 strings and choir; p3 the same harmony in double time
# (the 152 BPM feel: sixteenth-note strings and driving drums).

def boss_p1():
    buf = blank()
    for bar in range(BARS):
        mix(buf, bar * 4 * BEAT, lowpass(additive(hz(ROOTS[bar]), 4.2 * BEAT, CELLO, attack=0.8, release=0.8), 0.2), 0.25)
    for start, length, f in _motif_notes(-1):
        s = additive(f, length * 1.9, CELLO, attack=0.12, release=0.35, vibrato=0.006, vib_rate=5.5)
        mix(buf, start * 2.0 % LOOP_S, s, 0.5)
    return normalise(buf, 0.72)


def boss_p2():
    buf = blank()
    for bar in range(BARS):
        pad_chord(buf, bar, CHORDS[bar][:4], lambda f, d: additive(f, d, STRING, attack=0.5, release=0.6,
                                                                  vibrato=0.004), 0.16, 4.2)
        pad_chord(buf, bar, CHORDS[bar][2:], lambda f, d: additive(f * 2.0, d, CHOIR, attack=0.7, release=0.8,
                                                                  detune=[0.995, 1.0, 1.005]), 0.12, 4.2)
        mix(buf, bar * 4 * BEAT, sweep(110, 42, 0.5, 6.0), 0.6)
    for start, length, f in _motif_notes(0):
        mix(buf, start, additive(f, length, CELLO, attack=0.05, release=0.2, vibrato=0.005), 0.32)
    return normalise(buf, 0.75)


def boss_p3():
    buf = blank()
    sixteenth = BEAT / 4.0
    stacc = lambda f: additive(f, 0.09, STRING, attack=0.003, release=0.04)
    for bar in range(BARS):
        root = hz(CHORDS[bar][1])
        for k in range(16):
            f = root * (2.0 if k % 4 == 2 else 1.0)
            mix(buf, bar * 4 * BEAT + k * sixteenth, stacc(f), 0.3 if k % 4 == 0 else 0.2)
        pad_chord(buf, bar, CHORDS[bar][2:], lambda f, d: additive(f * 2.0, d, CHOIR, attack=0.2, release=0.4), 0.13, 4.0)
        for b in range(8):
            t0 = (bar * 4 + b * 0.5) * BEAT
            mix(buf, t0, sweep(150, 45, 0.22, 12.0), 0.7)
            if b % 2 == 1:
                mix(buf, t0, noise(0.12, 28.0), 0.3)
    for start, length, f in _motif_notes(0):
        mix(buf, start, additive(f, length * 0.5, BRASS, attack=0.02, release=0.1), 0.28)
    return normalise(buf, 0.78)


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
    ap.add_argument("--only", default="", help="comma list: stem or sfx names, track names, or track/stem")
    args = ap.parse_args()
    only = set(x for x in args.only.split(",") if x)
    random.seed(1234)
    zone1 = (BPM, BEATS_PER_BAR, BARS, SUBDIV, CHORDS, ROOTS, MOTIF, 0)
    z2_leads = {k: v for k, v in STEMS.items() if k.startswith("lead_")}
    tracks = [
        ("zone1", zone1, STEMS),
        ("zone2", (84, 2, 16, 3, Z2_CHORDS, Z2_ROOTS, MOTIF, 5),
         dict({"bed": z2_bed, "pulse": z2_pulse, "combat": z2_combat, "elite": z2_elite}, **z2_leads)),
        ("altar", (60, 3, 8, 2, ALTAR_CHORDS, ["A1", "F1", "C2", "E1"] * 2, MOTIF, 0), {"bed": altar_bed}),
        ("zone3", (72, 4, 8, 2, Z3_CHORDS, Z3_ROOTS, MOTIF, 7), dict(STEMS)),
        ("boss_sovereign", (76, 4, 8, 2, Z3_CHORDS, Z3_ROOTS, MOTIF, 7), {"p1": boss_p1, "p2": boss_p2, "p3": boss_p3}),
    ]
    for track, cfg, stems in tracks:
        configure(*cfg)
        music_dir = os.path.join(args.out, "music", track)
        for name, fn in stems.items():
            if only and name not in only and "%s/%s" % (track, name) not in only and track not in only:
                continue
            buf = fn()
            assert len(buf) == N, (track, name, len(buf), N)
            write_wav(os.path.join(music_dir, name + ".wav"), buf)
            print("%-6s stem %-12s %d frames  %.3f s" % (track, name, len(buf), len(buf) / SR))
    configure(*zone1)
    for name, buf in sfx_bank().items():
        if only and name not in only:
            continue
        normalise(buf, 0.85)
        write_wav(os.path.join(args.out, "sfx", name + ".wav"), buf)
        print("sfx  %-18s %.3f s" % (name, len(buf) / SR))


if __name__ == "__main__":
    main()
