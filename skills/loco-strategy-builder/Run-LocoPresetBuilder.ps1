<#
.SYNOPSIS
    Run SipherLocomotionPresetCommandlet to create LocomotionStrategyPreset data assets.

.DESCRIPTION
    Wrapper script that constructs the commandlet invocation correctly.
    Prevents the "-run=S2Editor .SipherLocomotionPresetCommandlet" space bug
    that causes engine crash (LoadModule("") -> AddModule(NAME_None) -> fatal).

.PARAMETER BlueprintPath
    Game path to enemy Blueprint (e.g., /Game/S2/Core_Ene/.../BP_S2_ene_sword_01A)

.PARAMETER AssetName
    Name for the created DataAsset (e.g., DA_LS_Ene_Sword_01A)

.PARAMETER OutputPath
    Output directory for the DataAsset. Default: /SipherAIScalableFramework/Navigation/LocomotionStrategyPresets

.PARAMETER LocomotionType
    Humanoid, Quadruped, Dragon, or Serpentine. Default: Humanoid

.PARAMETER Force
    Overwrite existing assets and assignments.

.EXAMPLE
    .\tools\Run-LocoPresetBuilder.ps1 -BlueprintPath "/Game/S2/Core_Ene/s2_ene_sword_01A_prototype/BP_S2_ene_sword_01A" -AssetName "DA_LS_Ene_Sword_01A"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$BlueprintPath,

    [Parameter(Mandatory=$true)]
    [string]$AssetName,

    [string]$OutputPath = "/SipherAIScalableFramework/Navigation/LocomotionStrategyPresets",

    [string]$LocomotionType = "Humanoid",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- Resolve engine path from registry ---
$regPath = "HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds"
$props = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
$EnginePath = $props | Select-Object -First 1 -ExpandProperty Value

if (-not $EnginePath) {
    Write-Error "Could not find engine path in registry at $regPath"
    exit 1
}

$EditorCmd = Join-Path $EnginePath "Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
if (-not (Test-Path $EditorCmd)) {
    Write-Error "UnrealEditor-Cmd.exe not found at: $EditorCmd"
    exit 1
}

# --- Resolve project root (walk up from script location to find .uproject) ---
$ProjectRoot = $PSScriptRoot
while ($ProjectRoot -and -not (Get-ChildItem -Path $ProjectRoot -Filter "*.uproject" -ErrorAction SilentlyContinue)) {
    $ProjectRoot = Split-Path $ProjectRoot -Parent
}
if (-not $ProjectRoot) {
    Write-Error "No .uproject file found in any parent of: $PSScriptRoot"
    exit 1
}
$ProjectFile = Get-ChildItem -Path $ProjectRoot -Filter "*.uproject" | Select-Object -First 1

# --- Build argument string ---
# CRITICAL: The -run= argument MUST be a single string with NO space between
# the module prefix and commandlet name. A space causes the engine to parse
# ".SipherLocomotionPresetCommandlet" as a separate non-switch token, leading
# to Token.Left(0)="" -> LoadModule("") -> AddModule(NAME_None) -> fatal crash.
#
# PowerShell Start-Process -ArgumentList with arrays joins items with spaces
# and mangles embedded quotes. Build a single string instead.

$LogDir = Join-Path $ProjectRoot "Saved\Logs"
$LogFile = Join-Path $LogDir "LocoPresetBuilder.log"
$ErrFile = Join-Path $LogDir "LocoPresetBuilder_err.log"

$ForceArg = if ($Force) { " -Force" } else { "" }

$ArgString = "`"$($ProjectFile.FullName)`" -run=SipherAIScalableFrameworkEditor.SipherLocomotionPresetCommandlet -BlueprintPath=`"$BlueprintPath`" -AssetName=`"$AssetName`" -OutputPath=`"$OutputPath`" -LocomotionType=$LocomotionType$ForceArg -unattended -nosplash -nullrhi -nosound -abslog=`"$LogFile`""

# --- Print invocation for debugging ---
Write-Host "=== Locomotion Strategy Preset Builder ===" -ForegroundColor Cyan
Write-Host "Engine:    $EditorCmd"
Write-Host "Project:   $($ProjectFile.FullName)"
Write-Host "Blueprint: $BlueprintPath"
Write-Host "Asset:     $AssetName"
Write-Host "Output:    $OutputPath"
Write-Host "Type:      $LocomotionType"
Write-Host "Force:     $Force"
Write-Host "Log:       $LogFile"
Write-Host ""
Write-Host "ArgString: $ArgString" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Starting commandlet..." -ForegroundColor Yellow

# --- Execute ---
$process = Start-Process -FilePath $EditorCmd `
    -ArgumentList $ArgString `
    -Wait -NoNewWindow -PassThru `
    -RedirectStandardError $ErrFile

$exitCode = $process.ExitCode

# --- Report result ---
Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "SUCCESS (exit code 0)" -ForegroundColor Green
} else {
    Write-Host "FAILED (exit code $exitCode)" -ForegroundColor Red
}

Write-Host "Log: $LogFile"
Write-Host "Err: $ErrFile"

exit $exitCode
