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
tools/store.sh   # store graphics and screenshots into build/store, then checks them (opens a window;
                 # the check is tests/release/test_store_assets.sh, outside check.sh)
tools/export.sh web|itch-apk   # the itch builds into build/ (the APK needs the Java SDK path in Godot)
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
src/animals/           animals.gd: ids, inks, textures, name/fact translation keys; art/*.svg (generated,
                       committed: tools/art/build.mjs with the kit's engraving library)
src/sound/             effects and music WAVs (generated, committed: tools/sound/build.mjs with the kit's synth)
src/board/             board_layout.gd (screen-size math), board_view.gd (draws the board)
src/screen/            game_screen.tscn/.gd (the screen, built in code; help, settings, win, confirm,
                       leave use the kit's KitSheet; About/Feedback/Support are the kit's KitPages)
src/i18n/strings.csv   the game's interface text, es and en; shared KIT_* strings come from the kit.
                       Language: KitLanguage (device default es/en, setting overrides)
game_info.cfg          name, repo, feedback email, donation links for the kit pages (exported via include_filter)
tests/                 GUT tests mirroring src/; tests/engine/fixtures.json from the web engine
tools/fixtures/        make_engine_fixtures.mjs: rebuild the fixtures (Node 26, needs ~/src/sudoku)
tools/art/             animals.mjs (the nine drawings), build.mjs, contact_sheet.gd (review sheet PNG),
                       brand.mjs (src/brand: icons, feature graphic), render_store.gd (store PNGs)
tools/shots/           screenshots.gd (store screenshots, any size and language)
tools/sound/           build.mjs (effects and music)
docs/store/, docs/privacy-policy.md, docs/release-checklist.md   listing texts, policy, Juan's release steps
addons/churrinche_kit/ the kit (vendored, see Repo)
addons/gut/            GUT (vendored with the kit)
export_presets.cfg     Android (Play, feature `play`), Web and Android itch (feature `itch`, the only
                       builds that may show donations); tests, GUT, docs and tools are excluded
docs/superpowers/      specs/ and plans/ (plans 1–2 done; 3 up to art checkpoint 1; 4 part 1: sound and store texts)
```

- Art and sound are generated: change the scripts and rebuild (`node tools/art/build.mjs`, `node tools/sound/build.mjs`), never edit the outputs; the shell tests fail when outputs and scripts disagree.
- Art checkpoint 1 (shapes) is waiting for Juan; only the penguin and hornero have full-level drawings.
- Rules never mutate a GameState; every screen change goes through Rules and is saved.

## Conventions

- Code, comments, commit messages and docs in English. Interface text in rioplatense Spanish (voseo) and English.
- **TDD is the rule:** write a failing test first, watch it fail, then write the minimal code to pass.
- `project.godot` is rewritten by the Godot editor (comments dropped, keys reordered), so its reasons live here: `default_texture_filter=2` (Linear Mipmap) because the engravings are downscaled a lot in board cells; `boot_splash/show_image=false` so no Godot logo shows; `quit_on_go_back=false` because Back opens the leave sheet.
- Feature folders in `src/`; tests in `tests/` mirroring them. Pure logic in plain `RefCounted` scripts, out of nodes and scenes.
- Static typing in GDScript everywhere.
- Art follows the kit's engraving style (design doc, Art direction; reference `~/src/game-kit/tools/art/engraving-study.html`).
- Pin new dependencies to existing major versions; don't add a dependency when a few lines will do.
- Keystores and passwords never enter the repo.
- Never add co-author or AI attribution to commits or PRs.
- Commit to `main`; push only when asked.
