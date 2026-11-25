#!/usr/bin/env bash
# Checks the rendered store graphics in build/store (made by tools/store.sh; not part of
# tools/check.sh, since rendering needs a window): sizes, no alpha channel, not blank.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
dir="${1:-$root/build/store}"
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1: $2" >&2; fail=1; fi; }
# "W H alpha" for a PNG.
info() { sips -g pixelWidth -g pixelHeight -g hasAlpha "$1" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} /hasAlpha/{a=$2} END{print w, h, a}'; }
bad=""
expect() { # file W H
  [ -f "$1" ] || { bad+=" missing:${1#"$dir"/}"; return; }
  [ "$(info "$1")" = "$2 $3 no" ] || bad+=" ${1#"$dir"/}:$(info "$1" | tr ' ' ',')"
  # A blank image compresses to almost nothing.
  [ "$(wc -c < "$1")" -gt 20000 ] || bad+=" blank:${1#"$dir"/}"
}
expect "$dir/icon-512.png" 512 512
for lang in es-419 en-US; do expect "$dir/feature-$lang.png" 1024 500; done
check test_icon_and_feature_graphics '[ -z "$bad" ]'
bad=""
for lang in es-419 en-US; do
  for size in 1080x1920 1080x2400 1600x1200 1280x720; do
    for scene in board notes win settings; do
      expect "$dir/screenshots/$lang/$size-$scene.png" "${size%x*}" "${size#*x}"
    done
  done
done
check test_screenshots '[ -z "$bad" ]'
exit "$fail"
