"""Audio técnico original, determinista, PCM mono 22050 Hz / 16 bits.

Solo escribe assets/placeholders/audio/. No modifica arte ni configura Godot.
Python estándar; no es necesario para jugar. Sin grabaciones ni licencias externas.
"""
from pathlib import Path
import math
import random
import struct
import wave
import zlib

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "assets/placeholders/audio"
DURATIONS = {
    "inventory_open": .09, "inventory_close": .085, "ui_select": .045,
    "pickup_supply": .13, "pickup_ammo": .10, "item_use": .22,
    "invalid": .10, "container_open": .17, "pistol_shot": .14,
    "revolver_shot": .20, "shotgun_shot": .30, "reload": .28,
    "machete_swing": .20, "machete_hit": .12, "dry_fire": .065,
    "zombie_groan": .70, "zombie_attack": .22, "zombie_hurt": .18,
    "zombie_death": .65, "ambience": 8.0,
}


def samples(name, duration):
    rng = random.Random(zlib.crc32(name.encode()))
    noise = 0.0
    values = []
    phases = [rng.uniform(0, math.tau) for _ in range(12)]
    for index in range(round(RATE * duration)):
        t = index / RATE
        x = t / duration
        noise = .77 * noise + .23 * rng.uniform(-1, 1)
        if name == "ambience":
            # Frecuencias con períodos enteros de 8 segundos: unión continua.
            value = sum(math.sin(math.tau * (i + 1) * t / 8 + phases[i]) / (i + 2)
                        for i in range(12)) * .12
            value += .02 * math.sin(math.tau * 47 * t) + .015 * math.sin(math.tau * 62 * t)
            values.append(value)
            continue
        fade = min(1, t / .004) * min(1, (duration - t) / .025)
        if name.endswith("_shot"):
            bass = {"pistol_shot": 92, "revolver_shot": 72, "shotgun_shot": 51}[name]
            value = noise * 1.8 * math.exp(-17 * t)
            value += .5 * math.sin(math.tau * bass * t) * math.exp(-23 * t)
        elif name.startswith("zombie_"):
            pitch = {"zombie_groan": 69, "zombie_attack": 95, "zombie_hurt": 115, "zombie_death": 63}[name]
            phase = math.tau * pitch * (t - .16 * t * t / duration)
            value = (.5 * math.sin(phase) + .18 * math.sin(2.1 * phase) + noise * .5)
            value *= math.sin(math.pi * x) ** .6
        elif name == "machete_swing":
            value = noise * math.sin(math.pi * x) ** 2
        elif name in ("machete_hit", "container_open", "reload", "dry_fire"):
            pulse = math.exp(-38 * t)
            if name == "reload": pulse += .55 * math.exp(-90 * abs(t - .17))
            value = (noise + .22 * math.sin(math.tau * 170 * t)) * pulse
        else:
            pitch = {"inventory_open": 440, "inventory_close": 360, "ui_select": 520,
                     "pickup_supply": 560, "pickup_ammo": 390, "item_use": 460,
                     "invalid": 210}.get(name, 420)
            value = (.6 * math.sin(math.tau * pitch * t) + noise * .1) * math.exp(-5 * x)
        values.append(value * fade)
    peak = max(abs(v) for v in values)
    target = .12 if name == "ambience" else .45
    return [v * target / max(peak, .0001) for v in values]


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    for name, duration in DURATIONS.items():
        values = samples(name, duration)
        pcm = struct.pack("<" + "h" * len(values), *(round(v * 32767) for v in values))
        with wave.open(str(DEST / (name + ".wav")), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(pcm)
        print(name, len(values), "samples")


if __name__ == "__main__":
    main()
