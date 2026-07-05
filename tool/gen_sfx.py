#!/usr/bin/env python3
"""合成糖果风音效 v2：马林巴/铃铛音色 + 柔和包络 + 回声尾音。

比 v1 的正弦扫频柔和悦耳：谐波泛音、指数衰减、软起音、
音符走五声音阶（连锁听起来像旋律）。
"""
import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(7)


def write_wav(name, samples, peak=0.82):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    m = max(1e-9, max(abs(s) for s in samples))
    k = peak / m
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1, min(1, s * k)) * 32767))
                for s in samples
            )
        )
    print(f"wrote {path} ({len(samples)/SR:.2f}s)")


def env_ad(t, attack, decay):
    a = t / attack if t < attack else 1.0
    return a * math.exp(-decay * max(0.0, t - attack))


def pluck(freq, dur=0.35, partials=((1, 1.0), (4.0, 0.16), (10.0, 0.04)),
          decay=9.0, attack=0.004, vol=1.0, bend=0.012):
    """马林巴式弹拨音：基音+泛音，高次泛音衰减更快。"""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq * (1.0 + bend * math.exp(-45 * t))
        s = 0.0
        for m, a in partials:
            s += a * math.sin(2 * math.pi * f * m * t) * \
                math.exp(-decay * 0.5 * (m - 1) * t)
        out.append(vol * env_ad(t, attack, decay) * s)
    return out


def bell(freq, dur=0.9, vol=1.0, decay=4.0):
    """铃铛音色（非整数泛音）。"""
    return pluck(freq, dur,
                 partials=((1, 1.0), (2.0, 0.5), (2.92, 0.28), (4.16, 0.14)),
                 decay=decay, attack=0.003, vol=vol, bend=0.0)


def knock(freq=190, dur=0.10, vol=1.0):
    """闷响敲击。"""
    return pluck(freq, dur, partials=((1, 1.0), (1.58, 0.35)),
                 decay=32, attack=0.002, vol=vol, bend=0.0)


def swish(dur, vol=0.3, lp_start=0.85, lp_end=0.15):
    """柔和气声（低通扫掠噪声，圆滑起落）。"""
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        p = t / dur
        alpha = lp_start + (lp_end - lp_start) * p
        x = random.uniform(-1, 1)
        prev = prev + alpha * (x - prev)
        out.append(vol * math.sin(math.pi * min(1.0, p * 1.15)) ** 2 * prev)
    return out


def boom(f0=130, f1=40, dur=0.5, vol=1.0):
    """低音轰鸣：下滑正弦 + 低通噪声。"""
    n = int(SR * dur)
    out = []
    phase = 0.0
    prev = 0.0
    for i in range(n):
        t = i / SR
        p = t / dur
        f = f0 + (f1 - f0) * math.sqrt(p)
        phase += 2 * math.pi * f / SR
        x = random.uniform(-1, 1)
        prev = prev + 0.10 * (x - prev)
        out.append(vol * env_ad(t, 0.005, 7.0) *
                   (0.92 * math.sin(phase) + 0.5 * prev))
    return out


def crunch(dur=0.05, vol=1.0, lp=0.35):
    """酥脆碎裂声单元。"""
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        x = random.uniform(-1, 1)
        prev = prev + lp * (x - prev)
        out.append(vol * env_ad(t, 0.002, 40) * prev)
    return out


def place(base, clip, offset_s):
    """把 clip 混入 base 的 offset 秒处（自动扩容）。"""
    off = int(SR * offset_s)
    need = off + len(clip)
    if len(base) < need:
        base = base + [0.0] * (need - len(base))
    for i, s in enumerate(clip):
        base[off + i] += s
    return base


def echo(x, delay=0.095, gain=0.26, taps=2):
    out = list(x) + [0.0] * int(SR * delay * taps)
    for t in range(1, taps + 1):
        off = int(SR * delay * t)
        g = gain ** t
        for i, s in enumerate(x):
            out[i + off] += s * g
    return out


# ---- 消除 pop：五声音阶三连音（连锁像旋律）----
for i, f in enumerate([659.26, 783.99, 987.77]):  # E5 G5 B5
    write_wav(f"pop{i+1}.wav", echo(pluck(f, 0.30, vol=0.9), gain=0.22))

# ---- 交换：清脆小嗒 + 轻气声 ----
s = pluck(1318.5, 0.10, decay=26, vol=0.55)
s = place(s, swish(0.10, 0.22, 0.9, 0.3), 0.0)
write_wav("swap.wav", s)

# ---- 无效交换：两下闷敲 ----
s = knock(215, vol=0.8)
s = place(s, knock(168, vol=0.9), 0.095)
write_wav("invalid.wav", s)

# ---- 条纹糖：嗖的一道光 + 亮尾音 ----
s = swish(0.30, 0.5, 0.97, 0.45)
s = place(s, pluck(1568, 0.16, decay=16, vol=0.45), 0.12)
write_wav("stripe.wav", echo(s, delay=0.07, gain=0.2, taps=1))

# ---- 包装糖：软轰 + 亮铃 ----
s = boom(150, 55, 0.38, vol=1.0)
s = place(s, knock(320, vol=0.5), 0.01)
s = place(s, bell(1046.5, 0.35, vol=0.22, decay=7), 0.10)
write_wav("wrap.wav", s)

# ---- 彩球/炸弹：深轰 + 上行铃闪 ----
s = boom(112, 36, 0.55, vol=1.1)
for j, f in enumerate([1318.5, 1568.0, 2093.0]):
    s = place(s, bell(f, 0.30, vol=0.16, decay=8), 0.14 + j * 0.09)
write_wav("bomb.wav", echo(s, delay=0.11, gain=0.22, taps=1))

# ---- 冰裂：玻璃脆响 ----
s = crunch(0.04, 0.5, lp=0.85)
s = place(s, pluck(2093, 0.18, partials=((1, 1.0), (2.76, 0.5)),
                   decay=18, vol=0.7), 0.008)
s = place(s, pluck(2637, 0.14, partials=((1, 1.0), (2.76, 0.4)),
                   decay=22, vol=0.5), 0.05)
write_wav("ice.wav", s)

# ---- 饼干：咔嚓酥碎 ----
s = crunch(0.06, 1.0, lp=0.4)
s = place(s, crunch(0.05, 0.8, lp=0.3), 0.055)
s = place(s, crunch(0.07, 0.6, lp=0.25), 0.11)
s = place(s, knock(130, vol=0.5), 0.0)
write_wav("cookie.wav", s)

# ---- 洗牌：竖琴琶音 ----
s = []
for j, f in enumerate([523.25, 587.33, 659.26, 783.99, 880.0]):
    s = place(s, pluck(f, 0.20, decay=11, vol=0.45), j * 0.045)
write_wav("shuffle.wav", s)

# ---- 胜利：铃铛琶音 + 高音收尾 ----
s = []
for j, f in enumerate([523.25, 659.26, 783.99, 1046.5]):
    s = place(s, bell(f, 0.7, vol=0.5, decay=3.5), j * 0.13)
s = place(s, bell(1568.0, 0.9, vol=0.3, decay=3.0), 0.55)
write_wav("win.wav", echo(s, delay=0.13, gain=0.2, taps=1))

# ---- 失败：温和下行双音 ----
s = bell(392.0, 0.55, vol=0.5, decay=4.5)
s = place(s, bell(293.66, 0.85, vol=0.55, decay=3.5), 0.30)
write_wav("lose.wav", s)

print("done")
