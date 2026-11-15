"""Validate original PCM sources, hashes and optional real Godot recordings."""
import hashlib
import json
import sys
import wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
checks = 0


def check(condition, message):
    global checks
    checks += 1
    if not condition:
        raise AssertionError(message)


def read(path):
    with wave.open(str(path), "rb") as wav:
        check(wav.getsampwidth() == 2, f"16-bit PCM: {path.name}")
        rate, channels = wav.getframerate(), wav.getnchannels()
        signal = np.frombuffer(wav.readframes(wav.getnframes()), dtype="<i2").astype(float)/32768
    return signal.reshape(-1, channels), rate


manifest = json.loads((ROOT/"assets/music/MANIFEST.json").read_text())
for track in manifest["tracks"]:
    path = ROOT/"assets/music"/track["file"]
    check(hashlib.sha256(path.read_bytes()).hexdigest() == track["sha256"], path.name+" SHA256")
    signal, rate = read(path)
    check(rate == 22050 and signal.shape[1] == 2, path.name+" stereo/rate")
    check(abs(len(signal)/rate-track["seconds"]) < 1/rate, path.name+" duration")
    jump = np.max(np.abs(signal[-1]-signal[0]))
    step = np.max(np.abs(np.diff(signal,axis=0)))
    check(jump < .01 and jump < step, path.name+" periodic boundary smaller than internal steps")
    check(np.max(np.abs(signal)) < .51, path.name+" source headroom")

results = {}
if "--captures" in sys.argv:
    for path in sorted((ROOT/"test-results/phase-fifteen-one").glob("*.wav")):
        signal, rate = read(path)
        peak = float(np.max(np.abs(signal)))
        check(peak < .99, path.name+" no clipped samples")
        results[path.name] = {"seconds":len(signal)/rate, "peak_dbfs":float(20*np.log10(max(peak,1e-12))),
                              "rms_dbfs":float(20*np.log10(max(float(np.sqrt(np.mean(signal**2))),1e-12))),
                              "clipped_samples":int(np.count_nonzero(np.abs(signal)>=.99))}
    check("gameplay-mix.wav" in results and "loop-menu.wav" in results and "loop-gameplay.wav" in results,
          "expected real captures exist")
    (ROOT/"test-results/phase-fifteen-one/wave-analysis.json").write_text(json.dumps(results,indent=2)+"\n")
print(f"Resultado recursos musicales: {checks} comprobaciones, 0 fallos")
print(json.dumps(results,indent=2))
