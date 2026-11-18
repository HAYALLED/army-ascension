#!/usr/bin/env python3
"""Procedural SFX + music generator for Army Ascension.
Run from the project root:  python3 Tools/generate_sounds.py
Writes WAV/OGG files into ./Sounds (requires numpy, scipy, ffmpeg for the music ogg)."""
import os, subprocess, wave
import numpy as np
from scipy.signal import lfilter

SR = 22050
rng = np.random.default_rng(7)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Sounds")
os.makedirs(OUT, exist_ok=True)


def tt(d): return np.arange(int(SR * d)) / SR
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, fc):
    a = 1 - np.exp(-2 * np.pi * fc / SR)
    return lfilter([a], [1, -(1 - a)], x)
def hp(x, fc): return x - lp(x, fc)
def env(d, k): return np.exp(-k * tt(d))
def sweep(f0, f1, d):
    t = tt(d)
    f = f0 * (f1 / f0) ** (t / d)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)
def saw(f0, f1, d):
    t = tt(d)
    f = f0 * (f1 / f0) ** (t / d)
    return 2 * ((np.cumsum(f) / SR) % 1.0) - 1
def sine(f, d): return np.sin(2 * np.pi * f * tt(d))
def tri(f, d): return 2 * np.abs(2 * ((f * tt(d)) % 1.0) - 1) - 1
def attack(x, a=0.005):
    n = min(int(SR * a), len(x))
    x = x.copy(); x[:n] *= np.linspace(0, 1, n); return x
def pad(x, n):
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]

def save(name, x, gain=0.9):
    x = np.tanh(x * 1.0) if np.max(np.abs(x)) > 1.5 else x
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    n = min(int(SR * 0.004), len(x)); x[-n:] *= np.linspace(1, 0, n)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())

# ---- weapons
d = .14; save("shoot_rifle", lp(noise(d), 3500) * env(d, 35) * .8 + sweep(180, 60, d) * env(d, 30) * .7)
d = .08; save("shoot_mg", lp(noise(d), 5000) * env(d, 70) + sweep(260, 120, d) * env(d, 50) * .6)
d = .55
save("shoot_sniper", hp(noise(d), 800) * env(d, 18) * .9 + sweep(120, 40, d) * env(d, 10) + lp(noise(d), 800) * env(d, 6) * .3)
d = .5; t = tt(d); save("rocket_launch", lp(noise(d), 1800) * np.sqrt(t / d) * np.exp(-3 * t) + sweep(200, 520, d) * env(d, 4) * .3)
d = .9; save("explosion", lp(noise(d), 900) * env(d, 5) + sweep(70, 30, d) * env(d, 6) + lp(noise(d), 4000) * env(d, 25) * .5)
d = .22; save("shoot_enemy", saw(520, 180, d) * env(d, 18) * .6 + lp(noise(d), 3000) * env(d, 30) * .4)
# ---- impacts / deaths
d = .06; save("hit", lp(noise(d), 2500) * env(d, 80) * .6 + sine(400, d) * env(d, 60) * .3)
d = .3; save("enemy_die", saw(300, 80, d) * env(d, 9) * .55 + lp(noise(d), 1500) * env(d, 12) * .3)
d = .35; save("soldier_die", tri(1, d) * 0 + sweep(240, 60, d) * env(d, 7) * .7 + lp(noise(d), 900) * env(d, 10) * .3)
# ---- support / ui
d = .4; x = sum(attack(sine(f, d - i * .08)) * env(d - i * .08, 9) for i, f in enumerate([660, 880, 1320]) for _ in [0]) if False else None
parts = [pad(np.concatenate([np.zeros(int(SR * i * .08)), attack(sine(f, .3)) * env(.3, 9)]), int(SR * .4)) for i, f in enumerate([660, 880, 1320])]
save("heal", sum(parts))
parts = [pad(np.concatenate([np.zeros(int(SR * i * .07)), attack(sine(f, .3) + .3 * sine(2 * f, .3)) * env(.3, 8)]), int(SR * .45)) for i, f in enumerate([523, 659, 784, 1047])]
save("gate_good", sum(parts))
d = .4; save("gate_bad", lp(saw(420, 160, d), 1200) * env(d, 5))
d = .06; save("ui_click", sweep(900, 600, d) * env(d, 40))
d = .2; save("soldier_spawn", sweep(300, 700, d) * env(d, 18) * .8)
# ---- boss
d = 1.4; t = tt(d); vib = 1 + .06 * np.sin(2 * np.pi * 14 * t)
roar = np.tanh(3 * (2 * ((np.cumsum(62 * vib * (45 / 62) ** (t / d)) / SR) % 1) - 1)) * .6
roar = lp(roar, 900) + lp(noise(d), 600) * .4 * (1 + np.sin(2 * np.pi * 9 * t)) / 2
roar *= np.minimum(1, t / .15) * np.exp(-1.6 * t)
save("boss_roar", roar)
d = .7; save("slam", sweep(55, 25, d) * env(d, 5) + lp(noise(d), 500) * env(d, 9) * .8)
d = .6; t = tt(d); save("wave_horn", lp(saw(220, 220, d) + saw(330, 330, d) * .7, 1400) * np.minimum(1, t / .08) * np.exp(-2.2 * t))
d = .3; save("boss_shoot", saw(150, 90, d) * env(d, 12) * .7 + lp(noise(d), 1200) * env(d, 20) * .4)
# ---- jingles
notes = [(523, 0), (659, .18), (784, .36), (1047, .54)]
v = np.zeros(int(SR * 1.8))
for f, s in notes:
    n = attack(sine(f, 1.0) + .35 * sine(2 * f, 1.0) + .2 * tri(f, 1.0)) * env(1.0, 2.2)
    i = int(SR * s); v[i:i + len(n)] += n[:len(v) - i]
save("victory", v)
notes = [(392, 0), (349, .35), (311, .7), (262, 1.05)]
v = np.zeros(int(SR * 2.0))
for f, s in notes:
    n = lp(saw(f, f * .98, .9), 1500) * attack(np.ones(int(SR * .9))) * env(.9, 2.8)
    i = int(SR * s); v[i:i + len(n)] += n[:len(v) - i]
save("defeat", v)

# ---- battle music loop (128 bpm, 8 bars, A minor)
bpm = 128; beat = 60 / bpm; bars = 8; total = bars * 4 * beat
buf = np.zeros(int(SR * total) + SR * 2)
def place(sig, t0, g=1.0):
    i = int(t0 * SR); buf[i:i + len(sig)] += sig[:len(buf) - i] * g
kick = sweep(150, 45, .25) * env(.25, 14)
snare = lp(noise(.2), 4000) * env(.2, 22) * .8 + sweep(220, 160, .2) * env(.2, 25) * .5
hat = hp(noise(.06), 6000) * env(.06, 70) * .35
chords = [[220, 261.63, 329.63], [174.61, 220, 261.63], [261.63, 329.63, 392], [196, 246.94, 293.66]] * 2
roots = [55, 43.65, 65.41, 49] * 2
for bar in range(bars):
    cb = chords[bar]; root = roots[bar]
    for b in range(4):
        t0 = (bar * 4 + b) * beat
        place(kick, t0, .9); place(hat, t0 + beat / 2, .8)
        if b in (1, 3): place(snare, t0, .7)
    for k in range(8):
        f = root * (2 if k in (3, 7) else 1)
        n = lp(saw(f, f, beat / 2), 600) * env(beat / 2, 5) * .55
        place(n, bar * 4 * beat + k * beat / 2)
    padn = sum(sine(f, 4 * beat) for f in cb) * .08
    padn *= np.minimum(1, tt(4 * beat) / .4) * np.minimum(1, (4 * beat - tt(4 * beat)) / .4)
    place(padn, bar * 4 * beat)
    if bar >= 2:
        for k in range(8):
            f = cb[[0, 1, 2, 1, 0, 2, 1, 2][k]] * 2
            n = (sine(f, .3) + .3 * sine(2 * f, .3)) * env(.3, 9) * .16
            place(attack(n), bar * 4 * beat + k * beat / 2)
m = buf[:int(SR * total)]
m = m / np.max(np.abs(m)) * .8
with wave.open(os.path.join(OUT, "music_battle.wav"), "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((m * 32767).astype(np.int16).tobytes())
try:
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(OUT, "music_battle.wav"),
                    "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, "music_battle.ogg")], check=True)
    os.remove(os.path.join(OUT, "music_battle.wav"))
except Exception as e:
    print("ogg encode skipped:", e)
print("sounds written to", os.path.abspath(OUT))
