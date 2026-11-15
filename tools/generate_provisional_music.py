"""Two original, provisional instrumental scores. NumPy + Python stdlib only.

No samples or borrowed melodies. Output is CC0-1.0; see assets/music/README.md.
Circular note tails and delay make the rendered timeline periodic.
"""
import hashlib
import json
import wave
from pathlib import Path
import numpy as np

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets" / "music"


def compose(name, bpm, bars, chords, motif, seed):
    rng = np.random.default_rng(seed)
    beat = 60 / bpm
    count = round(bars * 4 * beat * RATE)
    score = np.zeros((count, 2), dtype=np.float64)

    def note(midi, start, duration, gain, pan, kind="pad"):
        length = round(duration * RATE)
        t = np.arange(length) / RATE
        frequency = 440 * 2 ** ((midi - 69) / 12)
        if kind == "pad":
            # Slowly bowed harmonic timbre, not a square-wave alarm.
            signal = sum(np.sin(2 * np.pi * frequency * h * t + .12 * np.sin(2*np.pi*.17*t)) / h**2
                         for h in (1, 2, 3, 4))
            envelope = np.sin(np.pi * np.arange(length) / (length-1))**1.7
        elif kind == "bell":
            signal = (np.sin(2*np.pi*frequency*t) + .22*np.sin(2*np.pi*frequency*2.003*t)
                      + .09*np.sin(2*np.pi*frequency*3.99*t))
            envelope = (1-np.exp(-t/.018)) * np.exp(-t/1.15) * np.minimum(1, (duration-t)/.2)
        else:
            signal = np.sin(2*np.pi*frequency*t + 1.5*np.exp(-t/.04))
            envelope = (1-np.exp(-t/.012))*np.exp(-t/.23)*np.minimum(1,(duration-t)/.1)
        signal *= gain * envelope
        stereo = signal[:, None] * np.array([np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)])
        indices = (round(start*RATE) + np.arange(length)) % count
        np.add.at(score, indices, stereo)

    bar = 4*beat
    for i in range(bars):
        chord = chords[i % len(chords)]
        for voice, midi in enumerate(chord):
            note(midi, i*bar-.35, bar+1.4, .105 if name=="menu_last_frequency" else .085,
                 -.65+voice*.4)
        note(chord[0]-12, i*bar, bar+1, .11, -.1)
        if name=="menu_last_frequency":
            # Eight-bar statement: sparse opening, answered motif, quiet resolution.
            for offset, interval in motif[i % len(motif)]:
                note(62+interval, i*bar+offset*beat, 2.6, .105, rng.uniform(-.45,.45), "bell")
            if i in (2,3,6,7):note(35, i*bar+2*beat, .8, .045, 0, "pulse")
        else:
            if i % 3 != 1:
                note(chord[-1]+12, i*bar+1.5*beat, 3.5, .055, rng.uniform(-.6,.6), "bell")
            for offset in (0, 2.75):note(33, i*bar+offset*beat, .85, .045, 0, "pulse")
    # Wrapped stereo delays: the last chord's reverb is present at the first sample.
    dry = score.copy()
    for delay, gain in ((.31,.20),(.67,.13),(1.13,.08),(1.71,.045)):
        score += np.roll(dry[:, ::-1], round(delay*RATE), axis=0)*gain
    score -= score.mean(axis=0)
    score *= .5 / np.max(np.abs(score))
    pcm = np.rint(score*32767).astype("<i2")
    path = ROOT / f"{name}.wav"
    with wave.open(str(path), "wb") as output:
        output.setparams((2,2,RATE,0,"NONE","not compressed"))
        output.writeframes(pcm.tobytes())
    difference = np.abs(np.diff(score, axis=0))
    return {"file":path.name,"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
            "bpm":bpm,"bars":bars,"seconds":count/RATE,"sample_rate":RATE,
            "channels":2,"peak_dbfs":float(20*np.log10(np.max(np.abs(score)))),
            "rms_dbfs":float(20*np.log10(np.sqrt(np.mean(score**2)))),
            "boundary_step":float(np.max(np.abs(score[0]-score[-1]))),
            "maximum_internal_step":float(difference.max()),"bytes":path.stat().st_size}


if __name__ == "__main__":
    ROOT.mkdir(parents=True, exist_ok=True)
    tracks = [compose("menu_last_frequency",72,8,
                      [[50,57,65,76],[46,57,62,65],[48,55,62,74],[45,57,60,64]],
                      [[(1,0),(2.5,7)],[(.5,3),(2,2)],[(1,0),(3,12)],[(1,7),(2.5,2)]],151),
              compose("gameplay_streets",60,12,
                      [[38,57,60,64],[38,53,57,62],[46,53,60,65],
                       [43,53,58,62],[45,52,59,64],[38,57,60,65]],[],152)]
    (ROOT/"MANIFEST.json").write_text(json.dumps({"license":"CC0-1.0","provisional":True,"tracks":tracks},indent=2)+"\n",encoding="utf-8")
    print(json.dumps(tracks,indent=2))
