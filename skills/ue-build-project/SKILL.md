---
name: ue-build-project
description: Build UE5 C++ project with smart detection of Live Coding vs Full Build, configuration selection, and error analysis. Use when compiling C++ code, fixing build errors, or iterating on code changes. Triggers on "build project", "compile", "build C++", "rebuild", "full build", "live coding".
---

# UE Build Project

Smart C++ project compilation with automatic build method detection and error analysis.

## Quick Start

1. Detect if editor is running (Live Coding vs Full Build)
2. Ask for configuration if full build (Development vs DebugGame)
3. Execute appropriate build command
4. Analyze output for errors and suggestions

## Build Method Detection

```
┌─────────────────────────────────────────┐
│ Is UnrealEditor.exe running?            │
│     ↓ YES              ↓ NO             │
│ ┌─────────────┐   ┌──────────────────┐  │
│ │ Live Coding │   │ Ask Configuration│  │
│ │ (5-15 sec)  │   │ Development or   │  │
│ │             │   │ DebugGame?       │  │
│ └─────────────┘   └──────────────────┘  │
│                         ↓               │
│                   ┌──────────────────┐  │
│                   │ Full Build (UBT) │  │
│                   │ (60-300 sec)     │  │
│                   └──────────────────┘  │
└─────────────────────────────────────────┘
```

## Build Configurations

| Configuration | Use Case | Debug Symbols | Optimization |
|---------------|----------|---------------|--------------|
| **Development** | Daily iteration | Partial | Optimized |
| **DebugGame** | Breakpoint debugging | Full | None |

**Recommendation**: Use Development unless actively debugging with breakpoints.

## Build Commands

### Live Coding (Editor Running)

```bash
# Trigger via command line
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{ProjectPath}/{ProjectFile}" -run=LiveCoding -compile

# Or via keyboard shortcut in editor
# Ctrl+Alt+F11
```

**When to use:**
- Editor is open with the project
- Making .cpp file changes only
- Quick iteration (5-15 seconds)

**Limitations:**
- Cannot change .h files (headers require full rebuild)
- Cannot add new classes
- Cannot change UPROPERTY/UFUNCTION signatures

### Full Build (Editor Closed)

```bash
# Development (Recommended for iteration)
"{EnginePath}/Engine/Build/BatchFiles/Build.bat" {ProjectName}Editor Win64 Development -Project="{ProjectPath}/{ProjectFile}" -WaitMutex -FromMSBuild

# DebugGame (For breakpoint debugging)
"{EnginePath}/Engine/Build/BatchFiles/Build.bat" {ProjectName}Editor Win64 DebugGame -Project="{ProjectPath}/{ProjectFile}" -WaitMutex -FromMSBuild
```

### Single Module Build (Fast Iteration)

```bash
# Build only specific module
"{EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" {ProjectName}Editor Win64 Development -Project="{ProjectPath}/{ProjectFile}" -Module={ModuleName} -WaitMutex
```

**Common Modules:**
- `S2` - Main game module
- `SipherComboGraph` - Combo system
- `SipherParryV2` - Parry system
- `SipherAIScalableFramework` - AI framework
- `SipherHitbox` - Hit detection

### Project File Generation

```bash
# Regenerate Visual Studio solution
"{EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" -projectfiles -project="{ProjectPath}/{ProjectFile}" -game -engine -progress
```

## Build Workflow

### Step 1: Detect Engine Path

```powershell
# Use ue-detect-engine skill or:
$CacheFile = Join-Path $PWD "Saved/claude-data.txt"
if (Test-Path $CacheFile) {
    $Content = Get-Content $CacheFile -Raw
    if ($Content -match 'EnginePath=(.+)') {
        $EnginePath = $Matches[1].Trim()
    }
}
```

### Step 2: Check Editor Status

```powershell
# Check if editor is running with this project
$EditorProcess = Get-Process -Name "UnrealEditor" -ErrorAction SilentlyContinue
$ProjectName = (Get-ChildItem "*.uproject").BaseName

if ($EditorProcess) {
    # Check command line for project
    $CommandLine = (Get-WmiObject Win32_Process -Filter "ProcessId=$($EditorProcess.Id)").CommandLine
    if ($CommandLine -match $ProjectName) {
        $UseLiveCoding = $true
    }
}
```

### Step 3: Execute Build

```powershell
if ($UseLiveCoding) {
    # Live Coding
    $EditorCmd = Join-Path $EnginePath "Engine/Binaries/Win64/UnrealEditor-Cmd.exe"
    $ProjectFile = (Get-ChildItem "*.uproject").FullName
    & $EditorCmd $ProjectFile -run=LiveCoding -compile
} else {
    # Full Build - Ask for configuration first
    Write-Host "Select build configuration:"
    Write-Host "1. Development (Recommended)"
    Write-Host "2. DebugGame (Full debug symbols)"
    $Choice = Read-Host "Choice"

    $Config = if ($Choice -eq "2") { "DebugGame" } else { "Development" }

    $BuildBat = Join-Path $EnginePath "Engine/Build/BatchFiles/Build.bat"
    & $BuildBat "${ProjectName}Editor" Win64 $Config -Project="$ProjectFile" -WaitMutex -FromMSBuild
}
```

## Error Analysis

### Common Compiler Errors

| Error Code | Meaning | Common Fix |
|------------|---------|------------|
| C2065 | Undeclared identifier | Add #include or forward declaration |
| C2061 | Syntax error | Check for missing semicolons, braces |
| C2143 | Syntax error: missing ';' | Add semicolon before error location |
| C2039 | Not a member | Check class hierarchy, include files |
| C2440 | Cannot convert type | Add cast or fix type mismatch |
| C4430 | Missing type specifier | Add return type to function |
| LNK2001 | Unresolved external | Add module dependency in .Build.cs |
| LNK2019 | Unresolved external symbol | Implement missing function |

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

## Report Template

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

## Best Practices

1. **Always close editor for header changes** - Live Coding cannot handle .h modifications
2. **Use Development for iteration** - DebugGame is slower and only needed for breakpoints
3. **Single module builds** - Use -Module flag when only one plugin changed
4. **Check Saved/Logs** - Build logs contain full compiler output

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
