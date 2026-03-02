---
name: read-uasset
description: Extract readable strings and metadata from Unreal Engine binary .uasset files
---

# Read UAsset Binary Skill

**Role:** Asset Data Extraction Utility
**Scope:** Any .uasset file in the project
**Platform:** Windows (PowerShell)
**Use Cases:** IMC analysis, Input Action review, Data Asset inspection, Blueprint metadata extraction

## Objective

Extract readable ASCII strings from binary .uasset files to analyze asset configuration without opening Unreal Editor. This enables agents to review Input Mapping Contexts, Input Actions, Data Tables, and other binary assets programmatically.

## What Can Be Extracted

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

## Setup

### Step 1: Create Extraction Script

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

### Step 2: Write the Script

```markdown
Action: Write PowerShell script to temp directory
Tool: Write
Path: C:\Users\Admin\AppData\Local\Temp\extract_uasset_strings.ps1
Content: (script above)
```

## Usage

### Basic Extraction

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Admin\AppData\Local\Temp\extract_uasset_strings.ps1" -FilePath "D:\s2\Content\Input\IMC_MainCharacter.uasset"
```

### With Line Limit (for large assets)

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Admin\AppData\Local\Temp\extract_uasset_strings.ps1" -FilePath "D:\s2\Content\Input\IMC_MainCharacter.uasset" 2>&1 | head -200
```

### Multiple Files in Parallel

```bash
# Extract from multiple files
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "path1.uasset"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "path2.uasset"
```

## Output Interpretation

### Input Mapping Context (IMC) Output

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

### Input Action (IA) Output

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

### Data Table Output

```
/Game/Data/DT_EnemyStats                   <-- Asset path
DataTable                                  <-- Class type
RowStruct                                  <-- Row structure type
/Script/S2.FEnemyStatsRow                  <-- Row struct class
```

## Common Asset Types

### Input Mapping Context (IMC)

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

### Input Action (IA)

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

### Data Asset

**Key Properties:**
- `NativeClass` - Base class path
- Custom properties vary by asset type

## Analysis Workflow

### Step 1: Find Assets

```bash
# Find all IMC files
dir /s /b "D:\s2\Content\Input\IMC*.uasset"

# Find all Input Actions
dir /s /b "D:\s2\Content\Input\IA_*.uasset"
```

Or use Glob tool:
```
Pattern: Content/Input/**/IMC*.uasset
Pattern: Content/Input/**/IA_*.uasset
```

### Step 2: Extract Data

For each asset of interest:
```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Admin\AppData\Local\Temp\extract_uasset_strings.ps1" -FilePath "{asset_path}"
```

### Step 3: Parse Results

Look for patterns:
- **Class identification:** `InputMappingContext`, `InputAction`, `DataTable`
- **Value types:** `Boolean`, `Axis2D`, `EInputActionValueType::*`
- **Triggers:** `InputTrigger*` strings
- **Modifiers:** `InputModifier*` strings
- **Key bindings:** `Gamepad_*`, `*MouseButton`, `SpaceBar`, etc.
- **Asset references:** `/Game/Input/IA_*` paths

### Step 4: Generate Report

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

## Example Session

### Analyze Combat IMC

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

### Compare Control Schemes

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

## Limitations

- **No float values:** Actual threshold values (e.g., HoldTimeThreshold=0.5) are stored as binary floats, not readable
- **No array indices:** Cannot determine exact mapping order
- **No hierarchy:** Cannot determine parent-child relationships
- **Large assets:** Very large assets may have truncated output
- **Blueprints:** BP logic is not readable, only metadata

## Troubleshooting

### Script Not Found

```
Error: The term 'extract_uasset_strings.ps1' is not recognized
Solution: Re-create the script using the Write tool
```

### Empty Output

```
Possible causes:
1. File path is incorrect
2. Asset is corrupted
3. Asset uses non-ASCII encoding

Solution: Verify file exists with 'dir' command
```

### Execution Policy Error

```
Error: Running scripts is disabled on this system
Solution: Use -ExecutionPolicy Bypass flag (already included in commands)
```

## Script Location

**Recommended path:** `C:\Users\Admin\AppData\Local\Temp\extract_uasset_strings.ps1`

This location:
- Is writable without admin privileges
- Persists across sessions (until system cleanup)
- Doesn't pollute project directory

## Integration with Other Skills

### Combat Review
Use with `combat-ai-review` to analyze combat input configurations.

### Open Editor
Use after `open-editor` to cross-reference editor view with extracted data.

### Blueprint Tools
Use with `huli-bp-tools` to understand BP asset dependencies.

## Success Criteria

- Script created at temp location
- Extraction returns readable strings
- Asset class type identified
- Key bindings extracted (for IMC)
- Value types identified (for IA)
- Referenced assets listed
- Report generated with findings

## Legacy Metadata

```yaml
skill: read-uasset
invoke: /asset-management:read-uasset
type: utility
category: asset-tools
scope: project-root
```
