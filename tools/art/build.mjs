// Writes the animals' SVGs into src/animals/art (committed; Godot imports them).
//   node tools/art/build.mjs
// Reproducible: the same scripts always write byte-identical files.
import { mkdirSync, writeFileSync, readdirSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Drawing, FULL, SIMPLE } from "../../addons/churrinche_kit/art/engraving.mjs";
import { ANIMALS, FULL_APPROVED } from "./animals.mjs";

const out = join(dirname(fileURLToPath(import.meta.url)), "../../src/animals/art");
mkdirSync(out, { recursive: true });
for (const f of readdirSync(out)) if (f.endsWith(".svg")) rmSync(join(out, f));

for (const { id, ink, draw } of ANIMALS) {
  const levels = FULL_APPROVED.includes(id) ? [["simple", SIMPLE], ["full", FULL]] : [["simple", SIMPLE]];
  for (const [name, level] of levels) {
    const dr = new Drawing(level);
    draw(dr, ink);
    writeFileSync(join(out, `${id}-${name}.svg`), dr.toSvg());
  }
}
console.log(`wrote ${readdirSync(out).filter((f) => f.endsWith(".svg")).length} SVGs to src/animals/art`);
