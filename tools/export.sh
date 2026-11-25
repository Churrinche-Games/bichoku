#!/usr/bin/env bash
# Exports the builds into build/ (debug-signed; the release key is Juan's):
#   tools/export.sh web        build/web/index.html (+ .pck, .wasm, .js): zip the folder for itch
#   tools/export.sh itch-apk   build/itch/bichoku.apk
#   tools/export.sh aab        build/android/bichoku.aab, the Play build (Gradle), debug-signed: for
#                              trying it out; Play rejects a debuggable bundle. Installs the Android
#                              build template into android/ (ignored by git) if it is missing; the
#                              first run downloads Gradle into ~/.gradle.
#   tools/export.sh aab-release  the same, release-signed with the upload key named by
#                              GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER and _PASSWORD (never in the repo).
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
  aab|aab-release)
    mode=--export-debug
    if [ "$1" = aab-release ]; then
      for v in PATH USER PASSWORD; do
        var="GODOT_ANDROID_KEYSTORE_RELEASE_$v"
        [ -n "${!var:-}" ] || { echo "set $var (the upload key; never commit it)" >&2; exit 2; }
      done
      mode=--export-release
    fi
    rm -rf "${root:?}/build/android" && mkdir -p build/android
    template=()
    [ -d android/build ] || template=(--install-android-build-template)
    "$GODOT" --headless ${template[@]+"${template[@]}"} "$mode" Android build/android/bichoku.aab
    [ -s build/android/bichoku.aab ] || { echo "no AAB written" >&2; exit 1; }
    grep -q "base/manifest/AndroidManifest.xml" <<< "$(unzip -l build/android/bichoku.aab)" || { echo "AAB lacks its manifest" >&2; exit 1; }
    echo "ok   build/android/bichoku.aab ($(du -h build/android/bichoku.aab | cut -f1))"
    ;;
  *) echo "usage: tools/export.sh web|itch-apk|aab|aab-release" >&2; exit 2 ;;
esac
