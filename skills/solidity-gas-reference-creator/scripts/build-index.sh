#!/usr/bin/env bash
# Generates the technique index (INDEX.md) from the category files, so the index
# can never drift from the cards. Cards are the source of truth: the ID and title
# come from each card heading, the remaining columns from its Kind/Tier/Hint fields,
# and the category table from the lead clause (up to the first colon) of each
# category file's header, so keep that clause a self-contained summary.
# Never edit INDEX.md by hand.
# Usage: build-index.sh [--check]
#   --check  regenerate to a temp file and diff against INDEX.md; exits nonzero
#            when the index is stale. Run by validate-references.sh as a PR gate.
set -euo pipefail
dir="$(cd "$(dirname "$0")/../../solidity-gas-optimizer/references" && pwd)"
files=(storage.md deployment.md external-calls.md architecture.md calldata.md assembly.md execution.md forbidden.md)

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

total=$(cat "${files[@]/#/$dir/}" | grep -c '^## ')

{
  echo "# Technique index"
  echo
  echo "Procedurally generated from the category files by \`build-index.sh\`; do not edit by hand."
  echo
  echo "The scan checklist: one row per technique, $total total. Each ID links to the category file holding the full card. Read this file in full when scanning; open a category file only when a Detect hint matches the code under review. Kind and tier semantics are defined in the audit skill's Reference catalog section and in the card spec."
  echo
  echo "## Categories"
  echo
  echo "Orientation for where a technique lives, not a filter: the scan still walks every hint below."
  echo
  echo "| Prefix | Category | Covers |"
  echo "|--------|----------|--------|"
  for f in "${files[@]}"; do
    prefix=$(awk '/^## / { split($2, a, "-"); print a[1]; exit }' "$dir/$f")
    desc=$(awk 'NR > 1 && NF { print; exit }' "$dir/$f" | sed 's/:.*//; s/|/\\|/g')
    echo "| $prefix | [$f]($f) | $desc |"
  done
  echo
  echo "## Techniques"
  echo
  echo "| ID | Technique | Kind | Tier | Detect hint |"
  echo "|----|-----------|------|------|-------------|"
  for f in "${files[@]}"; do
    awk -v file="$f" '
      function emit() { if (id != "") printf "| [%s](%s) | %s | %s | %s | %s |\n", id, file, title, kind, tier, hint }
      /^## /              { emit(); id=$2; title=$0; sub(/^## [A-Z]+-[0-9]+ · /, "", title); kind=tier=hint="" ; next }
      /^- \*\*Kind\*\*: / { kind=substr($0, 13) }
      /^- \*\*Tier\*\*: / { tier=substr($0, 13) }
      /^- \*\*Hint\*\*: / { hint=substr($0, 13); gsub(/\|/, "\\|", hint) }
      END                 { emit() }
    ' "$dir/$f"
  done
} > "$tmp"

if [ "${1:-}" = "--check" ]; then
  if ! diff -u "$dir/INDEX.md" "$tmp"; then
    echo "FAIL INDEX.md is stale; regenerate with build-index.sh"
    exit 1
  fi
  echo "OK INDEX.md is current"
else
  mv "$tmp" "$dir/INDEX.md"
  trap - EXIT
  echo "WROTE $dir/INDEX.md ($total techniques)"
fi
