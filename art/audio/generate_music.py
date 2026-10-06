"""Generates the placeholder cozy music loop (assets/audio/music/farm_loop.wav) by synthesis.

8 bars at 92 bpm, C - Am - F - G: soft plucked arpeggios, a round bass and a quiet pad.
Run from the repo root: python art/audio/generate_music.py
"""

import math
import struct
import wave
from pathlib import Path

RATE = 44100
BPM = 92
BEAT = 60.0 / BPM
BARS = 8
BEATS_PER_BAR = 4
LENGTH = BARS * BEATS_PER_BAR * BEAT
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "music" / "farm_loop.wav"

# (root, chord tones) in Hz, two bars each
C4, D4, E4, F4, G4, A4, B4, C5, D5, E5 = 261.63, 293.66, 329.63, 349.23, 392.0, 440.0, 493.88, 523.25, 587.33, 659.25
PROGRESSION = [
    (130.81, [C4, E4, G4, C5]),
    (110.0, [A4 / 2 * 2, C5, E5, A4]),
    (87.31, [F4, A4, C5, F4 * 2]),
    (98.0, [G4, B4, D5, G4 * 2]),
]


def pluck(freq, start, duration, gain, samples):
    begin = int(start * RATE)
    for i in range(int(duration * RATE)):
        t = i / RATE
        env = min(1.0, t / 0.008) * math.exp(-4.5 * t)
        value = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t)
        index = (begin + i) % len(samples)
        samples[index] += gain * env * value


def pad(freq, start, duration, gain, samples):
    begin = int(start * RATE)
    count = int(duration * RATE)
    for i in range(count):
        t = i / RATE
        env = math.sin(math.pi * i / count)
        index = (begin + i) % len(samples)
        samples[index] += gain * env * math.sin(2 * math.pi * freq * t)


def main():
    samples = [0.0] * int(LENGTH * RATE)
    bar = BEATS_PER_BAR * BEAT
    pattern = [0, 1, 2, 3, 2, 1, 2, 3]
    for chord_index, (root, tones) in enumerate(PROGRESSION):
        chord_start = chord_index * 2 * bar
        for beat in range(8):
            t = chord_start + beat * BEAT
            pluck(root, t, BEAT * 1.5, 0.35 if beat % 4 == 0 else 0.2, samples)
            for half in range(2):
                note = tones[pattern[(beat * 2 + half) % len(pattern)]]
                pluck(note, t + half * BEAT / 2, BEAT * 1.2, 0.16, samples)
        for tone in tones[:3]:
            pad(tone / 2, chord_start, 2 * bar, 0.05, samples)
    peak = max(abs(s) for s in samples)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.8 * 32767)) for s in samples))
    print("written", OUT, f"{LENGTH:.1f}s")


if __name__ == "__main__":
    main()
