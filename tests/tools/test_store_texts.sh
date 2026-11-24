#!/usr/bin/env bash
# Store listing texts fit Play's limits and never mention donations; the privacy policy says no
# data is collected, in both languages.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1: $2" >&2; fail=1; fi; }
# A listing file has "## Title", "## Short description" and "## Full description" sections.
section() { awk -v h="## $2" '$0 == h { on = 1; next } /^## / { on = 0 } on' "$1" | sed '/^[[:space:]]*$/d'; }
chars() { printf '%s' "$1" | wc -m | tr -d ' '; }
for lang in es-419 en-US; do
  f="$root/docs/store/listing.$lang.md"
  check "test_${lang}_exists" '[ -f "$f" ]'
  [ -f "$f" ] || continue
  title="$(section "$f" "Title")"; short="$(section "$f" "Short description")"; full="$(section "$f" "Full description")"
  check "test_${lang}_title_fits" '[ -n "$title" ] && [ "$(chars "$title")" -le 30 ]'
  check "test_${lang}_short_fits" '[ -n "$short" ] && [ "$(chars "$short")" -le 80 ]'
  check "test_${lang}_full_fits" '[ -n "$full" ] && [ "$(chars "$full")" -le 4000 ]'
  check "test_${lang}_no_donations" '! grep -qiE "don(a|ó)|donat|apoy|support (the|us|it)|ko-fi|cafecito|sponsor|paypal" "$f"'
done
p="$root/docs/privacy-policy.md"
check test_privacy_policy_both_languages '[ -f "$p" ] && grep -qi "no recopila" "$p" && grep -qi "does not collect" "$p"'
check test_release_checklist '[ -f "$root/docs/release-checklist.md" ]'
exit "$fail"
