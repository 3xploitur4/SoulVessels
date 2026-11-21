#!/usr/bin/env python3
"""Sound v2 for Soul Vessels (story 055, decision D-065): the user's style, original material.

The user's references are lo-fi indie (warbly tape, chorused keys and guitar, soft drums, hazy and
melancholy) and dark rage / trap (808 slides, rolling hi-hats, bell synths). The score keeps the
game's dark keys and leitmotif and splits the two moods by state:

  bed     explore   lo-fi: wobbly electric piano, chorused guitar, round bass, soft drums, vinyl
  pulse   alert     trap ground: 808 bass sliding on the roots, a kick
  combat  fight     trap drums: rolling hats, claps, kick pattern, a riser every 4 bars
  elite   elites    rage: a bright detuned bell synth arp, saturated
  boss p1-p3        rage escalating: 808s and bells, then trap drums, then everything driven

Also (story 060) the murmured voices under a conversation's text, and the SFX the user asked for (a new jump, sword slashes, hits, kills, footsteps, landings,
dodges) and the exploration ambience: a loop per zone theme plus one-shots (a distant bell,
chains, drips, wind, falling stones, a far choir, a wooden creak).

Pure standard library, built on tools/audio/synth_stems.py's helpers; writes 22.05 kHz mono WAVs
under the same stem names, so nothing else changes. The leitmotif lead stems are untouched.

Usage: bash tools/python.sh tools/audio/synth_v2.py [--only name,track,...]
"""
import argparse
import math
import os
import random
import sys
from array import array

sys.path.insert(0, os.path.dirname(__file__))
import synth_stems as S  # noqa: E402

SR = S.SR


# ---- Tools ---------------------------------------------------------------------------------

def buf_of(n):
    return array("f", bytes(4 * n))


def sat(buf, drive):
    """tanh saturation in place (warmth at 1-2, rage distortion at 4+)."""
    k = 1.0 / math.tanh(drive)
    for i in range(len(buf)):
        buf[i] = math.tanh(buf[i] * drive) * k
    return buf


def scale(buf, g):
    for i in range(len(buf)):
        buf[i] *= g
    return buf


def bandsweep(src, f0, f1, q=0.7):
    """A resonant band-pass (state-variable filter) whose centre sweeps f0 -> f1 (whooshes)."""
    n = len(src)
    out = buf_of(n)
    low = band = 0.0
    damp = 1.0 / max(q, 0.1)
    for i in range(n):
        t = i / max(n - 1, 1)
        fc = f0 * ((f1 / f0) ** t)
        f = 2.0 * math.sin(math.pi * min(fc, SR * 0.2) / SR)
        high = src[i] - low - damp * band
        band += f * high
        low += f * band
        out[i] = band
    return out


def env_shape(buf, attack_share):
    """Rise over `attack_share` of the sound, then fall (whooshes swell and pass)."""
    n = len(buf)
    a = max(1, int(n * attack_share))
    for i in range(n):
        e = i / a if i < a else max(0.0, (n - i) / max(n - a, 1))
        buf[i] *= e * e
    return buf


def tape(buf, depth_ms=1.6, flutter_ms=0.12):
    """Wow and flutter: a slowly wandering read position, as off an old cassette. The rates fit
    whole cycles into the loop so the stem still loops cleanly."""
    n = len(buf)
    loop_s = n / SR
    wow = max(1, round(loop_s * 0.45)) / loop_s
    flt = max(1, round(loop_s * 6.5)) / loop_s
    out = buf_of(n)
    d0 = depth_ms * SR / 1000.0
    d1 = flutter_ms * SR / 1000.0
    for i in range(n):
        t = i / SR
        d = d0 * (1.0 + math.sin(2 * math.pi * wow * t)) + d1 * math.sin(2 * math.pi * flt * t)
        pos = i - d
        j = math.floor(pos)
        fr = pos - j
        out[i] = buf[j % n] * (1.0 - fr) + buf[(j + 1) % n] * fr
    return out


def crackle(dur, density, gain):
    """Vinyl: soft hiss and sparse clicks."""
    n = int(dur * SR)
    out = buf_of(n)
    prev = 0.0
    for i in range(n):
        x = random.uniform(-1, 1) * 0.08
        if random.random() < density / SR:
            x += random.choice((-1, 1)) * random.uniform(0.4, 1.0)
        x, prev = x - prev * 0.6, x
        out[i] = x * gain
    return out


def bar_s():
    return S.BEATS_PER_BAR * S.BEAT


def chord(bar):
    return S.CHORDS[bar % len(S.CHORDS)]


def root(bar):
    return S.ROOTS[bar % len(S.ROOTS)]


# ---- Instruments ----------------------------------------------------------------------------

EPIANO = [(1, 1.0), (2, 0.3), (3, 0.09), (4, 0.04)]


def epiano(f, dur):
    """A warm electric piano: soft partials and a bell-like tine that fades fast."""
    s = S.additive(f, dur, EPIANO, attack=0.004, release=0.35, decay=1.0, detune=[0.997, 1.003])
    tine = S.additive(f * 7.02, min(dur, 0.25), [(1, 0.06)], attack=0.001, release=0.1, decay=14.0)
    for i in range(len(tine)):
        s[i] += tine[i]
    # Tremolo, as on a suitcase piano.
    for i in range(len(s)):
        s[i] *= 0.85 + 0.15 * math.sin(2 * math.pi * 4.2 * i / SR)
    return s


def chorus_pluck(f, dur):
    """A clean guitar note doubled slightly out of tune (chorus)."""
    a = S.pluck(f, dur, 0.4)
    b = S.pluck(f * 1.004, dur, 0.4)
    d = int(0.011 * SR)
    for i in range(len(a)):
        a[i] = a[i] * 0.6 + (b[i - d] if i >= d else 0.0) * 0.5
    return S.lowpass(a, 0.35)


def round_bass(f, dur):
    return S.additive(f, dur, [(1, 1.0), (2, 0.25)], attack=0.01, release=0.15, decay=1.2)


def kick_soft():
    return S.sweep(95, 48, 0.3, 11.0)


def snare_brush():
    nz = S.lowpass(S.noise(0.22, 16.0), 0.35)
    tone = S.sweep(210, 180, 0.08, 30.0)
    for i in range(len(tone)):
        nz[i] += tone[i] * 0.3
    return nz


def hat_soft():
    return S.noise(0.035, 120.0, highpass=True, gain=0.5)


def b808(f, dur, slide_from=None, drive=1.6):
    """An 808: a sine bass with a punchy start, a long tail and an optional slide up to `f`."""
    n = int(dur * SR)
    out = buf_of(n)
    phase = 0.0
    f0 = slide_from or f
    for i in range(n):
        t = i / SR
        ff = f + (f0 - f) * math.exp(-t / 0.05) if slide_from else f * (1.0 + 0.6 * math.exp(-t * 40.0))
        phase += ff * S.TABLE / SR
        e = min(1.0, t / 0.004) * math.exp(-t * (1.6 / max(dur, 0.2)))
        out[i] = S.SINE[int(phase) & (S.TABLE - 1)] * e
    return sat(out, drive)


def kick_trap():
    k = S.sweep(170, 46, 0.32, 9.0)
    click = S.noise(0.01, 300.0, highpass=True, gain=0.6)
    for i in range(len(click)):
        k[i] += click[i]
    return sat(k, 1.5)


def clap():
    out = buf_of(int(0.32 * SR))
    for off in (0.0, 0.011, 0.023):
        burst = S.lowpass(S.noise(0.3 - off, 24.0, highpass=True), 0.5)
        S_i = int(off * SR)
        for i in range(len(burst)):
            if S_i + i < len(out):
                out[S_i + i] += burst[i] * (0.6 if off < 0.02 else 1.0)
    return out


def hat_trap(open_hat=False):
    return S.noise(0.16 if open_hat else 0.03, 18.0 if open_hat else 160.0, highpass=True, gain=0.7)


RAGE = [(k, 1.0 / k) for k in range(1, 9)]


def rage_bell(f, dur):
    """The rage lead: a detuned saw with a bell attack, pushed into distortion."""
    s = S.additive(f, dur, RAGE, attack=0.002, release=0.08, decay=2.2, detune=[0.991, 1.0, 1.009])
    b = S.additive(f * 2.0, dur, [(1, 0.5), (2.76, 0.25)], attack=0.001, release=0.05, decay=7.0)
    for i in range(len(s)):
        s[i] += b[i]
    return sat(s, 2.6)


def church_bell(f, dur):
    return S.additive(f, dur, [(0.5, 0.6), (1, 1.0), (1.19, 0.6), (1.56, 0.45), (2.0, 0.4), (2.51, 0.25), (3.01, 0.18)],
                      attack=0.002, release=0.6, decay=0.9)


def choir_pad(f, dur):
    return S.additive(f, dur, S.CHOIR, attack=0.6, release=0.8, vibrato=0.004, vib_rate=5.0, detune=[0.995, 1.0, 1.005])


# ---- Zone stems -----------------------------------------------------------------------------

def lofi_bed():
    buf = S.blank()
    bs = bar_s()
    beat = S.BEAT
    for bar in range(S.BARS):
        t0 = bar * bs
        notes = chord(bar)[1:5]
        # Keys: a strummed chord on the one, a softer stab on the "and" of two.
        for k, nm in enumerate(notes):
            S.mix(buf, t0 + k * 0.022, epiano(S.hz(nm), bs * 0.95), 0.16)
        if S.BEATS_PER_BAR >= 3:
            for k, nm in enumerate(notes[1:]):
                S.mix(buf, t0 + 1.5 * beat + k * 0.018, epiano(S.hz(nm), beat * 1.2), 0.07)
        # Chorused guitar picking the chord every other bar, an octave up.
        if bar % 2 == 1:
            pick = [notes[0], notes[2], notes[1], notes[3], notes[2], notes[1]]
            step = bs / len(pick)
            for k, nm in enumerate(pick):
                S.mix(buf, t0 + k * step, chorus_pluck(S.hz(nm) * 2.0, step * 2.2), 0.13)
        # Round bass on the one and the "and" of two.
        S.mix(buf, t0, round_bass(S.hz(root(bar)) * 2.0, beat * 1.4), 0.3)
        if S.BEATS_PER_BAR >= 3:
            S.mix(buf, t0 + 1.5 * beat, round_bass(S.hz(root(bar)) * 2.0, beat * 0.8), 0.18)
        # Soft drums with a little swing.
        S.mix(buf, t0, kick_soft(), 0.32)
        if S.BEATS_PER_BAR >= 4:
            S.mix(buf, t0 + 2.5 * beat, kick_soft(), 0.22)
            for b in (1, 3):
                S.mix(buf, t0 + b * beat, snare_brush(), 0.16)
        else:
            S.mix(buf, t0 + (S.BEATS_PER_BAR - 1) * beat, snare_brush(), 0.16)
        for e in range(S.BEATS_PER_BAR * 2):
            swing = 0.06 * beat if e % 2 else 0.0
            S.mix(buf, t0 + e * beat * 0.5 + swing, hat_soft(), 0.06 if e % 2 else 0.09)
    S.mix(buf, 0.0, crackle(S.LOOP_S, 6.0, 0.05), 1.0)
    S.mix(buf, 0.0, S.lowpass(S.noise(S.LOOP_S, 0.0, gain=0.035), 0.02), 1.0)
    buf = tape(S.lowpass(buf, 0.55))
    # Glue: a soft saturation lifts the quiet keys up to the drums, as tape compression would.
    return S.normalise(sat(S.normalise(buf, 1.0), 2.2), 0.7)


def trap_pulse():
    buf = S.blank()
    bs = bar_s()
    beat = S.BEAT
    prev = None
    for bar in range(S.BARS):
        t0 = bar * bs
        f = S.hz(root(bar)) * 2.0
        S.mix(buf, t0, b808(f, bs * 0.75, slide_from=prev), 0.55)
        if S.BEATS_PER_BAR >= 4:
            S.mix(buf, t0 + 2.75 * beat, b808(f * (1.5 if bar % 2 else 1.0), beat * 1.1), 0.4)
        prev = f
        S.mix(buf, t0, kick_trap(), 0.6)
        if S.BEATS_PER_BAR >= 4:
            S.mix(buf, t0 + 2.5 * beat, kick_trap(), 0.45)
    return S.normalise(buf, 0.72)


def trap_combat():
    buf = S.blank()
    bs = bar_s()
    beat = S.BEAT
    for bar in range(S.BARS):
        t0 = bar * bs
        # Claps on the backbeat (half time: the trap pocket at double the tempo).
        if S.BEATS_PER_BAR >= 4:
            for b in (1, 3):
                S.mix(buf, t0 + b * beat, clap(), 0.42)
        else:
            S.mix(buf, t0 + (S.BEATS_PER_BAR - 1) * beat, clap(), 0.42)
        # Hats in sixteenths; every second bar ends on a roll (thirty-seconds, then triplets).
        steps = S.BEATS_PER_BAR * 4
        for k in range(steps):
            t = t0 + k * beat / 4.0
            roll = bar % 2 == 1 and k >= steps - 4
            if roll:
                for r in range(3 if k % 2 else 2):
                    S.mix(buf, t + r * beat / (12.0 if k % 2 else 8.0), hat_trap(), 0.2)
            else:
                S.mix(buf, t, hat_trap(), 0.24 if k % 2 == 0 else 0.14)
        if bar % 4 == 2:
            S.mix(buf, t0 + bs - beat * 0.5, hat_trap(True), 0.22)
        # Extra kicks that push the groove.
        for b in (0.0, 0.75, 2.25) if S.BEATS_PER_BAR >= 4 else (0.0,):
            S.mix(buf, t0 + b * beat, kick_trap(), 0.55)
        # A reversed swell into every fourth bar.
        if bar % 4 == 3:
            sw = env_shape(bandsweep(S.noise(bs * 0.6, 0.0), 400.0, 5000.0, 1.2), 0.95)
            S.mix(buf, t0 + bs * 0.4, sw, 0.5)
    return S.normalise(sat(S.normalise(buf, 1.0), 2.4), 0.75)


def rage_elite():
    buf = S.blank()
    bs = bar_s()
    for bar in range(S.BARS):
        t0 = bar * bs
        c = chord(bar)
        pattern = [c[2], c[3], c[4], c[3], c[2], c[4], c[3], c[1]]
        step = bs / len(pattern)
        for k, nm in enumerate(pattern):
            S.mix(buf, t0 + k * step, rage_bell(S.hz(nm) * 2.0, step * 1.6), 0.2)
        S.mix(buf, t0, b808(S.hz(root(bar)) * 2.0, bs * 0.5, drive=4.0), 0.25)
    return S.normalise(buf, 0.74)


def lofi_altar():
    """The altar: the lo-fi keys alone, slow, no drums, a rest."""
    buf = S.blank()
    bs = bar_s()
    for bar in range(S.BARS):
        t0 = bar * bs
        for k, nm in enumerate(chord(bar)[1:5]):
            S.mix(buf, t0 + k * 0.035, epiano(S.hz(nm), bs * 1.2), 0.16)
        S.mix(buf, t0 + bs * 0.66, epiano(S.hz(chord(bar)[-1]) * 2.0, bs * 0.6), 0.06)
        S.mix(buf, t0, round_bass(S.hz(root(bar)) * 2.0, bs * 0.9), 0.22)
    S.mix(buf, 0.0, crackle(S.LOOP_S, 5.0, 0.05), 1.0)
    return S.normalise(tape(S.lowpass(buf, 0.5)), 0.68)


# ---- Boss stems: rage, escalating ------------------------------------------------------------

def _boss_core(buf, drive):
    bs = bar_s()
    prev = None
    for bar in range(S.BARS):
        t0 = bar * bs
        f = S.hz(root(bar)) * 2.0
        S.mix(buf, t0, b808(f, bs * 0.9, slide_from=prev, drive=drive), 0.5)
        prev = f
        for nm in chord(bar)[2:5]:
            S.mix(buf, t0, choir_pad(S.hz(nm), bs * 1.05), 0.07)
    for start, length, f in S._motif_notes(0):
        S.mix(buf, start % S.LOOP_S, church_bell(f, length * 2.5), 0.09)


def boss_rage_p1():
    buf = S.blank()
    _boss_core(buf, 1.8)
    for bar in range(S.BARS):
        S.mix(buf, bar * bar_s(), kick_trap(), 0.5)
    return S.normalise(buf, 0.74)


def boss_rage_p2():
    buf = S.blank()
    _boss_core(buf, 2.5)
    S.mix(buf, 0.0, trap_combat(), 0.55)
    return S.normalise(buf, 0.76)


def boss_rage_p3():
    buf = S.blank()
    _boss_core(buf, 4.0)
    S.mix(buf, 0.0, trap_combat(), 0.6)
    S.mix(buf, 0.0, rage_elite(), 0.45)
    for start, length, f in S._motif_notes(0):
        S.mix(buf, start % S.LOOP_S, rage_bell(f, length * 0.9), 0.12)
    return S.normalise(sat(buf, 1.3), 0.78)


# ---- SFX ------------------------------------------------------------------------------------

def _layer(*parts):
    n = max(len(p) + int(off * SR) for p, _, off in parts)
    out = buf_of(n)
    for p, g, off in parts:
        o = int(off * SR)
        for i in range(len(p)):
            if o + i < n:
                out[o + i] += p[i] * g
    return out


def whoosh(dur, f0, f1, q=0.9, attack=0.35):
    return env_shape(bandsweep(S.noise(dur, 0.0), f0, f1, q), attack)


def clink(f, dur=0.12):
    return S.additive(f, dur, [(1, 1.0), (2.76, 0.5), (5.4, 0.25)], attack=0.0005, release=0.05, decay=25.0)


def gravel(dur, gain=1.0):
    return S.lowpass(S.noise(dur, 30.0, gain=gain), 0.25)


def sfx_bank():
    s = {}
    # Movement: armour and cloth, not a beep.
    s["jump"] = _layer((whoosh(0.2, 300, 1200, 0.8, 0.3), 0.7, 0.0), (S.sweep(150, 70, 0.08, 30.0), 0.5, 0.0),
                       (gravel(0.07), 0.5, 0.0), (clink(2900), 0.08, 0.02))
    s["wall_jump"] = _layer((whoosh(0.18, 350, 1300, 0.8, 0.3), 0.6, 0.0), (gravel(0.1), 0.7, 0.0), (clink(2600), 0.08, 0.01))
    s["land"] = _layer((S.sweep(120, 42, 0.22, 14.0), 0.9, 0.0), (gravel(0.14), 0.8, 0.0), (clink(2400), 0.07, 0.01),
                       (clink(3100), 0.05, 0.05))
    s["step"] = _layer((gravel(0.07), 0.8, 0.0), (S.sweep(100, 55, 0.06, 40.0), 0.4, 0.0))
    s["dodge"] = _layer((whoosh(0.26, 250, 900, 0.7, 0.4), 0.8, 0.0), (gravel(0.12), 0.4, 0.05))
    # Steel: a swish through the air with a ring of the blade.
    s["slash"] = _layer((whoosh(0.2, 4200, 700, 1.6, 0.25), 0.9, 0.0), (clink(3600, 0.18), 0.05, 0.02))
    s["slash_heavy"] = _layer((whoosh(0.32, 2600, 300, 1.4, 0.3), 1.0, 0.0), (clink(2200, 0.3), 0.06, 0.04),
                              (S.sweep(90, 50, 0.2, 10.0), 0.3, 0.06))
    # Impacts: a thump, a crunch and a clang of armour.
    s["hit"] = sat(_layer((S.sweep(190, 60, 0.16, 18.0), 0.9, 0.0), (S.noise(0.07, 50.0), 0.6, 0.0),
                          (clink(1900, 0.1), 0.12, 0.0)), 1.8)
    s["kill"] = sat(_layer((S.sweep(170, 38, 0.45, 7.0), 1.0, 0.0), (S.lowpass(S.noise(0.2, 16.0), 0.3), 0.8, 0.0),
                           (clink(1500, 0.2), 0.12, 0.0), (whoosh(0.35, 3000, 300, 1.0, 0.2), 0.4, 0.05)), 2.2)
    # The body burns away into soul-light: a falling breath and a low dark tone.
    dark = S.additive(110.0, 0.9, [(1, 1.0), (1.5, 0.4), (2.01, 0.3)], attack=0.02, release=0.6, decay=2.5,
                      detune=[0.99, 1.0, 1.01])
    s["enemy_death"] = _layer((whoosh(0.8, 2400, 200, 0.8, 0.15), 0.6, 0.0), (dark, 0.5, 0.05), (gravel(0.25), 0.4, 0.0))
    return s


# ---- Voices (story 060): the murmur under a conversation's text ------------------------------

def vowel(f0, dur, formants, breath=0.0, rough=0.0):
    """A sung syllable: harmonics of `f0` weighted by vowel resonances (formants, [(hz, width)]),
    a quick swell and fall, a little breath noise and roughness."""
    partials = []
    k = 1
    while f0 * k < 5000 and k < 40:
        f = f0 * k
        amp = sum(math.exp(-((f - fc) / bw) ** 2) for fc, bw in formants) / k ** 0.6
        if amp > 0.01:
            partials.append((k, amp))
        k += 1
    s = S.additive(f0, dur, partials, attack=0.012, release=dur * 0.6, vibrato=0.01 + rough * 0.04,
                   vib_rate=6.0 + rough * 30.0)
    if breath > 0.0:
        nz = bandsweep(S.noise(dur, 0.0), formants[0][0], formants[-1][0], 1.2)
        env_shape(nz, 0.25)
        for i in range(len(s)):
            s[i] += nz[i] * breath
    return s


def voice_bank():
    v = {}
    v["voice_male"] = vowel(120.0, 0.075, [(650, 160), (1100, 220)], breath=0.15)
    v["voice_female"] = vowel(215.0, 0.07, [(800, 180), (1350, 260)], breath=0.2)
    v["voice_deep"] = sat(vowel(85.0, 0.09, [(500, 150), (900, 200)], breath=0.1, rough=0.4), 1.6)
    v["voice_echo"] = vowel(160.0, 0.11, [(700, 200), (1500, 300)], breath=0.3)
    echo = buf_of(len(v["voice_echo"]) + int(0.09 * SR))
    for i in range(len(v["voice_echo"])):
        echo[i] += v["voice_echo"][i]
        echo[i + int(0.09 * SR)] += v["voice_echo"][i] * 0.4
    v["voice_echo"] = echo
    whisper = bandsweep(S.noise(0.1, 0.0), 1800.0, 900.0, 1.4)
    v["voice_whisper"] = env_shape(whisper, 0.3)
    stone = sat(vowel(55.0, 0.12, [(300, 120), (700, 200)], breath=0.3, rough=1.0), 2.5)
    for i in range(len(stone)):
        stone[i] += random.uniform(-1, 1) * 0.15 * math.exp(-i / SR * 20.0)
    v["voice_stone"] = stone
    v["voice_beast"] = sat(vowel(48.0, 0.16, [(250, 120), (520, 180)], breath=0.5, rough=0.8), 2.2)
    return v


# ---- Ambience --------------------------------------------------------------------------------

AMB_S = 20.0


def _loop_buf():
    return buf_of(int(AMB_S * SR))


def _loop_mix(buf, start_s, samples, gain):
    n = len(buf)
    i0 = int(start_s * SR) % n
    for k in range(len(samples)):
        buf[(i0 + k) % n] += samples[k] * gain


def _wind(buf, gain, rate=0.1):
    n = len(buf)
    cycles = max(1, round(AMB_S * rate))
    nz = S.lowpass(S.noise(AMB_S, 0.0), 0.04)
    for i in range(n):
        t = i / SR
        swell = 0.55 + 0.45 * math.sin(2 * math.pi * cycles * t / AMB_S) * math.sin(2 * math.pi * 3 * t / AMB_S)
        buf[i] += nz[i] * swell * gain


def _rumble(buf, gain):
    nz = S.lowpass(S.lowpass(S.noise(AMB_S, 0.0), 0.006), 0.01)
    for i in range(len(buf)):
        buf[i] += nz[i] * gain


def drip():
    return _layer((S.sweep(2200, 900, 0.09, 35.0), 0.6, 0.0), (S.sweep(1800, 900, 0.07, 45.0), 0.2, 0.12))


def ambience_beds():
    out = {}
    rnd = random.Random(55)
    b = _loop_buf()
    _rumble(b, 3.0)
    _wind(b, 0.5)
    for _ in range(9):
        _loop_mix(b, rnd.uniform(0, AMB_S), drip(), 0.25)
    out["amb_cavern"] = b
    b = _loop_buf()
    _rumble(b, 1.5)
    _wind(b, 0.25)
    for _ in range(14):
        f = rnd.choice([1760.0, 2093.0, 2349.0, 2637.0])
        _loop_mix(b, rnd.uniform(0, AMB_S), S.additive(f, 1.2, [(1, 1.0), (2.01, 0.2)], attack=0.05, release=0.8,
                                                         decay=2.5), 0.05)
    out["amb_forest"] = b
    b = _loop_buf()
    _rumble(b, 2.0)
    lap = S.lowpass(S.noise(AMB_S, 0.0), 0.03)
    for i in range(len(b)):
        b[i] += lap[i] * (0.5 + 0.5 * math.sin(2 * math.pi * 5 * i / SR / AMB_S * 4)) * 0.6
    for _ in range(12):
        _loop_mix(b, rnd.uniform(0, AMB_S), drip(), 0.3)
    out["amb_palace"] = b
    b = _loop_buf()
    _rumble(b, 4.0)
    _wind(b, 0.35)
    for _ in range(160):
        _loop_mix(b, rnd.uniform(0, AMB_S), S.noise(0.004, 600.0, highpass=True), rnd.uniform(0.05, 0.25))
    out["amb_rift"] = b
    b = _loop_buf()
    _rumble(b, 1.5)
    _wind(b, 0.4, 0.15)
    for k in range(3):
        wave = env_shape(S.lowpass(S.noise(5.5, 0.0), 0.05), 0.45)
        _loop_mix(b, k * AMB_S / 3.0, wave, 0.9)
    out["amb_shore"] = b
    for k in out:
        S.normalise(out[k], 0.6)
    return out


def ambience_oneshots():
    s = {}
    bell = S.lowpass(church_bell(196.0, 4.5), 0.25)
    echo = buf_of(len(bell) + int(0.7 * SR))
    for i in range(len(bell)):
        echo[i] += bell[i]
        echo[i + int(0.7 * SR)] += bell[i] * 0.3
    s["amb_bell"] = echo
    s["amb_chain"] = _layer(*[(clink(random.uniform(1300, 2400), 0.15), 0.6, k * random.uniform(0.09, 0.16))
                              for k in range(5)])
    s["amb_drip"] = drip()
    s["amb_wind"] = env_shape(bandsweep(S.noise(3.5, 0.0), 300, 900, 0.6), 0.5)
    s["amb_stones"] = _layer(*[(gravel(random.uniform(0.04, 0.09)), random.uniform(0.3, 0.8), k * random.uniform(0.05, 0.13))
                               for k in range(9)])
    s["amb_choir"] = S.lowpass(_layer(*[(choir_pad(S.hz(n), 3.5), 0.4, 0.0) for n in ("A3", "C4", "E4")]), 0.12)
    creak = buf_of(int(0.9 * SR))
    ph = 0.0
    for i in range(len(creak)):
        t = i / SR
        ph += (90.0 + 30.0 * math.sin(t * 7.0)) * S.TABLE / SR
        creak[i] = S.SINE[int(ph) & (S.TABLE - 1)] * math.sin(math.pi * t / 0.9) * (0.5 + 0.5 * random.random())
    s["amb_creak"] = S.lowpass(sat(creak, 2.0), 0.3)
    return s


# ---- Main -----------------------------------------------------------------------------------

ZONE_TRACKS = {"zone1", "zone2", "zone3", "zone4", "zone4_shore"}
ZONE_STEMS = {"bed": lofi_bed, "pulse": trap_pulse, "combat": trap_combat, "elite": rage_elite}
BOSS_STEMS = {"p1": boss_rage_p1, "p2": boss_rage_p2, "p3": boss_rage_p3}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default="assets/audio")
    ap.add_argument("--only", default="", help="comma list of tracks, track/stem, sfx or ambience names, or 'sfx', 'ambience'")
    args = ap.parse_args()
    only = set(x for x in args.only.split(",") if x)
    random.seed(2055)
    tracks = {
        "zone1": (S.BPM, S.BEATS_PER_BAR, S.BARS, S.SUBDIV, S.CHORDS, S.ROOTS, S.MOTIF, 0),
        "zone2": (84, 2, 16, 3, S.Z2_CHORDS, S.Z2_ROOTS, S.MOTIF, 5),
        "altar": (60, 3, 8, 2, S.ALTAR_CHORDS, ["A1", "F1", "C2", "E1"] * 2, S.MOTIF, 0),
        "zone3": (72, 4, 8, 2, S.Z3_CHORDS, S.Z3_ROOTS, S.MOTIF, 7),
        "boss_sovereign": (76, 4, 8, 2, S.Z3_CHORDS, S.Z3_ROOTS, S.MOTIF, 7),
        "zone4": (66, 4, 8, 2, S.Z4_CHORDS, S.Z4_ROOTS, S.MOTIF, 5),
        "zone4_shore": (60, 4, 8, 2, S.SHORE_CHORDS, S.SHORE_ROOTS, S.MOTIF, 7),
        "boss_guardian": (65, 4, 8, 2, S.Z4_CHORDS, S.Z4_ROOTS, S.MOTIF, 5),
        "boss_leviathan": (96, 5, 8, 2, S.SHORE_CHORDS, S.SHORE_ROOTS, S.MOTIF, 7),
    }
    for track, cfg in tracks.items():
        if track in ZONE_TRACKS:
            stems = ZONE_STEMS
        elif track.startswith("boss_"):
            stems = BOSS_STEMS
        else:
            stems = {"bed": lofi_altar}
        S.configure(*cfg)
        for name, fn in stems.items():
            if only and track not in only and "%s/%s" % (track, name) not in only:
                continue
            buf = fn()
            assert len(buf) == S.N, (track, name, len(buf), S.N)
            S.write_wav(os.path.join(args.out, "music", track, name + ".wav"), buf)
            print("%-15s %-7s %.2f s" % (track, name, len(buf) / SR), flush=True)
    S.configure(*tracks["zone1"])
    if not only or "voices" in only:
        for name, buf in voice_bank().items():
            S.normalise(buf, 0.8)
            S.write_wav(os.path.join(args.out, "sfx", name + ".wav"), buf)
            print("voice %-14s %.2f s" % (name, len(buf) / SR), flush=True)
    if not only or "sfx" in only or any(k in only for k in ("jump", "slash", "hit", "kill")):
        for name, buf in sfx_bank().items():
            S.normalise(buf, 0.85)
            S.write_wav(os.path.join(args.out, "sfx", name + ".wav"), buf)
            print("sfx %-14s %.2f s" % (name, len(buf) / SR), flush=True)
    if not only or "ambience" in only:
        for name, buf in list(ambience_beds().items()) + list(ambience_oneshots().items()):
            S.normalise(buf, 0.7 if not name.startswith("amb_c") else 0.55)
            S.write_wav(os.path.join(args.out, "ambience", name + ".wav"), buf)
            print("amb %-14s %.2f s" % (name, len(buf) / SR), flush=True)


if __name__ == "__main__":
    main()
