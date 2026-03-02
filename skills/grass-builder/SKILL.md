---
name: grass-builder
description: Convert landscape grass to foliage actors using CascadeFoliage Grass Builder
---

# CascadeFoliage Grass Builder Skill

**Role:** World Partition Builder Operator
**Scope:** Level-specific grass conversion
**Platform:** Windows (Win64)

## Objective

Run `USipherCascadeFoliageGrassBuilder` to convert landscape grass into `AInstancedFoliageActor` instances for Cascade Foliage system management.

## Prerequisites

1. Engine path available (from registry)
2. SipherCascadeFoliageEditor module compiled
3. Target level contains landscapes with grass types

## Core Command

```powershell
# Get engine path from registry
$EnginePath = (Get-ItemProperty "HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds" -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Value -like "*UnrealEngine*" } | Select-Object -First 1 -ExpandProperty Value

# Run from project root (CWD)
# Uses SipherWorldPartitionBuilderCommandlet (not engine's WorldPartitionBuilderCommandlet)
# to trigger Streamline D3D12 disable via SipherWorldPartitionEditorPreConfigModule
Start-Process -FilePath "$EnginePath\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" `
  -ArgumentList ".\S2.uproject","{LevelPath}","-run=SipherWorldPartitionBuilderCommandlet","-Builder=/Script/SipherCascadeFoliageEditor.SipherCascadeFoliageGrassBuilder","-nullrhi","-nosplash","-unattended" `
  -Wait -NoNewWindow `
  -RedirectStandardOutput ".\Saved\Logs\GrassBuilder.log" `
  -RedirectStandardError ".\Saved\Logs\GrassBuilder_err.log"
```

> **Note:** Must use `SipherWorldPartitionBuilderCommandlet` to avoid Streamline/DLSS crash.
> The PreConfig module (`SipherWorldPartitionEditorPreConfigModule`) disables Streamline D3D12 when this commandlet runs.

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `{LevelPath}` | Game path (e.g., `/Game/S2/Main_Flow/Teaser/Level/L_Teaser_Temp_Autumn_03`) | **Required** |
| `-DensityScale=` | Density multiplier (0.1 - 2.0) | `1.0` |
| `-MinSampleSpacing=` | Minimum spacing in cm | `50.0` |

## Workflow

1. **Get Engine Path** from registry: `HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds`
2. **Run Builder** from project root with level path as argument
3. **Check Results** in `.\Saved\Logs\GrassBuilder.log`

## Expected Output

### Summary Statistics

```
Grass conversion complete:
  Landscapes processed: 25
  Grass types processed: 325
  FoliageTypes created: 13
  Total instances created: 1595810
Execution took 45.6 sec
```

### Detailed Change Log

The builder logs all modified actors/assets with reasons using these tags:

| Tag | Meaning |
|-----|---------|
| `[REUSE]` | Existing asset found and reused |
| `[CREATE]` | New asset created |
| `[MODIFY]` | Actor/asset was modified |
| `[SKIP]` | Item skipped (already processed) |
| `[QUEUED]` | Package queued for batch save |
| `[SAVE]` | Package saved to disk |
| `[DONE]` | Operation completed |

**Example Log Output:**

```
LogCascadeFoliageGrassBuilder: Display: Processing Landscape: LandscapeStreamingProxy_0
LogCascadeFoliageGrassBuilder: Display:     [REUSE] FoliageType: /Game/S2/Generated/FoliageTypes/Grass/FT_LGT_Grass_Autumn_Yellow_Grass_LOD_0
LogCascadeFoliageGrassBuilder: Display:             Reason: Existing asset found with matching mesh SM_Grass_Autumn_Yellow_LOD

LogCascadeFoliageGrassBuilder: Display:     [CREATE] FoliageType: /Game/S2/Generated/FoliageTypes/Grass/FT_LGT_Rocks_SM_Small_Rocks_01_0
LogCascadeFoliageGrassBuilder: Display:              Reason: No existing FoliageType found for mesh SM_Small_Rocks_01

LogCascadeFoliageGrassBuilder: Display:     [MODIFY] IFA Actor: InstancedFoliageActor_0
LogCascadeFoliageGrassBuilder: Display:              Reason: Added 15420 grass instances for FoliageType FT_LGT_Grass_Autumn_Yellow_Grass_LOD_0

LogCascadeFoliageGrassBuilder: Display:     [MODIFY] Landscape Actor: LandscapeStreamingProxy_0
LogCascadeFoliageGrassBuilder: Display:              Reason: Added tag 'CascadeGrassConverted' to prevent re-conversion

LogCascadeFoliageGrassBuilder: Display:     [QUEUED] Package: /Game/S2/Generated/FoliageTypes/Grass/FT_LGT_Rocks_SM_Small_Rocks_01_0
LogCascadeFoliageGrassBuilder: Display:              Reason: New FoliageType asset needs to be saved

LogCascadeFoliageGrassBuilder: Display:     [SKIP] Landscape: LandscapeStreamingProxy_5
LogCascadeFoliageGrassBuilder: Display:            Reason: Already has 'CascadeGrassConverted' tag

LogCascadeFoliageGrassBuilder: Display: [SAVE] Saving 15 packages to disk...
LogCascadeFoliageGrassBuilder: Display: [DONE] All packages saved successfully
```

### Log Categories

- **FoliageType operations**: Shows whether existing assets are reused or new ones created
- **IFA modifications**: Shows instance counts added to each foliage actor
- **Landscape tagging**: Shows tag applied to prevent duplicate conversion
- **Package saves**: Shows which packages are queued and saved to disk

## What It Does

1. Finds all `ALandscapeProxy` actors in level
2. Extracts `ULandscapeGrassType` from landscape materials
3. Creates `UFoliageType_InstancedStaticMesh` for each grass variety
4. Samples grass positions using grid sampling with jitter
5. Adds instances to `AInstancedFoliageActor`
6. Tags converted landscapes to prevent duplicates

## Generated Assets

Saved to `/Game/S2/Generated/FoliageTypes/Grass/`:
- `FT_LGT_Grass_Autumn_Yellow_Grass_LOD_0`
- `FT_LGT_Rocks_SM_Small_Rocks_01_0`

## Usage

```
/grass-builder /Game/S2/Main_Flow/Teaser/Level/L_Teaser_Temp_Autumn_03
```

## Error Handling

| Error | Solution |
|-------|----------|
| `Missing world name` | Use `/Game/...` format without `.umap` |
| `Builder class not found` | Rebuild with SipherCascadeFoliageEditor |
| `No landscapes found` | Check level contents |
| `Streamline/DLSS crash` | Use `SipherWorldPartitionBuilderCommandlet` (not engine's `WorldPartitionBuilderCommandlet`) |

## Log Location

- Output: `Saved/Logs/GrassBuilder.log`
- Errors: `Saved/Logs/GrassBuilder_err.log`

## Legacy Metadata

```yaml
skill: grass-builder
invoke: /system-architect:grass-builder
type: development
category: world-partition-builder
scope: project-root
```
