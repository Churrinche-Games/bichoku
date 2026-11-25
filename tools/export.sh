#!/usr/bin/env bash
# Exports the itch.io builds into build/ (no Gradle; debug-signed APK, the release key is Juan's):
#   tools/export.sh web        build/web/index.html (+ .pck, .wasm, .js): zip the folder for itch
#   tools/export.sh itch-apk   build/itch/bichoku.apk
# Then checks what it built.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$root"
# Godot must never import or export build outputs.
mkdir -p build && touch build/.gdignore
case "${1:-}" in
  web)
    rm -rf "${root:?}/build/web" && mkdir -p build/web
    "$GODOT" --headless --export-release Web build/web/index.html
    for f in index.html index.pck index.wasm index.js; do [ -s "build/web/$f" ] || { echo "missing build/web/$f" >&2; exit 1; }; done
    # itch wants index.html at the zip's root.
    (cd build/web && rm -f ../bichoku-web.zip && zip -qr ../bichoku-web.zip .)
    echo "ok   build/web and build/bichoku-web.zip"
    ;;
  itch-apk)
    rm -rf "${root:?}/build/itch" && mkdir -p build/itch
    "$GODOT" --headless --export-debug "Android itch" build/itch/bichoku.apk
    listing="$(unzip -l build/itch/bichoku.apk)"
    for f in classes.dex AndroidManifest.xml; do
      grep -q " $f\$" <<< "$listing" || { echo "APK lacks $f" >&2; exit 1; }
    done
    echo "ok   build/itch/bichoku.apk ($(du -h build/itch/bichoku.apk | cut -f1))"
    ;;
  *) echo "usage: tools/export.sh web|itch-apk" >&2; exit 2 ;;
esac
