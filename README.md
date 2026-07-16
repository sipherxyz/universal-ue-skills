# Universal UE Skills

A small, portable Unreal Engine skill pack for Codex, Claude Code, and Pi.

## Scope

This pack contains engine-level practices that travel between Unreal projects: official Unreal MCP operation, C++ builds, testing, debugging, rendering analysis, platform compliance, and editor-plugin authoring.

Live Editor and asset work starts with `unreal-mcp`, which uses Epic's `ModelContextProtocol` server and discovers the installed toolsets at runtime. The pack does not ship a parallel Unreal MCP, a generic asset editor, or project-specific asset conventions.

Project-specific skills, custom commandlets, asset naming, team trackers, CI, and GitHub workflow belong in that project's `.codex/skills` and documentation.

## Included skills

```text
create-editor-plugin          ue-cpp-build
graphics-debug                ue-crash-callstack-linker
plugin-documenter             ue-localization-scanner
read-uasset                   ue-memory-leak-hunter
renderdoc-gpu-debug           ue-network-replication-review
ue-run-automation-tests       ue-toolbar-extension
ue-trc-compliance-checker     ue-xr-compliance-checker
unreal-mcp
```

`read-uasset` is intentionally user-invoked: it is an offline fallback, not a substitute for live Editor inspection.

## Install

From a clone:

```bash
bash scripts/install-skills.sh --agent codex --scope project --project-dir /path/to/project
```

From GitHub:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sipherxyz/universal-ue-skills/main/scripts/install-from-github.sh) --agent codex --scope project --project-dir /path/to/project
```

Use `--dry-run` to inspect the destination before copying. The installer replaces only skills with the same name.

## Validate

```bash
bash scripts/validate-skills.sh
```

The validator checks the skill catalog, frontmatter, retired integrations, and retained legacy tool vocabulary.
