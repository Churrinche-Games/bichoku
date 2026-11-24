# Bichoku 2: kit modules — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the kit's shared modules (theme and sheet, language, game info and links, About/Feedback/Support, sound, mobile), release them as kit v0.3.0, and use them in Bichoku.

**Architecture:** Kit code lives in `~/src/game-kit/addons/churrinche_kit/<module>/`, knows no game, and is tested in the kit. Each game supplies a `res://game_info.cfg` (name, repo, feedback email, donation links) and fills the palette slots. Bichoku syncs the tag and replaces its own `Sheet` and theme with the kit's.

**Tech Stack:** Godot 4.7.2, GDScript (static typing), GUT 9.7.1, gdlint/gdformat.

**Spec:** `~/src/bichoku/docs/superpowers/specs/2026-11-24-bichoku-design.md` (sections Game → Settings/Language, Screen, Screen sizes, Kit modules built along the way, Sound); `~/src/game-kit/docs/superpowers/specs/2026-11-21-portfolio-design.md` (Donations, Kit).

## Global Constraints

- Kit modules must not know about Bichoku. Synced kit paths are never edited in the game.
- Play build: **no donation links or donation wording.** A build flag `store = play | itch` decides (Godot custom feature `itch`; anything else is `play`).
- Language: Spanish if the device locale starts with `es`, otherwise English; the setting overrides and is saved (`""` = follow the device).
- Sound: music and effects are separate on/off toggles in settings; **music off by default**, effects on.
- About: game name and version, "Source code on GitHub" link, licenses and credits.
- Feedback subject: "Comentarios sobre Bichoku v…" / "Feedback on Bichoku v…"; plus a GitHub issues link.
- Android back button closes an open dialog, else asks before leaving.
- Content stays inside the device safe area.
- Interface text rioplatense Spanish (voseo) and English. TDD. No AI attribution. Commit to main; never push.

## Review Focus

1. **Missing feedback email or donation links** (both are release blockers, so the first builds ship without them): the entries must hide, not open `mailto:` with no address or an empty Support sheet. → K3 tests.
2. **`game_info.cfg` not exported** (`.cfg` is not a resource; export_filter `all_resources` drops it): About would show nothing in the real build. → G3 test on `include_filter`.
3. **Changing language while a game is in progress**: the screen rebuilds; the game, clock and selection must survive and the settings sheet stays open. → G2 test.
4. **Back button with a sheet open over another state** (confirm-discard open, then back): closes that sheet only and never quits. → G5 test.
5. **Safe area with a tall notch on a short screen**: the board shrinks; nothing leaves the safe rect. → G5 test.

---

## Kit tasks (in `~/src/game-kit`)

### Task K1: Theme and sheet

**Files:**
- Create: `addons/churrinche_kit/ui/kit_theme.gd`, `addons/churrinche_kit/ui/kit_sheet.gd`
- Test: `tests/ui/test_kit_theme.gd`, `tests/ui/test_kit_sheet.gd`

**Interfaces — Produces:**
- `class_name KitTheme`: `static func make(palette: Dictionary) -> Theme`; `const SLOTS := ["paper", "line", "accent", "error"]`. Missing slot → `push_error` and a default color. Buttons: paper fill, line border 2, radius 16; pressed = line fill with paper text; disabled text = line at 0.4 alpha; Label/CheckButton font = line; PanelContainer panel = paper, radius 24; default font size 30. (Port of Bichoku's `_make_theme`.)
- `class_name KitSheet extends Control`: modal over its parent (dim + centered panel, width `min(560, parent width - 32)`), content in a `ScrollContainer` capped at 90% of the viewport height. `signal closed`; `add_title(text) -> Label`, `add_text(text) -> Label`, `add_check(text, value, on_toggle: Callable) -> CheckButton`, `add_button(text, on_press := Callable()) -> Button` (closes, then calls), `add_action(text, on_press: Callable) -> Button` (calls, stays open), `add_link(text, url) -> Button` (`KitLinks.open(url)`, stays open — K3 defines `KitLinks`; K1 adds it as a one-line static wrapper and K3 tests it), `add_choice(options: Array[Dictionary] /*{"text","value"}*/, current: Variant, on_pick: Callable) -> HBoxContainer` (toggle buttons, exactly one pressed), `close()`. All buttons ≥ 96 units tall, `FOCUS_NONE`.

- [ ] Tests: `test_theme_uses_palette_slots` (button normal stylebox bg == paper, border == line; Label font_color == line), `test_theme_missing_slot_errors` (assert_push_error), `test_sheet_button_closes_and_calls`, `test_action_and_link_stay_open` (link calls a stub opener with the url), `test_choice_presses_one` (pick second → only it pressed, on_pick got its value), `test_long_text_scrolls` (100 lines in a 720×1280 parent: the panel's height ≤ 1152), `test_closed_emitted_once`.
- [ ] Run, see them fail; implement; run `tools/check.sh`; commit "Add KitTheme and KitSheet".

### Task K2: Language and shared strings

**Files:**
- Create: `addons/churrinche_kit/i18n/kit_language.gd`, `addons/churrinche_kit/i18n/kit_strings.csv` (keys,es,en; Godot imports it to `kit_strings.{es,en}.translation`, committed like games do)
- Modify: `project.godot` (register the two translations, fallback `en`)
- Test: `tests/i18n/test_kit_language.gd`

**Interfaces — Produces:**
- `class_name KitLanguage`: `const SUPPORTED := ["es", "en"]`; `static func device_default(os_locale: String) -> String` (`es*` → `"es"`, else `"en"`); `static func resolve(saved: String, os_locale: String) -> String` (saved if supported, else device default); `static func apply(saved: String) -> String` (resolves with `OS.get_locale()`, calls `TranslationServer.set_locale`, returns it); `static func display_name(code: String) -> String` ("Español", "English").
- Strings (es / en), exact:
  - `KIT_CLOSE` Cerrar / Close; `KIT_CANCEL` Cancelar / Cancel
  - `KIT_LANGUAGE` Idioma / Language; `KIT_MUSIC` Música / Music; `KIT_EFFECTS` Efectos de sonido / Sound effects
  - `KIT_ABOUT` Acerca de / About; `KIT_VERSION` Versión %s / Version %s; `KIT_BY` Un juego de Churrinche Games / A Churrinche Games game; `KIT_SOURCE` Código fuente en GitHub / Source code on GitHub; `KIT_LICENSE_TEXT` "El código es libre (licencia MIT). El arte y el sonido son CC BY-NC 4.0: podés compartirlos dando crédito, sin fines comerciales. El nombre y el logo no están licenciados." / "The code is free software (MIT license). The art and sound are CC BY-NC 4.0: share them with credit, not commercially. The name and logo are not licensed."; `KIT_MADE_WITH` Hecho con Godot Engine / Made with Godot Engine; `KIT_LICENSES` Licencias de terceros / Third-party licenses
  - `KIT_FEEDBACK` Comentarios / Feedback; `KIT_FEEDBACK_TEXT` "Contanos qué te gustó, qué no, o si encontraste un error." / "Tell us what you liked, what you didn't, or a bug you found."; `KIT_FEEDBACK_EMAIL` Escribir un email / Send an email; `KIT_FEEDBACK_ISSUES` Abrir un issue en GitHub / Open an issue on GitHub; `KIT_FEEDBACK_SUBJECT` "Comentarios sobre %s v%s" / "Feedback on %s v%s"
  - `KIT_SUPPORT` Apoyar / Support; `KIT_SUPPORT_TEXT` "%s es gratis y de código abierto. Si te gusta, podés apoyarlo con una donación:" / "%s is free and open source. If you enjoy it, you can support it with a donation:"
  - `KIT_LEAVE_TITLE` ¿Salir de %s? / Leave %s?; `KIT_LEAVE_TEXT` Tu partida queda guardada. / Your game is saved.; `KIT_LEAVE_YES` Salir / Leave

- [ ] Tests: `test_device_default` (`es`, `es_AR`, `es-419` → es; `en_US`, `pt_BR`, `""` → en), `test_saved_overrides` (saved `en` with `es_AR` → en; saved `fr` → device default), `test_apply_sets_locale`, `test_every_key_has_both_languages` (parse the CSV: no empty cell, voseo check: KIT_FEEDBACK_TEXT es contains "Contanos"), `test_translations_load` (es translation has KIT_ABOUT = "Acerca de").
- [ ] Fail, implement, check, commit "Add KitLanguage and the shared strings".

### Task K3: Game info, links, About, Feedback, Support

**Files:**
- Create: `addons/churrinche_kit/info/kit_game_info.gd`, `addons/churrinche_kit/info/kit_links.gd`, `addons/churrinche_kit/info/kit_pages.gd`
- Test: `tests/info/test_kit_game_info.gd`, `tests/info/test_kit_pages.gd`, fixture `tests/info/game_info_full.cfg`, `tests/info/game_info_min.cfg`

**Interfaces — Produces:**
- `class_name KitLinks`: `static var opener: Callable = OS.shell_open`; `static func open(url: String) -> void`.
- `class_name KitGameInfo extends RefCounted`: `var name: String`, `var version: String` (from `application/config/version`), `var repo_url: String`, `var feedback_email: String`, `var support_links: Array[Dictionary]` (`{"name","url"}`). `static func from_file(path := "res://game_info.cfg") -> KitGameInfo` (sections `[game] name, repo_url`, `[feedback] email`, `[support] links = [["Ko-fi","https://…"], …]`; missing file or keys → empty values, `push_warning` for a missing file); `func issues_url() -> String` (`repo_url + "/issues"` or `""`); `func feedback_mailto(locale: String) -> String` (`""` without email; else `mailto:<email>?subject=<uri_encoded KIT_FEEDBACK_SUBJECT in that locale>`, using `TranslationServer.get_translation_object(locale)`); `static func store() -> StringName` (`&"itch"` if `OS.has_feature("itch")` else `&"play"`); `func support_links_for(store: StringName) -> Array[Dictionary]` (empty unless `&"itch"`).
- `class_name KitPages`: fill an open sheet. `static func about(sheet: KitSheet, info: KitGameInfo, on_licenses: Callable) -> void` (title name; text KIT_VERSION; KIT_BY; link KIT_SOURCE if repo_url; KIT_LICENSE_TEXT; KIT_MADE_WITH; action KIT_LICENSES → on_licenses; button KIT_CLOSE). `static func licenses(sheet: KitSheet) -> void` (Godot's `Engine.get_license_text()`, then each `Engine.get_copyright_info()` component name with its copyright lines and license id; KIT_CLOSE). `static func has_feedback(info) -> bool` (email or repo); `static func feedback(sheet, info) -> void` (KIT_FEEDBACK_TEXT; link email only if mailto non-empty; link issues only if repo); `static func has_support(info, store: StringName) -> bool`; `static func support(sheet, info, store) -> void` (KIT_SUPPORT_TEXT % name; one link per donation link).

- [ ] Tests: `test_reads_full_file`, `test_missing_file_is_empty` (assert warning, all empty), `test_mailto_subject_es_and_en` (`mailto:a@b.c?subject=Comentarios%20sobre%20Juego%20v1.2.3`; en "Feedback%20on%20…"), `test_no_email_no_mailto`, `test_store_is_play_here` (the test runner has no `itch` feature), `test_support_links_only_for_itch`, `test_about_has_version_and_source` (source link opens repo_url via stub opener), `test_about_without_repo_has_no_source_link`, `test_feedback_hides_missing_parts` (no email: only the issues link; neither: `has_feedback` false), `test_no_support_on_play` (`has_support(full, &"play")` false; itch true), `test_licenses_mention_godot` (sheet text contains "Godot Engine").
- [ ] Fail, implement, check, commit "Add game info, links, and the About, Feedback and Support pages".

### Task K4: Sound

**Files:** Create `addons/churrinche_kit/sound/kit_sound.gd`; Test `tests/sound/test_kit_sound.gd`.

**Interfaces — Produces:** `class_name KitSound extends Node`. `signal played(name: StringName)`; `var effects_on := true`; `var music_on := false` (setter starts or stops the music); `func add_effect(name: StringName, stream: AudioStream) -> void`; `func play(name: StringName) -> void` (no-op when off or unknown; round-robin over 4 `AudioStreamPlayer`s; emits `played` when it plays); `func set_music(stream: AudioStream) -> void` (looping; plays now if `music_on`); `func is_music_playing() -> bool` (music_on and a stream set and the player was started).

- [ ] Tests (streams: a 0.1 s `AudioStreamWAV` made in the test): `test_plays_known_effect`, `test_unknown_effect_is_silent`, `test_effects_off_is_silent`, `test_music_off_by_default`, `test_music_toggle_starts_and_stops`, `test_five_quick_effects_use_four_players` (no error; 5 `played`).
- [ ] Fail, implement, check, commit "Add KitSound".

### Task K5: Mobile, template, release v0.3.0

**Files:**
- Create: `addons/churrinche_kit/mobile/kit_mobile.gd`; Test `tests/mobile/test_kit_mobile.gd`
- Modify: `templates/game/project.godot` (kit translations, `application/config/quit_on_go_back=false`), `templates/game/export_presets.cfg` (Android `custom_features="play"`, Web `custom_features="itch"`, both `include_filter="game_info.cfg"`), create `templates/game/game_info.cfg` (`name="{{NAME}}"`, `repo_url="https://github.com/churrinche-games/{{SLUG}}"`, empty email and links), `tests/tools/test_new_game.sh` (asserts for those), `kit_version.gd` → `"0.3.0"`, `CHANGELOG.md`, `CLAUDE.md` Architecture.

**Interfaces — Produces:** `class_name KitMobile`: `static func safe_rect(window: Vector2i, safe: Rect2i, canvas: Vector2) -> Rect2` (the safe area in canvas units; scale `canvas / window`; clipped to the canvas; zero window → full canvas); `static func current_safe_rect(viewport: Viewport) -> Rect2` (on `OS.has_feature("mobile")` uses `DisplayServer.get_display_safe_area()` and `window_get_size()`; elsewhere the full visible rect); `static func is_back(what: int) -> bool` (`NOTIFICATION_WM_GO_BACK_REQUEST`).

- [ ] Tests: `test_full_safe_area_is_full_canvas`, `test_notch_and_gesture_bar` (window 1080×2400, safe (0,120,1080,2220), canvas 720×1600 → Rect2(0,80,720,1480)), `test_zero_window`, `test_not_mobile_is_full_rect`; shell: `test_template_has_game_info_and_features`.
- [ ] Fail, implement, check, update docs, commit "Add KitMobile; template ships game_info.cfg and store features", then "Release 0.3.0" and `git tag v0.3.0`.

## Game tasks (in `~/src/bichoku`)

### Task G1: Sync v0.3.0, use the kit theme and sheet

- Run `~/src/game-kit/tools/sync-kit.sh v0.3.0 ~/src/bichoku`. Register `res://addons/churrinche_kit/i18n/kit_strings.{es,en}.translation` in `project.godot`; `application/config/quit_on_go_back=false`.
- Delete `src/screen/sheet.gd`; GameScreen uses `KitSheet` and `KitTheme.make({"paper": PAPER, "line": LINE, "accent": Color("#b5532a"), "error": Color("#b3261e")})`. `CLOSE`/`CANCEL` game strings replaced by `KIT_CLOSE`/`KIT_CANCEL`.
- [ ] Existing screen tests pass unchanged; add `test_uses_kit_sheet` (help opens a `KitSheet`). Commit "Sync kit v0.3.0 and use its theme and sheet".

### Task G2: Language switch

- `GameStore.DEFAULT_SETTINGS` gains `"language": ""`, `"music": false`, `"effects": true`.
- `_ready` calls `KitLanguage.apply(settings.language)` before building. Settings sheet: KIT_LANGUAGE title + `add_choice` (Español/English, current = resolved code). Picking saves the code, applies it, rebuilds the screen's controls (`_rebuild()`: free the column and rebuild, keep `state`, the sheet reopens as settings).
- [ ] Tests: `test_language_follows_saved_setting` (saved `en` → tab text "Easy"), `test_switching_language_keeps_the_game` (switch to es mid-game: tab "Fácil", same `state.values`, `selected`, `elapsed_ms`; a settings sheet is open; saved setting `es`). Restore locale `en` in `after_each`. Commit "Switch language in settings".

### Task G3: About, Feedback, Support

- Create `game_info.cfg` (`name="Bichoku"`, `repo_url="https://github.com/churrinche-games/bichoku"`, `email=""`, `links=[]`). Export presets: Android `custom_features="play"`, Web `custom_features="itch"`, add preset "Android itch" (APK for itch.io, `custom_features="itch"`, same package and options, export path `build/itch/bichoku.apk`); every preset `include_filter="game_info.cfg"`.
- Settings sheet entries after the toggles: About (always), Feedback (if `KitPages.has_feedback`), Support (if `KitPages.has_support(info, KitGameInfo.store())`). About's licenses action opens the licenses sheet.
- [ ] Tests: `test_about_opens_with_version` (text contains "0.1.0"), `test_no_donation_words_in_play_settings` (every Button/Label text in the settings sheet, in es and en, contains none of "don", "apoy", "support", "Ko-fi", "Cafecito"), `test_support_shown_for_itch_with_links` (screen var `store_override := &"itch"` and an info with one link → a Support button), `test_feedback_hidden_without_email_or_repo` is covered in K3; here `test_feedback_shows_issues_link`. Shell: `tests/tools/test_export_presets.sh` (each preset has `include_filter` with game_info.cfg; Android preset has feature play; Web and Android itch have itch). Commit "Add About, Feedback and Support to settings".

### Task G4: Sound toggles

- A `KitSound` child of the screen; settings sheet gets checks KIT_MUSIC and KIT_EFFECTS, saved in `music`/`effects`, applied to the `KitSound` on start and on change. No sounds yet (plan 4); `GameScreen.sound` is public for tests.
- [ ] Tests: `test_sound_settings_default` (music off, effects on, applied to `sound`), `test_toggling_music_saves` (reload store: music true; `sound.music_on` true). Commit "Add music and effects toggles".

### Task G5: Back button and safe area

- `_notification`: on `KitMobile.is_back(what)`: if a sheet is open, close it; else open the leave sheet (KIT_LEAVE_TITLE % name, KIT_LEAVE_TEXT, KIT_LEAVE_YES → save and `quit_handler.call()`, KIT_CANCEL). `var quit_handler: Callable` defaults to `get_tree().quit`.
- `_layout` works inside `KitMobile.current_safe_rect(get_viewport())`, or `safe_rect_override` when it has area (tests).
- [ ] Tests: `test_back_closes_open_sheet` (open confirm-discard, back → no sheet, not quit), `test_back_asks_then_leaves` (back → leave sheet; press Leave → stub quit called, game saved), `test_layout_inside_safe_rect` (sizes × override Rect2(0, 100, w, h-180): every part's global rect inside the safe rect; at 720×1280 with that override the board is still ≥ 560 square). Commit "Back button and safe areas".

### Task G6: Docs and final check

- Update `CLAUDE.md` (Architecture: kit modules, `game_info.cfg`, store features). `tools/check.sh` green; screenshot settings and About in es at 720×1280 for the report. Then the final fresh review of both repos' changes.
