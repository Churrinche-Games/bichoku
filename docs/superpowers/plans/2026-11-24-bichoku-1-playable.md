# Bichoku 1: playable game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A fully playable Bichoku in Godot with placeholder animals: the web engine ported (same seed, same puzzle), the web game rules, background puzzle generation, saving, the game screen with its dialogs, Spanish/English text, and a layout that fits every screen size.

**Architecture:** Pure logic in `RefCounted` scripts (`src/engine/`, `src/game/`), tested with GUT and driven by fixtures produced by the web engine; a thin UI in `src/screen/` and `src/board/` on top. Animals are placeholders (colored initials in each animal's ink) until plan 3 brings the art.

**Tech Stack:** Godot 4.7.2, GDScript (static typing), GUT 9.7.1, the vendored Churrinche kit `v0.2.0` (`SaveStore`), Node 26 only to produce test fixtures from `~/src/sudoku`.

**Spec:** `docs/superpowers/specs/2026-11-24-bichoku-design.md` (and the web version's code in `~/src/sudoku/src/engine` and `~/src/sudoku/src/features/game`, which this ports).

This is plan 1 of 4. Later plans: 2 kit modules (language switch, About, feedback, support, sound, theme, back button and safe area), 3 art (two checkpoints), 4 sound and the release candidate.

## Global Constraints

- Godot 4.7, static typing everywhere, TDD; `tools/check.sh` must pass before any task is done (it fails on GUT parse errors too).
- Never edit `addons/churrinche_kit`, `addons/gut` or the kit skills here.
- **Same seed, same puzzle as the web version**: the GDScript engine reproduces the committed web fixtures exactly.
- Difficulties: Easy `min_clues` 40, 3 hints; Medium 32, 2 hints; Hard 0 (as few as possible), 1 hint. `check_nodes` default 5000; fills of 20,000 steps, up to 100 attempts.
- Digit `d` is animal `d`: 1 yaguareté `#b07d1c`, 2 lobo marino `#6b5a4e`, 3 pingüino `#2f4a5c`, 4 cóndor `#5b3f8c`, 5 hornero `#b5532a`, 6 yacaré `#3d6b4f`, 7 flamenco `#9c3d6b`, 8 guanaco `#7d6b4a`, 9 ballena `#2a6a6e`. Paper `#f1e6d6`, line `#4a3b2e`, clash red `#c0392b`.
- Interface text through `tr()` keys only; Spanish rioplatense (voseo) and English. The first locale follows the device: Spanish for `es*`, else English (Godot's translation fallback `en`).
- Offline; no network, no permissions.
- Commit to `main`, no push, no AI attribution.

## Review Focus

1. **The app is closed in the middle of a game** (swiped away, phone restarts): reopening restores values, notes, hints used, elapsed time and difficulty exactly; undo history and selection are not kept (as on the web). `test_saved_game_round_trip` (Task 4).
2. **"New game" while the next puzzle is still being generated** (first launch, fast taps, switching difficulty): never freezes the screen; shows the preparing state and starts the game when it's ready. `test_take_before_ready_returns_null_then_ready` (Task 3).
3. **Switching difficulty or starting a new game with progress on the board**: asks before throwing the game away, unless it is won or nothing was entered (web behavior). `test_needs_confirm_to_discard` (Task 4).
4. **The clock while the app is in the background**: it stops. `test_clock_stops_when_focus_lost` (Task 6).
5. **A corrupt or old save file**: the game starts fresh instead of crashing (SaveStore moves it aside). `test_broken_save_starts_fresh` (Task 4).

---

### Task 1: Engine port with web fixtures

**Files:**
- Create: `tools/fixtures/make_engine_fixtures.mjs`, `tests/engine/fixtures.json`, `src/engine/rng.gd`, `src/engine/shape.gd`, `src/engine/solver.gd`, `src/engine/generator.gd`
- Test: `tests/engine/test_rng.gd`, `tests/engine/test_solver.gd`, `tests/engine/test_generator.gd`

**Interfaces:**
- Produces:
  - `class_name Mulberry32 extends RefCounted`: `_init(seed: int)`, `next_float() -> float` (identical sequence to the web `mulberry32`), `static func shuffle(items: Array, rng: Mulberry32) -> Array` (new array; same algorithm as the web `shuffle`).
  - `class_name Shape extends RefCounted`: `size: int`, `cell_count: int`, `houses: Array[PackedInt32Array]`, `cell_houses: Array[PackedInt32Array]`, `peers: Array[PackedInt32Array]` (cells sharing a house, excluding itself, ascending); `static func classic9() -> Shape` with cells `r * 9 + c` and houses in the web order: 9 rows, 9 columns, 9 boxes (boxes row-major).
  - `class_name Solver extends RefCounted` (static): `solve(shape, grid: PackedInt32Array, rng: Mulberry32 = null, max_nodes: int = -1) -> PackedInt32Array` (empty array when none or aborted); `uniqueness(shape, grid, max_nodes: int = -1) -> StringName` (`&"none"`, `&"unique"`, `&"multiple"`, `&"unknown"`); `count_solutions(shape, grid, limit: int = 2) -> int`; `is_valid(shape, grid) -> bool`; `is_complete(shape, grid) -> bool`.
  - `class_name Generator extends RefCounted`: `static func generate(shape: Shape, seed: int, min_clues: int = 0, check_nodes: int = 5000) -> Dictionary` returning `{"puzzle": PackedInt32Array, "solution": PackedInt32Array}`.

- [ ] **Step 1: Fixture script.** `tools/fixtures/make_engine_fixtures.mjs` imports `~/src/sudoku/src/engine/{random,shapes,solver,generator}.ts` (Node 26 strips types) and writes `tests/engine/fixtures.json`: `rng`: first 12 values for seeds `1`, `42`, `2026`, `4294967295`; `shuffle`: `shuffle([0..9], mulberry32(7))`; `solve`: `solve(classic(3,3), empty, {random: mulberry32(5), maxNodes: 20000})`; `generate`: for seeds `1, 2, 3` × `minClues` `40, 32, 0`, puzzle and solution. Run it with `node tools/fixtures/make_engine_fixtures.mjs`; commit the JSON (the script documents how to rebuild it).
- [ ] **Step 2: Failing tests.**
  - `test_rng_matches_web`: every fixture sequence, values equal within `1e-12`.
  - `test_shuffle_matches_web`.
  - `test_classic9_houses`: 27 houses of 9 cells; house 0 is `0..8`, house 9 is `0,9,…,72`, house 18 is `0,1,2,9,10,11,18,19,20`; every cell is in 3 houses and has 20 peers.
  - `test_solve_fixture_matches_web`.
  - `test_uniqueness`: a fixture puzzle is `unique`; the same puzzle with one clue removed until `multiple` is `multiple`; a grid with two equal digits in a row is `none`; `max_nodes = 1` on an empty grid is `unknown`.
  - `test_is_valid_and_complete` (fixture solution complete; a duplicate makes it invalid).
  - `test_generate_matches_web`: all 9 fixtures equal exactly.
  - `test_generated_puzzles_are_unique`: each fixture puzzle is `unique` with no budget.
- [ ] **Step 3: Run** `tools/check.sh`. Expected: fails on the unknown classes.
- [ ] **Step 4: Implement** the four scripts as a line-for-line port of the web engine (same branch order, same use of `rng` inside the search, same `bestCount` updates). `mulberry32` on 64-bit ints: keep values in `[0, 2^32)` with `& 0xFFFFFFFF`; implement `imul(a, b)` with 16-bit halves (`((a_hi * b_lo + a_lo * b_hi) << 16) + a_lo * b_lo`, masked) so nothing overflows; `>>>` is `>>` on the masked value. `Math.floor(random() * (i + 1))` is `int(floor(r * (i + 1)))`; `Math.log2(bit) + 1` is the bit's index + 1.
- [ ] **Step 5: Run** `tools/check.sh`. Expected: all engine tests pass. Note in the commit message how long `test_generate_matches_web` takes for the Hard fixtures (it bounds the on-device wait).
- [ ] **Step 6: Commit** `Port the puzzle engine from the web version, checked against its fixtures`.

### Task 2: Game rules

**Files:**
- Create: `src/game/difficulty.gd`, `src/game/game_state.gd`, `src/game/rules.gd`
- Test: `tests/game/test_rules.gd`

**Interfaces:**
- Consumes: `Shape.classic9()`, `Shape.peers`, `Shape.houses`.
- Produces:
  - `class_name Difficulty`: `const EASY := &"easy"`, `MEDIUM := &"medium"`, `HARD := &"hard"`, `const ALL: Array[StringName]`, `static func min_clues(d: StringName) -> int`, `static func hints(d: StringName) -> int`.
  - `class_name GameState extends RefCounted`: `difficulty: StringName`, `seed: int`, `puzzle`, `solution`, `values: PackedInt32Array`, `notes: PackedInt32Array` (bit `d-1` for digit `d`), `selected: int` (`-1` = none), `notes_mode: bool`, `history: Array` (of `{values, notes}`), `hints_used: int`, `elapsed_ms: int`, `won: bool`; `static func create(puzzle, solution, difficulty: StringName, seed: int) -> GameState`; `duplicate_state() -> GameState` (deep copy).
  - `class_name Rules extends RefCounted` (static, each returns a new `GameState`, never mutates its input): `select(s, cell: int)`, `input(s, digit: int)`, `erase(s)`, `undo(s)`, `hint(s)`, `toggle_notes(s)`, `tick(s, ms: int)`; queries `hints_left(s) -> int`, `counts_for_best(s) -> bool`, `conflicts(s) -> PackedInt32Array` (sorted cells), `remaining(s) -> PackedInt32Array` (9 counts, index `d-1`).

- [ ] **Step 1: Failing tests,** a port of `~/src/sudoku/src/features/game/game.test.ts` (read it; every case there becomes a GUT test with the same name in snake_case), plus:
  - `test_rules_never_mutate_input`: after each action the original state is unchanged.
  - `test_win_only_on_exact_solution`: a full valid grid that differs from the stored solution is not a win (cannot happen with unique puzzles, but the rule is "equals the solution").
  - `test_nothing_changes_after_win` except `select` and `toggle_notes`.
- [ ] **Step 2: Run** `tools/check.sh`. Expected: fails on unknown classes.
- [ ] **Step 3: Implement** to the web `game.ts` semantics (input in notes mode toggles a note only on an empty cell; placing clears the cell's notes and the digit from its peers' notes; erase only on a non-given cell with a value or notes; undo restores values and notes; hint order: selected cell if empty or wrong, else first wrong value, else the empty cell with the fewest options, ties by lowest index).
- [ ] **Step 4: Run** `tools/check.sh`. Expected: pass.
- [ ] **Step 5: Commit** `Add the game rules, ported from the web version`.

### Task 3: Background puzzle source

**Files:**
- Create: `src/game/puzzle_source.gd`
- Test: `tests/game/test_puzzle_source.gd`

**Interfaces:**
- Consumes: `Generator.generate`, `Difficulty.min_clues`, `GameState.create`.
- Produces: `class_name PuzzleSource extends RefCounted`:
  - `_init(seed_source: Callable = Callable())`: `seed_source() -> int` gives new seeds (default: `randi()`; tests pass a counter).
  - `signal ready(difficulty: StringName)`
  - `prepare(difficulty: StringName) -> void`: starts generating one puzzle for that difficulty on `WorkerThreadPool` unless one is ready or in progress.
  - `take(difficulty: StringName) -> GameState`: returns a ready game (and immediately calls `prepare` for the next one) or `null` if none is ready yet.
  - `wait_until_ready(difficulty: StringName) -> void` for tests only (blocks on the task).
  - `ready` is emitted on the main thread (`call_deferred`).

- [ ] **Step 1: Failing tests:** `test_take_before_ready_returns_null_then_ready` (first `take` is `null`, after `ready` the `take` returns a game whose puzzle equals `Generator.generate(Shape.classic9(), seed, 40)`), `test_take_prepares_the_next`, `test_difficulties_are_independent`, `test_prepare_twice_starts_one_job`.
- [ ] **Step 2: Run** `tools/check.sh`. Expected: fail.
- [ ] **Step 3: Implement.** One pending task id and one ready game per difficulty; the worker writes its result under a `Mutex`.
- [ ] **Step 4: Run** `tools/check.sh`. Expected: pass.
- [ ] **Step 5: Commit** `Generate puzzles in the background, one ready per difficulty`.

### Task 4: Saving

**Files:**
- Create: `src/game/game_store.gd`
- Test: `tests/game/test_game_store.gd`

**Interfaces:**
- Consumes: kit `SaveStore`, `GameState`, `Rules`.
- Produces: `class_name GameStore extends RefCounted`:
  - `_init(path: String = "user://bichoku.json")`, file version `1`.
  - `save_game(s: GameState) -> void` (without history and selection), `load_game() -> GameState` (`null` when none), `clear_game() -> void`.
  - `record_win(s: GameState) -> bool`: true when it set a new best (only if `Rules.counts_for_best(s)`); `best_ms(d: StringName) -> int` (`0` = none).
  - `settings() -> Dictionary` with defaults `{"animals_left": true, "mark_clashes": true, "show_numbers": false}`; `set_setting(key: String, value: Variant) -> void`.
  - `static func needs_confirm_to_discard(s: GameState) -> bool`: true when not won and at least one non-given cell has a value.

- [ ] **Step 1: Failing tests:** `test_saved_game_round_trip` (values, notes, hints_used, elapsed_ms, difficulty, seed, puzzle, solution equal; history empty; selected `-1`), `test_no_saved_game_returns_null`, `test_best_only_without_hints`, `test_best_keeps_the_faster`, `test_settings_defaults_and_changes`, `test_needs_confirm_to_discard` (empty board false; one entry true; won false), `test_broken_save_starts_fresh` (garbage file → `load_game()` null, settings defaults).
- [ ] **Step 2: Run** `tools/check.sh`. Expected: fail.
- [ ] **Step 3: Implement** on `SaveStore` (one file holding `game`, `best`, `settings`; `PackedInt32Array` stored as arrays of ints with int defaults so types come back).
- [ ] **Step 4: Run** `tools/check.sh`. Expected: pass.
- [ ] **Step 5: Commit** `Save the game, best times and settings`.

### Task 5: Animals and text

**Files:**
- Create: `src/animals/animals.gd`, `src/i18n/strings.csv`
- Modify: `project.godot` (`internationalization/locale/translations` lists the generated `strings.es.translation` and `strings.en.translation`; `internationalization/locale/fallback="en"`)
- Test: `tests/test_animals_and_text.gd`

**Interfaces:**
- Produces: `class_name Animals`: `const COUNT := 9`; `static func ink(digit: int) -> Color`; `static func initial(digit: int) -> String` (placeholder: `Y L P C H Yc F G B`); `static func id(digit: int) -> StringName` (`yaguarete, lobo_marino, pinguino, condor, hornero, yacare, flamenco, guanaco, ballena`); names and facts are tr keys `ANIMAL_<ID>_NAME`, `ANIMAL_<ID>_FACT`.
- `strings.csv`: `keys,es,en`; every interface string: title, difficulty names (`Fácil/Easy`, `Medio/Medium`, `Difícil/Hard`), `Pistas: %d / Hints: %d`, tools (`Deshacer, Borrar, Notas, Pista / Undo, Erase, Notes, Hint`), preparing (`Preparando…/Preparing…`), new game confirm, win texts (time, best, "best times only count games without hints"), settings labels, help text, and all animal names and facts (web facts in English and a rioplatense Spanish version; the lobo marino fact about its colonies at Península Valdés in both).

- [ ] **Step 1: Failing tests:** `test_inks_match_the_spec` (the nine colors from Global Constraints), `test_every_key_has_both_languages` (parse the CSV: no empty cell), `test_every_animal_has_name_and_fact_keys`, `test_spanish_uses_voseo` (`TranslationServer.set_locale("es")`: the help text contains `tocá` and no `toca `).
- [ ] **Step 2: Run** `tools/check.sh`. Expected: fail.
- [ ] **Step 3: Implement**; import the CSV (Godot generates the `.translation` files on import; commit the CSV and its `.import`).
- [ ] **Step 4: Run** `tools/check.sh`. Expected: pass.
- [ ] **Step 5: Commit** `Add the animals and the Spanish and English text`.

### Task 6: The game screen

**Files:**
- Create: `src/board/board_layout.gd`, `src/board/board_view.gd`, `src/screen/game_screen.tscn`, `src/screen/game_screen.gd`, `src/screen/settings_dialog.tscn/.gd`, `src/screen/win_dialog.tscn/.gd`, `src/screen/help_dialog.tscn/.gd`
- Modify: `project.godot` (`run/main_scene="res://src/screen/game_screen.tscn"`), remove `src/main/`, update `tests/test_smoke.gd` to the new main scene
- Test: `tests/board/test_board_layout.gd`, `tests/board/test_board_view.gd`, `tests/screen/test_game_screen.gd`

**Interfaces:**
- Consumes: everything above.
- Produces:
  - `class_name BoardLayout` (static): `column_width(viewport: Vector2) -> float` (`min(viewport.x, 720.0)`); `board_side(viewport: Vector2, chrome_height: float) -> float` (`min(column_width, viewport.y - chrome_height)`, never below 0).
  - `class_name BoardView extends Control`: `state: GameState` setter redraws; `show_numbers`, `mark_clashes: bool`; `signal cell_pressed(cell: int)`; `cell_at(local: Vector2) -> int` (`-1` outside).
  - `game_screen.gd` owns a `GameStore` and a `PuzzleSource`; every state change goes through `Rules`, then `GameStore.save_game`; the clock ticks once per second only while the window has focus (`NOTIFICATION_APPLICATION_FOCUS_OUT/IN`, also `NOTIFICATION_APPLICATION_PAUSED/RESUMED`).
- Look (spec Screen section): header (title, help, settings), difficulty tabs, clock and hints left, the square board, the palette of nine with counts (hidden when "animals left" is off; finished animals dim only when it's on), tools Undo/Erase/Notes/Hint. Board: paper fill, thin lines `1`, box lines `3`, selected cell fill `line @ 20%`, its row/column/box `line @ 7%`, same-animal underline, clash ring, givens bolder than entered animals, notes as dots in the animal's ink at its 3×3 spot (digits when "show numbers" is on). Keyboard: 1–9, arrows, Backspace, N, U or Ctrl+Z, H.
- New games: tapping a difficulty tab starts a new game of that difficulty, asking first when `GameStore.needs_confirm_to_discard` is true; the win dialog has "Nuevo juego / New game" (same difficulty). After any new game starts, `PuzzleSource.prepare` refills that difficulty.
- First launch: `PuzzleSource.prepare(easy)` and the preparing state until `ready`; then the saved game if any.

- [ ] **Step 1: Failing tests:**
  - `test_board_side_fits` at logical sizes `720×1280`, `720×1600`, `960×1280`, `2276×1280` with chrome `560`: side equals `min(column, height - 560)` and the column is centred.
  - `test_cell_at_corners_and_outside` for a 630 px board.
  - `test_clock_stops_when_focus_lost`: send focus-out, advance 3 s of ticks, `elapsed_ms` unchanged; focus-in resumes.
  - `test_nothing_overlaps_at_each_size`: instance the screen in a `SubViewport` at each logical size above; header, tabs, board, palette and tools rects lie inside the viewport and don't intersect.
  - `test_input_through_screen_saves` (tap a cell via `cell_pressed`, press a palette button, the store has the new value).
- [ ] **Step 2: Run** `tools/check.sh`. Expected: fail.
- [ ] **Step 3: Implement** the layout and views; dialogs use plain `PanelContainer`s (the kit theme comes in plan 2).
- [ ] **Step 4: Run** `tools/check.sh`. Expected: pass. Then run the game (`$GODOT --path . ` windowed, or a headless screenshot via `--write-movie` of one frame) and look at it at 720×1280 and 1080×2400.
- [ ] **Step 5: Commit** `Add the game screen with placeholder animals`.

### Task 7: Plan wrap-up

- [ ] **Step 1:** Update `CLAUDE.md` Architecture with `src/engine`, `src/game`, `src/board`, `src/screen`, `src/animals`, `src/i18n`, `tools/fixtures`.
- [ ] **Step 2: Run** `tools/check.sh`. Expected: pass. Export the web build once (`$GODOT --headless --export-release Web build/web/index.html`) to confirm the game exports.
- [ ] **Step 3: Commit** `Document the playable game's structure`.
