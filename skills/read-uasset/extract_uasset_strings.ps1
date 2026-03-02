# UAsset Binary String Extractor
# Extracts readable ASCII strings from Unreal Engine .uasset files
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File extract_uasset_strings.ps1 -FilePath "path/to/file.uasset"

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [Parameter(Mandatory=$false)]
    [int]$MinLength = 4,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeOffset
)

if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes($FilePath)
$sb = [System.Text.StringBuilder]::new()
$startOffset = 0
$currentOffset = 0

foreach ($byte in $bytes) {
    if ($byte -ge 32 -and $byte -le 126) {
        if ($sb.Length -eq 0) {
            $startOffset = $currentOffset
        }
        [void]$sb.Append([char]$byte)
    } else {
        if ($sb.Length -gt $MinLength) {
            if ($IncludeOffset) {
                Write-Output ("{0:X8}: {1}" -f $startOffset, $sb.ToString())
            } else {
                Write-Output $sb.ToString()
            }
        }
        [void]$sb.Clear()
    }
    $currentOffset++
}

# Output any remaining string
if ($sb.Length -gt $MinLength) {
    if ($IncludeOffset) {
        Write-Output ("{0:X8}: {1}" -f $startOffset, $sb.ToString())
    } else {
        Write-Output $sb.ToString()
    }
}
