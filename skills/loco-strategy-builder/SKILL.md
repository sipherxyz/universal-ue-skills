---
name: loco-strategy-builder
description: Create LocomotionStrategyPreset data asset for an enemy character BP
---

# Locomotion Strategy Preset Builder Skill

**Role:** AI Locomotion Configuration Operator
**Scope:** Per-enemy locomotion preset creation and assignment
**Platform:** Windows (Win64)

## Objective

Run `USipherLocomotionPresetCommandlet` to create a `ULocomotionStrategyPreset` DataAsset and assign it to an enemy Blueprint's `USipherAIScalableParametersComponent::LocomotionPreset`.

The commandlet **reads the Blueprint's actual properties** (movement speeds, capsule dimensions) to derive appropriate preset values rather than using hardcoded defaults.

## Prerequisites

1. Engine path available (from registry)
2. SipherAIScalableFrameworkEditor module compiled (contains the commandlet)
3. Target Blueprint has `USipherAIScalableParametersComponent` in its hierarchy

## Core Command

**ALWAYS use the wrapper script** — never construct the commandlet invocation inline.

```bash
# Run from project root (MSYS_NO_PATHCONV prevents Git Bash from mangling /Game/... paths)
MSYS_NO_PATHCONV=1 powershell -ExecutionPolicy Bypass -File ".\./Run-LocoPresetBuilder.ps1" \
  -BlueprintPath "{BlueprintPath}" \
  -AssetName "{AssetName}" \
  -OutputPath "{OutputPath}" \
  -LocomotionType "{LocomotionType}" \
  [-Force]
```

**Script location:** `./Run-LocoPresetBuilder.ps1`

The script handles engine path lookup, argument construction, and logging automatically. It prevents:
- The fatal `-run=` space bug that crashes the engine
- UE command-line parsing of `/Game/...` as switch prefixes (quoted args)

**CRITICAL: `MSYS_NO_PATHCONV=1`** — Git Bash's MSYS2 converts `/Game/...` to `C:/Program Files/Git/Game/...`. This env var disables that conversion.

### NEVER Do This (Inline Invocation)

Do NOT construct `Start-Process` inline — the `-run=SipherAIScalableFrameworkEditor.SipherLocomotionPresetCommandlet` argument can get split by a space, causing a fatal engine crash:

```
# BAD: "-run=SipherAIScalableFrameworkEditor .SipherLocomotionPresetCommandlet" (space before dot)
# Engine parses ".SipherLocomotionPresetCommandlet" as separate token
# Token.Left(0) = "" -> LoadModule("") -> AddModule(NAME_None) -> CRASH
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-BlueprintPath` | Game path to enemy Blueprint (e.g., `/Game/S2/Core_Ene/.../BP_S2_ene_sword_01A`) | **Required** |
| `-AssetName` | Name for the created DataAsset (e.g., `DA_LS_Ene_Sword`) | **Required** |
| `-OutputPath` | Output directory for the DataAsset | `/SipherAIScalableFramework/Navigation/LocomotionStrategyPresets` |
| `-LocomotionType` | `Humanoid`, `Quadruped`, `Dragon`, or `Serpentine` | `Humanoid` |
| `-Force` | Overwrite existing assets and assignments | Off |

## BP-Derived Configuration

The commandlet reads character properties from the Blueprint CDO and derives preset values:

### Speed Values (from ParametersComponent)

| Preset Field | Source | Formula |
|-------------|--------|---------|
| `WalkSpeed` | `ParamsComp->GetParamWalkingMaxSpeed()` | Direct copy |
| `RunSpeed` | `ParamsComp->GetParamRunningMaxSpeed()` | Direct copy |
| `SprintSpeed` | — | `RunSpeed * 1.5` |

### Physical Properties (from CapsuleComponent)

| Preset Field | Source | Formula |
|-------------|--------|---------|
| `MaxJumpHeight` | `CapsuleHalfHeight` | `HalfHeight * 3.0` |
| `MaxDropHeight` | `CapsuleHalfHeight` | `HalfHeight * 5.0` |
| `BodyMass` | Capsule dimensions | `PI * Radius² * HalfHeight * 2 * 0.001` (clamped 30-500 kg) |

### Type-Specific Capabilities

| Type | Turn Rate | Pivot | Strafe | Gravity | Can Fly |
|------|-----------|-------|--------|---------|---------|
| **Humanoid** | 720 deg/s | Yes | 360 deg | 1.0 | No |
| **Quadruped** | 540 deg/s | No | 90 deg | 1.2 | No |
| **Dragon** | 360 deg/s | Yes | 360 deg | 0.8 | Yes |
| **Serpentine** | 360 deg/s | No | 180 deg | 1.0 | No |

### Jump Curve Profiles

All three profiles (JumpUp, JumpDown, JumpHorizontal) have `MinClearance = 0.0`.

## Workflow

1. **Run Script** with Blueprint path, asset name, and locomotion type
2. **Check Results** in `.\Saved\Logs\LocoPresetBuilder.log`
3. **Verify** created .uasset exists at output path

## Expected Output

### Success Log

```
LogLocoPresetCmdlet: === Locomotion Strategy Preset Generator ===
LogLocoPresetCmdlet: Blueprint Path:   /Game/S2/Core_Ene/s2_ene_sword_01A_prototype/BP_S2_ene_sword_01A
LogLocoPresetCmdlet: Asset Name:       DA_LS_Ene_Sword_01A
LogLocoPresetCmdlet: Output Path:      /SipherAIScalableFramework/Navigation/LocomotionStrategyPresets
LogLocoPresetCmdlet: Locomotion Type:  0
LogLocoPresetCmdlet: Force Overwrite:  No

LogLocoPresetCmdlet: [LOAD] Loading Blueprint: ...
LogLocoPresetCmdlet: [LOAD] Blueprint loaded: BP_S2_ene_sword_01A
LogLocoPresetCmdlet: [FOUND] ParametersComponent on CDO (native C++ component)
LogLocoPresetCmdlet: [READ] WalkingMaxSpeed: 100.0 cm/s
LogLocoPresetCmdlet: [READ] RunningMaxSpeed: 400.0 cm/s
LogLocoPresetCmdlet: [READ] CapsuleHalfHeight: 88.0 cm, CapsuleRadius: 34.0 cm
LogLocoPresetCmdlet: [CALC] WalkSpeed=100.0, RunSpeed=400.0, SprintSpeed=600.0
LogLocoPresetCmdlet: [CALC] MaxJumpHeight=264.0, MaxDropHeight=440.0, BodyMass=64.3
LogLocoPresetCmdlet:   [CONFIG] Humanoid capabilities applied
LogLocoPresetCmdlet: [ASSIGN] LocomotionPreset set to: ...
LogLocoPresetCmdlet: [SAVE] Preset saved + Blueprint saved
LogLocoPresetCmdlet: [DONE] LocomotionStrategyPreset created and assigned successfully
```

### Log Tags Reference

| Tag | Meaning |
|-----|---------|
| `[LOAD]` | Asset being loaded from disk |
| `[FOUND]` | Component template located in SCS hierarchy or CDO |
| `[READ]` | Value read from Blueprint CDO properties |
| `[CALC]` | Derived value calculated from read data |
| `[CREATE]` | New DataAsset created |
| `[CONFIG]` | Type-specific capabilities applied |
| `[ASSIGN]` | Preset assigned to component via reflection |
| `[SAVE]` | Package saved to disk |
| `[SKIP]` | Asset or assignment skipped (already exists) |
| `[FAIL]` | Operation failed |
| `[DONE]` | All operations completed |

## Usage Examples

```bash
# Humanoid sword enemy (reads speeds from BP automatically)
MSYS_NO_PATHCONV=1 powershell -ExecutionPolicy Bypass -File ".\./Run-LocoPresetBuilder.ps1" -BlueprintPath "/Game/S2/Core_Ene/s2_ene_sword_01A_prototype/BP/BP_S2_ene_sword_01A" -AssetName "DA_LS_Ene_Sword_01A"

# Quadruped beast
MSYS_NO_PATHCONV=1 powershell -ExecutionPolicy Bypass -File ".\./Run-LocoPresetBuilder.ps1" -BlueprintPath "/Game/S2/Core_Ene/s2_ene_beast_01/BP/BP_S2_ene_beast_01" -AssetName "DA_LS_Beast_01" -LocomotionType "Quadruped"

# Force overwrite
MSYS_NO_PATHCONV=1 powershell -ExecutionPolicy Bypass -File ".\./Run-LocoPresetBuilder.ps1" -BlueprintPath "/Game/S2/Core_Ene/s2_ene_sword_01A_prototype/BP/BP_S2_ene_sword_01A" -AssetName "DA_LS_Ene_Sword_01A" -Force
```

## Verification

After running the commandlet, verify the result:

1. **Check .uasset exists** at the output path (default: plugin Content folder)

2. **Open in editor** to verify:
   - LocomotionType matches specified type
   - GaitSpeeds match BP's movement speeds (Walk/Run from ParamsComp, Sprint = Run*1.5)
   - Capabilities match type defaults
   - Physical properties (MaxJumpHeight, MaxDropHeight, BodyMass) derived from capsule
   - All JumpCurveProfile MinClearance = 0

3. **Check Blueprint assignment:**
   - Open enemy BP in editor
   - Find ParametersComponent in Components panel
   - Verify LocomotionPreset property points to created DataAsset

## Error Handling

| Error | Solution |
|-------|----------|
| `Missing required parameter: -BlueprintPath` | Provide `-BlueprintPath="/Game/..."` (no `.uasset` extension) |
| `Could not load Blueprint` | Verify Blueprint path exists, use `/Game/` prefix |
| `No USipherAIScalableParametersComponent found` | Ensure BP or parent BP has this component (SCS or native C++) |
| `Asset already exists` | Use `-Force` to overwrite |
| `LocomotionPreset already assigned` | Use `-Force` to reassign |
| `Could not find LocomotionPreset property` | Framework version mismatch — rebuild SipherAIScalableFrameworkEditor |
| `Could not find engine path in registry` | Register custom engine build in UE settings |
| `InModuleName != NAME_None crash` | Space in `-run=` arg — use the wrapper script, never inline |
| `Blueprint file is locked (Error Code 32)` | Editor has BP open — close editor or manually assign preset. Preset DataAsset is still created. |
| `BlueprintPath: C:/Program Files/Git/...` | MSYS2 path conversion — prefix command with `MSYS_NO_PATHCONV=1` |

## Generated Assets

Default output: `/SipherAIScalableFramework/Navigation/LocomotionStrategyPresets/`

Examples:
- `DA_LS_Ene_Sword_01A.uasset`
- `DA_LS_Beast_01.uasset`

## Log Location

- Output: `Saved/Logs/LocoPresetBuilder.log`
- Errors: `Saved/Logs/LocoPresetBuilder_err.log`

## Legacy Metadata

```yaml
skill: loco-strategy-builder
invoke: /system-architect:loco-strategy-builder
type: development
category: ai-locomotion
scope: project-root
```
