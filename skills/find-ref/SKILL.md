---
name: find-ref
description: Find asset references and dependencies using SipherReferenceFinder commandlet
---

# Find Asset References Skill

**Role:** Asset Reference & Dependency Finder
**Scope:** Any .uasset file or GameplayTag in the project
**Platform:** Windows (Unreal Editor Commandlet)
**Use Cases:** Dependency analysis, refactoring impact assessment, asset cleanup, GameplayTag usage tracking

## Objective

Find all referencers (assets that use a target asset) and dependencies (assets that the target uses) for any Unreal Engine asset. Also supports finding all assets that use specific GameplayTags.

## Prerequisites

- S2Editor must be built with the `SipherAIBPTools` plugin enabled
- Engine path: `F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe`
- Project path: `D:/s2/S2.uproject`

## Usage

### Find Asset References & Dependencies

**Convert file path to UE package path:**
```
D:\s2\Content\S2\Folder\AssetName.uasset
         ↓
/Game/S2/Folder/AssetName
```

**Command:**
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/Path/To/Asset" -stdout
```

> **Note:** Use `//Game` (double slash) to prevent bash path expansion on Windows.

**Example:**
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/BehaviorTrees/BBD_eli_beast_" -stdout
```

### Find GameplayTag References

**Find all assets using a specific tag:**
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -tag="Sipher.ComboGraph" -stdout
```

**Include child tags:**
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -tag="Sipher.ComboGraph" -children -stdout
```

**Find all GameplayTags usage:**
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -alltags -stdout
```

## Output

### Console Output

```
=== REFERENCERS (assets that use this asset): 24 ===
  [/Game/S2/...] AssetName (AssetClass)
  ...

=== DEPENDENCIES (assets this asset uses): 6 ===
  [/Game/S2/...] AssetName (AssetClass)
  ...

Total: 30 reference(s).
```

### Generated Reports

Reports are saved to: `D:/s2/Saved/Reports/References/`

| Format | File Pattern | Content |
|--------|--------------|---------|
| Markdown | `asset_report_{AssetName}_{timestamp}.md` | Tree view of folder hierarchy |
| CSV | `references_{SearchTerm}_{timestamp}.csv` | Flat list for spreadsheet |

### Markdown Report Example

```markdown
# Asset Reference Report

**Asset:** `/Game/S2/Core_Boss/s2_boss_gaolanying/BP_AnimNotify_SpawnFan`

## Referencers (24)

```
Game
└── S2/
    ├── Core_Boss/
    │   └── s2_boss_gaolanying/
    │       ├── Animation/
    │       │   └── Movement/
    │       │       └── Dodge_B_180_Montage [AnimMontage]
    │       └── Montage/
    │           └── Phase2/
    │               └── UE5_combo03_Montage_With_Clone [AnimMontage]
    └── Core_Ene/
        └── s2_eli_Grimwarden_01A_prototype/
            └── ANM/
                └── AMT_SlashDown_Magic [AnimMontage]
```

## Dependencies (6)

```
Engine
└── EditorBlueprintResources/
    └── StandardMacros [Blueprint]
Game
└── S2/
    └── Skills/
        └── BP_LogicReferenceGraph [Blueprint]
Script
├── AIModule [Unknown]
└── SipherProjectileRuntime [Unknown]
```

## Summary

| Direction | Count |
|-----------|-------|
| Referencers | 24 |
| Dependencies | 6 |
| **Total** | **30** |
```

## Path Conversion Reference

| File System Path | UE Package Path |
|------------------|-----------------|
| `D:\s2\Content\S2\...` | `/Game/S2/...` |
| `D:\s2\Content\...` | `/Game/...` |
| `D:\s2\Plugins\{Plugin}\Content\...` | `/{Plugin}/...` |

## Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-asset=` | UE package path to analyze | `-asset="//Game/S2/MyAsset"` |
| `-tag=` | GameplayTag to search for | `-tag="Sipher.ComboGraph"` |
| `-children` | Include child tags (with -tag) | `-tag="Sipher" -children` |
| `-alltags` | Find all GameplayTag references | `-alltags` |
| `-format=` | Output format (csv/json) | `-format=json` |
| `-stdout` | Print progress to console | `-stdout` |

## Common Use Cases

### 1. Safe Delete Check

Before deleting an asset, check if anything uses it:
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/ToDelete/MyAsset" -stdout
```

If **Referencers = 0**, safe to delete.

### 2. Refactoring Impact

Before renaming/moving an asset:
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/OldPath/MyBlueprint" -stdout
```

All listed referencers will need redirector or update.

### 3. GameplayTag Cleanup

Find where a tag is used before removing it:
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -tag="Sipher.Deprecated.OldTag" -stdout
```

### 4. Dependency Chain Analysis

Understand what an asset needs:
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/Characters/BP_MainCharacter" -stdout
```

Review Dependencies section to understand all required assets.

## Timeout

The commandlet requires loading the Asset Registry which takes ~10-15 seconds. Use timeout of 120000ms (2 minutes) minimum:

```bash
# With explicit timeout
timeout 120 "F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" ...
```

## Filtering Output

### Quick Check (grep for specific info)
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/MyAsset" -stdout 2>&1 | grep -E "REFERENCERS|DEPENDENCIES|Total"
```

### Get Markdown Path Only
```bash
"F:/S2UE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "D:/s2/S2.uproject" -run=SipherReferenceFinder -asset="//Game/S2/MyAsset" -stdout 2>&1 | grep "Markdown report written"
```

## Integration with Other Skills

### With `read-uasset`
Use `find-ref` to discover dependencies, then `read-uasset` to inspect their contents.

### With `huli-bp-tools`
After finding references, use BP tools to analyze Blueprint logic.

### With `combat-ai-review`
Find all assets using combat-related GameplayTags for review.

## Troubleshooting

### "Could not find the class"
- Ensure `SipherAIBPTools` plugin is enabled in S2.uproject
- Rebuild S2Editor after enabling the plugin

### Path gets mangled
- Use `//Game` (double slash) instead of `/Game`
- Or use single quotes around the asset parameter

### No results found
- Verify asset path is correct (no .uasset extension)
- Check if asset exists: `ls "D:/s2/Content/Path/To/Asset.uasset"`

### Commandlet timeout
- Asset Registry loading takes 10-15 seconds
- Full scan can take 30+ seconds
- Use timeout of at least 120000ms

## Success Criteria

- Commandlet executes without errors
- Referencers count displayed
- Dependencies count displayed
- Markdown report generated in `Saved/Reports/References/`
- Tree view shows folder hierarchy correctly

## Legacy Metadata

```yaml
skill: find-ref
invoke: /asset-management:find-ref
type: utility
category: asset-tools
scope: project-root
```
