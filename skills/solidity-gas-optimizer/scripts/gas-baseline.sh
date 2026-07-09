#!/usr/bin/env bash
# Records a gas baseline for later comparison.
# Usage: gas-baseline.sh <foundry|hardhat> <output-dir> [repo-root]
# Env: GAS_ENV overrides the variable enabling the hardhat reporter (default REPORT_GAS;
#      some configs use GAS via yargs .env('')). TEST_FILES optionally scopes the run.
set -euo pipefail
fw="$1"; out="$2"
cd "${3:-.}"
mkdir -p "$out"

case "$fw" in
  foundry)
    forge snapshot --snap "$out/gas.snapshot"
    forge build --sizes > "$out/sizes.txt" 2>/dev/null || true
    echo "BASELINE=$out/gas.snapshot"
    ;;
  hardhat)
    env "${GAS_ENV:-REPORT_GAS}=true" npx hardhat test ${TEST_FILES:-} > "$out/gas-report.txt" 2>&1
    echo "BASELINE=$out/gas-report.txt"
    echo "NOTE=hardhat baseline is the reporter table; only functions the tests exercise appear in it"
    ;;
  *)
    echo "ERROR=unknown framework '$fw' (expected foundry or hardhat)"
    exit 1
    ;;
esac
