#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install universal UE skills for Codex and/or Claude Code.

Usage:
  scripts/install-skills.sh [codex|claude|both] [global|project] [project-dir]
  scripts/install-skills.sh [options]

Options:
  --agent codex|claude|both   Agent target (default: both)
  --scope global|project      Install scope (default: global)
  --project-dir PATH          Project root when scope=project (default: current directory)
  --source-dir PATH           Skills source directory (default: <repo>/skills)
  --codex-dir PATH            Override Codex skills destination
  --claude-dir PATH           Override Claude skills destination
  --dry-run                   Print actions without copying
  -h, --help                  Show this help

Examples:
  scripts/install-skills.sh both global
  scripts/install-skills.sh codex project /Users/me/work/my-game
  scripts/install-skills.sh --agent claude --scope project --project-dir .
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="both"
SCOPE="global"
PROJECT_DIR="$(pwd)"
SKILLS_SRC="$ROOT_DIR/skills"
CODEX_DIR=""
CLAUDE_DIR=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    codex|claude|claude-code|both)
      AGENT="$1"
      shift
      ;;
    global|project)
      SCOPE="$1"
      shift
      ;;
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --scope)
      SCOPE="${2:-}"
      shift 2
      ;;
    --project-dir)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    --source-dir)
      SKILLS_SRC="${2:-}"
      shift 2
      ;;
    --codex-dir)
      CODEX_DIR="${2:-}"
      shift 2
      ;;
    --claude-dir)
      CLAUDE_DIR="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$AGENT" == "claude-code" ]]; then
  AGENT="claude"
fi

case "$AGENT" in
  codex|claude|both) ;;
  *)
    echo "Invalid --agent value: $AGENT" >&2
    usage >&2
    exit 1
    ;;
esac

case "$SCOPE" in
  global|project) ;;
  *)
    echo "Invalid --scope value: $SCOPE" >&2
    usage >&2
    exit 1
    ;;
esac

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "Skills directory not found: $SKILLS_SRC" >&2
  exit 1
fi

if [[ "$SCOPE" == "project" ]]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

if [[ -z "$CODEX_DIR" ]]; then
  if [[ "$SCOPE" == "global" ]]; then
    CODEX_DIR="$HOME/.codex/skills"
  else
    CODEX_DIR="$PROJECT_DIR/.codex/skills"
  fi
fi

if [[ -z "$CLAUDE_DIR" ]]; then
  if [[ "$SCOPE" == "global" ]]; then
    CLAUDE_DIR="$HOME/.claude/skills"
  else
    CLAUDE_DIR="$PROJECT_DIR/.claude/skills"
  fi
fi

ensure_claude_plugin_manifest() {
  local claude_skills_dir="$1"
  local claude_root
  claude_root="$(cd "$claude_skills_dir/.." && pwd)"
  local plugin_dir="$claude_root/.claude-plugin"
  local manifest_path="$plugin_dir/plugin.json"

  if [[ -f "$manifest_path" ]]; then
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] create $manifest_path"
    return
  fi

  mkdir -p "$plugin_dir"
  cat > "$manifest_path" <<'EOF'
{
  "name": "claude-code-skills",
  "version": "1.0.0"
}
EOF
}

install_to() {
  local dest="$1"
  local label="$2"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] install -> $label ($dest)"
  else
    mkdir -p "$dest"
  fi

  local count=0
  for dir in "$SKILLS_SRC"/*; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[dry-run]   copy $name"
    else
      rm -rf "$dest/$name"
      cp -R "$dir" "$dest/$name"
    fi
    count=$((count + 1))
  done

  echo "Installed $count skills to $label: $dest"
}

case "$AGENT" in
  codex)
    install_to "$CODEX_DIR" "codex"
    ;;
  claude)
    install_to "$CLAUDE_DIR" "claude"
    ensure_claude_plugin_manifest "$CLAUDE_DIR"
    ;;
  both)
    install_to "$CODEX_DIR" "codex"
    install_to "$CLAUDE_DIR" "claude"
    ensure_claude_plugin_manifest "$CLAUDE_DIR"
    ;;
esac
