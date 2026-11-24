# Bichoku

A small, free, open-source, Argentine-themed game by Churrinche Games, made with Godot for Android (Google Play) and the web (itch.io).

**Start here:** read [docs/superpowers/specs/2026-11-24-bichoku-design.md](docs/superpowers/specs/2026-11-24-bichoku-design.md), the game's design. The portfolio's design (brand, art direction, release process) is in the kit: `~/src/game-kit/docs/superpowers/specs/2026-11-21-portfolio-design.md`.

## Repo

- Local git only, no remote. Pushing anywhere happens only when Juan says so. The future home is `github.com/churrinche-games/bichoku` (public).
- Created from Churrinche kit `v0.2.0`. The kit is vendored: `addons/churrinche_kit`, `addons/gut` and the skills listed in `.claude/skills/.kit-skills` are **never edited here**. Fix things in `~/src/game-kit`, tag a kit release, then run `~/src/game-kit/tools/sync-kit.sh <tag> .` here and commit.
- Android package: `com.churrinche.bichoku`. It is permanent once the game is on Google Play.

## Environment

- Godot 4.7.2 at `/Applications/Godot.app/Contents/MacOS/Godot` (scripts read `$GODOT`).
- gdtoolkit (`gdlint`, `gdformat`), JDK 17 and the Android SDK are installed (see the kit's CLAUDE.md).

## Commands

```sh
tools/check.sh   # everything: import, GUT tests, shell tests, lint, format. Must pass before work is done.
```

GUT exits 0 when a test script fails to parse, so use `tools/check.sh`, not bare GUT, to call something done.

## Architecture

```
project.godot          portrait 720x1280, mobile renderer; main scene src/screen/game_screen.tscn
src/engine/            the puzzle engine, ported from ~/src/sudoku (same seed, same puzzle):
                       rng.gd (Mulberry32), shape.gd (cells + houses), solver.gd, generator.gd
src/game/              difficulty.gd, game_state.gd, rules.gd (pure rules, port of the web game.ts),
                       puzzle_source.gd (background generation, one ready per difficulty),
                       game_store.gd (saved game, best times, settings on the kit's SaveStore)
src/animals/           animals.gd: ids, inks, placeholder initials, name/fact translation keys
src/board/             board_layout.gd (screen-size math), board_view.gd (draws the board)
src/screen/            game_screen.tscn/.gd (the screen, built in code), sheet.gd (help, settings, win, confirm)
src/i18n/strings.csv   all interface text, es and en (Godot picks the device language, fallback en)
tests/                 GUT tests mirroring src/; tests/engine/fixtures.json from the web engine
tools/fixtures/        make_engine_fixtures.mjs: rebuild the fixtures (Node 26, needs ~/src/sudoku)
addons/churrinche_kit/ the kit (vendored, see Repo)
addons/gut/            GUT (vendored with the kit)
export_presets.cfg     Android and Web; tests, GUT, docs and tools are excluded from exports
docs/superpowers/      specs/ and plans/ (plan 1 of 4 done: the playable game)
```

- The animals are placeholders (colored initials) until the art plan; the inks are final candidates.
- Rules never mutate a GameState; every screen change goes through Rules and is saved.

## Conventions

- Code, comments, commit messages and docs in English. Interface text in rioplatense Spanish (voseo) and English.
- **TDD is the rule:** write a failing test first, watch it fail, then write the minimal code to pass.
- Feature folders in `src/`; tests in `tests/` mirroring them. Pure logic in plain `RefCounted` scripts, out of nodes and scenes.
- Static typing in GDScript everywhere.
- Art follows the kit's engraving style (design doc, Art direction; reference `~/src/game-kit/tools/art/engraving-study.html`).
- Pin new dependencies to existing major versions; don't add a dependency when a few lines will do.
- Keystores and passwords never enter the repo.
- Never add co-author or AI attribution to commits or PRs.
- Commit to `main`; push only when asked.
