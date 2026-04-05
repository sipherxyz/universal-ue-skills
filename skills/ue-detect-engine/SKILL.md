---
name: ue-detect-engine
description: Detect custom Unreal Engine installation path from registry, cache, or .uproject file. Use when needing engine path for builds, editor launch, or tool execution. Triggers on "engine path", "detect engine", "find engine", "engine location", "custom engine", "engine association".
---

# UE Detect Engine

Detect custom Unreal Engine installation path using multiple fallback strategies.

## Quick Start

1. Check cache file first (fastest)
2. Fall back to Windows Registry lookup
3. Validate engine exists
4. Cache result for future use

## Detection Strategy

```
┌─────────────────────────────────────────┐
│ 1. Check Saved/claude-data.txt cache    │
│    ↓ (if missing/invalid)               │
│ 2. Read .uproject EngineAssociation     │
│    ↓ (get GUID or version string)       │
│ 3. Query Windows Registry               │
│    HKCU\SOFTWARE\Epic Games\UE\Builds   │
│    ↓ (match GUID to path)               │
│ 4. Validate engine installation         │
│    ↓ (check UnrealBuildTool exists)     │
│ 5. Save to cache for next time          │
└─────────────────────────────────────────┘
```

## Implementation

### Step 1: Check Cache File

```powershell
# Cache location
$CacheFile = Join-Path $ProjectRoot "Saved/claude-data.txt"

if (Test-Path $CacheFile) {
    $CacheContent = Get-Content $CacheFile -Raw
    if ($CacheContent -match 'EnginePath=(.+)') {
        $CachedPath = $Matches[1].Trim()

        # Validate cached path still exists
        $UBT = Join-Path $CachedPath "Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe"
        if (Test-Path $UBT) {
            return $CachedPath
        }
    }
}
```

### Step 2: Read .uproject File

```powershell
# Find .uproject in current directory
$UProjectFile = Get-ChildItem -Path $ProjectRoot -Filter "*.uproject" | Select-Object -First 1

if ($UProjectFile) {
    $UProject = Get-Content $UProjectFile.FullName | ConvertFrom-Json
    $EngineAssociation = $UProject.EngineAssociation

    # EngineAssociation can be:
    # - GUID: "{71C58201-4B67-1872-E953-7BB83BB142F3}"
    # - Version: "5.7.1-huli"
    # - Empty: Uses launcher default
}
```

### Step 3: Query Windows Registry

```powershell
# Registry path for custom engine builds
$RegistryPath = "HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds"

if (Test-Path $RegistryPath) {
    $Builds = Get-ItemProperty $RegistryPath

    # Get all properties (each is a GUID -> Path mapping)
    $Builds.PSObject.Properties | Where-Object {
        $_.Name -notlike "PS*"  # Skip PowerShell metadata
    } | ForEach-Object {
        $GUID = $_.Name
        $Path = $_.Value

        # Match GUID with or without braces
        $CleanGUID = $GUID -replace '[{}]', ''
        $CleanAssociation = $EngineAssociation -replace '[{}]', ''

        if ($CleanGUID -eq $CleanAssociation) {
            return $Path
        }
    }
}
```

### Step 4: Validate Engine Installation

```powershell
function Test-EngineValid {
    param([string]$EnginePath)

    $RequiredFiles = @(
        "Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe",
        "Engine/Binaries/Win64/UnrealEditor.exe",
        "Engine/Build/BatchFiles/Build.bat"
    )

    foreach ($File in $RequiredFiles) {
        $FullPath = Join-Path $EnginePath $File
        if (-not (Test-Path $FullPath)) {
            return $false
        }
    }
    return $true
}
```

### Step 5: Save to Cache

```powershell
function Save-EngineCache {
    param(
        [string]$ProjectRoot,
        [string]$EnginePath,
        [string]$EngineAssociation
    )

    $CacheFile = Join-Path $ProjectRoot "Saved/claude-data.txt"
    $CacheDir = Split-Path $CacheFile -Parent

    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }

    $Content = @"
[UnrealEngine]
EnginePath=$EnginePath
EngineAssociation=$EngineAssociation
LastDetected=$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

[ProjectInfo]
ProjectName=$((Get-ChildItem "$ProjectRoot/*.uproject").BaseName)
ProjectPath=$ProjectRoot
"@

    Set-Content -Path $CacheFile -Value $Content
}
```

## Bash/CMD Implementation

```bash
# Query registry for all custom engines
reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds"

# Get specific engine path by GUID
reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds" /v "{GUID-HERE}"

# Extract EngineAssociation from .uproject (using PowerShell one-liner)
powershell -Command "(Get-Content S2.uproject | ConvertFrom-Json).EngineAssociation"
```

## Cache File Format

**Location**: `{ProjectRoot}/Saved/claude-data.txt`

```ini
[UnrealEngine]
EnginePath={engine.path}
EngineAssociation={71C58201-4B67-1872-E953-7BB83BB142F3}
LastDetected=2026-01-27T12:00:00

[ProjectInfo]
ProjectName=S2
ProjectPath={project.root}
```

## Engine Association Types

| Type | Example | Detection Method |
|------|---------|------------------|
| GUID | `{71C58201-4B67-...}` | Registry lookup by GUID |
| Version | `5.7.1-huli` | Registry lookup by version tag |
| Empty | `""` | Use Epic Games Launcher default |

## Fallback Chain

1. **Cache** (0ms) - Fastest, no I/O except file read
2. **Registry** (50ms) - Windows Registry query
3. **Manual** (user input) - Ask user to provide path
4. **Error** - No engine found

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| No .uproject found | Wrong directory | Navigate to project root |
| Registry key missing | Engine not registered | Re-run engine setup or register manually |
| Engine path invalid | Moved/deleted engine | Re-detect or update cache |
| GUID mismatch | Different engine version | Update .uproject or re-register engine |

## Report Template

```markdown
# Engine Detection Report

## Result
- **Status**: {Found/Not Found}
- **Engine Path**: {Path}
- **Engine Version**: {Version from Build.version}
- **Association Type**: {GUID/Version/Default}

## Detection Method
- **Source**: {Cache/Registry/Manual}
- **Cache Status**: {Valid/Invalid/Missing}
- **Registry Status**: {Found/Not Found}

## Validation
- **UnrealBuildTool**: {Exists/Missing}
- **UnrealEditor**: {Exists/Missing}
- **Build.bat**: {Exists/Missing}

## Project Info
- **Project Name**: {Name}
- **Project Path**: {Path}
- **EngineAssociation**: {Value}
```

## Usage in Other Skills

```powershell
# Get engine path for use in build commands
$EnginePath = & .\Detect-Engine.ps1 -ProjectRoot $PWD

# Use in build command
$UBT = Join-Path $EnginePath "Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe"
& $UBT S2Editor Win64 Development -Project="$PWD/S2.uproject"
```

## Console Commands

```bash
# List all registered engines
reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds"

# Check engine version
type "{EnginePath}\Engine\Build\Build.version"

# Validate engine installation
dir "{EnginePath}\Engine\Binaries\Win64\UnrealEditor.exe"
```
