---
name: ue-blueprint-to-cpp
description: Convert Blueprint classes to C++ using NodeToCode with project-aware context gathering, validation, and auto-fix. Triggers on "blueprint to cpp", "convert blueprint", "nativize", "BP to C++".
---

# UE Blueprint to C++ Converter v2

Convert Blueprints to high-quality C++ with project-aware context and automatic error correction.

## Source Directories

When searching for project context, scan these locations:

| Type | Paths |
|------|-------|
| Main Module | `Source/S2/Public/`, `Source/S2/Private/` |
| Sipher Plugins | `Plugins/Sipher*/Source/*/Public/`, `Plugins/Sipher*/Source/*/Private/` |
| Framework Plugins | `Plugins/Frameworks/*/Source/*/Public/`, `Plugins/Frameworks/*/Source/*/Private/` |

---

## Phase 1: Input & Export

### Step 1.1: Get Blueprint Path

If not provided, ask user:
> "Which Blueprint do you want to convert to C++?"
> Example: `/Game/S2/Core/GAS/GA_Jump`

### Step 1.2: Export N2C JSON

Run the NodeToCode export commandlet:

```bash
# Get engine path from registry
$EngineBuilds = Get-ItemProperty "HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds"
$EnginePath = $EngineBuilds.PSObject.Properties | Where-Object { $_.Value -like "*Engine*" } | Select-Object -First 1 -ExpandProperty Value

# Export Blueprint to JSON
& "$EnginePath/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "G:/s2/S2.uproject" -run=N2CExport -Blueprint={BlueprintPath} -Output=G:/s2/Saved/NodeToCode/Export/temp.json -Pretty
```

### Step 1.3: Parse JSON

Read the exported JSON and extract:
- `metadata.BlueprintClass` - Parent class name
- All `member_parent` values - Classes being called
- All `sub_type` values - Struct/class types on pins
- All `member_name` values - Functions being called

---

## Phase 2: Context Gathering

### Step 2.1: Resolve Include Paths

For each unique class/struct identified, find its actual header location:

```bash
# Search patterns for class declarations
grep -r "UCLASS.*" Source/S2/Public --include="*.h" -l
grep -r "USTRUCT.*" Source/S2/Public --include="*.h" -l
grep -r "class.*{ClassName}" Plugins/Sipher*/Source/*/Public --include="*.h" -l
grep -r "class.*{ClassName}" Plugins/Frameworks/*/Source/*/Public --include="*.h" -l
```

Build the **Include Map**:

```json
{
  "includes": {
    "USipherAbilitySystemComponent": "Core/ASC/SipherAbilitySystemComponent.h",
    "PlayerCombatAttributeSet": "Core/ASC/AttributeSet/PlayerCombatAttributeSet.h",
    "FSipherGenericAbilityData": "GameplayAbilities/AbilityData/SipherGenericAbilityData.h",
    "USipherGameplayAbilityRuntime": "GameplayAbilities/SipherGameplayAbilityRuntime.h"
  }
}
```

### Step 2.2: Extract Base Class Signatures

If the Blueprint extends a C++ class, read the base class header:

```bash
# Find base class header
grep -r "class.*{BaseClassName}.*:" Source/S2/Public Plugins/Sipher*/Source/*/Public Plugins/Frameworks/*/Source/*/Public --include="*.h" -l
```

Then read the header and extract:
- All `virtual` method signatures
- `UFUNCTION` specifiers
- Parameter types and names

Format as **Base Class Context**:

```json
{
  "baseClass": "USipherGameplayAbilityRuntime",
  "headerPath": "GameplayAbilities/SipherGameplayAbilityRuntime.h",
  "virtualMethods": [
    {
      "signature": "virtual bool K2_OverrideRuntimeData_Implementation(TInstancedStruct<FSipherGenericAbilityData>& OverridenData)",
      "specifiers": ["BlueprintNativeEvent"]
    },
    {
      "signature": "virtual void ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData)",
      "specifiers": ["override"]
    }
  ]
}
```

### Step 2.3: Detect API Patterns

For known problem areas, verify the correct API:

**UAITask_MoveTo Delegate Check:**
```bash
grep -B2 -A2 "OnMoveFinished\|OnMoveTaskFinished" Plugins/Frameworks/SipherAIScalableFramework/Source/*/Public --include="*.h"
```

**AbilityTask_WaitDelay Check:**
```bash
grep -r "UAbilityTask_WaitDelay\|UGameplayTask_WaitDelay" Source/S2 Plugins/Sipher* Plugins/Frameworks --include="*.h" --include="*.cpp" | head -5
```

**TSoftObjectPtr Usage Check:**
```bash
grep -r "\.LoadSynchronous()" Source/S2 Plugins/Sipher* --include="*.cpp" | head -3
```

---

## Phase 3: Prompt Assembly

Combine all gathered context into the LLM prompt:

```xml
<projectContext>
  <includeMap>
    {Include Map JSON from Step 2.1}
  </includeMap>

  <baseClassSignatures>
    {Base Class Context JSON from Step 2.2}
  </baseClassSignatures>

  <apiPatterns>
    - For UAITask_MoveTo: Use OnMoveTaskFinished (public native delegate), NOT OnMoveFinished (protected)
    - For ability wait delays: Use UAbilityTask_WaitDelay::WaitDelay(), NOT UGameplayTask_WaitDelay
    - For TSoftObjectPtr assignment to raw pointer: Call .LoadSynchronous()
    - For attribute getters: Use 2-param version returning float, NOT 3-param with out reference
  </apiPatterns>

  <namingConventions>
    - Actor classes: ASipher{Name}
    - Components: USipher{Name}Component
    - Structs: FSipher{Name}
    - Avoid shadowing base class members (e.g., don't name local var "AnimationData" if base has it)
  </namingConventions>
</projectContext>

<nodeToCodeJson>
  {N2C JSON from Step 1.2}
</nodeToCodeJson>

<task>
  Convert this Blueprint to C++ following the project context above.
  Use ONLY the include paths from the includeMap - do not guess paths.
  Match base class method signatures EXACTLY as shown in baseClassSignatures.
  Follow the apiPatterns for known UE5.7 patterns.
</task>
```

---

## Phase 4: Generation & Validation Loop

### Step 4.1: Generate Code

Send the assembled prompt to generate C++ code.

### Step 4.2: Validate Includes

For each `#include` in the generated code:

```bash
# Check if include path exists
ls "Source/S2/Public/{IncludePath}" 2>/dev/null || \
ls "Plugins/Sipher*/Source/*/Public/{IncludePath}" 2>/dev/null || \
ls "Plugins/Frameworks/*/Source/*/Public/{IncludePath}" 2>/dev/null
```

**If include not found:**
1. Search for the class name to find correct path
2. Replace the incorrect include with the correct one

### Step 4.3: Validate Method Signatures

For each override method in generated code:

```bash
# Extract the base class signature
grep -A1 "virtual.*{MethodName}" {BaseClassHeader}
```

**If signature mismatch:**
1. Extract correct signature from base class
2. Replace the incorrect signature

### Step 4.4: Validate Structure

Check generated .cpp file structure:

```
1. Includes come first (starting with own header)
2. Then other includes
3. Then implementation
```

**If structure wrong:**
1. Reorder: Move all `#include` statements to top
2. Own header first: `#include "{ClassName}.h"`

### Step 4.5: Apply Known Fixes

| Pattern | Check | Fix |
|---------|-------|-----|
| `OnMoveFinished.AddDynamic` | grep | Replace with `OnMoveTaskFinished.AddUObject` |
| `UGameplayTask_WaitDelay` | grep | Replace with `UAbilityTask_WaitDelay` |
| `TSoftObjectPtr<T>(...) assigned to T*` | grep | Add `.LoadSynchronous()` |
| Variable shadows base member | compare | Rename local variable |

---

## Phase 5: Output

### Step 5.1: Determine Output Paths

From Blueprint path `/Game/{Module}/{SubPath}/{AssetName}`:

| Module | Public Path | Private Path |
|--------|-------------|--------------|
| `S2` | `Source/S2/Public/{SubPath}/` | `Source/S2/Private/{SubPath}/` |
| `Sipher*` | `Plugins/{Module}/Source/{Module}/Public/{SubPath}/` | `...Private/{SubPath}/` |
| `Frameworks/*` | `Plugins/Frameworks/{Module}/Source/{Module}/Public/{SubPath}/` | `...Private/{SubPath}/` |

### Step 5.2: Write Files

1. Write header to `{PublicPath}/{ClassName}.h`
2. Write implementation to `{PrivatePath}/{ClassName}.cpp`

### Step 5.3: Report

```
Generated:
   - Source/S2/Public/Core/GAS/GA_Jump.h
   - Source/S2/Private/Core/GAS/GA_Jump.cpp

Validation Results:
   - Include paths: All verified
   - Method signatures: All match base class
   - Structure: Correct

Manual Review Needed:
   - Line 45: Verify GameplayTag value matches Blueprint
```

---

## Known Issues & Auto-Fixes

These issues are automatically detected and corrected:

| # | Issue | Detection | Auto-Fix |
|---|-------|-----------|----------|
| 1 | Wrong include path | Include file not found | Search and replace with correct path |
| 2 | Wrong method signature | Signature doesn't match base class | Replace with base class signature |
| 3 | Protected delegate access | `OnMoveFinished.Add` | Use `OnMoveTaskFinished.AddUObject` |
| 4 | Wrong WaitDelay class | `UGameplayTask_WaitDelay` | Use `UAbilityTask_WaitDelay` |
| 5 | TSoftObjectPtr assignment | `TSoftObjectPtr<T>(...)` to `T*` | Add `.LoadSynchronous()` |
| 6 | Variable shadowing | Local name matches base member | Rename local variable |
| 7 | Wrong API signature | Old 3-param style | Use new 2-param return style |
| 8 | Code before includes | Function before `#include` | Reorder file structure |

---

## Example Workflow

```
User: Convert /Game/S2/Core/GAS/GA_HitReaction_Direct to C++

Skill:
1. Export N2C JSON -> Saved/NodeToCode/Export/temp.json
2. Parse JSON:
   - Base class: USipherGameplayAbilityRuntime
   - Uses: FSipherAbilityData_Animation, PlayerCombatAttributeSet
3. Gather context:
   - Found USipherGameplayAbilityRuntime at GameplayAbilities/SipherGameplayAbilityRuntime.h
   - Found FSipherAbilityData_Animation at GameplayAbilities/AbilityData/SipherAbilityData_Animation.h
   - Extracted K2_OverrideRuntimeData_Implementation signature
4. Assemble prompt with all context
5. Generate code
6. Validate:
   - All includes exist
   - K2_OverrideRuntimeData_Implementation signature matches
   - Found AnimationData shadowing - renamed to LocalAnimData
7. Write files:
   - Source/S2/Public/Core/GAS/GA_HitReaction_Direct.h
   - Source/S2/Private/Core/GAS/GA_HitReaction_Direct.cpp
```

---

## Commandlet Reference

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Blueprint=<path>` | Yes | Asset path (e.g., `/Game/S2/Core/GAS/GA_Jump`) |
| `-Output=<file>` | No | Output JSON file path |
| `-Graph=<name>` | No | Specific graph to export |
| `-Depth=<0-5>` | No | Translation depth for nested graphs |
| `-Pretty` | No | Pretty-print JSON output |
