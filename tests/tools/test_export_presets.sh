#!/usr/bin/env bash
# The export presets ship game_info.cfg (not a resource, so it needs include_filter) and carry the
# store feature: play for the Play build, itch for the web build and the itch.io APK.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cfg="$root/export_presets.cfg"
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1: $2" >&2; fail=1; fi; }
# Prints "name|custom_features|include_filter" per preset.
presets="$(awk -F'=' '/^\[preset\.[0-9]+\]$/{if(n)print n"|"f"|"i; n=f=i=""} /^name=/{n=$2} /^custom_features=/{f=$2} /^include_filter=/{i=$2} END{print n"|"f"|"i}' "$cfg")"
check test_three_presets '[ "$(echo "$presets" | wc -l | tr -d " ")" = 3 ]'
check test_every_preset_includes_game_info '! echo "$presets" | cut -d"|" -f3 | grep -vq "game_info.cfg"'
check test_play_android '[ "$(echo "$presets" | grep -c "^\"Android\"|\"play\"|")" = 1 ]'
check test_itch_web '[ "$(echo "$presets" | grep -c "^\"Web\"|\"itch\"|")" = 1 ]'
check test_itch_android '[ "$(echo "$presets" | grep -c "^\"Android itch\"|\"itch\"|")" = 1 ]'
check test_same_package '[ "$(grep -c "^package/unique_name=\"com.churrinche.bichoku\"" "$cfg")" = 2 ]'
# The Play preset builds an AAB with Gradle; the itch APK stays a plain template export.
play_block="$(awk '/^\[preset\.0\.options\]/{on=1;next} /^\[preset/{on=0} on' "$cfg")"
itch_block="$(awk '/^\[preset\.2\.options\]/{on=1;next} /^\[preset/{on=0} on' "$cfg")"
check test_play_is_a_gradle_aab 'grep -q "^gradle_build/use_gradle_build=true" <<< "$play_block" && grep -q "^gradle_build/export_format=1" <<< "$play_block" && grep -q "^export_path=\"build/android/bichoku.aab\"" "$cfg"'
check test_itch_apk_without_gradle 'grep -q "^gradle_build/use_gradle_build=false" <<< "$itch_block"'
# The Android build template is installed by tools/export.sh, never committed.
check test_build_template_is_ignored 'grep -qx "android/" "$root/.gitignore"'
# Both Android presets use the brand icon, never Godot's.
icons_ok=1
for key in main_192x192 adaptive_foreground_432x432 adaptive_background_432x432 adaptive_monochrome_432x432; do
  [ "$(grep -c "^launcher_icons/$key=\"res://src/brand/" "$cfg")" = 2 ] || icons_ok=0
done
check test_android_launcher_icons_are_ours '[ "$icons_ok" = 1 ]'
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
(cd "$root" && "$GODOT" --headless --export-pack Web "$work/web.pck" > "$work/out" 2>&1)
strings "$work/web.pck" > "$work/web.txt" 2> /dev/null
check test_exports_skip_the_build_folder '! grep -q "build/" "$work/web.txt" && [ "$(grep -c "^exclude_filter=\"[^\"]*build/\*" "$cfg")" = 3 ]'
check test_web_export_ships_game_info 'grep -q "game_info.cfg" "$work/web.txt" && grep -q "repo_url" "$work/web.txt"'
exit "$fail"
