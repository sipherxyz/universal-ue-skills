---
name: n2c-json-export
description: Export Blueprint to NodeToCode JSON format using N2CExport commandlet. Sub-agent of n2c-orchestrator.
---

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
If not found, auto-detect using `ue-detect-engine` skill or prompt the user.

# N2C JSON Export Agent

Exports Blueprint graphs to NodeToCode JSON format via commandlet.

## Input Contract

```json
{
  "blueprintPath": "/Game/S2/Core/GAS/GA_Jump",
  "outputPath": "{project.root}/Saved/NodeToCode/Export/GA_Jump.json",
  "depth": 2,
  "prettyPrint": true
}
```

## Output Contract

**Success:**
```json
{
  "success": true,
  "jsonPath": "{project.root}/Saved/NodeToCode/Export/GA_Jump.json",
  "metadata": {
    "blueprintName": "GA_Jump",
    "baseClass": "USipherGameplayAbilityRuntime",
    "blueprintType": "Normal",
    "referencedTypes": ["FSipherAbilityData_Animation", "PlayerCombatAttributeSet"],
    "referencedFunctions": ["ActivateAbility", "K2_OverrideRuntimeData"],
    "graphCount": 3,
    "nodeCount": 45
  }
}
```

**Failure:**
```json
{
  "success": false,
  "errorCode": "EXPORT_TIMEOUT",
  "errorMessage": "Commandlet did not complete within 60 seconds",
  "suggestion": "Check if Unreal Editor is running and blocking the project"
}
```

## Error Codes

| Code | Description | Suggestion |
|------|-------------|------------|
| `EXPORT_TIMEOUT` | Commandlet hung >60s | Check if Editor is running |
| `BLUEPRINT_NOT_FOUND` | Asset path invalid | Verify path in Content Browser |
| `INVALID_JSON` | Output JSON malformed | Re-run with -Verbose |
| `EMPTY_BLUEPRINT` | No graphs in Blueprint | Confirm BP has event graph |
| `ENGINE_NOT_FOUND` | Can't locate UE installation | Check registry entry |
| `PROJECT_NOT_FOUND` | .uproject not at expected path | Verify project path |

---

## Execution Steps

### Step 1: Validate Blueprint Path

```bash
# Path must:
# - Start with /Game/
# - Not contain: .., //, special chars
# - Have valid format: /Game/{Module}/{SubPath}/{AssetName}

if [[ ! "$BLUEPRINT_PATH" =~ ^/Game/[A-Za-z0-9_/]+$ ]]; then
  return { success: false, errorCode: "INVALID_PATH" }
fi
```

### Step 2: Get Engine Path

```powershell
# Read from Windows registry
$builds = Get-ItemProperty "HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds" -ErrorAction SilentlyContinue

if (-not $builds) {
  return { success: false, errorCode: "ENGINE_NOT_FOUND" }
}

# Find the engine path (value contains path to Engine folder)
$enginePath = $builds.PSObject.Properties |
  Where-Object { $_.Value -like "*Engine*" -and (Test-Path "$($_.Value)\Engine\Binaries\Win64\UnrealEditor-Cmd.exe") } |
  Select-Object -First 1 -ExpandProperty Value
```

Or check cache:
```bash
# Check if cached in project
if [ -f "Saved/claude-data.txt" ]; then
  ENGINE_PATH=$(grep "EnginePath=" Saved/claude-data.txt | cut -d'=' -f2)
fi
```

### Step 3: Verify Project File

```powershell
$projectFile = "{project.root}/{project.uproject}"

if (-not (Test-Path $projectFile)) {
  return { success: false, errorCode: "PROJECT_NOT_FOUND" }
}
```

### Step 4: Prepare Output Directory

```powershell
$outputDir = "{project.root}/Saved/NodeToCode/Export"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
```

### Step 5: Run Export Commandlet (with timeout)

```powershell
$editorCmd = "$enginePath\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
$arguments = @(
  "`"{project.root}/{project.uproject}`"",
  "-run=N2CExport",
  "-Blueprint=$blueprintPath",
  "-Output=`"$outputPath`"",
  "-Depth=$depth",
  "-Pretty"
)

$process = Start-Process -FilePath $editorCmd -ArgumentList $arguments -PassThru -NoNewWindow

# 60 second timeout
if (-not $process.WaitForExit(60000)) {
  $process.Kill()
  return {
    success: false,
    errorCode: "EXPORT_TIMEOUT",
    suggestion: "Commandlet did not complete within 60 seconds. Check if Editor is running."
  }
}

if ($process.ExitCode -ne 0) {
  return {
    success: false,
    errorCode: "EXPORT_FAILED",
    exitCode: $process.ExitCode
  }
}
```

### Step 6: Validate JSON Output

```powershell
if (-not (Test-Path $outputPath)) {
  return { success: false, errorCode: "OUTPUT_NOT_FOUND" }
}

try {
  $json = Get-Content $outputPath -Raw | ConvertFrom-Json
} catch {
  return {
    success: false,
    errorCode: "INVALID_JSON",
    rawOutput: (Get-Content $outputPath -Raw | Select-Object -First 100)
  }
}

# Validate required fields
$requiredFields = @("version", "metadata", "graphs")
foreach ($field in $requiredFields) {
  if (-not $json.$field) {
    return { success: false, errorCode: "MISSING_FIELD", field: $field }
  }
}

# Check for empty graphs
if ($json.graphs.Count -eq 0) {
  return {
    success: false,
    errorCode: "EMPTY_BLUEPRINT",
    suggestion: "Blueprint has no graphs. Verify it contains event graph or functions."
  }
}
```

### Step 7: Extract Metadata

```powershell
# Extract base class
$baseClass = $json.metadata.BlueprintClass

# Extract all referenced types from nodes
$referencedTypes = @()
$referencedFunctions = @()

foreach ($graph in $json.graphs) {
  foreach ($node in $graph.nodes) {
    # Collect member_parent (class references)
    if ($node.member_parent -and $node.member_parent -notin $referencedTypes) {
      $referencedTypes += $node.member_parent
    }

    # Collect sub_type from pins (struct/class types)
    foreach ($pin in ($node.input_pins + $node.output_pins)) {
      if ($pin.sub_type -and $pin.sub_type -notin $referencedTypes) {
        $referencedTypes += $pin.sub_type
      }
    }

    # Collect function names
    if ($node.member_name -and $node.member_name -notin $referencedFunctions) {
      $referencedFunctions += $node.member_name
    }
  }
}

# Build metadata
$metadata = @{
  blueprintName = $json.metadata.Name
  baseClass = $baseClass
  blueprintType = $json.metadata.BlueprintType
  referencedTypes = $referencedTypes
  referencedFunctions = $referencedFunctions
  graphCount = $json.graphs.Count
  nodeCount = ($json.graphs | ForEach-Object { $_.nodes.Count } | Measure-Object -Sum).Sum
}
```

### Step 8: Return Result

```json
{
  "success": true,
  "jsonPath": "{project.root}/Saved/NodeToCode/Export/GA_Jump.json",
  "metadata": {
    "blueprintName": "GA_Jump",
    "baseClass": "USipherGameplayAbilityRuntime",
    "blueprintType": "Normal",
    "referencedTypes": [
      "FSipherAbilityData_Animation",
      "PlayerCombatAttributeSet",
      "USipherAbilitySystemComponent"
    ],
    "referencedFunctions": [
      "ActivateAbility",
      "K2_OverrideRuntimeData",
      "PlayMontage"
    ],
    "graphCount": 3,
    "nodeCount": 45
  }
}
```

---

## Commandlet Reference

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Blueprint=<path>` | Yes | Asset path (e.g., `/Game/S2/Core/GAS/GA_Jump`) |
| `-Output=<file>` | No | Output JSON file path (default: `Saved/NodeToCode/Export/{Name}.json`) |
| `-Graph=<name>` | No | Specific graph to export (default: all) |
| `-Depth=<0-5>` | No | Translation depth for nested graphs (default: 0) |
| `-Pretty` | No | Pretty-print JSON output |
