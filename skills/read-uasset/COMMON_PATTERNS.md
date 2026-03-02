# Common UAsset String Patterns Reference

Quick reference for interpreting extracted strings from .uasset binary files.

## Asset Identification

| String Pattern | Meaning |
|----------------|---------|
| `/Game/...` | Asset path in content browser |
| `[A-F0-9]{32}` | Asset GUID (unique identifier) |
| `++UE5+Release-5.6` | Engine version asset was saved with |
| `/Script/ModuleName` | Module/plugin dependency |

## Class Types

| String | Asset Type |
|--------|------------|
| `InputMappingContext` | IMC - Key/button to action mappings |
| `InputAction` | IA - Single input action definition |
| `DataTable` | DT - Row-based data storage |
| `Blueprint` | BP - Blueprint class |
| `WidgetBlueprint` | WBP - UI Widget |
| `AnimSequence` | Animation clip |
| `AnimMontage` | Animation montage |
| `Material` | Material asset |
| `MaterialInstance` | Material instance |
| `Texture2D` | 2D texture |
| `SkeletalMesh` | Skeletal mesh |
| `StaticMesh` | Static mesh |
| `SoundWave` | Audio file |
| `SoundCue` | Sound cue (audio logic) |
| `NiagaraSystem` | Niagara particle system |
| `LevelSequence` | Sequencer cinematic |

## Input System (Enhanced Input)

### Value Types

| String | Type | Use Case |
|--------|------|----------|
| `Boolean` | bool | Button press (on/off) |
| `Axis1D` | float | Trigger analog (0-1) |
| `Axis2D` | FVector2D | Stick (X,Y) |
| `Axis3D` | FVector | Motion controller |
| `EInputActionValueType::Axis2D` | Enum form | Same as above |

### Gamepad Keys

| String | Physical Button | PlayStation | Xbox |
|--------|-----------------|-------------|------|
| `Gamepad_FaceButton_Bottom` | Bottom | Cross (X) | A |
| `Gamepad_FaceButton_Right` | Right | Circle (O) | B |
| `Gamepad_FaceButton_Left` | Left | Square | X |
| `Gamepad_FaceButton_Top` | Top | Triangle | Y |
| `Gamepad_LeftShoulder` | Left Bumper | L1 | LB |
| `Gamepad_RightShoulder` | Right Bumper | R1 | RB |
| `Gamepad_LeftTrigger` | Left Trigger | L2 | LT |
| `Gamepad_LeftTriggerAxis` | Left Trigger Analog | L2 | LT |
| `Gamepad_RightTrigger` | Right Trigger | R2 | RT |
| `Gamepad_RightTriggerAxis` | Right Trigger Analog | R2 | RT |
| `Gamepad_Left2D` | Left Stick | Left Analog | Left Analog |
| `Gamepad_Right2D` | Right Stick | Right Analog | Right Analog |
| `Gamepad_LeftThumbstick` | Left Stick Click | L3 | LS |
| `Gamepad_RightThumbstick` | Right Stick Click | R3 | RS |
| `Gamepad_DPad_Up` | D-Pad Up | Up | Up |
| `Gamepad_DPad_Down` | D-Pad Down | Down | Down |
| `Gamepad_DPad_Left` | D-Pad Left | Left | Left |
| `Gamepad_DPad_Right` | D-Pad Right | Right | Right |
| `Gamepad_Special_Left` | Special Left | Share | View |
| `Gamepad_Special_Right` | Special Right | Options | Menu |

### Keyboard Keys

| String | Key |
|--------|-----|
| `SpaceBar` | Space |
| `LeftShift` | Left Shift |
| `RightShift` | Right Shift |
| `LeftControl` | Left Ctrl |
| `RightControl` | Right Ctrl |
| `LeftAlt` | Left Alt |
| `RightAlt` | Right Alt |
| `Escape` | Escape |
| `Tab` | Tab |
| `Enter` | Enter |
| `BackSpace` | Backspace |
| `One` through `Zero` | Number keys |
| `A` through `Z` | Letter keys |
| `F1` through `F12` | Function keys |

### Mouse

| String | Input |
|--------|-------|
| `LeftMouseButton` | Left Click |
| `RightMouseButton` | Right Click |
| `MiddleMouseButton` | Middle Click |
| `ThumbMouseButton` | Mouse 4 |
| `ThumbMouseButton2` | Mouse 5 |
| `Mouse2D` | Mouse Movement |
| `MouseX` | Horizontal Movement |
| `MouseY` | Vertical Movement |
| `MouseWheelAxis` | Scroll Wheel |

### Input Triggers

| String | Behavior |
|--------|----------|
| `InputTriggerPressed` | Fire once on press |
| `InputTriggerReleased` | Fire once on release |
| `InputTriggerDown` | Fire every frame while held |
| `InputTriggerHold` | Fire after hold threshold |
| `InputTriggerTap` | Fire on quick tap (release before threshold) |
| `InputTriggerPulse` | Fire repeatedly while held |
| `InputTriggerChordAction` | Requires modifier held first |
| `InputTriggerCombo` | Requires sequence of inputs |

### Input Modifiers

| String | Effect |
|--------|--------|
| `InputModifierDeadZone` | Ignore small stick movements |
| `InputModifierNegate` | Invert the value |
| `InputModifierScalar` | Multiply by constant |
| `InputModifierSmooth` | Interpolate over time |
| `InputModifierSwizzleAxis` | Swap X/Y components |
| `InputModifierFOVScaling` | Scale by camera FOV |
| `InputModifierToWorldSpace` | Convert to world coordinates |
| `InputModifierResponseCurve` | Apply response curve |

### Dead Zone Types

| String | Behavior |
|--------|----------|
| `EDeadZoneType::Axial` | Dead zone per axis (square) |
| `EDeadZoneType::Radial` | Dead zone as circle |

## Property Names

### Common Properties

| String | Type | Description |
|--------|------|-------------|
| `Mappings` | Array | Key-to-action bindings |
| `Action` | Object | Reference to InputAction |
| `Modifiers` | Array | Input modifiers |
| `Triggers` | Array | Activation triggers |
| `Key` | Struct | Physical key/button |
| `KeyName` | Name | Key identifier |
| `ValueType` | Enum | Action value type |
| `bConsumesActionAndAxisMappings` | Bool | Block legacy input |
| `HoldTimeThreshold` | Float | Hold trigger timing |
| `ActuationThreshold` | Float | Activation sensitivity |
| `LowerThreshold` | Float | Dead zone inner bound |
| `UpperThreshold` | Float | Dead zone outer bound |
| `PlayerMappableKeySettings` | Struct | Rebinding options |
| `bIsPlayerMappable` | Bool | Can player rebind |
| `DisplayName` | Text | UI display name |
| `DisplayCategory` | Text | Settings category |

## GAS (Gameplay Ability System)

| String | Meaning |
|--------|---------|
| `GameplayAbility` | Ability class |
| `GameplayEffect` | Effect class |
| `GameplayTag` | Tag reference |
| `GameplayTagContainer` | Tag set |
| `GameplayCue` | Visual/audio feedback |
| `AbilityTask` | Async ability task |
| `AttributeSet` | Character attributes |

## Animation

| String | Meaning |
|--------|---------|
| `AnimNotify_*` | Animation notify class |
| `AnimNotifyState_*` | Animation notify state |
| `Skeleton` | Skeleton reference |
| `BlendSpace` | Blend space asset |
| `AnimBlueprintGeneratedClass` | Animation blueprint |
| `Montage` | Montage reference |
| `Section` | Montage section |
| `Slot` | Animation slot |

## Useful Grep Patterns

```bash
# Find all actions in IMC
grep -E "^IA_" output.txt

# Find all gamepad bindings
grep -E "^Gamepad_" output.txt

# Find all triggers
grep -E "^InputTrigger" output.txt

# Find all modifiers
grep -E "^InputModifier" output.txt

# Find asset references
grep -E "^/Game/" output.txt

# Find engine version
grep -E "^\+\+UE5" output.txt
```

## Example Output Analysis

### IMC File

```
/Game/Input/IMC_MainCharacter     <- This is an IMC
InputMappingContext               <- Confirmed class type
Gamepad_FaceButton_Left           <- X/Square button bound
/Game/Input/IA_LightAttack        <- To this action
InputTriggerPressed               <- With press trigger
```

### IA File with Hold

```
/Game/Input/IA_Parry              <- This is Parry action
InputAction                       <- Confirmed class type
ValueType                         <- Has value type property
Boolean                           <- It's a boolean (press/release)
Triggers                          <- Has triggers configured
InputTriggerHold                  <- Uses hold trigger
HoldTimeThreshold                 <- With timing threshold
```

### IA File without Triggers

```
/Game/Input/IA_LightAttack        <- This is Light Attack
InputAction                       <- Confirmed class type
ValueType                         <- Has value type property
Boolean                           <- It's a boolean
bConsumesActionAndAxisMappings    <- Blocks legacy input
                                  <- NO InputTrigger* = uses default Pressed
```
