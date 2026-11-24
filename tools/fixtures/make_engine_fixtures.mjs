// Writes tests/engine/fixtures.json from the web version's engine (~/src/sudoku), so the GDScript
// port can be checked to give the same numbers and the same puzzles for the same seeds.
// Rebuild with Node 26 (it runs the .ts files directly):
//   node tools/fixtures/make_engine_fixtures.mjs [path-to-sudoku-repo]
import { writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join, dirname } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const web = process.argv[2] ?? join(homedir(), 'src', 'sudoku')
const load = (name) => import(pathToFileURL(join(web, 'src', 'engine', `${name}.ts`)).href)
const { mulberry32, shuffle } = await load('random')
const { classic } = await load('shapes')
const { solve } = await load('solver')
const { generate } = await load('generator')

const shape = classic(3, 3)
const rng = {}
for (const seed of [1, 42, 2026, 4294967295]) {
  const r = mulberry32(seed)
  rng[seed] = Array.from({ length: 12 }, () => r())
}
const fixtures = {
  rng,
  shuffle: shuffle([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], mulberry32(7)),
  solve: solve(shape, new Array(81).fill(0), { random: mulberry32(5), maxNodes: 20000 }),
  generate: [],
}
for (const seed of [1, 2, 3]) {
  for (const minClues of [40, 32, 0]) {
    const { puzzle, solution } = generate(shape, { seed, minClues })
    fixtures.generate.push({ seed, minClues, puzzle, solution })
  }
}
const out = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'tests', 'engine', 'fixtures.json')
writeFileSync(out, JSON.stringify(fixtures, null, 1) + '\n')
console.log(`wrote ${out}`)
