#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"

fail() {
  echo "validation failed: $*" >&2
  exit 1
}

[[ -d "$SKILLS_DIR" ]] || fail "missing skills directory"

skill_count=0
while IFS= read -r -d '' skill; do
  skill_count=$((skill_count + 1))
  grep -q '^name: ' "$skill" || fail "missing name in ${skill#$ROOT_DIR/}"
  grep -q '^description: ' "$skill" || fail "missing description in ${skill#$ROOT_DIR/}"

  expected_name="$(basename "$(dirname "$skill")")"
  actual_name="$(sed -n 's/^name: //p' "$skill" | head -n 1)"
  [[ "$actual_name" == "$expected_name" ]] || fail "name must match directory in ${skill#$ROOT_DIR/}"

  description="$(sed -n 's/^description: //p' "$skill" | head -n 1)"
  description_words="$(wc -w <<<"$description" | tr -d ' ')"
  [[ "$description_words" -le 30 ]] || fail "description exceeds 30 words in ${skill#$ROOT_DIR/}"
done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | sort -z)

[[ "$skill_count" -gt 0 ]] || fail "no skills found"

if find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d ! -exec test -f '{}/SKILL.md' \; -print -quit | grep -q .; then
  fail "every top-level skill directory must contain SKILL.md"
fi

for retired in setup-bpgenerator sipher-asset-mcp ue-setup-neostack-aik; do
  [[ ! -e "$SKILLS_DIR/$retired" ]] || fail "retired integration remains: $retired"
done

if grep -R -n -E 'Legacy Metadata|AskUserQuestion|TodoWrite|Task tool' "$SKILLS_DIR"; then
  fail "retained legacy tool vocabulary"
fi

echo "validated ${skill_count} skills"
