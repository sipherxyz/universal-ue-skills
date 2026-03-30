---
name: setup-bpgenerator
description: Configure Ultimate Blueprint Generator plugin to use ai-gateway — detects API key from env vars and writes ApiKeySlots.json
---

# Setup BpGenerator

Configure the Ultimate Blueprint Generator plugin (Slot 0) to use a custom AI gateway.

**Platform:** Windows + PowerShell

## What It Does

1. Walks up from the script location until it finds a `.uproject` file (project root)
2. Detects API key from supported environment variables (in priority order)
3. XOR+Base64-encodes the key as the plugin expects
4. Patches `Saved/BpGeneratorUltimate/ApiKeySlots.json` — Slot 0 only, other slots preserved

## Prerequisites

- Unreal Editor opened at least once with the plugin enabled (creates `ApiKeySlots.json`)
- API key set in one of the supported environment variables

## Environment Variables (checked in order)

| Variable | Notes |
|----------|-------|
| `AI_GATEWAY_API_KEY` | Preferred |
| `ATHERLABS_API_KEY` | Alternative |
| `SIPHER_AI_KEY` | Internal alias |
| `OPENAI_API_KEY` | Fallback |
| `ANTHROPIC_API_KEY` | Fallback |

## Defaults

| Setting | Value |
|---------|-------|
| Provider | `Custom` |
| BaseURL | `https://ai-gateway.atherlabs.com/v1/chat/completions` |
| Model | `gpt-5.4` |
| Slot | `0` (ActiveSlot) |

## Workflow

### Step 1 — Set your API key

```powershell
$env:AI_GATEWAY_API_KEY = "clp_your_key_here"
```

### Step 2 — Run the script

Locate the installed script (it's inside this skill folder) and run:

```powershell
powershell -ExecutionPolicy Bypass -File "path/to/skills/setup-bpgenerator/scripts/setup-bpgenerator.ps1"
```

For a **project-scoped** install (run from project root):

```powershell
# Claude
powershell -ExecutionPolicy Bypass -File ".claude/skills/setup-bpgenerator/scripts/setup-bpgenerator.ps1"

# Codex
powershell -ExecutionPolicy Bypass -File ".codex/skills/setup-bpgenerator/scripts/setup-bpgenerator.ps1"
```

Optional parameter overrides:

```powershell
# Different model
... -ModelName "claude-sonnet-4-6"

# Different base URL
... -BaseURL "https://my-gateway.example.com/v1/chat/completions"
```

### Step 3 — Restart Unreal Editor

The plugin reads config at startup. Restart the editor (or reload the BpGenerator plugin) for changes to take effect.

## Error Reference

| Error | Fix |
|-------|-----|
| `Could not locate project root` | Run from inside the UE project directory |
| `No API key found in environment` | Set `AI_GATEWAY_API_KEY` env var |
| `Config not found` | Open Unreal Editor once to generate `ApiKeySlots.json` |

## Config File

```
<ProjectRoot>/Saved/BpGeneratorUltimate/ApiKeySlots.json
```

Only Slot 0 is modified. All other slots remain unchanged.

## Legacy Metadata

```yaml
skill: setup-bpgenerator
invoke: /dev-workflow:setup-bpgenerator
type: setup
category: tooling
scope: project-root
```
