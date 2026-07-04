#!/usr/bin/env python3
"""Synthesize game sound effects as WAV files (44.1kHz 16-bit mono)."""
import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = 0.9 / peak if peak > 0.9 else 1.0
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1, min(1, s * norm)) * 32767))
                for s in samples
            )
        )
    print(f"wrote {path} ({len(samples)/SR:.2f}s)")


def env(t, dur, attack=0.005, release=None):
    release = release if release is not None else dur * 0.6
    if t < attack:
        return t / attack
    if t > dur - release:
        return max(0.0, (dur - t) / release)
    return 1.0


def sine_sweep(f0, f1, dur, curve=2.0, vol=1.0, attack=0.005):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        p = (t / dur) ** curve
        f = f0 + (f1 - f0) * p
        phase += 2 * math.pi * f / SR
        out.append(vol * env(t, dur, attack) * math.sin(phase))
    return out


def noise_burst(dur, vol=1.0, lp=0.3):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        x = random.uniform(-1, 1)
        prev = prev + lp * (x - prev)  # 简易低通
        out.append(vol * env(t, dur, 0.001) * prev)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for tr in tracks:
        for i, s in enumerate(tr):
            out[i] += s
    return out


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def bubble_pop(base, dur=0.12):
    """水泡爆破：短促上滑正弦 + 噪声点击。"""
    body = sine_sweep(base, base * 2.2, dur, curve=0.5, vol=0.9)
    click = noise_burst(0.02, vol=0.5, lp=0.8)
    return mix(body, click)


random.seed(42)

# 交换：轻柔嗖声
write_wav("swap.wav", sine_sweep(400, 900, 0.09, curve=1.0, vol=0.5))

# 消除 pop（连锁 1/2/3 音调递增）
write_wav("pop1.wav", bubble_pop(500))
write_wav("pop2.wav", bubble_pop(650))
write_wav("pop3.wav", bubble_pop(820))

# 条纹糖：激光扫射
write_wav(
    "stripe.wav",
    mix(
        sine_sweep(1400, 300, 0.30, curve=0.7, vol=0.7),
        noise_burst(0.28, vol=0.35, lp=0.5),
    ),
)

# 包装糖：低音爆炸
write_wav(
    "wrap.wav",
    mix(
        sine_sweep(220, 55, 0.4, curve=0.6, vol=1.0),
        noise_burst(0.35, vol=0.6, lp=0.15),
    ),
)

# 彩球：更大的爆炸 + 闪烁尾音
sparkle = []
for k in range(6):
    f = 1200 + k * 350
    tone = sine_sweep(f, f * 1.1, 0.08, vol=0.25)
    sparkle = mix(sparkle + [0.0] * (len(tone) + int(SR * 0.04 * k) - len(sparkle)),
                  [0.0] * int(SR * 0.04 * k) + tone)
write_wav(
    "bomb.wav",
    mix(
        sine_sweep(180, 40, 0.55, curve=0.6, vol=1.0),
        noise_burst(0.5, vol=0.7, lp=0.12),
        [0.0] * int(SR * 0.1) + sparkle,
    ),
)

# 洗牌：一串短音
notes = [523, 659, 784, 659, 523]
shuffle_snd = []
for i, f in enumerate(notes):
    tone = sine_sweep(f, f, 0.07, vol=0.4)
    pad = [0.0] * int(SR * 0.06 * i)
    shuffle_snd = mix(shuffle_snd + [0.0] * (len(pad) + len(tone) - len(shuffle_snd)), pad + tone)
write_wav("shuffle.wav", shuffle_snd)

# 无效交换：低沉否定音
write_wav(
    "invalid.wav",
    concat(sine_sweep(240, 200, 0.08, vol=0.5), sine_sweep(190, 150, 0.12, vol=0.5)),
)

# 胜利：上行琶音
win_notes = [523, 659, 784, 1047, 1319]
win_snd = []
for i, f in enumerate(win_notes):
    tone = sine_sweep(f, f, 0.22, vol=0.5)
    pad = [0.0] * int(SR * 0.11 * i)
    win_snd = mix(win_snd + [0.0] * max(0, len(pad) + len(tone) - len(win_snd)), pad + tone)
write_wav("win.wav", win_snd)

# 失败：下行
lose_notes = [440, 392, 330, 262]
lose_snd = []
for i, f in enumerate(lose_notes):
    tone = sine_sweep(f, f * 0.97, 0.3, vol=0.5)
    pad = [0.0] * int(SR * 0.18 * i)
    lose_snd = mix(lose_snd + [0.0] * max(0, len(pad) + len(tone) - len(lose_snd)), pad + tone)
write_wav("lose.wav", lose_snd)

print("done")
