---
name: foliage-grid-builder
description: Redistribute IFA actors to match grid cell sizes using SipherFoliageGridBuilder
---

# Foliage Grid Builder Skill

**Role:** World Partition Builder Operator
**Scope:** Level-specific IFA redistribution
**Platform:** Windows (Win64)

## Objective

Run `USipherFoliageGridBuilder` to redistribute `AInstancedFoliageActor` instances
based on grid cell sizes defined in `FSipherWPGridConfig`.

## Prerequisites

1. Engine path available (from registry)
2. SipherWorldPartitionEditor module compiled
3. Target level contains IFA actors in foliage-grid folders
4. Grid configs have `bIsFoliageGrid=true` in Project Settings

## Core Command

**IMPORTANT:**
- The commandlet requires the `-Build` phase flag
- Use PowerShell to avoid Git bash path conversion (`/Game/...` → `C:/Program Files/Git/Game/...`)

```powershell
powershell -Command "& 'D:\UnrealEngine\Engine\Binaries\Win64\UnrealEditor-Cmd.exe' 'D:\s2\S2.uproject' '{LevelPath}' '-run=SipherWorldPartitionBuilderCommandlet' '-Builder=SipherFoliage' '-Build' '-nullrhi' '-nosplash' '-unattended' 2>&1 | Tee-Object -FilePath 'D:\s2\Saved\Logs\FoliageGridBuilder.log'"
```

### Dynamic Engine Path Detection

```powershell
# Get engine path from registry
$EnginePath = (reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds" 2>$null | Select-String "REG_SZ" | ForEach-Object { ($_ -split "\s+REG_SZ\s+")[1] } | Select-Object -First 1)

# Run commandlet
& "$EnginePath\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" `
  "$PWD\S2.uproject" `
  "{LevelPath}" `
  "-run=SipherWorldPartitionBuilderCommandlet" `
  "-Builder=SipherFoliage" `
  "-Build" `
  "-nullrhi" "-nosplash" "-unattended" 2>&1 | Tee-Object -FilePath "$PWD\Saved\Logs\FoliageGridBuilder.log"
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `{LevelPath}` | Game path (e.g., `/Game/S2/Levels/OpenWorld`) | **Required** |
| `-Build` | **REQUIRED** phase flag to run the builder | **Required** |
| `-GridNames=` | Comma-separated grid names to process | All foliage grids |
| `-ForceRebuild` | Force rebuild even if IFAs appear correct | `false` |
| `-KeepEmptyIFAs` | Keep empty IFAs after redistribution | `false` |

### Phase Flags (one required)

| Flag | Description |
|------|-------------|
| `-Setup` | Setup phase only |
| `-Build` | **Main build phase** - use this for foliage redistribution |
| `-Composition` | Composition phase only |
| `-Finalize` | Finalize phase only |

## Workflow

1. **Get Engine Path** from registry
2. **Run Builder** from project root with level path and `-Build` flag
3. **Check Results** in `.\Saved\Logs\FoliageGridBuilder.log`

## Cell Bounds Checking

The builder checks if each IFA is already correctly positioned within World Partition cells:

1. **Compute instance bounds** - Calculate min/max cell keys from all foliage instances
2. **Single cell check** - If all instances are within the same cell, IFA is "correct"
3. **Position check** - Verify IFA actor location is within that cell's bounds
4. **Skip or redistribute** - Skip correct IFAs, redistribute ones that span multiple cells

Use `-ForceRebuild` to bypass this check and redistribute all matching IFAs.

## Expected Output

### Summary Statistics

```
========================================
Foliage Grid Build Complete:
  Grids processed: 2
  Total IFAs processed: 15
  Total IFAs skipped (already correct): 8
  Total IFAs created: 42
  Total IFAs deleted: 7
  Total instances redistributed: 156000
========================================
```

### Log Tags

| Tag | Meaning |
|-----|---------|
| `[GRID]` | Processing a foliage grid |
| `[MATCH]` | IFA matches grid by folder path |
| `[EXTRACT]` | Extracting instances from IFA |
| `[SPLIT]` | Splitting instances into cells |
| `[CREATE]` | Creating new IFA for cell |
| `[DELETE]` | Deleting source IFA |
| `[CLEAR]` | Cleared foliage from IFA (kept empty) |
| `[DONE]` | Grid processing complete |
| `[SKIP]` | IFA already in correct cell (all instances within single cell bounds) |
| `[KEEP]` | Source IFA kept (also used as target) |
| `[SAVE]` | Saving packages |
| `[SAVED]` | Package saved successfully |
| `[VALIDATE]` | Validation check |
| `[FOLDER]` | Setting IFA folder path |
| `[OVERFLOW]` | IFA reached max instances limit |

### Example Log

```
LogSipherFoliageGridBuilder: Display: [GRID] Processing: LargeWPO (CellSize: 10000)
LogSipherFoliageGridBuilder: Display: [MATCH] IFA: InstancedFoliageActor_25600_-1_-1_-1
LogSipherFoliageGridBuilder: Display:         FolderPath: WPO_LARGE
LogSipherFoliageGridBuilder: Display:         MatchedPrefix: WPO_LARGE
LogSipherFoliageGridBuilder: Display: [EXTRACT] IFA: InstancedFoliageActor_25600_-1_-1_-1 (spans multiple cells or wrong position)
LogSipherFoliageGridBuilder: Display:           FoliageType: FT_SM_EuropeanHornbeam_Forest_07_Autumn03_02
LogSipherFoliageGridBuilder: Display:           Instances: 25
LogSipherFoliageGridBuilder: Display: [SPLIT] FoliageType: FT_SM_EuropeanHornbeam_Forest_07_Autumn03_02
LogSipherFoliageGridBuilder: Display:         TotalInstances: 25
LogSipherFoliageGridBuilder: Display:         CellCount: 9
LogSipherFoliageGridBuilder: Display: [CREATE] New IFA for Cell (-1,-1,-1): InstancedFoliageActor_10000_-1_-1_-1
LogSipherFoliageGridBuilder: Display:         Cell (-1,-1,-1): 1 instances -> InstancedFoliageActor_10000_-1_-1_-1
LogSipherFoliageGridBuilder: Display: [DELETE] Source IFA: InstancedFoliageActor_25600_-1_-1_-1
LogSipherFoliageGridBuilder: Display: [DONE] Grid: LargeWPO
LogSipherFoliageGridBuilder: Display:        IFAs processed: 6
LogSipherFoliageGridBuilder: Display:        Instances redistributed: 88
LogSipherFoliageGridBuilder: Display: [VALIDATE] PASSED: All 13 IFAs have instances in correct cells
LogSipherFoliageGridBuilder: Display: [SAVE] Saving 13 packages...
LogSipherFoliageGridBuilder: Display: [SAVE] Complete: 13 saved, 0 failed
```

## Usage Examples

```bash
# Process all foliage grids in OpenWorld level
/system-architect:foliage-grid-builder build /Game/S2/Levels/OpenWorld

# Process specific grids only
/system-architect:foliage-grid-builder build /Game/S2/Main_Flow/Teaser/Level/L_Teaser -GridNames=LargeWPO,SmallWPO

# Force rebuild all
/system-architect:foliage-grid-builder build /Game/S2/Levels/OpenWorld -ForceRebuild
```

### Direct PowerShell Command

```powershell
# From project root (D:\s2)
powershell -Command "& 'D:\UnrealEngine\Engine\Binaries\Win64\UnrealEditor-Cmd.exe' 'D:\s2\S2.uproject' '/Game/S2/Main_Flow/Teaser/Level/L_Teaser_Temp_Autumn_03' '-run=SipherWorldPartitionBuilderCommandlet' '-Builder=SipherFoliage' '-Build' '-nullrhi' '-nosplash' '-unattended' 2>&1 | Tee-Object -FilePath 'D:\s2\Saved\Logs\FoliageGridBuilder.log'"
```

## Configuration

Enable foliage grid in Project Settings:

1. Open **Project Settings** -> **Sipher World Partition**
2. Find or add a grid config in **Default Grids**
3. Enable **bIsFoliageGrid** checkbox
4. IFAs matching **FolderPrefixes** (e.g., `WPO_LARGE`) will be processed automatically
5. Optionally set **FoliageTypes** to filter specific foliage types
6. Adjust **MaxInstancesPerFoliageActor** if needed (default: 200000)

## Error Handling

| Error | Solution |
|-------|----------|
| `No phase specified. Use -Setup, -Build, -Composition, or -Finalize` | Add `-Build` flag to command (required) |
| Path becomes `C:/Program Files/Git/Game/...` | Use PowerShell instead of Git bash to avoid path conversion |
| `No foliage grids found` | Enable `bIsFoliageGrid` in Project Settings |
| `No IFAs match grid` | Check IFA folder paths contain one of the grid's FolderPrefixes |
| `Builder class not found` | Rebuild SipherWorldPartitionEditor module |
| `[OVERFLOW] reached MaxInstances` | Increase MaxInstancesPerFoliageActor or use smaller cells |

## Log Location

- Output: `Saved/Logs/FoliageGridBuilder.log`
- Errors: `Saved/Logs/FoliageGridBuilder_err.log`

## Legacy Metadata

```yaml
skill: foliage-grid-builder
invoke: /system-architect:foliage-grid-builder
type: development
category: world-partition-builder
scope: project-root
```
