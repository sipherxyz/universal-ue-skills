---
name: read-uasset
description: Extract readable strings, metadata, and deep structural information from Unreal Engine binary .uasset files. Supports both quick PowerShell string extraction and full Python-based structure parsing with dependency analysis.
---

# Read UAsset Binary Skill

**Role:** Asset Data Extraction Utility
**Scope:** Any .uasset file in the project
**Platform:** Windows (PowerShell + Python)
**Use Cases:** IMC analysis, Input Action review, Data Asset inspection, Blueprint metadata extraction, dependency graphing, BT/AI review, export table analysis

## Configuration

This skill reads project paths from `skills.config.json` at the repository root.
- `project.root` / `project.content_path` -- asset locations
If not found, uses current working directory.

## Quick Reference

This skill provides two complementary approaches. Choose based on your need:

| Approach | Tool | Best For |
|----------|------|----------|
| **Surface Extraction** | PowerShell | Quick string extraction, IMC/IA key binding analysis, data table field names, fast triage |
| **Deep Parsing** | Python | Full structure parsing, dependency graphs, export/import tables, name table analysis, recursive dependency reading |

**Rule of thumb:**
- Need to quickly see what keys are bound or what actions an IMC references? Use **Surface**.
- Need the complete asset structure, categorized dependencies, or gameplay tag extraction? Use **Deep**.
- For a full picture, run both: surface for human-readable strings, deep for structural data.

---

## Surface Extraction (PowerShell)

Extract readable ASCII strings from binary .uasset files to analyze asset configuration without opening Unreal Editor. This enables agents to review Input Mapping Contexts, Input Actions, Data Tables, and other binary assets programmatically.

### What Can Be Extracted

The extraction reveals:
- **Asset paths** (e.g., `/Game/Input/IA_LightAttack`)
- **Asset GUIDs** (unique identifiers)
- **Engine version** (e.g., `++UE5+Release-5.6`)
- **Class types** (e.g., `InputAction`, `InputMappingContext`, `DataTable`)
- **Property names** (e.g., `ValueType`, `Triggers`, `Mappings`)
- **Property values** (enums, booleans, references)
- **Key bindings** (e.g., `Gamepad_FaceButton_Bottom`, `LeftMouseButton`)
- **Referenced assets** (other IA/IMC/BP paths)
- **Modifier/Trigger types** (e.g., `InputTriggerHold`, `InputModifierDeadZone`)

### Setup

#### Step 1: Create Extraction Script

Create the PowerShell script at a temp location:

**File:** `$env:TEMP\extract_uasset_strings.ps1`

```powershell
param([string]$FilePath)
$bytes = [System.IO.File]::ReadAllBytes($FilePath)
$currentString = ""
foreach ($byte in $bytes) {
    if ($byte -ge 32 -and $byte -le 126) {
        $currentString += [char]$byte
    } else {
        if ($currentString.Length -gt 4) {
            Write-Output $currentString
        }
        $currentString = ""
    }
}
if ($currentString.Length -gt 4) {
    Write-Output $currentString
}
```

#### Step 2: Write the Script

```markdown
Action: Write PowerShell script to temp directory
Tool: Write
Path: $env:TEMP\extract_uasset_strings.ps1
Content: (script above)
```

> **Note:** A copy of this script is also available at `skills/read-uasset/extract_uasset_strings.ps1`.

### Usage

#### Basic Extraction

```bash
# Example path -- replace with your project path
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "${PROJECT_ROOT}/Content/Input/IMC_MainCharacter.uasset"
```

#### With Line Limit (for large assets)

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "${PROJECT_ROOT}/Content/Input/IMC_MainCharacter.uasset" 2>&1 | head -200
```

#### Multiple Files in Parallel

```bash
# Extract from multiple files
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "path1.uasset"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "path2.uasset"
```

### Output Interpretation

#### Input Mapping Context (IMC) Output

```
/Game/Input/IMC_MainCharacter              <-- Asset path
9E97F245C98F526E0E309854C1B07855          <-- Asset GUID
++UE5+Release-5.6                          <-- Engine version
/Script/EnhancedInput                      <-- Module dependency
InputMappingContext                        <-- Class type
Mappings                                   <-- Property (array of mappings)
Gamepad_FaceButton_Bottom                  <-- Key binding
Gamepad_LeftTrigger                        <-- Key binding
LeftMouseButton                            <-- Key binding
/Game/Input/IA_LightAttack                 <-- Referenced Input Action
/Game/Input/IA_HeavyAttack                 <-- Referenced Input Action
InputModifierDeadZone                      <-- Modifier type
InputTriggerHold                           <-- Trigger type
EDeadZoneType::Axial                       <-- Enum value
```

#### Input Action (IA) Output

```
/Game/Input/IA_Parry                       <-- Asset path
F50E7EB76D5B14F6F29064E5E4FC42E1          <-- Asset GUID
InputAction                                <-- Class type
ValueType                                  <-- Property name
Boolean                                    <-- Value type (Boolean/Axis2D/Axis1D)
Triggers                                   <-- Has triggers configured
InputTriggerHold                           <-- Trigger type (hold to activate)
HoldTimeThreshold                          <-- Hold timing property
```

#### Data Table Output

```
/Game/Data/DT_EnemyStats                   <-- Asset path
DataTable                                  <-- Class type
RowStruct                                  <-- Row structure type
/Script/S2.FEnemyStatsRow                  <-- Row struct class
```

### Common Asset Types

#### Input Mapping Context (IMC)

**Location:** `Content/Input/IMC_*.uasset`

**Key Properties:**
- `Mappings` - Array of key-to-action bindings
- `Modifiers` - Input modifiers (dead zone, negate, scalar)
- `Triggers` - Activation triggers (pressed, hold, released)
- `PlayerMappableKeySettings` - Rebinding settings

**Key Bindings to Look For:**
```
Gamepad_FaceButton_Bottom    (A / Cross)
Gamepad_FaceButton_Left      (X / Square)
Gamepad_FaceButton_Right     (B / Circle)
Gamepad_FaceButton_Top       (Y / Triangle)
Gamepad_LeftShoulder         (LB / L1)
Gamepad_RightShoulder        (RB / R1)
Gamepad_LeftTrigger          (LT / L2)
Gamepad_RightTrigger         (RT / R2)
Gamepad_Left2D               (Left Stick)
Gamepad_Right2D              (Right Stick)
Gamepad_LeftThumbstick       (L3)
Gamepad_RightThumbstick      (R3)
Gamepad_DPad_*               (D-Pad)
Gamepad_Special_Left         (Select / View)
Gamepad_Special_Right        (Start / Menu)
LeftMouseButton
RightMouseButton
MiddleMouseButton
Mouse2D
SpaceBar
LeftShift
LeftControl
Escape
```

#### Input Action (IA)

**Location:** `Content/Input/IA_*.uasset`

**Key Properties:**
- `ValueType` - Boolean, Axis1D, Axis2D, Axis3D
- `Triggers` - Array of trigger conditions
- `bConsumesActionAndAxisMappings` - Blocks legacy input
- `TriggerEventsThatConsumeLegacyKeys` - Legacy compatibility

**Trigger Types:**
```
InputTriggerPressed          - Fire on button press
InputTriggerReleased         - Fire on button release
InputTriggerDown             - Fire while held
InputTriggerHold             - Fire after hold threshold
InputTriggerChordAction      - Requires modifier key
```

**Modifier Types:**
```
InputModifierDeadZone        - Stick dead zone
InputModifierNegate          - Invert axis
InputModifierScalar          - Scale input value
InputModifierSmooth          - Smooth input over time
InputModifierSwizzleAxis     - Swap X/Y axes
```

#### Data Asset

**Key Properties:**
- `NativeClass` - Base class path
- Custom properties vary by asset type

### Analysis Workflow

#### Step 1: Find Assets

```bash
# Find all IMC files (example path -- replace with your project path)
dir /s /b "${PROJECT_ROOT}\Content\Input\IMC*.uasset"

# Find all Input Actions
dir /s /b "${PROJECT_ROOT}\Content\Input\IA_*.uasset"
```

Or use Glob tool:
```
Pattern: Content/Input/**/IMC*.uasset
Pattern: Content/Input/**/IA_*.uasset
```

#### Step 2: Extract Data

For each asset of interest:
```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "{asset_path}"
```

#### Step 3: Parse Results

Look for patterns:
- **Class identification:** `InputMappingContext`, `InputAction`, `DataTable`
- **Value types:** `Boolean`, `Axis2D`, `EInputActionValueType::*`
- **Triggers:** `InputTrigger*` strings
- **Modifiers:** `InputModifier*` strings
- **Key bindings:** `Gamepad_*`, `*MouseButton`, `SpaceBar`, etc.
- **Asset references:** `/Game/Input/IA_*` paths

#### Step 4: Generate Report

Compile findings into structured format:

```markdown
## Asset: IMC_MainCharacter

**Path:** /Game/Input/IMC_MainCharacter
**GUID:** 9E97F245C98F526E0E309854C1B07855
**Engine:** ++UE5+Release-5.6
**Class:** InputMappingContext

### Bindings
| Button | Action |
|--------|--------|
| Gamepad_FaceButton_Left | IA_LightAttack |
| Gamepad_FaceButton_Top | IA_HeavyAttack |
| ... | ... |

### Triggers Used
- InputTriggerHold (for IA_Parry)
- InputTriggerPressed (default)

### Modifiers Used
- InputModifierDeadZone (Axial)
- InputModifierSmooth
```

### Example Session

#### Analyze Combat IMC

```
User: Review the main character input bindings

Agent:
1. Finding IMC files...
   Found: Content/Input/IMC_MainCharacter.uasset

2. Extracting binary data...
   [runs extraction script]

3. Analysis Results:

   Asset: IMC_MainCharacter
   Actions: 55 input actions mapped

   Combat Bindings:
   - Gamepad_FaceButton_Left -> IA_LightAttack
   - Gamepad_FaceButton_Top -> IA_HeavyAttack
   - Gamepad_LeftTrigger -> IA_Parry (with InputTriggerHold)
   - Gamepad_FaceButton_Right -> IA_DashDodge

   Modifiers:
   - InputModifierDeadZone (Axial) on sticks
   - InputModifierSmooth on camera

   Triggers:
   - InputTriggerHold used for Parry
   - InputTriggerChordAction for combo moves
```

#### Compare Control Schemes

```
User: Compare Default and Sekiro control schemes

Agent:
1. Extracting IMC_MainCharacter...
2. Extracting IMC_MainCharacter_NewScheme...
3. Comparing action lists...

   Actions in Sekiro but not Default:
   - IA_ActivateCurrentArtifact
   - IA_ArtifactCombo
   - IA_SelectTalisman_DpadDown/Left/Right/Up

   Actions in Default but not Sekiro:
   - IA_Cutscene

   Conclusion: Sekiro scheme adds artifact quick-select,
   removes cutscene skip binding
```

### Surface Extraction Limitations

- **No float values:** Actual threshold values (e.g., HoldTimeThreshold=0.5) are stored as binary floats, not readable
- **No array indices:** Cannot determine exact mapping order
- **No hierarchy:** Cannot determine parent-child relationships
- **Large assets:** Very large assets may have truncated output
- **Blueprints:** BP logic is not readable, only metadata

### Troubleshooting

#### Script Not Found

```
Error: The term 'extract_uasset_strings.ps1' is not recognized
Solution: Re-create the script using the Write tool
```

#### Empty Output

```
Possible causes:
1. File path is incorrect
2. Asset is corrupted
3. Asset uses non-ASCII encoding

Solution: Verify file exists with 'dir' command
```

#### Execution Policy Error

```
Error: Running scripts is disabled on this system
Solution: Use -ExecutionPolicy Bypass flag (already included in commands)
```

### Script Location

**Recommended path:** `$env:TEMP\extract_uasset_strings.ps1`

This location:
- Is writable without admin privileges
- Persists across sessions (until system cleanup)
- Doesn't pollute project directory

---

## Deep Parsing (Python)

Parse .uasset files to extract internal structure as JSON or text. Supports deep recursive analysis with dependency categorization.

### Quick Start

```bash
# Full structure as JSON (example path -- replace with your project path)
python scripts/parse_uasset.py ${PROJECT_ROOT}/Content/Characters/BP_Player.uasset

# Human-readable text format
python scripts/parse_uasset.py ${PROJECT_ROOT}/Content/Characters/BP_Player.uasset --format text

# Quick summary only
python scripts/parse_uasset.py ${PROJECT_ROOT}/Content/Characters/BP_Player.uasset --summary

# Deep analysis with recursive dependency reading
python scripts/parse_uasset.py ${PROJECT_ROOT}/Content/BT/BT_Enemy.uasset --deep --format text

# Control recursion depth (default: 2)
python scripts/parse_uasset.py ${PROJECT_ROOT}/Content/BT/BT_Boss.uasset --deep --max-depth 3
```

### Deep Analysis Mode

Use `--deep` for comprehensive analysis including:
- **Categorized dependencies** (Ability, Montage, BehaviorTree, BTNode, Module, etc.)
- **Gameplay tag extraction**
- **BT node type listing**
- **Automated warnings** (WIP assets, typos, TEMP prefixes)
- **Recursive dependency analysis** (reads /Game/ dependencies)

```bash
# Deep analysis of a Behavior Tree (example path -- replace with your project path)
python scripts/parse_uasset.py "${PROJECT_ROOT}/Content/S2/Core_Boss/BT/BT_boss_phase_01.uasset" --deep --format text

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

### Output Structure

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

### Common Use Cases

#### Analyze Behavior Tree
```bash
python scripts/parse_uasset.py BT_Enemy.uasset --deep --format text
```

#### List all abilities used by asset
```bash
python scripts/parse_uasset.py MyAsset.uasset --deep | python -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d['categorized_dependencies'].get('Ability',[])))"
```

#### Find gameplay tags
```bash
python scripts/parse_uasset.py MyAsset.uasset --deep | python -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d['name_analysis']['gameplay_tags']))"
```

#### Find FNames matching pattern
```bash
python scripts/parse_uasset.py MyAsset.uasset | jq '.names[] | select(contains("Anim"))'
```

### Script Reference

`scripts/parse_uasset.py <path> [options]`

| Option | Description |
|--------|-------------|
| `--format json\|text` | Output format (default: json) |
| `--output FILE` | Write to file instead of stdout |
| `--summary` | Brief summary only |
| `--deep` | Deep analysis with recursive dependency reading |
| `--max-depth N` | Max recursion depth for deep analysis (default: 2) |
| `--content-root PATH` | Content folder root (auto-detected if not specified) |

### Format Support

| UE Version | Format | Support |
|------------|--------|---------|
| UE4.x | Uncooked | Full |
| UE5.0-5.2 | Uncooked | Full |
| UE5.3-5.7 | Uncooked | Full |
| UE5.3+ | Cooked | Basic (version info only) |

### Deep Parsing Limitations

- Header structure only (name/import/export tables)
- Does not deserialize UObject properties
- Cooked UE5.3+ assets have limited parsing
- .uexp bulk data not parsed
- Deep analysis only follows /Game/ paths (not /Script/ or /Engine/)

---

## Integration with Other Skills

### Combat Review
Use with `combat-ai-review` to analyze combat input configurations.

### Open Editor
Use after `open-editor` to cross-reference editor view with extracted data.

### Blueprint Tools
Use with `huli-bp-tools` to understand BP asset dependencies.

## Success Criteria

- Extraction returns readable strings (surface) or structured JSON/text (deep)
- Asset class type identified
- Key bindings extracted (for IMC)
- Value types identified (for IA)
- Referenced assets listed
- Dependencies categorized (deep mode)
- Report generated with findings

## Legacy Metadata

```yaml
skill: read-uasset
invoke: /asset-management:read-uasset
type: utility
category: asset-tools
scope: project-root
```
