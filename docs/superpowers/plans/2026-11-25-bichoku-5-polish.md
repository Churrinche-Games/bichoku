# Bichoku 5: music on, a mute button, win fireworks — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Juan's requests after the release-candidate screenshots (2026-11-25): music on by default; a mute button on the main screen; more fanfare when you win (small fireworks).

**Decisions:**
- (Juan) Music on by default.
- (Me, asked by Juan) The mute button sits next to "?", and it does not replace the switches in Ajustes. It silences music and effects together; tapping it again restores what the switches say. The switches cover finer choices (music off, effects on). `muted` is a saved setting.
- (Me) Fireworks: about 2 s of bursts over the whole screen, in the animals' inks, drawn by a `Fireworks` control above the win sheet. They ignore input. Each burst plays a soft `pop` effect (synthesized like the others).

## Tasks

### P1: music on by default, Cmd+Z
- `GameStore.DEFAULT_SETTINGS.music = true`; the test becomes `test_music_is_loaded_and_on_by_default`; spec (Sound) updated.
- Undo also on Cmd+Z (macOS), next to Ctrl+Z and U.

### P2: the mute button
- `src/brand` gets `sound-on.svg` and `sound-off.svg` (a speaker in the line colour; `brand.mjs`).
- Header: title, `?`, the speaker, Ajustes. Its tooltip reads "Silenciar"/"Mute" or "Activar sonido"/"Unmute".
- Tests: the button mutes music and effects and its icon changes; unmuting restores the switches; the mute is saved and survives a restart; the switches in Ajustes still work while unmuted.

### P3: fireworks
- `src/screen/fireworks.gd` (`Fireworks extends Control`): seeded, so tests are deterministic. Six bursts 0.28 s apart, each with 36 sparks in one of the six brighter inks; about 2.4 s in all; the sparks fly out, fall and fade, and then the node frees itself. It emits `burst(index)`. `MOUSE_FILTER_IGNORE`.
- `GameScreen`: on the winning move, after the win sheet, add a `Fireworks` on top. Each burst plays `pop`.
- `tools/sound/build.mjs`: `pop`, a soft thump and crackle (≤ 0.4 s, peak ≤ 0.8, zero at the ends; the existing sound tests apply).
- Tests: the winning move adds fireworks above the sheet; they ignore the mouse; they use only the animals' inks; they free themselves after their duration; each burst plays `pop`; muted means no pops.

## As built

- The review found the win sound cut off by the fourth pop (KitSound's round robin): fixed in kit v0.5.3, where a new effect takes the player that frees up first.
- A new game ends the last show; the show fills the screen (tests).
- Help keys: on the web a touchscreen counts as no keyboard (iPad Safari reports macOS).
