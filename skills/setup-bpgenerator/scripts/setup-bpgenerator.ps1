# setup-bpgenerator.ps1
# Configures Ultimate Blueprint Generator plugin to use a custom AI gateway.
# Detects API key from environment variables, writes to ApiKeySlots.json.

param(
    [string]$ModelName = "gpt-5.4",
    [string]$BaseURL   = "https://ai-gateway.atherlabs.com/v1/chat/completions"
)

# Walk up from $PSScriptRoot until we find a .uproject file (= project root)
$ProjectRoot = $PSScriptRoot
while ($ProjectRoot -and !(Get-ChildItem $ProjectRoot -Filter "*.uproject" -ErrorAction SilentlyContinue)) {
    $ProjectRoot = Split-Path $ProjectRoot -Parent
}
if (-not $ProjectRoot) {
    Write-Host "ERROR: Could not locate project root (.uproject not found)." -ForegroundColor Red
    exit 1
}

$ConfigPath = Join-Path $ProjectRoot "Saved\BpGeneratorUltimate\ApiKeySlots.json"

# --- Detect API key from environment ---
$EnvCandidates = @(
    "AI_GATEWAY_API_KEY",
    "ATHERLABS_API_KEY",
    "SIPHER_AI_KEY",
    "OPENAI_API_KEY",
    "ANTHROPIC_API_KEY"
)

$ApiKey  = $null
$FoundVar = $null
foreach ($var in $EnvCandidates) {
    $val = [System.Environment]::GetEnvironmentVariable($var)
    if ($val -and $val.Trim() -ne "") {
        $ApiKey   = $val.Trim()
        $FoundVar = $var
        break
    }
}

if (-not $ApiKey) {
    Write-Host ""
    Write-Host "ERROR: No API key found in environment." -ForegroundColor Red
    Write-Host ""
    Write-Host "Set one of these environment variables before running:" -ForegroundColor Yellow
    foreach ($var in $EnvCandidates) {
        Write-Host "  $var" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Example (PowerShell):"
    Write-Host "  `$env:AI_GATEWAY_API_KEY = 'clp_your_key_here'" -ForegroundColor Green
    exit 1
}

Write-Host ""
Write-Host "Found API key in: $FoundVar" -ForegroundColor Green

# --- Read existing config ---
if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: Config not found at: $ConfigPath" -ForegroundColor Red
    Write-Host "Open Unreal Editor once with BpGeneratorUltimate enabled to create the config file."
    exit 1
}

$json = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# --- Encode API key (XOR each byte with 0x55, then base64) ---
$keyBytes   = [System.Text.Encoding]::ASCII.GetBytes($ApiKey)
$xorBytes   = $keyBytes | ForEach-Object { $_ -bxor 0x55 }
$encodedKey = [Convert]::ToBase64String([byte[]]$xorBytes)

# --- Patch Slot 0 (active slot) ---
$slot                 = $json.Slots[0]
$slot.Provider        = "Custom"
$slot.ApiKey          = $encodedKey
$slot.CustomBaseURL   = $BaseURL
$slot.CustomModelName = $ModelName
$json.ActiveSlot      = 0

# --- Write back ---
$json | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8

Write-Host "Config updated: $ConfigPath" -ForegroundColor Green
Write-Host ""
Write-Host "Settings applied to Slot 0:" -ForegroundColor Cyan
Write-Host "  Provider  : Custom"
Write-Host "  Model     : $ModelName"
Write-Host "  BaseURL   : $BaseURL"
Write-Host "  ApiKey    : $($ApiKey.Substring(0, [Math]::Min(8, $ApiKey.Length)))..." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Restart Unreal Editor (or reload the BpGenerator plugin) for changes to take effect." -ForegroundColor Yellow
