---
name: n2c-context-gatherer
description: Gather project context for C++ code generation including include paths, base class signatures, and API patterns. Sub-agent of n2c-orchestrator.
---

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
If not found, auto-detect using `ue-detect-engine` skill or prompt the user.

# N2C Context Gatherer Agent

Gathers verified include paths, base class signatures, and API patterns from the project.

## Input Contract

```json
{
  "jsonPath": "{project.root}/Saved/NodeToCode/Export/GA_Jump.json",
  "metadata": {
    "baseClass": "USipherGameplayAbilityRuntime",
    "referencedTypes": ["FSipherAbilityData_Animation", "PlayerCombatAttributeSet"]
  }
}
```

## Output Contract

**Success:**
```json
{
  "success": true,
  "includeMap": {
    "USipherGameplayAbilityRuntime": "GameplayAbilities/SipherGameplayAbilityRuntime.h",
    "FSipherAbilityData_Animation": "GameplayAbilities/AbilityData/SipherAbilityData_Animation.h",
    "PlayerCombatAttributeSet": "Core/ASC/AttributeSet/PlayerCombatAttributeSet.h"
  },
  "baseClassContext": {
    "className": "USipherGameplayAbilityRuntime",
    "headerPath": "GameplayAbilities/SipherGameplayAbilityRuntime.h",
    "fullHeaderPath": "{project.root}/Source/S2/Public/GameplayAbilities/SipherGameplayAbilityRuntime.h",
    "virtualMethods": [
      {
        "name": "K2_OverrideRuntimeData_Implementation",
        "signature": "virtual bool K2_OverrideRuntimeData_Implementation(TInstancedStruct<FSipherGenericAbilityData>& OverridenData)",
        "returnType": "bool",
        "isConst": false
      },
      {
        "name": "ActivateAbility",
        "signature": "virtual void ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData) override",
        "returnType": "void",
        "isConst": false
      }
    ],
    "memberVariables": ["AnimationData", "AbilityData"]
  },
  "apiPatterns": {
    "UAITask_MoveTo": "Use OnMoveTaskFinished.AddUObject (public), NOT OnMoveFinished.AddDynamic (protected)",
    "AbilityWaitDelay": "Use UAbilityTask_WaitDelay::WaitDelay, NOT UGameplayTask_WaitDelay",
    "TSoftObjectPtr": "Call .LoadSynchronous() when assigning to raw pointer",
    "AttributeGetter": "Use 2-param version returning float, NOT 3-param with out reference"
  },
  "namingConventions": {
    "actorPrefix": "ASipher",
    "componentPrefix": "USipher",
    "structPrefix": "FSipher",
    "enumPrefix": "ESipher"
  },
  "potentialConflicts": ["AnimationData", "AbilityData"]
}
```

**Failure:**
```json
{
  "success": false,
  "errorCode": "BASE_CLASS_NOT_FOUND",
  "errorMessage": "Could not find header for USipherGameplayAbilityRuntime",
  "searchedPaths": ["Source/S2/Public", "Plugins/..."]
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `BASE_CLASS_NOT_FOUND` | Cannot locate base class header |
| `TYPE_NOT_FOUND` | Referenced type not in project |
| `AMBIGUOUS_TYPE` | Multiple headers define same type |
| `PARSE_ERROR` | Cannot parse header file |

---

## Source Directories

Search these locations in order:

```
1. Source/S2/Public/**/*.h
2. Source/S2/Private/**/*.h
3. Plugins/Sipher*/Source/*/Public/**/*.h
4. Plugins/Sipher*/Source/*/Private/**/*.h
5. Plugins/Frameworks/*/Source/*/Public/**/*.h
6. Plugins/Frameworks/*/Source/*/Private/**/*.h
```

---

## Execution Steps

### Step 1: Build Type List

From metadata, collect all types to resolve:

```python
types_to_resolve = set()

# Add base class
types_to_resolve.add(metadata.baseClass)

# Add all referenced types
for type_name in metadata.referencedTypes:
    types_to_resolve.add(type_name)

# Clean type names (remove prefixes/suffixes)
# "SKEL_USipherGameplayAbility_C" -> "USipherGameplayAbility"
```

### Step 2: Resolve Include Paths (Parallel)

For each type, search for its header:

```bash
# Search pattern for class declaration
grep -r "class\s+\w*_API\s+{ClassName}\s*:" Source/S2/Public --include="*.h" -l
grep -r "class\s+{ClassName}\s*:" Source/S2/Public --include="*.h" -l

# Search pattern for struct declaration
grep -r "struct\s+\w*_API\s+{ClassName}" Source/S2/Public --include="*.h" -l
grep -r "struct\s+{ClassName}" Source/S2/Public --include="*.h" -l

# Also search plugins
grep -r "class.*{ClassName}" Plugins/Sipher*/Source/*/Public --include="*.h" -l
grep -r "class.*{ClassName}" Plugins/Frameworks/*/Source/*/Public --include="*.h" -l
```

Build include map:
```python
include_map = {}

for type_name in types_to_resolve:
    header_path = find_header(type_name)
    if header_path:
        # Convert absolute path to relative include path
        # {project.root}/Source/S2/Public/Core/ASC/SipherASC.h -> Core/ASC/SipherASC.h
        relative_path = make_relative(header_path, "Source/S2/Public/")
        include_map[type_name] = relative_path
    else:
        # Mark as not found
        include_map[type_name] = None
```

### Step 3: Extract Base Class Signatures

Read the base class header and extract virtual methods:

```bash
# Find base class header
BASE_HEADER=$(grep -r "class.*{BaseClassName}.*:" Source/S2/Public Plugins/Sipher*/Source/*/Public Plugins/Frameworks/*/Source/*/Public --include="*.h" -l | head -1)
```

Parse header for virtual methods:
```python
# Read header content
header_content = read_file(base_header_path)

# Extract virtual method declarations
# Pattern: virtual {return_type} {method_name}({params}) [const] [override] [= 0];
virtual_pattern = r'virtual\s+(\w+[\w\s\*\&<>,]*)\s+(\w+)\s*\(([^)]*)\)\s*(const)?\s*(override)?\s*(=\s*0)?'

virtual_methods = []
for match in re.finditer(virtual_pattern, header_content):
    return_type = match.group(1).strip()
    method_name = match.group(2)
    params = match.group(3)
    is_const = bool(match.group(4))

    virtual_methods.append({
        "name": method_name,
        "signature": match.group(0).rstrip(';'),
        "returnType": return_type,
        "isConst": is_const
    })
```

Extract member variables (to detect shadowing):
```python
# Pattern: UPROPERTY(...) {type} {name};
# or plain: {type} {name};
member_pattern = r'(?:UPROPERTY[^)]*\))?\s*(\w+[\w\s\*\&<>,]*)\s+(\w+)\s*[;=]'

member_variables = []
for match in re.finditer(member_pattern, header_content):
    var_name = match.group(2)
    if var_name not in ['GENERATED_BODY', 'public', 'private', 'protected']:
        member_variables.append(var_name)
```

### Step 4: Detect API Patterns

Check for known UE5.7 patterns in the codebase:

```bash
# Check UAITask_MoveTo delegate pattern
grep -r "OnMoveTaskFinished" Plugins/Frameworks/SipherAIScalableFramework --include="*.h" --include="*.cpp" | head -3
grep -r "OnMoveFinished" Plugins/Frameworks/SipherAIScalableFramework --include="*.h" --include="*.cpp" | head -3

# Check AbilityTask_WaitDelay usage
grep -r "UAbilityTask_WaitDelay" Source/S2 Plugins/Sipher* --include="*.cpp" | head -3

# Check TSoftObjectPtr loading pattern
grep -r "\.LoadSynchronous()" Source/S2 Plugins/Sipher* --include="*.cpp" | head -3

# Check attribute getter pattern
grep -r "GetCharacterAttributeValue" Source/S2/Public/BFL --include="*.h" -A2 | head -5
```

Build API patterns based on findings:
```python
api_patterns = {}

if found_OnMoveTaskFinished and not_found_OnMoveFinished_public:
    api_patterns["UAITask_MoveTo"] = "Use OnMoveTaskFinished.AddUObject (public), NOT OnMoveFinished.AddDynamic (protected)"

if found_UAbilityTask_WaitDelay:
    api_patterns["AbilityWaitDelay"] = "Use UAbilityTask_WaitDelay::WaitDelay, NOT UGameplayTask_WaitDelay"

# Always include these known patterns
api_patterns["TSoftObjectPtr"] = "Call .LoadSynchronous() when assigning to raw pointer"
api_patterns["K2Functions"] = "Use native functions (SetActorLocation), NOT K2_ wrappers (K2_SetActorLocation)"
```

### Step 5: Identify Potential Conflicts

Compare member variables with common local variable names:

```python
potential_conflicts = []

common_local_names = ["AnimationData", "AbilityData", "CombatData", "CharacterData", "TargetData"]

for member in member_variables:
    if member in common_local_names:
        potential_conflicts.append(member)
```

### Step 6: Return Context

```json
{
  "success": true,
  "includeMap": { ... },
  "baseClassContext": {
    "className": "USipherGameplayAbilityRuntime",
    "headerPath": "GameplayAbilities/SipherGameplayAbilityRuntime.h",
    "fullHeaderPath": "{project.root}/Source/S2/Public/GameplayAbilities/SipherGameplayAbilityRuntime.h",
    "virtualMethods": [ ... ],
    "memberVariables": ["AnimationData", "AbilityData"]
  },
  "apiPatterns": { ... },
  "namingConventions": {
    "actorPrefix": "ASipher",
    "componentPrefix": "USipher",
    "structPrefix": "FSipher",
    "enumPrefix": "ESipher"
  },
  "potentialConflicts": ["AnimationData"]
}
```

---

## Handling Missing Types

If a type cannot be found in project source:

1. **Check Engine source** (if available)
2. **Mark as external** in include map with module hint
3. **Add to warnings** for orchestrator

```json
{
  "includeMap": {
    "UGameplayAbility": {
      "external": true,
      "module": "GameplayAbilities",
      "include": "Abilities/GameplayAbility.h"
    }
  }
}
```
