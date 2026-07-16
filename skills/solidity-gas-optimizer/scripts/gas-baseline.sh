#!/usr/bin/env bash
# Records a gas baseline for later comparison. For Foundry it also captures a
# per-function gas report (RANKING output) used to rank hot functions in Phase 1.3;
# the snapshot stays the diff baseline of record and the two are not interchangeable.
# Usage: gas-baseline.sh <foundry|hardhat> <output-dir> [repo-root]
# Env: GAS_CMD is the full hardhat gas command from detect-toolchain.sh
#      (HARDHAT_GAS_CMD, e.g. "npm run test:gas" or "npx hardhat test --gas-stats").
#      Prefer it. When unset, GAS_ENV overrides the legacy HH2 reporter variable
#      (default REPORT_GAS; some configs use GAS via yargs .env('')).
#      TEST_FILES optionally scopes the run.
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo "Usage: gas-baseline.sh <foundry|hardhat> <output-dir> [repo-root]" >&2
  exit 2
fi
fw="$1"
out="$(mkdir -p "$2" && cd "$2" && pwd)"
cd "${3:-.}"

trap 'echo "BASELINE_FAILED=$fw baseline failed; see output above" >&2' ERR

case "$fw" in
  foundry)
    forge snapshot --snap "$out/gas.snapshot"
    forge build --sizes > "$out/sizes.txt" 2>/dev/null || true
    echo "BASELINE=$out/gas.snapshot"
    if forge test --gas-report > "$out/gas-report.txt" 2>/dev/null && [ -s "$out/gas-report.txt" ]; then
      echo "RANKING=$out/gas-report.txt"
      echo "NOTE=gas.snapshot is the diff baseline of record; gas-report.txt is per-function data for ranking only and is not comparable to snapshot totals"
    else
      echo "WARN=gas-report capture failed or is empty; rank functions from a manual 'forge test --gas-report' run and keep gas.snapshot as the baseline of record"
    fi
    ;;
  hardhat)
    if [ -n "${GAS_CMD:-}" ]; then
      # Package-manager scripts need `--` to forward file args to the underlying command.
      sep=""
      if [ -n "${TEST_FILES:-}" ] && echo "$GAS_CMD" | grep -Eq '(npm|pnpm|yarn) run'; then
        sep="--"
      fi
      ${GAS_CMD} ${sep} ${TEST_FILES:-} > "$out/gas-report.txt" 2>&1
    else
      env "${GAS_ENV:-REPORT_GAS}=true" npx hardhat test ${TEST_FILES:-} > "$out/gas-report.txt" 2>&1
    fi
    echo "BASELINE=$out/gas-report.txt"
    echo "NOTE=hardhat baseline is the reporter table; only functions the tests exercise appear in it"
    ;;
  *)
    echo "ERROR=unknown framework '$fw' (expected foundry or hardhat)"
    exit 1
    ;;
esac
