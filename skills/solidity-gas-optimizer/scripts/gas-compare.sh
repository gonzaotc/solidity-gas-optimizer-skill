#!/usr/bin/env bash
# Compares current gas usage against a baseline recorded by gas-baseline.sh.
# Usage: gas-compare.sh <foundry|hardhat> <baseline-dir> [repo-root]
# Env: GAS_CMD, GAS_ENV, and TEST_FILES as in gas-baseline.sh; use identical values for both runs.
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo "Usage: gas-compare.sh <foundry|hardhat> <baseline-dir> [repo-root]" >&2
  exit 2
fi
fw="$1"; base="$2"
cd "${3:-.}"

case "$fw" in
  foundry)
    forge snapshot --diff "$base/gas.snapshot"
    ;;
  hardhat)
    if [ -n "${GAS_CMD:-}" ]; then
      sep=""
      if [ -n "${TEST_FILES:-}" ] && echo "$GAS_CMD" | grep -Eq '(npm|pnpm|yarn) run'; then
        sep="--"
      fi
      ${GAS_CMD} ${sep} ${TEST_FILES:-} > "$base/gas-report.new.txt" 2>&1 || { echo "TESTS=red"; exit 1; }
    else
      env "${GAS_ENV:-REPORT_GAS}=true" npx hardhat test ${TEST_FILES:-} > "$base/gas-report.new.txt" 2>&1 || { echo "TESTS=red"; exit 1; }
    fi
    echo "--- gas report diff (baseline < | current >) ---"
    diff "$base/gas-report.txt" "$base/gas-report.new.txt" || true
    echo "NOTE=reporter output is not line-deterministic; read the diff, do not count its lines"
    ;;
  *)
    echo "ERROR=unknown framework '$fw' (expected foundry or hardhat)"
    exit 1
    ;;
esac
