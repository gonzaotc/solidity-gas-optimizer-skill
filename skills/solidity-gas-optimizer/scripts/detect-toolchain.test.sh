#!/usr/bin/env bash
# Smoke tests for detect-toolchain.sh exit contract: a measurable repo must exit 0,
# an unmeasurable one must exit nonzero. Guards the Foundry-only regression where a
# healthy repo printed success yet exited 1.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
detect="$here/detect-toolchain.sh"
fail=0

run_case() {
  local name="$1" want="$2"; shift 2
  local dir; dir="$(mktemp -d)"
  ( cd "$dir" && "$@" )   # setup, run inside the fixture
  "$detect" "$dir" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then
    echo "PASS $name (exit $got)"
  else
    echo "FAIL $name: want exit $want, got $got"
    fail=1
  fi
  rm -rf "$dir"
}

setup_foundry_only() { : > foundry.toml; }
setup_empty()        { :; }

if command -v forge >/dev/null 2>&1; then
  run_case "foundry-only exits 0" 0 setup_foundry_only
else
  echo "SKIP foundry-only: forge not installed"
fi
run_case "empty dir exits nonzero" 1 setup_empty

if [ "$fail" -eq 0 ]; then
  echo "OK detect-toolchain smoke tests passed"
else
  exit 1
fi
