"""Synthesise the app's short sound effects as 16-bit mono WAV files.

Usage:  python3 tool/make_sounds.py   (standard library only)
Writes: assets/sounds/correct.wav, wrong.wav, finish.wav
"""
import math
import pathlib
import struct
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
RATE = 22050


def tone(freq, dur, volume=0.35, decay=6.0):
    """A soft bell-like note: sine plus a quiet octave, fading out."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.01)
        env = attack * math.exp(-decay * t)
        s = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t)
        out.append(volume * env * s / 1.25)
    return out


def mix(*parts):
    """Overlay (offset_seconds, samples) pairs."""
    length = max(int(off * RATE) + len(s) for off, s in parts)
    out = [0.0] * length
    for off, s in parts:
        start = int(off * RATE)
        for i, v in enumerate(s):
            out[start + i] += v
    return out


def write(name, samples):
    path = ROOT / "assets" / "sounds" / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in samples))


if __name__ == "__main__":
    # Rising major third: E5 → G#5.
    write("correct.wav", mix((0, tone(659.3, 0.35)), (0.09, tone(830.6, 0.45))))
    # Low, gentle falling pair: A3 → F3.
    write("wrong.wav", mix((0, tone(220.0, 0.3, volume=0.3, decay=9)), (0.12, tone(174.6, 0.4, volume=0.3, decay=8))))
    # Little arpeggio for finishing a quiz: C5 E5 G5 C6.
    write("finish.wav", mix(*[(0.1 * i, tone(f, 0.6, volume=0.28, decay=5)) for i, f in enumerate([523.3, 659.3, 784.0, 1046.5])]))
    print("Sounds written.")
