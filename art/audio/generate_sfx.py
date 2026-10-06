"""Generates the placeholder sound effects in assets/audio/sfx (pure synthesis, no third-party audio).

Run from the repo root: python art/audio/generate_sfx.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.9 * 32767)) for s in samples))


def tone(duration, freq_start, freq_end, decay, harmonics=((1, 1.0),), attack=0.004):
    samples, phase = [], 0.0
    n = int(duration * RATE)
    for i in range(n):
        t = i / RATE
        freq = freq_start + (freq_end - freq_start) * (i / n)
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        samples.append(env * sum(a * math.sin(phase * h) for h, a in harmonics))
    return samples


def mix(*tracks):
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def delayed(samples, seconds):
    return [0.0] * int(seconds * RATE) + samples


random.seed(7)
write("pop.wav", tone(0.09, 520, 980, 38, ((1, 1.0), (2, 0.25))))
write("drop.wav", mix(tone(0.12, 220, 140, 30, ((1, 1.0), (2, 0.4))),
                      [random.uniform(-1, 1) * math.exp(-90 * i / RATE) * 0.3 for i in range(int(0.05 * RATE))]))
write("cash.wav", mix(tone(0.35, 1320, 1320, 9, ((1, 1.0), (2.76, 0.3))),
                      delayed(tone(0.4, 1760, 1760, 8, ((1, 1.0), (2.76, 0.3))), 0.07)))
write("coin.wav", mix(tone(0.18, 1900, 2100, 22, ((1, 1.0), (3, 0.2))),
                      delayed(tone(0.18, 2500, 2700, 22, ((1, 1.0),)), 0.05)))
notes = [523.25, 659.25, 783.99, 1046.5]
write("unlock.wav", mix(*[delayed(tone(0.45, f, f, 6, ((1, 1.0), (2, 0.35), (3, 0.1))), i * 0.09)
                          for i, f in enumerate(notes)]))
print("written to", OUT)
