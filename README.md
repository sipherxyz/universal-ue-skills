# Universal UE Skills

Universal Unreal Engine skill pack compatible with Codex and Claude Code.

## Contents

- `skills/` - all universal skill folders (`<slug>/SKILL.md` + bundled resources)
- `metadata/aliases.json` - legacy invoke alias mapping
- `metadata/migration-report.json` - conversion report
- `metadata/migration-report.md` - human-readable migration report
- `scripts/install-skills.sh` - installer for Codex and Claude Code

## Install

### Quick commands

Install to Codex:

```bash
bash scripts/install-skills.sh codex
```

Install to Claude Code:

```bash
bash scripts/install-skills.sh claude
```

Install to both:

```bash
bash scripts/install-skills.sh both
```

### Manual install commands

Codex:

```bash
mkdir -p ~/.codex/skills
cp -R skills/* ~/.codex/skills/
```

Claude Code:

```bash
mkdir -p ~/.claude/skills
cp -R skills/* ~/.claude/skills/
```

## Notes

- This repo is generated from `.claude` skill sources and normalized to universal `SKILL.md` format.
- Some skills contain machine-specific absolute path examples; see `metadata/migration-report.json` warnings.
