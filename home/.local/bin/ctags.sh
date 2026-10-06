#!/usr/bin/env bash
set -euo pipefail

tags="$PWD/tags"
root=$(realpath "${1:-$PWD}")

exec 9<"$PWD"
flock 9

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export LC_ALL=C

base=("$root" -type f -not -name tags
  -not -path '*/.git/*' -not -path '*/build/*'
  -not -path '*/target/*' -not -path '*/__pycache__/*')

find "${base[@]}" | sort > "$tmp/all"

# files already in tags that live under $root
: > "$tmp/known"
if [[ -f $tags ]]; then
  { rg -v '^!' "$tags" || true; } | cut -f2 | sort -u \
    | awk -v p="$root/" 'index($0, p) == 1' > "$tmp/known"
fi

if [[ -s $tmp/known ]]; then
  find "${base[@]}" -newer "$tags" > "$tmp/files"
  comm -23 "$tmp/known" "$tmp/all" > "$tmp/gone"
else
  cp "$tmp/all" "$tmp/files"
  : > "$tmp/gone"
fi

[[ -s $tmp/files || -s $tmp/gone ]] || exit 0

parallel -j "$(nproc)" -n 50 ctags --sort=no -f - {} < "$tmp/files" > "$tmp/new"

if [[ -f $tags ]]; then
  cat "$tmp/files" "$tmp/gone" | sed 's/^/\t/; s/$/\t/' > "$tmp/pat"
  rg -vF -f "$tmp/pat" "$tags" > "$tmp/old" || true
else
  : > "$tmp/old"
fi

sort -u "$tmp/new" -o "$tmp/new"
sort -mu "$tmp/old" "$tmp/new" > "$tmp/tags"
mv "$tmp/tags" "$tags"
