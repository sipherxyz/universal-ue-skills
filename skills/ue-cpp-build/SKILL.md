---
name: ue-cpp-build
description: Compile UE5 C++ code with error analysis, hot-reload support, Live Coding vs Full Build detection, and build diagnostics. Use when compiling C++ code, fixing build errors, or iterating on code changes. Triggers on "build project", "compile", "build C++", "rebuild", "full build", "live coding".
---

# Unreal Engine C++ Build & Compile Skill

**Role:** C++ Build Engineer
**Scope:** Project-wide compilation and build operations
**Engine Version:** Auto-detected from *.uproject
**Platform:** Windows (Win64)

## Configuration

This skill reads project paths from `skills.config.json` at the repository root.
- `project.root` / `project.uproject` — project location
- `engine.path` — custom engine installation
If not found, auto-detect using `ue-detect-engine` skill and CWD.

## Objective

Compile Unreal Engine C++ code, analyze build errors, support hot-reload workflows, and provide actionable diagnostics for fixing compilation issues.

## Prerequisites

Before using this skill, ensure:
1. Engine path is cached (use `open-editor` skill first, or this skill will auto-detect)
2. Visual Studio 2022 or Rider is installed
3. Project has been set up with GenerateProjectFiles

## Dynamic Path Resolution

```
{CWD} = Current Working Directory
{ProjectFile} = First *.uproject file in {CWD}
{ProjectName} = Name from {ProjectFile} (e.g., "S2")
{CacheFile} = {CWD}/Saved/claude-data.txt
{EnginePath} = From cache or registry lookup
{UBT} = {EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe
{UAT} = {EnginePath}/Engine/Build/BatchFiles/RunUAT.bat
```

## Build Configurations

| Configuration | Use Case | Command Flag |
|---------------|----------|--------------|
| Development Editor | Daily development, hot-reload | `-Development -Editor` |
| DebugGame Editor | Debugging with symbols | `-DebugGame -Editor` |
| Development | Packaged game testing | `-Development` |
| Shipping | Final release build | `-Shipping` |

## Core Operations

### 0. Smart Build Selection (Auto-Detect)

**Before running any build, detect if editor is running:**

```bash
# Check if UnrealEditor.exe is running with this project
tasklist /FI "IMAGENAME eq UnrealEditor.exe" /NH
wmic process where "name='UnrealEditor.exe'" get commandline | findstr "{ProjectName}"
```

**Decision tree:**

```
┌─────────────────────────────────────────┐
│ Is UnrealEditor.exe running?            │
│     ↓ YES              ↓ NO            │
│ ┌─────────────┐   ┌──────────────────┐ │
│ │ Live Coding │   │ Ask Configuration│ │
│ │ (5-15 sec)  │   │ Development or   │ │
│ │             │   │ DebugGame?       │ │
│ └─────────────┘   └──────────────────┘ │
│                         ↓              │
│                   ┌──────────────────┐ │
│                   │ Full Build (UBT) │ │
│                   │ (60-300 sec)     │ │
│                   └──────────────────┘ │
└─────────────────────────────────────────┘
```

- Editor running + project match → Use Live Coding (fast, 5-15 seconds)
- Editor not running → Use Build.bat or UBT (full rebuild)
- Editor running but different project → Use Build.bat or UBT

### 1. Live Coding (Editor Running) - Preferred

**When:** Editor is currently open with this project
**Advantage:** Fast hot-reload (5-15 seconds) without restarting editor

```bash
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{CWD}/{ProjectFile}" -run=LiveCoding -compile
```

**Limitations:**
- Cannot change UPROPERTY/UFUNCTION signatures
- Cannot add/remove class members
- Best for implementation-only changes

### 2. Full Build - Rider Method (Editor Closed)

**When:** Editor is not running or header changes made
**Advantage:** Full rebuild, all changes supported

**IMPORTANT: Ask user for build configuration before running:**
Use AskUserQuestion tool to prompt:
- **Development** (Recommended) - Optimized code with debug symbols, faster iteration
- **DebugGame** - Full debug symbols for breakpoints, slower but best for debugging

```bash
# Build.bat method - use user's selected configuration
"{EnginePath}/Engine/Build/BatchFiles/Build.bat" {ProjectName}Editor Win64 {Configuration} -Project="{CWD}/{ProjectFile}" -WaitMutex -FromMSBuild
```

**Configuration options:**
- `Development` - Standard for daily development, good balance of speed and debuggability
- `DebugGame` - Use when setting breakpoints or inspecting variables in debugger

### 3. Full Build - UBT Method (Alternative)

```bash
# Using UnrealBuildTool directly
"{EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" {ProjectName}Editor Win64 Development -Project="{CWD}/{ProjectFile}" -WaitMutex -FromMsBuild
```

**Expected Output:**
- Success: `Total build time: XX.XX seconds`
- Failure: Compiler errors with file:line references

### 4. Compile Single Module (Fast Iteration)

For quick iteration on a single plugin or module:

```bash
# Compile specific module only
"{UBT}" {ProjectName}Editor Win64 Development -Project="{CWD}/{ProjectFile}" -Module={ModuleName} -WaitMutex
```

**Common Modules:**
- `S2` - Main game module
- `SipherComboGraph` - Combo system
- `SipherParryV2` - Parry mechanics
- `SipherAIScalableFramework` - AI system

### 5. Full Rebuild (Clean Build)

When incremental build fails or after major changes:

```bash
# Clean intermediates first
rmdir /s /q "{CWD}/Intermediate"
rmdir /s /q "{CWD}/Binaries"

# Full rebuild
"{UBT}" {ProjectName}Editor Win64 Development -Project="{CWD}/{ProjectFile}" -WaitMutex -FromMsBuild
```

### 6. Generate Project Files

After adding new source files or changing Build.cs:

```bash
# Generate Visual Studio / Rider project files
"{UBT}" -projectfiles -project="{CWD}/{ProjectFile}" -game -engine -progress
```

Or use the batch file:
```bash
"{EnginePath}/GenerateProjectFiles.bat" "{CWD}/{ProjectFile}"
```

## Error Analysis

### Parsing Compiler Output

When compilation fails, extract and analyze errors:

**Error Pattern:**
```
{FilePath}({Line},{Column}): error {Code}: {Message}
```

**Example:**
```
E:\S2_\Source\S2\Private\Combat\SipherCombatAbility.cpp(123,45): error C2065: 'UndeclaredVariable': undeclared identifier
```

### Common Error Categories

| Error Code | Category | Common Fix |
|------------|----------|------------|
| C2065 | Undeclared identifier | Add #include or forward declaration |
| C2061 | Syntax error | Check for missing semicolons, brackets |
| C2143 | Syntax error | Missing header, wrong namespace |
| C2039 | Not a member | Check class hierarchy, include base class |
| C2440 | Cannot convert type | Add cast or fix type mismatch |
| C2664 | Cannot convert argument | Type mismatch, check function signatures |
| C4430 | Missing type specifier | Add return type to function |
| C4996 | Deprecated | Update to new API (check engine source) |
| LNK2001 | Unresolved external | Missing module dependency in Build.cs |
| LNK2019 | Unresolved external | Missing implementation, wrong export macro |

### UE5-Specific Errors

| Pattern | Issue | Solution |
|---------|-------|----------|
| `GENERATED_BODY()` error | Missing or wrong macro | Ensure class derives from UObject/AActor |
| `static assert` in template | Wrong TInstancedStruct usage | Check template parameters |
| `Cannot find UClass` | Missing module dependency | Add to PublicDependencyModuleNames |
| `Circular dependency` | Headers include each other | Use forward declarations |

## Workflow

### Standard Compile Workflow

```markdown
1. **Detect Project & Engine**
   - Find {ProjectFile} in {CWD}
   - Read engine path from cache or registry

2. **Check Editor Status**
   - Query running processes for UnrealEditor.exe
   - Verify it's running this project (check command line args)

3. **Choose Build Method**
   - If editor running with project: Use Live Coding (fast, 5-15s)
   - If editor closed: Ask user for configuration (Development recommended, DebugGame for debugging), then use Build.bat
   - If editor running different project: Ask user for configuration, then use Build.bat

4. **Run Compilation**
   - Execute appropriate build command
   - Capture stdout and stderr

5. **Analyze Output**
   - Parse for errors/warnings
   - Extract file:line references
   - Categorize by error type

6. **Report Results**
   - Success: Report build time and method used
   - Failure: List errors with suggested fixes
   - Warnings: List with severity assessment
```

### Error Resolution Workflow

```markdown
1. **Parse Error**
   - Extract file path, line number, error code
   - Read surrounding code context

2. **Diagnose Cause**
   - Check for missing includes
   - Verify class/function signatures
   - Check Build.cs dependencies

3. **Suggest Fix**
   - Provide specific code changes
   - Offer to apply fix automatically
   - Explain why the error occurred

4. **Verify Fix**
   - Re-run compilation after fix
   - Confirm error is resolved
```

## Build Commands Reference

### Quick Compile (Editor)
```bash
"{UBT}" {ProjectName}Editor Win64 Development -Project="{CWD}/{ProjectFile}" -WaitMutex -FromMsBuild
```

### Debug Build
```bash
"{UBT}" {ProjectName}Editor Win64 DebugGame -Project="{CWD}/{ProjectFile}" -WaitMutex
```

### Shipping Build (for testing)
```bash
"{UBT}" {ProjectName} Win64 Shipping -Project="{CWD}/{ProjectFile}" -WaitMutex
```

### Cook Content (for packaging)
```bash
"{UAT}" BuildCookRun -project="{CWD}/{ProjectFile}" -noP4 -platform=Win64 -clientconfig=Development -cook -allmaps -build -stage -pak -archive -archivedirectory="{CWD}/Packaged"
```

### Compile with Verbose Output
```bash
"{UBT}" {ProjectName}Editor Win64 Development -Project="{CWD}/{ProjectFile}" -WaitMutex -Verbose
```

### Parallel Compilation
```bash
"{UBT}" {ProjectName}Editor Win64 Development -Project="{CWD}/{ProjectFile}" -WaitMutex -MaxParallelActions=16
```

## Integration with Editor

### Before Opening Editor
```markdown
1. Run compile to ensure code is buildable
2. Check for unresolved errors
3. Launch editor only if compile succeeds
```

### During Development
```markdown
1. Make code changes in IDE
2. Use Hot-Reload (Ctrl+Alt+F11) for quick iterations
3. Full compile when Hot-Reload fails
4. Restart editor for header changes
```

### After Adding New Files
```markdown
1. Add .cpp/.h files to Source folder
2. Run GenerateProjectFiles
3. Refresh IDE project
4. Compile
```

## User Interaction

### Default Behavior
When user says "compile" or "build":
1. Auto-detect project and engine
2. Check if editor is running (use Live Coding if yes)
3. If full build needed: Ask user for configuration (Development recommended, DebugGame for debugging)
4. Run selected build configuration
5. Report success or analyze errors

### With Options
- "compile" → Prompts for Development or DebugGame
- "compile dev" or "compile development" → Development configuration (skip prompt)
- "compile debug" → DebugGame configuration (skip prompt)
- "compile shipping" → Shipping configuration
- "compile module X" → Single module compilation
- "rebuild" → Clean + full rebuild
- "generate project files" → Regenerate VS/Rider files

### Error Fixing
When errors occur:
1. List all errors with context
2. Offer to fix automatically if possible
3. Explain the root cause
4. Suggest manual fixes if auto-fix unavailable

## Error Handling

### Engine Not Found
```markdown
Error: Could not find Unreal Engine path
Solution:
1. Run 'open-editor' skill first to cache engine path
2. Or manually set engine path in Saved/claude-data.txt
3. Or verify engine is registered in Epic Games Launcher
```

### Build Tool Not Found
```markdown
Error: UnrealBuildTool.exe not found at expected path
Solution:
1. Verify engine installation is complete
2. Check path: {EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/
3. Engine may need to be rebuilt from source
```

### Compilation Timeout
```markdown
Warning: Compilation taking longer than expected (>5 minutes)
Suggestions:
1. Check for infinite template recursion
2. Reduce parallel actions if low memory
3. Consider module-specific compilation
4. Check for network drives (slow I/O)
```

## Performance Tips

### Faster Iteration
1. Use `-Module={ModuleName}` for single-module compilation
2. Enable Incredibuild if available: `-UseIncredibuild`
3. Use SSD for Intermediate folder
4. Increase parallel actions: `-MaxParallelActions=16`

### Reducing Build Times
1. Minimize header includes (use forward declarations)
2. Use precompiled headers (PCH)
3. Split large modules into smaller ones
4. Use unity builds: `-DisableUnity=false`

## Success Criteria

- ✅ Project compiles successfully
- ✅ No errors in output
- ✅ Build time reported
- ✅ Warnings listed (if any)
- ✅ Ready for editor launch or hot-reload

## Example Sessions

### Successful Compile (Editor Running - Live Coding)
```
User: compile
Assistant:
1. Detecting project... Found: S2.uproject
2. Engine path: {engine.path}
3. Editor detected running (PID: 12345)
4. Using Live Coding for fast hot-reload...
5. Hot-reload succeeded in 8.3 seconds
6. Changes active in editor immediately
```

### Successful Compile (Editor Closed - Full Build)
```
User: compile
Assistant:
1. Detecting project... Found: S2.uproject
2. Engine path: {engine.path}
3. Editor not running, using full build...
4. [Asks user: Development (recommended) or DebugGame?]
5. User selects: Development
6. Running Development Editor build...
7. ████████████████████ 100%
8. Build succeeded in 45.3 seconds
9. 0 errors, 2 warnings (non-critical)
```

### Failed Compile with Fix
```
User: compile
Assistant:
1. Detecting project... Found: S2.uproject
2. Running Development Editor build...
3. ❌ Build failed with 1 error:

Error: Source/S2/Private/Combat/SipherCombatAbility.cpp(123,15)
  error C2065: 'DamageAmount': undeclared identifier

Context (lines 121-125):
  121: void USipherCombatAbility::ApplyDamage()
  122: {
  123:     float Value = DamageAmount;  // <-- Error here
  124:     // ...
  125: }

Diagnosis: 'DamageAmount' is not declared in this scope.

Suggested Fix:
- If this is a class member, add to header: `float DamageAmount;`
- If this is a local variable, declare it before use
- If this comes from a base class, verify inheritance

Would you like me to:
1. Read the header file to check for missing member?
2. Search codebase for 'DamageAmount' definition?
3. Apply a specific fix?
```

## Build Error Parsing

### Error Parsing Pattern

```powershell
# Parse build output for errors
$Output = & $BuildCommand 2>&1

$Errors = $Output | Where-Object { $_ -match "error C\d+:" -or $_ -match "error LNK\d+:" }

foreach ($Error in $Errors) {
    if ($Error -match "(.+)\((\d+)\):\s*error\s+(C\d+|LNK\d+):\s*(.+)") {
        $File = $Matches[1]
        $Line = $Matches[2]
        $Code = $Matches[3]
        $Message = $Matches[4]

        Write-Host "Error in $File at line $Line"
        Write-Host "  $Code: $Message"
    }
}
```

## Build Output Locations

| Output | Location |
|--------|----------|
| Binaries | `{ProjectPath}/Binaries/Win64/` |
| Intermediate | `{ProjectPath}/Intermediate/Build/Win64/` |
| Build Logs | `{ProjectPath}/Saved/Logs/` |
| Compilation DB | `{ProjectPath}/.vscode/compile_commands.json` |

## Build Report Template

```markdown
# Build Report

## Summary
- **Build Method**: {Live Coding / Full Build}
- **Configuration**: {Development / DebugGame}
- **Duration**: {Time}
- **Result**: {Success / Failed}

## Errors Found
| File | Line | Code | Message |
|------|------|------|---------|
| {File} | {Line} | {Code} | {Message} |

## Suggested Fixes
1. {Fix suggestion based on error analysis}

## Warnings
- {Warning count} warnings found
- Critical warnings: {List}

## Next Steps
- [ ] Fix errors listed above
- [ ] Re-run build to verify fixes
- [ ] Test changes in editor
```

## Troubleshooting

### Build Fails with "Mutex" Error
```bash
# Another build is running, wait or:
taskkill /IM UnrealBuildTool.exe /F
```

### Live Coding Fails
- Check editor is focused on correct project
- Verify no .h files were modified
- Fall back to full build

### Out of Memory
```bash
# Reduce parallel compilation
-MaxParallelActions=4
```

### Cached Build Issues
```bash
# Clean intermediate files
rmdir /s /q Intermediate\Build
rmdir /s /q Binaries\Win64\*.pdb
```

## Notes

- **Smart build detection:** Automatically chooses fastest method (Live Coding vs Full Build)
- **Live Coding preferred:** When editor is running and changes are compatible
- **Fallback to full build:** If Live Coding fails or editor closed
- **Configuration prompt:** Always ask user for Development (recommended) or DebugGame before full builds
- This skill does NOT auto-run builds after fixes (per CLAUDE.md guidelines)
- User must explicitly request compilation
- Engine paths are never hardcoded
- All paths resolved dynamically from CWD

## Legacy Metadata

```yaml
skill: ue-cpp-build
invoke: /dev-workflow:ue-cpp-build
type: development
category: cpp-development
scope: project-root
```
