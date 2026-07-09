#!/usr/bin/env bash
# Detects the Solidity test/gas toolchain of a repo. Prints key=value lines.
# Usage: detect-toolchain.sh [repo-root]
set -uo pipefail
cd "${1:-.}" || { echo "ERROR=cannot cd to ${1:-.}"; exit 1; }

foundry=false; hardhat=false
[ -f foundry.toml ] && foundry=true
ls hardhat.config.* >/dev/null 2>&1 && hardhat=true

if ! $foundry && ! $hardhat; then
  echo "ERROR=no foundry.toml or hardhat.config.* found"
  exit 1
fi

if $foundry; then
  if command -v forge >/dev/null 2>&1; then
    echo "FOUNDRY=yes"
    echo "FOUNDRY_TEST_CMD=forge test"
    echo "FOUNDRY_TARGETED_TEST_CMD=forge test --match-path '*{Name}*' (or --match-contract {Name})"
    echo "FOUNDRY_SNAPSHOT_CMD=forge snapshot"
    echo "FOUNDRY_GAS_REPORT_CMD=forge test --gas-report"
    echo "FOUNDRY_SIZES_CMD=forge build --sizes"
    grep -E '^[[:space:]]*(optimizer|optimizer_runs|via_ir|solc|solc_version|evm_version)[[:space:]]*=' foundry.toml \
      | sed -E 's/[[:space:]]//g; s/^/FOUNDRY_CONFIG_/'
  else
    echo "FOUNDRY=configured-but-forge-missing"
  fi
fi

if $hardhat; then
  echo "HARDHAT=yes"
  echo "HARDHAT_TEST_CMD=npx hardhat test"
  echo "HARDHAT_TARGETED_TEST_CMD=npx hardhat test <specific test files>"
  [ -d node_modules ] || echo "WARN=node_modules missing; run the package manager install first"
  if grep -q '"hardhat-gas-reporter"' package.json 2>/dev/null; then
    echo "HARDHAT_GAS_REPORTER=installed (commonly toggled via REPORT_GAS=true or the gasReporter config block)"
  else
    echo "HARDHAT_GAS_REPORTER=not-found (measurement will be coarse; prefer foundry if available)"
  fi
fi

if $foundry && $hardhat; then
  echo "MEASURE_WITH=foundry"
  echo "NOTE=both frameworks present; foundry snapshots are deterministic per-test, prefer them for measurement"
elif $foundry; then
  echo "MEASURE_WITH=foundry"
else
  echo "MEASURE_WITH=hardhat"
fi
