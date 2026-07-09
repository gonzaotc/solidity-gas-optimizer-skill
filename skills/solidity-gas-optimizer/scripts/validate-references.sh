#!/usr/bin/env bash
# Validates the reference catalog: card schema, ID uniqueness, per-file prefixes.
# Run from anywhere; exits nonzero on any violation. Intended as a PR gate.
set -uo pipefail
dir="$(cd "$(dirname "$0")/../references" && pwd)"
fail=0

declare -A prefixes=(
  [storage.md]=ST
  [deployment.md]=DEP
  [external-calls.md]=XC
  [architecture.md]=ARC
  [calldata.md]=CD
  [assembly.md]=ASM
  [execution.md]=EXE
  [forbidden.md]=FBD
)

dups=$(grep -h '^## ' "$dir"/*.md 2>/dev/null | awk '{print $2}' | sort | uniq -d)
if [ -n "$dups" ]; then
  echo "FAIL duplicate card IDs:"
  echo "$dups"
  fail=1
fi

for f in "$dir"/*.md; do
  name=$(basename "$f")
  case "$name" in INDEX.md|SOURCES.md) continue ;; esac
  prefix="${prefixes[$name]:-}"
  if [ -z "$prefix" ]; then
    echo "FAIL unknown reference file $name (add it to the prefix map in this script)"
    fail=1
    continue
  fi

  count=$(grep -c '^## ' "$f" || true)
  echo "$name: $count cards"

  bad=$(grep '^## ' "$f" | grep -v "^## $prefix-" || true)
  if [ -n "$bad" ]; then
    echo "FAIL wrong ID prefix in $name (expected $prefix-):"
    echo "$bad"
    fail=1
  fi

  awk -v file="$name" '
    function check(   n, req, i) {
      n = split("**Kind**,**Tier**,**Detect**,**Transform**,**Savings**,**Preconditions**,**Risks**,**Source**", req, ",")
      for (i = 1; i <= n; i++)
        if (index(body, req[i]) == 0) { printf "FAIL %s %s missing field %s\n", file, id, req[i]; bad = 1 }
    }
    /^## / { if (id != "") check(); id = $2; body = ""; next }
    { body = body $0 "\n" }
    END { if (id != "") check(); exit bad }
  ' "$f" || fail=1
done

if [ "$fail" -eq 0 ]; then
  echo "OK all reference cards valid"
else
  exit 1
fi
