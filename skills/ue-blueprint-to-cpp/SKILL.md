---
name: ue-blueprint-to-cpp
description: Convert Blueprint classes to C++ using NodeToCode with project-aware context gathering, inheritance chain orchestration, validation, and auto-fix. Triggers on "blueprint to cpp", "convert blueprint", "nativize", "BP to C++".
---

# UE Blueprint to C++ Converter

Convert Blueprints to high-quality C++ with project-aware context, multi-blueprint inheritance chain support, and automatic error correction.

## Configuration

This skill reads project paths from `skills.config.json` at the repository root.
- `project.root` / `project.uproject` — project location
- `engine.path` — custom engine installation

If not found, auto-detect using `ue-detect-engine` skill and CWD.

---

## Pipeline Overview

```
BLUEPRINT TO C++ PIPELINE
    │
    ├──[0] Detect Blueprint Inheritance Chain
    │        └─► Recursively find all BP parents until C++ base
    │
    ├──[1] Input & User Confirmation
    │        └─► Confirm output paths and conversion scope
    │
    ├──[2] Convert Each Blueprint (parent-first order)
    │        ├─► n2c-json-export        (JSON export sub-agent)
    │        ├─► n2c-context-gatherer   (context gathering sub-agent)
    │        ├─► n2c-code-generator     (code generation sub-agent)
    │        └─► n2c-validator          (validation sub-agent)
    │
    ├──[3] Write Files (after user confirmation)
    │
    ├──[4] Build Verification
    │        └─► Compile project to verify code
    │
    └──[5] Final Report
```

---

## Source Directories

When searching for project context, scan these locations:

| Type | Paths |
|------|-------|
| Main Module | `Source/{Module}/Public/`, `Source/{Module}/Private/` |
| Sipher Plugins | `Plugins/Sipher*/Source/*/Public/`, `Plugins/Sipher*/Source/*/Private/` |
| Framework Plugins | `Plugins/Frameworks/*/Source/*/Public/`, `Plugins/Frameworks/*/Source/*/Private/` |

---

## Phase 0: Detect Blueprint Inheritance Chain

Before converting, trace the full inheritance chain:

**Detection Logic:**
1. Use MCP `blueprint_read` or export JSON to get `parent_class`
2. If parent starts with `/Game/` — it is a Blueprint parent
3. Recursively trace until reaching a C++ class (no `/Game/` prefix)

**Example Chain:**
```
GA_Companion_StunStrike (Blueprint)
    └─► GA_CompanionAnimDrivenAttack (Blueprint parent)
        └─► USipherPhysicalAbility (C++ base)
```

**Inheritance Chain Conversion Order:**

When converting a chain like:
```
Child (BP) → Parent (BP) → Grandparent (BP) → CppBase (C++)
```

Convert in order:
1. Grandparent — inherits from CppBase
2. Parent — inherits from converted Grandparent
3. Child — inherits from converted Parent

This ensures each C++ class has its parent available during generation.

**Ask User (using AskUserQuestion tool):**

```
Blueprint Inheritance Detected

GA_Companion_StunStrike inherits from:
  → GA_CompanionAnimDrivenAttack (Blueprint)
    → USipherPhysicalAbility (C++)

How should we handle the Blueprint parent?

Options:
1. Convert Both (Recommended) - Convert parent BP to C++ first, then child inherits from it
2. Flatten - Merge parent BP logic into child C++ class
3. Skip Parent - Convert only child, inherit from USipherPhysicalAbility directly
```

If only a single Blueprint with a C++ base class is being converted, skip this phase and proceed directly to Phase 1.

---

## Phase 1: Input & User Confirmation

### Step 1.1: Get Blueprint Path

If not provided, ask user:
> "Which Blueprint do you want to convert to C++?"
> Example: `/Game/S2/Core/GAS/GA_Jump`

### Step 1.2: Confirm Output Paths

**Default Path Mapping:**

From Blueprint path `/Game/{Module}/{SubPath}/{AssetName}`:

| Module | Public Path | Private Path |
|--------|-------------|--------------|
| `S2` | `Source/S2/Public/{SubPath}/` | `Source/S2/Private/{SubPath}/` |
| `Sipher*` | `Plugins/{Module}/Source/{Module}/Public/{SubPath}/` | `...Private/{SubPath}/` |
| `Frameworks/*` | `Plugins/Frameworks/{Module}/Source/{Module}/Public/{SubPath}/` | `...Private/{SubPath}/` |

**For multi-blueprint chains, confirm all output paths:**

```
Confirm Output Paths

The following files will be generated:

1. GA_CompanionAnimDrivenAttack (parent)
   Header: Source/S2/Public/GameplayAbilities/GA_CompanionAnimDrivenAttack.h
   Impl:   Source/S2/Private/GameplayAbilities/GA_CompanionAnimDrivenAttack.cpp

2. GA_Companion_StunStrike (child)
   Header: Source/S2/Public/GameplayAbilities/GA_Companion_StunStrike.h
   Impl:   Source/S2/Private/GameplayAbilities/GA_Companion_StunStrike.cpp

Options:
1. Confirm paths
2. Change paths (specify new locations)
```

If user wants to change paths, accept their input and update accordingly.

---

## Phase 2: Convert Blueprints

For each Blueprint in the chain (starting from topmost parent, or a single Blueprint if no chain):

### Step 2.1: Export N2C JSON

Use sub-agent `n2c-json-export`.

Run the NodeToCode export commandlet (paths from `skills.config.json`):

```bash
# Get paths from skills.config.json or auto-detect
$EnginePath = ...  # from skills.config.json engine.path or ue-detect-engine
$ProjectPath = ... # from skills.config.json project.uproject or CWD

# Export Blueprint to JSON
& "$EnginePath/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$ProjectPath" -run=N2CExport -Blueprint={BlueprintPath} -Output={ProjectRoot}/Saved/NodeToCode/Export/{AssetName}.json -Depth=2 -Pretty -unattended -nosplash -nullrhi
```

### Step 2.2: Parse JSON

Read the exported JSON and extract:
- `metadata.BlueprintClass` — Parent class name
- All `member_parent` values — Classes being called
- All `sub_type` values — Struct/class types on pins
- All `member_name` values — Functions being called

### Step 2.3: Context Gathering

Use sub-agent `n2c-context-gatherer`.

#### Resolve Include Paths

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

#### Extract Base Class Signatures

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

**For multi-blueprint chains:** Include `previouslyGeneratedClasses` — the list of parent classes already converted in this session — so the code generator can inherit from converted C++ classes instead of Blueprint parents.

#### Detect API Patterns

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

### Step 2.4: Prompt Assembly

Combine all gathered context into the LLM prompt:

```xml
<projectContext>
  <includeMap>
    {Include Map JSON from Step 2.3}
  </includeMap>

  <baseClassSignatures>
    {Base Class Context JSON from Step 2.3}
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
  {N2C JSON from Step 2.1}
</nodeToCodeJson>

<task>
  Convert this Blueprint to C++ following the project context above.
  Use ONLY the include paths from the includeMap - do not guess paths.
  Match base class method signatures EXACTLY as shown in baseClassSignatures.
  Follow the apiPatterns for known UE5.7 patterns.
  CRITICAL: If parent was converted in this session, inherit from the converted C++ class.
</task>
```

### Step 2.5: Code Generation

Use sub-agent `n2c-code-generator`.

Send the assembled prompt to generate C++ code.

### Step 2.6: Validation

Use sub-agent `n2c-validator`.

#### Validate Includes

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

#### Validate Method Signatures

For each override method in generated code:

```bash
# Extract the base class signature
grep -A1 "virtual.*{MethodName}" {BaseClassHeader}
```

**If signature mismatch:**
1. Extract correct signature from base class
2. Replace the incorrect signature

#### Validate Structure

Check generated .cpp file structure:

```
1. Includes come first (starting with own header)
2. Then other includes
3. Then implementation
```

**If structure wrong:**
1. Reorder: Move all `#include` statements to top
2. Own header first: `#include "{ClassName}.h"`

#### Apply Known Auto-Fixes

| # | Pattern | Check | Fix |
|---|---------|-------|-----|
| 1 | Wrong include path | Include file not found | Search and replace with correct path |
| 2 | Wrong method signature | Signature doesn't match base class | Replace with base class signature |
| 3 | Protected delegate access | `OnMoveFinished.Add` | Use `OnMoveTaskFinished.AddUObject` |
| 4 | Wrong WaitDelay class | `UGameplayTask_WaitDelay` | Use `UAbilityTask_WaitDelay` |
| 5 | TSoftObjectPtr assignment | `TSoftObjectPtr<T>(...)` to `T*` | Add `.LoadSynchronous()` |
| 6 | Variable shadowing | Local name matches base member | Rename local variable |
| 7 | Wrong API signature | Old 3-param style | Use new 2-param return style |
| 8 | Code before includes | Function before `#include` | Reorder file structure |

---

## Phase 3: Write Files

After all Blueprints are validated:

1. **Show final confirmation:**
```
Ready to write files:

1. GA_CompanionAnimDrivenAttack
   - Source/S2/Public/GameplayAbilities/GA_CompanionAnimDrivenAttack.h (NEW)
   - Source/S2/Private/GameplayAbilities/GA_CompanionAnimDrivenAttack.cpp (NEW)

2. GA_Companion_StunStrike
   - Source/S2/Public/GameplayAbilities/GA_Companion_StunStrike.h (EXISTS - will backup)
   - Source/S2/Private/GameplayAbilities/GA_Companion_StunStrike.cpp (EXISTS - will backup)

Proceed? [Y/n]
```

2. **Create directories** if needed
3. **Backup existing files** with `.bak` extension
4. **Write all files**

---

## Phase 4: Build Verification

After writing files, compile to verify (paths from `skills.config.json`):

```bash
# Get paths from skills.config.json or auto-detect
$EnginePath = ...  # from skills.config.json engine.path or ue-detect-engine
$ProjectPath = ... # from skills.config.json project.uproject or CWD
$ModuleName = ...  # from skills.config.json or detect from .uproject

& "$EnginePath/Engine/Build/BatchFiles/Build.bat" "${ModuleName}Editor" Win64 Development -Project="$ProjectPath" -WaitMutex
```

**Check build result:**
- **Success**: Report completion
- **Failure**: Show errors, offer to rollback `.bak` files

### Rollback on Build Failure

If build fails after writing files:

```
Build Failed - Compilation Errors

Error: GA_Companion_StunStrike.cpp(45): error C2039: 'MakeEffectContext' is not a member of 'UAbilitySystemComponent'

Options:
1. Rollback - Restore .bak files and delete generated code
2. Keep files - Leave generated code for manual fixing
3. Retry generation - Re-run code generator with error context
```

---

## Phase 5: Final Report

```
Blueprint Conversion Complete

Converted 2 Blueprints:

1. GA_CompanionAnimDrivenAttack → UGA_CompanionAnimDrivenAttack
   - Source/S2/Public/GameplayAbilities/GA_CompanionAnimDrivenAttack.h
   - Source/S2/Private/GameplayAbilities/GA_CompanionAnimDrivenAttack.cpp
   - Base: USipherPhysicalAbility

2. GA_Companion_StunStrike → UGA_Companion_StunStrike
   - Source/S2/Public/GameplayAbilities/GA_Companion_StunStrike.h
   - Source/S2/Private/GameplayAbilities/GA_Companion_StunStrike.cpp
   - Base: UGA_CompanionAnimDrivenAttack (converted above)

Build Status: SUCCESS
Validation Fixes Applied: 3
Warnings: 0

Next Steps:
- Delete original Blueprint assets if no longer needed
- Update any Blueprint references to use new C++ classes
```

---

## Error Handling

| Phase | Error | Action |
|-------|-------|--------|
| 0 | Circular inheritance | Error — invalid BP structure |
| 1 | User cancels | Abort gracefully |
| 2.1 | EXPORT_TIMEOUT | Check if Editor is running |
| 2.5 | GENERATION_FAILED | Show partial, ask guidance |
| 2.6 | VALIDATION_FAILED (3x) | Proceed with warnings |
| 4 | BUILD_FAILED | Show errors, offer rollback |

---

## Example Workflow (Single Blueprint)

```
User: Convert /Game/S2/Core/GAS/GA_HitReaction_Direct to C++

Skill:
1. Export N2C JSON -> Saved/NodeToCode/Export/GA_HitReaction_Direct.json
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

## Example Workflow (Multi-Blueprint Inheritance Chain)

```
User: Convert /Game/S2/Core/GAS/Companion/GA_Companion_StunStrike to C++

Skill:
1. Detect inheritance chain:
   GA_Companion_StunStrike → GA_CompanionAnimDrivenAttack (BP) → USipherPhysicalAbility (C++)
2. Ask user: Convert both? Flatten? Skip parent?
3. User selects: Convert Both
4. Confirm output paths for both files
5. Convert GA_CompanionAnimDrivenAttack first (parent):
   - Export JSON, gather context, generate code, validate
6. Convert GA_Companion_StunStrike (child):
   - Export JSON, gather context (includes converted parent), generate code, validate
7. Show final confirmation, write all files
8. Build verification
9. Report: 2 Blueprints converted, build SUCCESS
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

## Sub-Agent Reference

This skill orchestrates the following sub-agents for the conversion pipeline:

| Sub-Agent | Skill | Role |
|-----------|-------|------|
| JSON Export | `n2c-json-export` | Export Blueprint to NodeToCode JSON |
| Context Gatherer | `n2c-context-gatherer` | Gather include paths, base class signatures, API patterns |
| Code Generator | `n2c-code-generator` | Generate C++ header and implementation |
| Validator | `n2c-validator` | Validate and auto-fix generated code |

## Legacy Metadata

```yaml
invocable: true
```
