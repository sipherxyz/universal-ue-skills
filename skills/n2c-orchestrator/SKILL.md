---
name: n2c-orchestrator
description: Lead orchestrator for Blueprint to C++ conversion using multi-agent pipeline. Triggers on "blueprint to cpp", "convert blueprint", "nativize", "n2c-orchestrator".
---

# N2C Lead Orchestrator

Coordinates sub-agents for Blueprint to C++ conversion with full inheritance support.

## Pipeline Overview

```
ORCHESTRATOR (this skill)
    │
    ├──[0] Detect Blueprint Inheritance Chain
    │        └─► Recursively find all BP parents until C++ base
    │
    ├──[1] User Confirmation
    │        └─► Confirm output paths and conversion scope
    │
    ├──[2] Convert Each Blueprint (parent-first order)
    │        ├─► n2c-json-export
    │        ├─► n2c-context-gatherer
    │        ├─► n2c-code-generator
    │        └─► n2c-validator
    │
    ├──[3] Write Files (after user confirmation)
    │
    └──[4] Build Verification
             └─► Compile S2Editor to verify code
```

---

## Phase 0: Detect Blueprint Inheritance Chain

Before converting, trace the full inheritance chain:

**Detection Logic:**
1. Use MCP `blueprint_read` or export JSON to get `parent_class`
2. If parent starts with `/Game/` → it's a Blueprint parent
3. Recursively trace until reaching a C++ class (no `/Game/` prefix)

**Example Chain:**
```
GA_Companion_StunStrike (Blueprint)
    └─► GA_CompanionAnimDrivenAttack (Blueprint parent)
        └─► USipherPhysicalAbility (C++ base)
```

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

---

## Phase 1: User Confirmation - Output Paths

**Before generating code, confirm output paths with user:**

**Default Path Mapping:**
| Blueprint Path | Header | Implementation |
|----------------|--------|----------------|
| `/Game/S2/Core/GAS/Companion/GA_X` | `Source/S2/Public/GameplayAbilities/GA_X.h` | `Source/S2/Private/GameplayAbilities/GA_X.cpp` |
| `/Game/S2/Core/GAS/Companion/GA_Parent` | `Source/S2/Public/GameplayAbilities/GA_Parent.h` | `Source/S2/Private/GameplayAbilities/GA_Parent.cpp` |

**Ask User (using AskUserQuestion tool):**

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

## Phase 2: Convert Blueprints (Parent-First Order)

For each Blueprint in the chain (starting from topmost parent):

### Step 2.1: JSON Export

Use Task tool with:
- `description`: "N2C JSON Export"
- `subagent_type`: "general-purpose"
- `prompt`: Prompt template below

```text
You are the N2C JSON Export agent. Follow ../n2c-json-export/SKILL.md

Input:
- blueprintPath: {BLUEPRINT_PATH}
- outputPath: G:/s2/Saved/NodeToCode/Export/{ASSET_NAME}.json

Execute via PowerShell:
powershell -Command "& 'G:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' 'G:/s2/S2.uproject' '-run=N2CExport' '-Blueprint={BLUEPRINT_PATH}' '-Output={OUTPUT_PATH}' '-Depth=2' '-Pretty' '-unattended' '-nosplash' '-nullrhi'"

Return: success, jsonPath, metadata (baseClass, referencedTypes, graphCount)
```

### Step 2.2: Context Gathering

Use Task tool with:
- `description`: "N2C Context Gatherer"
- `subagent_type`: "general-purpose"
- `prompt`: Prompt template below

```text
You are the N2C Context Gatherer agent. Follow ../n2c-context-gatherer/SKILL.md

Input:
- jsonPath: {JSON_PATH}
- metadata: {METADATA_FROM_STEP_1}
- previouslyGeneratedClasses: {LIST_OF_PARENT_CLASSES_ALREADY_CONVERTED}

Search directories:
- Source/S2/Public/**/*.h
- Plugins/Sipher*/Source/*/Public/**/*.h
- Plugins/Frameworks/*/Source/*/Public/**/*.h

Return: includeMap, baseClassContext (virtualMethods), apiPatterns, potentialConflicts
```

### Step 2.3: Code Generation

Use Task tool with:
- `description`: "N2C Code Generator"
- `subagent_type`: "general-purpose"
- `prompt`: Prompt template below

```text
You are the N2C Code Generator agent. Follow ../n2c-code-generator/SKILL.md

Input:
- jsonPath: {JSON_PATH}
- context: {CONTEXT_FROM_STEP_2}
- outputClassName: U{ASSET_NAME}
- baseClass: {PARENT_CPP_CLASS_OR_PREVIOUSLY_CONVERTED}
- moduleName: S2

CRITICAL: If parent was converted in this session, inherit from the converted C++ class.

Return: header, implementation, notes, buildDependencies
```

### Step 2.4: Validation

Use Task tool with:
- `description`: "N2C Validator"
- `subagent_type`: "general-purpose"
- `prompt`: Prompt template below

```text
You are the N2C Validator agent. Follow ../n2c-validator/SKILL.md

Input:
- header: {GENERATED_HEADER}
- implementation: {GENERATED_IMPLEMENTATION}
- context: {CONTEXT}
- outputPaths: {USER_CONFIRMED_PATHS}

Validation checks:
1. .generated.h is last include in header
2. Own header is first include in .cpp
3. Include paths exist
4. Method signatures match base class
5. Apply known pattern fixes
6. No variable shadowing

Return: valid, fixedHeader, fixedImplementation, appliedFixes, warnings
```

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

**After writing files, compile to verify:**

```bash
powershell -Command "& 'G:/UnrealEngine/Engine/Build/BatchFiles/Build.bat' S2Editor Win64 Development -Project='G:/s2/S2.uproject' -WaitMutex"
```

**Check build result:**
- **Success**: Report completion
- **Failure**: Show errors, offer to rollback `.bak` files

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
| 0 | Circular inheritance | Error - invalid BP structure |
| 1 | User cancels | Abort gracefully |
| 2.1 | EXPORT_TIMEOUT | Check if Editor is running |
| 2.3 | GENERATION_FAILED | Show partial, ask guidance |
| 2.4 | VALIDATION_FAILED (3x) | Proceed with warnings |
| 4 | BUILD_FAILED | Show errors, offer rollback |

---

## Rollback on Build Failure

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

## Inheritance Chain Conversion Order

When converting a chain like:
```
Child (BP) → Parent (BP) → Grandparent (BP) → CppBase (C++)
```

Convert in order:
1. Grandparent → inherits from CppBase
2. Parent → inherits from converted Grandparent
3. Child → inherits from converted Parent

This ensures each C++ class has its parent available during generation.

## Legacy Metadata

```yaml
invocable: true
```
