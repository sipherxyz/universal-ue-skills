#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-both}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="$ROOT_DIR/skills"

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "Skills directory not found: $SKILLS_SRC" >&2
  exit 1
fi

install_to() {
  local dest="$1"
  mkdir -p "$dest"
  for dir in "$SKILLS_SRC"/*; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    rm -rf "$dest/$name"
    cp -R "$dir" "$dest/$name"
  done
  echo "Installed skills to: $dest"
}

case "$TARGET" in
  codex)
    install_to "$HOME/.codex/skills"
    ;;
  claude|claude-code)
    install_to "$HOME/.claude/skills"
    ;;
  both)
    install_to "$HOME/.codex/skills"
    install_to "$HOME/.claude/skills"
    ;;
  *)
    echo "Usage: $0 [codex|claude|both]" >&2
    exit 1
    ;;
esac
