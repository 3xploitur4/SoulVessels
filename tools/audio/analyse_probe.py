#!/usr/bin/env python3
"""Read the audio track of a Movie Maker AVI (PCM) and print loudness per half second, plus the
ratio of loudness after vs before an expected change time. Observations only.

Usage: bash tools/python.sh tools/audio/analyse_probe.py <file.avi> [--change 13.714]
"""
import math
import struct
import sys


def read_avi_audio(path):
    data = open(path, "rb").read()
    fmt = None
    chunks = []
    i = 12
    def walk(start, end):
        nonlocal fmt
        j = start
        while j + 8 <= end:
            cid = data[j:j + 4]
            size = struct.unpack("<I", data[j + 4:j + 8])[0]
            body = j + 8
            if cid in (b"LIST", b"RIFF"):
                walk(body + 4, body + size)
            elif cid == b"strf" and fmt is None and size >= 16:
                tag, ch, rate, _br, _al, bits = struct.unpack("<HHIIHH", data[body:body + 16])
                if tag == 1:
                    fmt = (ch, rate, bits)
            elif cid[2:4] == b"wb":
                chunks.append(data[body:body + size])
            j = body + size + (size & 1)
    walk(12, len(data))
    return fmt, b"".join(chunks)


def rms_windows(path):
    fmt, pcm = read_avi_audio(path)
    ch, rate, bits = fmt
    n = len(pcm) // (2 * ch)
    samples = struct.unpack("<%dh" % (n * ch), pcm[: n * ch * 2])
    mono = [samples[k * ch] for k in range(n)]
    win = rate // 2
    return [math.sqrt(sum(x * x for x in mono[w:w + win]) / win) / 32768.0 for w in range(0, n - win, win)]


def compare(path, control, change):
    a = rms_windows(path)
    b = rms_windows(control)
    m = min(len(a), len(b))
    print("  time   probe  control  ratio")
    for k in range(m):
        print("%5.1f s  %.4f  %.4f  %.2f" % (k * 0.5, a[k], b[k], a[k] / b[k] if b[k] else 0.0))
    ci = int(change / 0.5)
    pre = [a[k] / b[k] for k in range(2, ci - 1) if b[k]]
    post = [a[k] / b[k] for k in range(ci + 4, m) if b[k]]
    print("RESULT ratio before change %.2f (should be ~1.00), after change %.2f" % (sum(pre) / len(pre), sum(post) / len(post)))


def main():
    path = sys.argv[1]
    if "--control" in sys.argv:
        change = float(sys.argv[sys.argv.index("--change") + 1]) if "--change" in sys.argv else 13.714
        compare(path, sys.argv[sys.argv.index("--control") + 1], change)
        return 0
    change = float(sys.argv[sys.argv.index("--change") + 1]) if "--change" in sys.argv else 13.714
    fmt, pcm = read_avi_audio(path)
    if fmt is None:
        print("no PCM audio stream found")
        return 2
    ch, rate, bits = fmt
    n = len(pcm) // (2 * ch)
    samples = struct.unpack("<%dh" % (n * ch), pcm[: n * ch * 2])
    mono = [samples[k * ch] for k in range(n)]
    print("audio: %d ch, %d Hz, %d bit, %.2f s" % (ch, rate, bits, n / rate))
    win = rate // 2
    rms = []
    for w in range(0, n - win, win):
        seg = mono[w:w + win]
        rms.append(math.sqrt(sum(x * x for x in seg) / len(seg)) / 32768.0)
    for k, r in enumerate(rms):
        bar = "#" * int(r * 200)
        print("%5.1f s  %.4f  %s" % (k * 0.5, r, bar))
    ci = int(change / 0.5)
    before = rms[max(0, ci - 6):ci - 1]
    after = rms[ci + 2:ci + 8]
    if before and after:
        b = sum(before) / len(before)
        a = sum(after) / len(after)
        print("RESULT before %.4f after %.4f ratio %.2f" % (b, a, a / b if b else float("inf")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
