---
name: read-uasset-deep
description: Parse Unreal Engine .uasset binary files to extract structure including package info, name tables, imports, exports, and dependencies. Supports deep analysis with recursive dependency reading. Use for analyzing UE asset contents, BT/AI review, debugging asset issues, or understanding asset structure. Best with uncooked/editor assets; UE5.3+ cooked assets have limited support.
---

# UE Read UAssets (Deep Parser)

Parse .uasset files to extract internal structure as JSON or text. Supports deep recursive analysis.

## Quick Start

```bash
# Full structure as JSON
python scripts/parse_uasset.py Content/Characters/BP_Player.uasset

# Human-readable text format
python scripts/parse_uasset.py Content/Characters/BP_Player.uasset --format text

# Quick summary only
python scripts/parse_uasset.py Content/Characters/BP_Player.uasset --summary

# Deep analysis with recursive dependency reading
python scripts/parse_uasset.py Content/BT/BT_Enemy.uasset --deep --format text

# Control recursion depth (default: 2)
python scripts/parse_uasset.py Content/BT/BT_Boss.uasset --deep --max-depth 3
```

## Deep Analysis Mode

Use `--deep` for comprehensive analysis including:
- **Categorized dependencies** (Ability, Montage, BehaviorTree, BTNode, Module, etc.)
- **Gameplay tag extraction**
- **BT node type listing**
- **Automated warnings** (WIP assets, typos, TEMP prefixes)
- **Recursive dependency analysis** (reads /Game/ dependencies)

```bash
# Deep analysis of a Behavior Tree
python scripts/parse_uasset.py "D:\s2\Content\S2\Core_Boss\s2_boss_baiwuchang\BT\BT_s2_boss_baiwuchang_phase_01_ver2.uasset" --deep --format text

# JSON output for programmatic use
python scripts/parse_uasset.py MyBT.uasset --deep --format json
```

### Dependency Categories

| Category | Patterns |
|----------|----------|
| `Ability` | `/GAS/`, `GA_`, `Ability` |
| `Montage` | `AMT_`, `Montage`, `/Anim/` |
| `BehaviorTree` | `BT_`, `/BT/` |
| `BTNode` | `BTT_`, `BTD_`, `BTS_` |
| `Blackboard` | `BB_`, `Blackboard` |
| `Enemy` | `BP_` + `ene_`/`enemy` |
| `Blueprint` | `BP_` |
| `Module` | `/Script/` |

### Automated Warnings

The parser detects:
- `BP_TestAbility_*` - WIP test abilities
- `TEMP_*` - Temporary assets
- Common typos (e.g., "Bawuchang" -> "Baiwuchang")

## Output Structure

| Section | Contents |
|---------|----------|
| `summary` | UE version, engine version, GUID, counts, offsets |
| `names` | Complete FName table (strings in asset) |
| `imports` | External dependencies with class/package info |
| `exports` | Exported objects with class, size, offset, flags |
| `dependencies` | Deduplicated list of package dependencies |
| `categorized_dependencies` | (deep mode) Dependencies grouped by type |
| `name_analysis` | (deep mode) Extracted tags, nodes, warnings |
| `analyzed_dependencies` | (deep mode) Recursive child analysis |

## Common Use Cases

### Analyze Behavior Tree
```bash
python scripts/parse_uasset.py BT_Enemy.uasset --deep --format text
```

### List all abilities used by asset
```bash
python scripts/parse_uasset.py MyAsset.uasset --deep | python -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d['categorized_dependencies'].get('Ability',[])))"
```

### Find gameplay tags
```bash
python scripts/parse_uasset.py MyAsset.uasset --deep | python -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d['name_analysis']['gameplay_tags']))"
```

### Find FNames matching pattern
```bash
python scripts/parse_uasset.py MyAsset.uasset | jq '.names[] | select(contains("Anim"))'
```

## Format Support

| UE Version | Format | Support |
|------------|--------|---------|
| UE4.x | Uncooked | Full |
| UE5.0-5.2 | Uncooked | Full |
| UE5.3-5.7 | Uncooked | Full |
| UE5.3+ | Cooked | Basic (version info only) |

## Script Reference

`scripts/parse_uasset.py <path> [options]`

| Option | Description |
|--------|-------------|
| `--format json\|text` | Output format (default: json) |
| `--output FILE` | Write to file instead of stdout |
| `--summary` | Brief summary only |
| `--deep` | Deep analysis with recursive dependency reading |
| `--max-depth N` | Max recursion depth for deep analysis (default: 2) |
| `--content-root PATH` | Content folder root (auto-detected if not specified) |

## Limitations

- Header structure only (name/import/export tables)
- Does not deserialize UObject properties
- Cooked UE5.3+ assets have limited parsing
- .uexp bulk data not parsed
- Deep analysis only follows /Game/ paths (not /Script/ or /Engine/)

## Legacy Metadata

```yaml
skill: read-uasset-deep
invoke: /asset-management:read-uasset-deep
```
