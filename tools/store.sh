#!/usr/bin/env bash
# Renders the Play store graphics and screenshots into build/store, then checks them.
# Opens a window for a few seconds per language (text needs a renderer).
#   tools/store.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
out="$root/build/store"
rm -rf "${out:?}"
node "$root/tools/art/brand.mjs" > /dev/null
"$GODOT" --path "$root" -s tools/art/render_store.gd -- "$out"
"$GODOT" --path "$root" -s tools/shots/screenshots.gd -- "$out/screenshots/es-419" es
"$GODOT" --path "$root" -s tools/shots/screenshots.gd -- "$out/screenshots/en-US" en
bash "$root/tests/release/test_store_assets.sh" "$out"
