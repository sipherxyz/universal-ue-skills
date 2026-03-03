#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install universal UE skills from GitHub without cloning the repository.

Usage:
  bash <(curl -fsSL https://raw.githubusercontent.com/buihuuloc/universal-ue-skills/main/scripts/install-from-github.sh) [options]

Options:
  --repo OWNER/REPO            GitHub repo (default: buihuuloc/universal-ue-skills)
  --ref BRANCH_OR_TAG          Git ref (default: main)
  --agent codex|claude|pi|both|all  Agent target (default: both)
  --scope global|project       Install scope (default: global)
  --project-dir PATH           Project root for project scope (default: current directory)
  --codex-dir PATH             Override Codex destination
  --claude-dir PATH            Override Claude destination
  --pi-dir PATH                Override Pi destination
  --dry-run                    Print actions only
  -h, --help                   Show this help

Examples:
  # Global install for both agents
  bash <(curl -fsSL https://raw.githubusercontent.com/buihuuloc/universal-ue-skills/main/scripts/install-from-github.sh)

  # Project-scoped install
  bash <(curl -fsSL https://raw.githubusercontent.com/buihuuloc/universal-ue-skills/main/scripts/install-from-github.sh) \
    --scope project --project-dir /Users/me/work/my-game
EOF
}

REPO="buihuuloc/universal-ue-skills"
REF="main"
PASSTHROUGH=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      PASSTHROUGH+=("$1")
      shift
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "tar is required" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_URL="https://codeload.github.com/${REPO}/tar.gz/${REF}"
ARCHIVE_PATH="$TMP_DIR/repo.tar.gz"

echo "Downloading ${REPO}@${REF} ..."
curl -fsSL "$ARCHIVE_URL" -o "$ARCHIVE_PATH"

tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

EXTRACTED_ROOT="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$EXTRACTED_ROOT" ]]; then
  echo "Failed to extract repository archive" >&2
  exit 1
fi

INSTALLER="$EXTRACTED_ROOT/scripts/install-skills.sh"
if [[ ! -x "$INSTALLER" ]]; then
  chmod +x "$INSTALLER"
fi

echo "Running installer from downloaded archive ..."
bash "$INSTALLER" "${PASSTHROUGH[@]}"
