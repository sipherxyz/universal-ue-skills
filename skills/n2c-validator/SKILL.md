---
name: n2c-validator
description: Validate generated C++ code and auto-fix common issues. Sub-agent of n2c-orchestrator.
---

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
If not found, auto-detect using `ue-detect-engine` skill or prompt the user.

# N2C Validator Agent

Validates generated C++ code against project context and auto-fixes known issues.

## Input Contract

```json
{
  "header": "// Generated .h content",
  "implementation": "// Generated .cpp content",
  "context": {
    "includeMap": { ... },
    "baseClassContext": { ... },
    "apiPatterns": { ... },
    "potentialConflicts": [ ... ]
  },
  "outputPaths": {
    "header": "Source/S2/Public/Core/GAS/GA_Jump.h",
    "implementation": "Source/S2/Private/Core/GAS/GA_Jump.cpp"
  }
}
```

## Output Contract

**Success (valid):**
```json
{
  "valid": true,
  "header": "// Validated .h content",
  "implementation": "// Validated .cpp content",
  "appliedFixes": [],
  "warnings": [],
  "requiresManualReview": false
}
```

**Success (fixed):**
```json
{
  "valid": true,
  "header": "// Fixed .h content",
  "implementation": "// Fixed .cpp content",
  "appliedFixes": [
    {"line": 15, "issue": "Wrong include path", "fix": "Changed to correct path"},
    {"line": 42, "issue": "OnMoveFinished is protected", "fix": "Changed to OnMoveTaskFinished"}
  ],
  "warnings": [
    {"line": 78, "issue": "Unknown function", "suggestion": "Verify this function exists"}
  ],
  "requiresManualReview": false
}
```

**Failure (unfixable):**
```json
{
  "valid": false,
  "header": "// Partially fixed .h content",
  "implementation": "// Partially fixed .cpp content",
  "appliedFixes": [ ... ],
  "unresolvedIssues": [
    {"line": 95, "issue": "Cannot determine correct signature", "context": "..."}
  ],
  "requiresManualReview": true
}
```

---

## Validation Checks (in order)

### Check 1: File Structure

**Header Structure:**
```
1. Copyright/pragma once
2. CoreMinimal.h
3. Base class include
4. Other includes
5. .generated.h (MUST BE LAST)
6. Forward declarations
7. Class definition
```

**Implementation Structure:**
```
1. Own header (MUST BE FIRST)
2. Other includes
3. Implementations (no code before includes)
```

**Detection:**
```bash
# Check .generated.h is last include in header
grep -n "#include" {header} | tail -1 | grep ".generated.h"

# Check own header is first include in cpp
grep -n "#include" {implementation} | head -1 | grep "{ClassName}.h"

# Check no code before includes in cpp
first_include_line=$(grep -n "#include" {implementation} | head -1 | cut -d: -f1)
first_code_line=$(grep -n "^\w" {implementation} | grep -v "^//" | head -1 | cut -d: -f1)
if [ $first_code_line -lt $first_include_line ]; then
  # ERROR: Code before includes
fi
```

**Fix:**
- Reorder includes to match expected structure
- Move code after includes

---

### Check 2: Include Paths Exist

For each `#include "..."` in header and implementation:

```bash
# Extract include path
INCLUDE_PATH=$(echo "$line" | grep -oP '#include\s+"\K[^"]+')

# Check if file exists
FOUND=false
for BASE in "Source/S2/Public" "Plugins/Sipher*/Source/*/Public" "Plugins/Frameworks/*/Source/*/Public"; do
  if [ -f "$BASE/$INCLUDE_PATH" ]; then
    FOUND=true
    break
  fi
done

if [ "$FOUND" = false ]; then
  # ERROR: Include not found
fi
```

**Fix:**
1. Extract class name from include path
2. Search for correct path using `grep`
3. Replace with correct path from includeMap

---

### Check 3: Method Signatures Match Base Class

For each `virtual` method in header:

```python
# Extract method name and signature
method_match = re.search(r'virtual\s+(\w+)\s+(\w+)\s*\(([^)]*)\)', line)
method_name = method_match.group(2)
generated_signature = method_match.group(0)

# Find in base class context
for base_method in base_class_context.virtualMethods:
    if base_method.name == method_name:
        expected_signature = base_method.signature

        if generated_signature != expected_signature:
            # ERROR: Signature mismatch
            # Fix: Replace with expected signature
```

**Fix:**
- Replace entire method signature with base class version

---

### Check 4: Known Bad Patterns

| Pattern | Detection Regex | Fix |
|---------|----------------|-----|
| `OnMoveFinished.AddDynamic` | `OnMoveFinished\s*\.\s*AddDynamic` | → `OnMoveTaskFinished.AddUObject` |
| `UGameplayTask_WaitDelay` | `UGameplayTask_WaitDelay` | → `UAbilityTask_WaitDelay` |
| `K2_SetActorLocation` | `K2_SetActorLocation` | → `SetActorLocation` |
| `K2_GetActorLocation` | `K2_GetActorLocation` | → `GetActorLocation` |
| `K2_DestroyActor` | `K2_DestroyActor` | → `Destroy` |
| TSoftObjectPtr without Load | `TSoftObjectPtr<\w+>\([^)]+\)[^.]*;` | Add `.LoadSynchronous()` |

**Detection and Fix:**
```python
patterns = [
    {
        "pattern": r"OnMoveFinished\s*\.\s*AddDynamic",
        "replacement": "OnMoveTaskFinished.AddUObject",
        "issue": "OnMoveFinished is protected in UE5.7"
    },
    {
        "pattern": r"UGameplayTask_WaitDelay",
        "replacement": "UAbilityTask_WaitDelay",
        "issue": "Wrong WaitDelay class for abilities"
    },
    {
        "pattern": r"K2_(\w+)",
        "replacement": lambda m: m.group(1),  # Remove K2_ prefix
        "issue": "K2_ functions are Blueprint wrappers"
    }
]

for p in patterns:
    if re.search(p["pattern"], code):
        code = re.sub(p["pattern"], p["replacement"], code)
        applied_fixes.append({"issue": p["issue"], "fix": "Applied pattern replacement"})
```

---

### Check 5: Variable Shadowing

Check if any local variables shadow base class members:

```python
# Extract local variable declarations from implementation
local_vars = re.findall(r'(\w+)\s+(\w+)\s*[;=]', implementation)

for var_type, var_name in local_vars:
    if var_name in context.potentialConflicts:
        # ERROR: Variable shadows base class member
        # Fix: Rename to Local{VarName} or {VarName}Local
```

**Fix:**
```python
# Rename pattern: AnimationData -> LocalAnimData
new_name = f"Local{var_name}"
implementation = implementation.replace(var_name, new_name)
```

---

### Check 6: Compile Verification (Optional)

If orchestrator requests compile verification:

```bash
# Single-module build
"{EnginePath}/Engine/Build/BatchFiles/Build.bat" S2Editor Win64 Development \
  -Project="{project.root}/{project.uproject}" \
  -Module=S2 \
  -WaitMutex \
  2>&1 | tee build_output.txt

# Check for errors
if grep -q "error C" build_output.txt; then
  # Extract error details
  ERRORS=$(grep "error C" build_output.txt)
  # Return compile errors for manual review
fi
```

---

## Fix Loop

```python
MAX_ATTEMPTS = 3

for attempt in range(MAX_ATTEMPTS):
    issues = run_all_checks(header, implementation, context)

    if not issues:
        return {
            "valid": True,
            "header": header,
            "implementation": implementation,
            "appliedFixes": all_fixes,
            "requiresManualReview": False
        }

    fixable = [i for i in issues if i.fixable]
    unfixable = [i for i in issues if not i.fixable]

    if not fixable:
        # No more auto-fixes possible
        break

    # Apply fixes
    for issue in fixable:
        header, implementation = apply_fix(header, implementation, issue)
        all_fixes.append(issue.to_dict())

# After max attempts
return {
    "valid": len(unfixable) == 0,
    "header": header,
    "implementation": implementation,
    "appliedFixes": all_fixes,
    "unresolvedIssues": [i.to_dict() for i in unfixable],
    "requiresManualReview": len(unfixable) > 0
}
```

---

## Writing Files

After validation passes (or with warnings):

```python
def write_files(header, implementation, output_paths):
    header_path = output_paths["header"]
    impl_path = output_paths["implementation"]

    # Ensure directories exist
    os.makedirs(os.path.dirname(header_path), exist_ok=True)
    os.makedirs(os.path.dirname(impl_path), exist_ok=True)

    # Backup existing files
    if os.path.exists(header_path):
        shutil.copy(header_path, f"{header_path}.bak")
    if os.path.exists(impl_path):
        shutil.copy(impl_path, f"{impl_path}.bak")

    # Write new files
    with open(header_path, 'w') as f:
        f.write(header)

    with open(impl_path, 'w') as f:
        f.write(implementation)

    return {
        "headerPath": header_path,
        "implementationPath": impl_path,
        "backedUp": True
    }
```

---

## Rollback on Failure

If write fails or subsequent build fails:

```python
def rollback(output_paths):
    header_path = output_paths["header"]
    impl_path = output_paths["implementation"]

    # Restore from backup
    if os.path.exists(f"{header_path}.bak"):
        shutil.move(f"{header_path}.bak", header_path)
    else:
        os.remove(header_path)  # New file, just delete

    if os.path.exists(f"{impl_path}.bak"):
        shutil.move(f"{impl_path}.bak", impl_path)
    else:
        os.remove(impl_path)

    return {"rolledBack": True}
```
