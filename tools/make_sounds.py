"""Generates SHIFT's synthesised sound effects (original, CC0).

Run:  python tools/make_sounds.py      (needs numpy and ffmpeg on PATH)
Writes assets/sounds/<key>.ogg, one per SoundIds key below.

These are the sounds that synthesis does well: drones, heartbeats,
stingers, electrical noise, UI blips. Real recorded footsteps and impacts
come from Kenney's CC0 packs instead (tools/fetch_cc0.py). The hum Jason
uploaded is kept as it is; DRONE sits underneath it.

DRONE is no longer uploaded (Roblox's IP filter took it down as a false
match on 27 Nov 2026; tools/upload_assets.py blocks it). The game uses the
hum, slowed, in its place.

Pass keys to regenerate only those:  python tools/make_sounds.py HEARTBEAT DRONE
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
rng = np.random.default_rng(1127)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack, release, sustain=None):
    """Attack/release envelope over n samples (times in seconds)."""
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def lowpass(x, cutoff):
    """FFT brick-wall-ish low pass with a soft knee."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1 / (1 + (f / cutoff) ** 4)
    return np.fft.irfft(X, len(x))


def bandpass(x, lo, hi):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= (1 / (1 + (f / hi) ** 4)) * (1 / (1 + (lo / np.maximum(f, 1)) ** 4))
    return np.fft.irfft(X, len(x))


def noise(n):
    return rng.standard_normal(n)


def brown(n):
    b = np.cumsum(noise(n))
    b -= np.convolve(b, np.ones(2001) / 2001, mode="same")  # remove drift
    return b / (np.abs(b).max() + 1e-9)


def reverb(x, seconds=1.2, mix=0.3, damp=4000):
    """Cheap convolution reverb with a decaying noise tail."""
    n = int(seconds * SR)
    ir = noise(n) * np.exp(-np.linspace(0, 7, n))
    ir = lowpass(ir, damp)
    ir /= np.abs(ir).sum() ** 0.5 * 4
    size = len(x) + n
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)
    dry = np.concatenate([x, np.zeros(n)])
    return dry * (1 - mix) + wet * mix


def loopable(x, fade=0.5):
    """Crossfade the tail into the head so a loop has no click."""
    n = int(fade * SR)
    head, tail = x[:n], x[-n:]
    w = np.linspace(0, 1, n)
    out = x[: len(x) - n].copy()
    out[:n] = head * w + tail * (1 - w)
    return out


def normalise(x, peak=0.9):
    return x / (np.abs(x).max() + 1e-9) * peak


def write(key, x, peak=0.9):
    os.makedirs(OUT, exist_ok=True)
    x = normalise(x, peak)
    wav_path = os.path.join(OUT, f"{key}.wav")
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    ogg_path = os.path.join(OUT, f"{key}.ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "5", ogg_path], check=True)
    os.remove(wav_path)
    print("wrote", key, f"{len(x) / SR:.2f}s")


# ---------------------------------------------------------------------------
# AMBIENCE


def DRONE():
    # The low bed under the hum: a dark, slowly breathing room tone with a
    # faint sub at 41 Hz and a distant air-handler rumble. 24 s seamless loop.
    t = t_axis(24.5)
    n = len(t)
    breathe = 0.75 + 0.25 * np.sin(2 * np.pi * t / 24.5 * 2)
    sub = np.sin(2 * np.pi * 41 * t) * 0.35 + np.sin(2 * np.pi * 61.5 * t + 1) * 0.12
    air = lowpass(brown(n), 180) * 0.9
    rumble = bandpass(noise(n), 60, 260) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 6.125)) * 0.5
    write("DRONE", loopable((sub + air + rumble) * breathe), 0.7)


def HEARTBEAT():
    # One lub-dub, loops at ~70 bpm; Audio speeds it up with PlaybackSpeed.
    t = t_axis(0.86)
    x = np.zeros(len(t))

    def thump(at, f, amp, dur):
        i = int(at * SR)
        tt = t_axis(dur)
        k = np.sin(2 * np.pi * f * tt * (1 - 0.4 * tt / dur)) * np.exp(-tt * 18) * amp
        x[i : i + len(tt)] += k[: len(x) - i]

    thump(0.0, 58, 1.0, 0.25)
    thump(0.22, 50, 0.7, 0.25)
    write("HEARTBEAT", lowpass(x, 300), 0.95)


def WHISPERS():
    # Low sanity: breathy, wordless whispering that drifts in and out.
    # Noise through moving vowel formants, chopped into syllables.
    t = t_axis(12.5)
    n = len(t)
    out = np.zeros(n)
    for voice in range(4):
        src = noise(n)
        syll = (np.sin(2 * np.pi * (3.1 + voice * 0.7) * t + voice) > 0.2).astype(float)
        syll = np.convolve(syll, np.ones(800) / 800, mode="same")
        f1 = 500 + 300 * np.sin(2 * np.pi * (0.9 + voice * 0.3) * t)
        v = np.zeros(n)
        # Approximate a moving formant with a few fixed bands blended over time.
        for centre in (400, 800, 1600, 2600):
            band = bandpass(src, centre * 0.8, centre * 1.25)
            w = np.exp(-((f1 * (1 + centre / 1600) - centre) / 500) ** 2)
            v += band * w
        swell = 0.5 + 0.5 * np.sin(2 * np.pi * t / 12.5 * (voice + 1) + voice * 2)
        out += v * syll * swell
    out = reverb(out, 1.5, 0.45, 3000)[:n]
    write("WHISPERS", loopable(out, 0.8), 0.6)


# ---------------------------------------------------------------------------
# ENTITY CUES (3D, looped on the entity)


def TENANT_CUE():
    # The Tenant: slow, wet, clicking breath. A rattle in the throat on the
    # in-breath, a long dry exhale. 4.2 s loop.
    t = t_axis(4.6)
    n = len(t)
    x = np.zeros(n)
    inhale = (t > 0.2) & (t < 1.6)
    exhale = (t > 1.9) & (t < 4.0)
    shape_in = np.sin(np.pi * np.clip((t - 0.2) / 1.4, 0, 1)) * inhale
    shape_ex = np.sin(np.pi * np.clip((t - 1.9) / 2.1, 0, 1)) ** 0.7 * exhale
    x += bandpass(noise(n), 300, 1800) * shape_in * 0.6
    x += bandpass(noise(n), 150, 900) * shape_ex * 0.8
    # Clicks: a stuttering train of short tocks in the throat.
    clicks = np.zeros(n)
    at = 0.25
    while at < 1.55:
        i = int(at * SR)
        k = np.exp(-t_axis(0.012) * 500) * np.sin(2 * np.pi * 1800 * t_axis(0.012))
        clicks[i : i + len(k)] += k
        at += 0.045 + rng.random() * 0.05
    x += bandpass(clicks, 600, 4000) * 0.8
    write("TENANT_CUE", loopable(reverb(x, 0.6, 0.2)[:n], 0.4), 0.85)


def LAMPJAW_CUE():
    # Lampjaw: a sick electrical crackle with teeth chattering inside it.
    t = t_axis(3.4)
    n = len(t)
    buzz = np.sign(np.sin(2 * np.pi * 120 * t)) * 0.3 + np.sin(2 * np.pi * 240 * t) * 0.2
    crackle = (rng.random(n) > 0.9985).astype(float) * noise(n) * 3
    crackle = bandpass(crackle, 1500, 9000)
    chatter = np.zeros(n)
    at = 0.0
    while at < 3.3:
        i = int(at * SR)
        k = np.exp(-t_axis(0.02) * 300) * noise(len(t_axis(0.02)))
        chatter[i : i + len(k)] += k
        at += 0.06 + rng.random() * 0.04 if rng.random() > 0.3 else 0.35
    chatter = bandpass(chatter, 900, 5000)
    wobble = 0.7 + 0.3 * np.sin(2 * np.pi * 0.9 * t)
    write("LAMPJAW_CUE", loopable((bandpass(buzz, 80, 3000) * wobble + crackle + chatter * 0.7), 0.3), 0.8)


# ---------------------------------------------------------------------------
# STINGERS


def QUIET_INHALE():
    # The Quiet: one long, slow breath in, very close, through a slack mouth,
    # that stops dead at the top: it's holding its breath, listening.
    # Breath noise through two drifting vowel bands (an "aah" opening
    # toward "ooh"), a thin whistle through the teeth, a low chest
    # rumble, and a small dry room. 2.4 s, not looped.
    seconds = 2.4
    t = t_axis(seconds)
    n = len(t)
    held = 2.05  # where the breath stops
    swell = np.clip(t / held, 0, 1) ** 1.6
    swell *= 0.85 + 0.15 * np.sin(2 * np.pi * 3.3 * t) * (t < held)  # the slight judder of a slow breath
    stop = np.ones(n)
    k = int(held * SR)
    r = int(0.05 * SR)
    stop[k:k + r] = np.linspace(1, 0, r) ** 2
    stop[k + r:] = 0
    air = noise(n)
    mouth = bandpass(air, 700, 1300) * (1.0 - 0.5 * t / seconds) + bandpass(air, 1700, 2900) * 0.6
    mouth += bandpass(air, 300, 600) * (0.3 + 0.5 * t / seconds)  # the vowel closing as the lungs fill
    whistle = bandpass(noise(n), 1500, 1650) * (0.15 + 0.35 * swell)
    chest = lowpass(brown(n), 220) * 0.25
    x = (mouth + whistle + chest) * swell * stop
    x *= env(n, 0.25, 0.01)
    out = reverb(x, 0.6, 0.18, 3500)
    write("QUIET_INHALE", out[: int(SR * (seconds + 0.5))], 0.75)


def FOREMAN_KEYS():
    # The Foreman's keyring: a heavy ring of keys swinging on a belt. A
    # cluster of clinks on each slow step (every 0.6 s), a few loose ones
    # between. Each clink is a handful of short, inharmonic metal partials.
    # 2.4 s loop (four steps).
    seconds = 2.4
    t = t_axis(seconds)
    n = len(t)
    out = np.zeros(n)

    def clink(at, level):
        k = int(at * SR) % n
        length = int(0.09 * SR)
        tt = np.arange(length) / SR
        c = np.zeros(length)
        for _ in range(4):
            f = rng.uniform(2300, 7400)
            c += np.sin(2 * np.pi * f * tt + rng.uniform(0, 6.28)) * np.exp(-tt * rng.uniform(35, 90)) * rng.uniform(0.4, 1.0)
        c += noise(length) * np.exp(-tt * 400) * 0.25  # the tick of contact
        end = min(n, k + length)
        out[k:end] += c[: end - k] * level

    for step in range(4):
        base = step * 0.6
        for j in range(int(rng.integers(5, 9))):
            clink(base + 0.02 + rng.uniform(0, 0.16) + j * 0.012, rng.uniform(0.5, 1.0))
        for _ in range(2):
            clink(base + rng.uniform(0.25, 0.55), rng.uniform(0.15, 0.35))
    out = bandpass(out, 1500, 9000)
    out = reverb(out, 0.5, 0.2, 6000)[:n]
    write("FOREMAN_KEYS", loopable(out, 0.05), 0.7)


def FOREMAN_WHISTLE():
    # The Foreman's whistle: two flat, idle notes that carry the length of a
    # corridor. The second is a little lower and a little off, held a beat
    # too long. Breathy, not musical: a sine through the teeth plus air.
    t = t_axis(2.6)
    n = len(t)
    freq = np.zeros(n)
    amp = np.zeros(n)
    for start, length, f0, f1 in ((0.05, 0.5, 1190, 1172), (0.66, 1.15, 985, 962)):
        a, b = int(start * SR), int((start + length) * SR)
        seg = np.linspace(0, 1, b - a)
        freq[a:b] = f0 + (f1 - f0) * seg + 14 * np.sin(2 * np.pi * 5.2 * seg * length) * seg  # a lazy wobble at the end
        freq[a:a + int(0.04 * SR)] *= np.linspace(0.92, 1.0, int(0.04 * SR))  # slides up into each note
        e = np.ones(b - a)
        r = int(0.05 * SR)
        e[:r] = np.linspace(0, 1, r)
        e[-int(0.12 * SR):] *= np.linspace(1, 0, int(0.12 * SR))
        amp[a:b] = e
    freq[freq == 0] = 1000
    phase = 2 * np.pi * np.cumsum(freq) / SR
    tone = np.sin(phase) + 0.08 * np.sin(2 * phase)
    air = bandpass(noise(n), 900, 1400) * 0.35 + bandpass(noise(n), 2500, 5000) * 0.08
    x = (tone + air) * amp
    out = reverb(x, 2.2, 0.42, 3200)
    write("FOREMAN_WHISTLE", out[: int(SR * 2.9)], 0.7)


def stinger(seconds, base, cluster, bite=1.0):
    t = t_axis(seconds)
    n = len(t)
    x = np.zeros(n)
    e = np.exp(-t * 2.2) * (1 - np.exp(-t * 200))
    for i, semis in enumerate(cluster):
        f = base * 2 ** (semis / 12)
        # Bowed, slightly detuned saw-ish tone.
        ph = 2 * np.pi * f * t + 0.4 * np.sin(2 * np.pi * 5.5 * t + i)
        x += (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.33 * np.sin(3 * ph)) * e
    hit = lowpass(noise(n), 2500) * np.exp(-t * 18) * bite
    boom = np.sin(2 * np.pi * 45 * t * (1 - 0.3 * t / seconds)) * np.exp(-t * 3) * 1.5
    return reverb(x * 0.4 + hit + boom, 2.0, 0.4)[: n + SR]


def STING_REVEAL():
    # The Tenant has seen you: a sharp dissonant string hit.
    write("STING_REVEAL", stinger(2.2, 220, [0, 1, 6, 11, 13]), 0.95)


def STING_DEATH():
    write("STING_DEATH", stinger(3.0, 110, [0, 1, 5, 6, 12], 1.6), 0.95)


def STING_WIPE():
    # The whole crew is gone: a long low boom and a falling cluster.
    t = t_axis(5.0)
    n = len(t)
    boom = np.sin(2 * np.pi * 38 * t * (1 - 0.25 * t / 5)) * np.exp(-t * 0.9)
    fall = np.zeros(n)
    for semis in (0, 1, 7, 13):
        f = 330 * 2 ** (semis / 12) * (1 - 0.35 * t / 5)
        fall += np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 0.8) * 0.25
    write("STING_WIPE", reverb(boom + fall + lowpass(noise(n), 600) * np.exp(-t * 4) * 0.5, 2.5, 0.4), 0.95)


def STING_GLIMPSE():
    # A hallucination: a short breathy swell that cuts off.
    t = t_axis(1.3)
    n = len(t)
    swell = np.clip(t / 1.1, 0, 1) ** 3 * (t < 1.1)
    x = bandpass(noise(n), 400, 3000) * swell + np.sin(2 * np.pi * 466 * t) * swell * 0.3
    write("STING_GLIMPSE", reverb(x, 1.2, 0.5), 0.8)


# ---------------------------------------------------------------------------
# THE SHIFT


def SHIFT_WARN():
    # The hum rising: a pitch-climbing electrical whine over 5 s.
    t = t_axis(5.0)
    f = 120 * 2 ** (t / 5 * 1.6)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = (np.sin(ph) + 0.4 * np.sin(2 * ph) + 0.2 * np.sign(np.sin(ph))) * (0.3 + 0.7 * t / 5)
    x += bandpass(noise(len(t)), 2000, 8000) * (t / 5) ** 2 * 0.3
    write("SHIFT_WARN", x * env(len(t), 0.3, 0.05), 0.75)


def BLACKOUT():
    # Every light dies at once: a heavy relay thunk and a dying ballast.
    t = t_axis(2.0)
    n = len(t)
    thunk = lowpass(noise(n), 900) * np.exp(-t * 30) * 1.5 + np.sin(2 * np.pi * 55 * t) * np.exp(-t * 8)
    f = 120 * np.exp(-t * 2.5)
    whine = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 2.2) * 0.4
    write("BLACKOUT", reverb(thunk + whine, 1.5, 0.35), 0.95)


def LIGHTS_ON():
    # Lights back: clack-clack of relays and a ballast ticking up.
    t = t_axis(1.6)
    n = len(t)
    x = np.zeros(n)
    for at in (0.0, 0.11, 0.35, 0.42, 0.7):
        i = int(at * SR)
        k = lowpass(noise(len(t_axis(0.05))), 4000) * np.exp(-t_axis(0.05) * 90)
        x[i : i + len(k)] += k
    f = 30 + 90 * (1 - np.exp(-t * 3))
    x += np.sin(2 * np.pi * np.cumsum(f) / SR) * (t > 0.3) * 0.25 * np.exp(-(t - 0.3) * 1.5)
    write("LIGHTS_ON", reverb(x, 0.8, 0.3), 0.9)


# ---------------------------------------------------------------------------
# THE LIFT AND THE LOOP


def LIFT_DING():
    t = t_axis(2.4)
    x = np.zeros(len(t))
    for f, at in ((880, 0.0), (659, 0.32)):
        tt = np.clip(t - at, 0, None)
        x += (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * f * 2.76 * tt)) * np.exp(-tt * 2.5) * (t >= at)
    write("LIFT_DING", reverb(x, 1.0, 0.25), 0.8)


def LIFT_MOTOR():
    # Going down: cable whine and the cage rattling. 6 s loop.
    t = t_axis(6.5)
    n = len(t)
    motor = np.sin(2 * np.pi * 92 * t) * 0.4 + np.sin(2 * np.pi * 184 * t) * 0.15
    rattle = bandpass(noise(n), 200, 1200) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t)) * 0.4
    rumble = lowpass(brown(n), 120)
    write("LIFT_MOTOR", loopable(motor + rattle + rumble, 0.5), 0.7)


def DEPOSIT():
    # Loot in the lift: a heavy drop into a metal cage and a register ching.
    t = t_axis(1.2)
    n = len(t)
    clank = bandpass(noise(n), 300, 5000) * np.exp(-t * 25)
    ring = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, d in ((1320, 6), (1980, 8), (2640, 10))) * 0.3 * (t > 0.08)
    write("DEPOSIT", reverb(clank + ring, 0.7, 0.25), 0.85)


def QUOTA_MET():
    t = t_axis(2.6)
    x = np.zeros(len(t))
    for f, at in ((523, 0.0), (659, 0.14), (784, 0.28), (1046, 0.42)):
        tt = np.clip(t - at, 0, None)
        x += np.sin(2 * np.pi * f * tt) * np.exp(-tt * 2.2) * (t >= at) * 0.5
    write("QUOTA_MET", reverb(x, 1.4, 0.35), 0.8)


def COUNTDOWN():
    t = t_axis(0.25)
    write("COUNTDOWN", np.sin(2 * np.pi * 740 * t) * np.exp(-t * 18), 0.6)


def PICKUP():
    # Grabbing loot: a quick cloth rustle and a light knock.
    t = t_axis(0.45)
    n = len(t)
    rustle = bandpass(noise(n), 1500, 7000) * np.exp(-((t - 0.12) / 0.08) ** 2)
    knock = lowpass(noise(n), 1500) * np.exp(-t * 60) * 0.8
    write("PICKUP", rustle + knock, 0.7)


def DROP():
    # Loot hitting the floor: a dull, heavy thud with a bounce.
    t = t_axis(0.8)
    n = len(t)
    x = lowpass(noise(n), 700) * np.exp(-t * 28) * 1.3 + np.sin(2 * np.pi * 70 * t) * np.exp(-t * 20)
    i = int(0.16 * SR)
    x[i:] += lowpass(noise(n - i), 900) * np.exp(-t[: n - i] * 40) * 0.4
    write("DROP", reverb(x, 0.6, 0.2), 0.9)


def FLASHLIGHT():
    t = t_axis(0.12)
    write("FLASHLIGHT", bandpass(noise(len(t)), 1500, 8000) * np.exp(-t * 120), 0.6)


# ---------------------------------------------------------------------------
# UI


def UI_CLICK():
    t = t_axis(0.06)
    write("UI_CLICK", np.sin(2 * np.pi * 1400 * t) * np.exp(-t * 90), 0.5)


def UI_OPEN():
    t = t_axis(0.3)
    f = 500 + 600 * t / 0.3
    write("UI_OPEN", np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.01, 0.15) * 0.6 + bandpass(noise(len(t)), 2000, 6000) * np.exp(-t * 30) * 0.2, 0.5)


def UI_CLOSE():
    t = t_axis(0.25)
    f = 1100 - 600 * t / 0.25
    write("UI_CLOSE", np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.01, 0.12) * 0.6, 0.5)


def PURCHASE():
    t = t_axis(0.9)
    x = np.sin(2 * np.pi * 988 * t) * np.exp(-t * 6) + np.sin(2 * np.pi * 1319 * np.clip(t - 0.09, 0, None)) * np.exp(-np.clip(t - 0.09, 0, None) * 6) * (t > 0.09)
    write("PURCHASE", reverb(x, 0.6, 0.2), 0.6)


def ERROR():
    t = t_axis(0.35)
    x = np.sign(np.sin(2 * np.pi * 110 * t)) * 0.5 + np.sin(2 * np.pi * 117 * t) * 0.5
    write("ERROR", lowpass(x, 1500) * env(len(t), 0.005, 0.05), 0.5)


KEYS = {f.__name__: f for f in [
    DRONE, HEARTBEAT, WHISPERS, TENANT_CUE, LAMPJAW_CUE, QUIET_INHALE, FOREMAN_KEYS, FOREMAN_WHISTLE, STING_REVEAL, STING_DEATH, STING_WIPE,
    STING_GLIMPSE, SHIFT_WARN, BLACKOUT, LIGHTS_ON, LIFT_DING, LIFT_MOTOR, DEPOSIT, QUOTA_MET,
    COUNTDOWN, PICKUP, DROP, FLASHLIGHT, UI_CLICK, UI_OPEN, UI_CLOSE, PURCHASE, ERROR,
]}

if __name__ == "__main__":
    for key in sys.argv[1:] or list(KEYS):
        KEYS[key]()
