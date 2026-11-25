// Writes Bichoku's brand art into src/brand (committed; Godot imports it, and tools/art/render_store.gd
// rasterizes the store graphics from it):
//   icon.svg             the app icon (project icon, web favicon, Android launcher, Play icon)
//   icon-foreground.svg  Android adaptive icon: the animal inside the 66 dp safe zone, transparent
//   icon-background.svg  Android adaptive icon: paper and the board's grid
//   feature.svg          Play feature graphic, 1024×500 (the name is added by render_store.gd)
//   sound-on.svg, sound-off.svg   the mute button's icons
//   node tools/art/brand.mjs
// Reproducible: the same scripts always write byte-identical files.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Drawing, FULL, PAPER, SIMPLE, fmt } from "../../addons/churrinche_kit/art/engraving.mjs";
import { ANIMALS } from "./animals.mjs";

// The board's colours (src/board/board_view.gd).
const LINE = "#4a3b2e";
const GIVEN = "#e3d2ba";

const out = join(dirname(fileURLToPath(import.meta.url)), "../../src/brand");
mkdirSync(out, { recursive: true });

const animal = (id) => ANIMALS.find((a) => a.id === id);

/** An animal drawn at a level, placed with its 200-unit-wide drawing w units wide at (x, y). */
function place(a, level, x, y, w) {
  const dr = new Drawing(level);
  a.draw(dr, a.ink);
  const k = w / 200;
  return `<g transform="translate(${fmt(x)} ${fmt(y)}) scale(${fmt(k)}) translate(-10 -20)">\n${dr.items.join("\n")}\n</g>`;
}

const paper = `<rect x="0" y="0" width="100%" height="100%" fill="${PAPER}"/>`;

/** A 3×3 grid of cells (size c) at (x, y): given cells shaded, inner lines thin, the box thick. */
function board(x, y, c, { givens = [], inner = 1.5, outer = 4, color = LINE } = {}) {
  const parts = givens.map(
    (i) => `<rect x="${fmt(x + (i % 3) * c)}" y="${fmt(y + Math.floor(i / 3) * c)}" width="${fmt(c)}" height="${fmt(c)}" fill="${GIVEN}"/>`,
  );
  let d = "";
  for (let k = 1; k < 3; k++) {
    d += `M${fmt(x + k * c)},${fmt(y)}V${fmt(y + 3 * c)}M${fmt(x)},${fmt(y + k * c)}H${fmt(x + 3 * c)}`;
  }
  parts.push(`<path d="${d}" fill="none" stroke="${color}" stroke-width="${fmt(inner)}"/>`);
  if (outer > 0) {
    parts.push(`<rect x="${fmt(x)}" y="${fmt(y)}" width="${fmt(3 * c)}" height="${fmt(3 * c)}" fill="none" stroke="${color}" stroke-width="${fmt(outer)}"/>`);
  }
  return parts.join("\n");
}

const svg = (w, h, body) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">\n${body}\n</svg>\n`;

// The icon: the yaguareté over a faint board running off the edges. The simple level: the full one
// washes out at the 48–96 px an icon is mostly seen at (compared at checkpoint 2's end).
// The shaded centre cell is the board's given treatment.
const jaguar = animal("yaguarete");
const iconGrid = board(-8, -8, 176, { givens: [4], inner: 8, outer: 0, color: GIVEN });
writeFileSync(join(out, "icon.svg"), svg(512, 512, [paper, iconGrid, place(jaguar, SIMPLE, 66, 70, 380)].join("\n")));

// Adaptive icon (432 = 108 dp): the launcher masks to at most the central 66 dp (264 px).
writeFileSync(join(out, "icon-foreground.svg"), svg(432, 432, place(jaguar, SIMPLE, 91, 93, 250)));
writeFileSync(join(out, "icon-background.svg"), svg(432, 432, [paper, board(-9, -9, 150, { givens: [4], inner: 7, outer: 0, color: GIVEN })].join("\n")));

// Feature graphic: the nine animals on a 3×3 board on the right; the left half is left for the name.
const fc = 140, fx = 560, fy = 40;
const featureBody = [paper, board(fx, fy, fc, { givens: [0, 4, 8], inner: 2, outer: 5 })];
ANIMALS.forEach((a, i) => {
  const w = fc * 0.84;
  featureBody.push(place(a, FULL, fx + (i % 3) * fc + (fc - w) / 2, fy + Math.floor(i / 3) * fc + (fc - w * 0.98) / 2, w));
});
writeFileSync(join(out, "feature.svg"), svg(1024, 500, featureBody.join("\n")));

// The mute button's two states: a speaker with sound waves, and the speaker crossed out.
const speaker = `<path d="M10,25 H21 L34,13 V51 L21,39 H10 Z" fill="${LINE}" stroke="${LINE}" stroke-width="3" stroke-linejoin="round"/>`;
const stroke = (d) => `<path d="${d}" fill="none" stroke="${LINE}" stroke-width="4.5" stroke-linecap="round"/>`;
writeFileSync(join(out, "sound-on.svg"), svg(64, 64, [speaker, stroke("M41,24 Q46,32 41,40"), stroke("M47,17 Q57,32 47,47")].join("\n")));
writeFileSync(join(out, "sound-off.svg"), svg(64, 64, [speaker, stroke("M42,24 L56,40 M56,24 L42,40")].join("\n")));

console.log("wrote 6 SVGs to src/brand");
