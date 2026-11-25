// Writes Bichoku's sound effects and music into src/sound (committed; Godot imports them).
//   node tools/sound/build.mjs
// Soft, short, paper-and-wood sounds; the music is a plucked 6/8 arpeggio with a zamba's sway.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { RATE, tone, noise, pluck, envelope, mix, loopFold, normalize, wav } from "../../addons/churrinche_kit/sound/synth.mjs";

const out = join(dirname(fileURLToPath(import.meta.url)), "../../src/sound");
mkdirSync(out, { recursive: true });
const hz = (midi) => 440 * Math.pow(2, (midi - 69) / 12);
const finish = (s, peak, release = 0.03) => normalize(envelope(s, { attack: 0.002, release }), peak);

/** A short bell: a sine with a quieter octave, fading. */
function bell(freq, dur) {
  const s = mix(dur, [[tone({ freq, dur, gain: 0.6 }), 0], [tone({ freq: freq * 2, dur, gain: 0.2 }), 0]]);
  for (let i = 0; i < s.length; i++) s[i] *= Math.exp((-6 * i) / s.length);
  return s;
}

const effects = {
  // A woody tock: a damped pluck and a tiny click.
  place: finish(mix(0.12, [[pluck({ freq: hz(69), dur: 0.12, seed: 1, damping: 0.985 }), 0], [envelope(noise({ dur: 0.006, seed: 2, gain: 0.4 }), {}), 0]]), 0.6, 0.05),
  // A light tick.
  note: finish(tone({ freq: 1320, dur: 0.05, wave: "triangle", gain: 0.5 }), 0.32, 0.03),
  // Two low, soft thuds.
  clash: finish(mix(0.22, [
    [envelope(tone({ freq: 190, freqEnd: 120, dur: 0.09, gain: 0.7 }), { release: 0.04 }), 0],
    [envelope(tone({ freq: 170, freqEnd: 105, dur: 0.1, gain: 0.7 }), { release: 0.05 }), 0.11],
  ]), 0.6, 0.04),
  // A rising three-note chime (E5 G5 A5).
  hint: finish(mix(0.3, [[bell(hz(76), 0.14), 0], [bell(hz(79), 0.14), 0.08], [bell(hz(81), 0.14), 0.16]]), 0.5, 0.06),
  // A short falling blip.
  undo: finish(tone({ freq: 520, freqEnd: 340, dur: 0.11, wave: "triangle", gain: 0.5 }), 0.45, 0.04),
  // A firework: a soft low thump, then a sparse crackle that dies away (one per burst on the win).
  pop: finish(mix(0.4, [
    [envelope(tone({ freq: 150, freqEnd: 55, dur: 0.14, gain: 0.8 }), { release: 0.08 }), 0],
    ...Array.from({ length: 14 }, (_, k) => [
      envelope(noise({ dur: 0.008, seed: 40 + k, gain: 0.5 * Math.pow(0.86, k) }), { attack: 0.001, release: 0.004 }),
      0.05 + k * 0.021 + ((k * 7) % 5) * 0.004,
    ]),
  ]), 0.55, 0.05),
  // A plucked phrase up the A minor pentatonic.
  win: finish(mix(1.3, [69, 72, 76, 79, 81].map((m, i) => [pluck({ freq: hz(m), dur: 0.7, seed: 10 + i, damping: 0.997 }), i * 0.15])), 0.7, 0.15),
};

// Music: eight bars of 6/8 at 60 dotted-quarter bpm (an eighth is 1/3 s): Am Dm G C F Dm E Am,
// bass on the first eighth, then the chord's tones up and back down.
const CHORDS = [
  [45, 52, 57, 60, 64], [50, 57, 62, 65, 69], [43, 50, 55, 59, 62], [48, 55, 60, 64, 67],
  [41, 48, 53, 57, 60], [50, 57, 62, 65, 69], [40, 47, 52, 56, 59], [45, 52, 57, 60, 64],
];
const EIGHTH = 1 / 3, BAR = 6 * EIGHTH, LOOP = CHORDS.length * BAR;
const parts = [];
let seed = 100;
CHORDS.forEach(([bass, ...up], bar) => {
  const t0 = bar * BAR;
  parts.push([pluck({ freq: hz(bass), dur: 2.4, seed: seed++, gain: 0.6, damping: 0.998 }), t0]);
  [up[0], up[1], up[2], up[3], up[2]].forEach((m, k) => {
    parts.push([pluck({ freq: hz(m), dur: 1.6, seed: seed++, gain: 0.32, damping: 0.996 }), t0 + (k + 1) * EIGHTH]);
  });
});
const music = normalize(loopFold(mix(LOOP + 2.5, parts), Math.round(LOOP * RATE)), 0.5);

for (const [name, s] of Object.entries({ ...effects, music })) writeFileSync(join(out, `${name}.wav`), wav(s));
console.log(`wrote ${Object.keys(effects).length + 1} sounds to src/sound`);
