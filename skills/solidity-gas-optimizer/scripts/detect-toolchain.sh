#!/usr/bin/env bash
# Detects the Solidity test/gas toolchain of a repo. Prints key=value lines.
# Exits nonzero when the repo cannot be gas-measured: that is a prerequisite
# failure and the skill must stop.
# Usage: detect-toolchain.sh [repo-root] [target]
#   target: optional contract file or name. When both toolchains exist, it
#   decides MEASURE_WITH from where the target's tests actually live.
set -uo pipefail
cd "${1:-.}" || { echo "ERROR=cannot cd to ${1:-.}"; exit 1; }
target="${2:-}"
target_name=""
if [ -n "$target" ]; then
  target_name="$(basename "$target")"
  target_name="${target_name%.sol}"
fi

foundry=false; hardhat=false
forge_ok=false; hardhat_measurable=false
[ -f foundry.toml ] && foundry=true
ls hardhat.config.* >/dev/null 2>&1 && hardhat=true

if ! $foundry && ! $hardhat; then
  echo "ERROR=no foundry.toml or hardhat.config.* found; supported toolchains are Foundry and Hardhat"
  exit 1
fi

if $foundry; then
  if command -v forge >/dev/null 2>&1; then
    forge_ok=true
    echo "FOUNDRY=yes"
    echo "FOUNDRY_TEST_CMD=forge test"
    echo "FOUNDRY_TARGETED_TEST_CMD=forge test --match-path '*{Name}*' (or --match-contract {Name})"
    echo "FOUNDRY_SNAPSHOT_CMD=forge snapshot"
    echo "FOUNDRY_GAS_REPORT_CMD=forge test --gas-report"
    echo "FOUNDRY_SIZES_CMD=forge build --sizes"
    grep -E '^[[:space:]]*(optimizer|optimizer_runs|via_ir|solc|solc_version|evm_version)[[:space:]]*=' foundry.toml \
      | sed -E 's/[[:space:]]//g; s/^/FOUNDRY_CONFIG_/'
    if grep -q 'node_modules' foundry.toml 2>/dev/null && [ ! -d node_modules ]; then
      echo "WARN=node_modules missing but foundry.toml references it; run the package manager install first"
    fi
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
    hardhat_measurable=true
    echo "HARDHAT_GAS_REPORTER=installed"
    hh_config="$(ls hardhat.config.* 2>/dev/null | head -1)"
    toggle=""
    if [ -n "$hh_config" ]; then
      if grep -q 'REPORT_GAS' "$hh_config" 2>/dev/null; then
        toggle="REPORT_GAS=true"
      elif grep -Eq 'argv\.gas|\.env\(' "$hh_config" 2>/dev/null; then
        toggle="GAS=true (yargs .env option)"
      elif grep -Eq 'gasReporter[^}]*enabled' "$hh_config" 2>/dev/null; then
        toggle="gasReporter.enabled flag in config"
      fi
    fi
    if [ -n "$toggle" ]; then
      echo "HARDHAT_GAS_TOGGLE=$toggle"
      echo "NOTE=gas toggle is a best guess from the config; verify before relying on it"
    else
      echo "HARDHAT_GAS_TOGGLE=unknown; commonly REPORT_GAS=true or a gasReporter config flag"
      echo "NOTE=could not detect the gas toggle; read the hardhat config to confirm"
    fi
  else
    echo "HARDHAT_GAS_REPORTER=not-found"
  fi
fi

# Per-target test coverage: which framework's tests exercise the target.
foundry_covers=false; hardhat_covers=false
if [ -n "$target_name" ]; then
  while IFS= read -r f; do
    if echo "$f" | grep -qi "$target_name" || grep -qi "$target_name" "$f" 2>/dev/null; then
      foundry_covers=true; break
    fi
  done < <(find . -name '*.t.sol' 2>/dev/null)
  while IFS= read -r f; do
    if echo "$f" | grep -qi "$target_name" || grep -qi "$target_name" "$f" 2>/dev/null; then
      hardhat_covers=true; break
    fi
  done < <(find . \( -name '*.test.js' -o -name '*.test.ts' -o -name '*.spec.js' -o -name '*.spec.ts' \) 2>/dev/null)
fi

if $forge_ok && $hardhat && [ -n "$target_name" ]; then
  if $foundry_covers; then
    echo "MEASURE_WITH=foundry"
    echo "NOTE=$target_name has Foundry test coverage; measuring there"
  elif $hardhat_measurable && $hardhat_covers; then
    echo "MEASURE_WITH=hardhat"
    echo "NOTE=forge exists but $target_name has no Foundry test coverage while Hardhat covers it; measuring with Hardhat"
  else
    echo "MEASURE_WITH=foundry"
    echo "WARN=no test found exercising $target_name; gas table will be empty"
  fi
elif $forge_ok; then
  echo "MEASURE_WITH=foundry"
  $hardhat && echo "NOTE=both frameworks present; confirm per target where its tests live before measuring"
elif $hardhat_measurable; then
  echo "MEASURE_WITH=hardhat"
  echo "NOTE=reporter tables only cover functions the tests exercise"
else
  echo "ERROR=no gas measurement available; install forge (Foundry) or add hardhat-gas-reporter, then rerun"
  exit 1
fi
