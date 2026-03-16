# Universal UE Skills

Universal Unreal Engine skill pack compatible with Codex, Claude Code, and Pi.

## Contents

- `skills/` - all universal skill folders (`<slug>/SKILL.md` + bundled resources)
- `metadata/aliases.json` - legacy invoke alias mapping
- `metadata/migration-report.json` - conversion report
- `metadata/migration-report.md` - human-readable migration report
- `scripts/install-skills.sh` - installer for Codex, Claude Code, and Pi

## Highlighted Skill

### `renderdoc-gpu-debug`

GPU frame capture and RenderDoc investigation workflow for `.rdc` files, shader issues, broken shadows, render-target inspection, draw-call tracing, and frame diffs.

Skill contents:

- `skills/renderdoc-gpu-debug/SKILL.md`
- `skills/renderdoc-gpu-debug/README.md`
- `skills/renderdoc-gpu-debug/references/`
- `skills/renderdoc-gpu-debug/mcp_server/`

How to use after install:

```text
Open this RenderDoc capture and tell me why this pixel is black.
Capture a frame and inspect the shadow map for acne artifacts.
Compare these two .rdc files and summarize the rendering regression.
```

## Install

### A) Install from local clone

Use [`scripts/install-skills.sh`](scripts/install-skills.sh).

Global install (Codex + Claude Code + Pi):

```bash
bash scripts/install-skills.sh --agent all --scope global
```

Project-scoped install (current directory):

```bash
bash scripts/install-skills.sh --agent all --scope project --project-dir .
```

Agent-specific installs:

```bash
# Codex only (global)
bash scripts/install-skills.sh --agent codex --scope global

# Claude Code only (project)
bash scripts/install-skills.sh --agent claude --scope project --project-dir /path/to/project

# Pi only (global)
bash scripts/install-skills.sh --agent pi --scope global
```

### B) Install without cloning (curl installer)

Use [`scripts/install-from-github.sh`](scripts/install-from-github.sh) directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/buihuuloc/universal-ue-skills/main/scripts/install-from-github.sh) --agent all --scope global
```

Project-scoped via curl:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/buihuuloc/universal-ue-skills/main/scripts/install-from-github.sh) \
  --agent all \
  --scope project \
  --project-dir /path/to/project
```

### Legacy positional syntax (still supported)

```bash
bash scripts/install-skills.sh all global
bash scripts/install-skills.sh codex project /path/to/project
```

## Notes

- This repo is generated from `.claude` skill sources and normalized to universal `SKILL.md` format.
- Some skills contain machine-specific absolute path examples; see `metadata/migration-report.json` warnings.
