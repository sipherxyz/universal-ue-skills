<#
.SYNOPSIS
    Parses Unreal Engine crash logs and extracts crash information for GitHub issue creation.

.PARAMETER Action
    Action to perform: list-crashes, get-crash, format-issue

.PARAMETER Source
    Log source to search: Steam, Editor, Both (default: Steam)

.PARAMETER HoursBack
    How many hours back to look for crashes (default: 24)

.PARAMETER LogPath
    Path to specific log file (for get-crash action)

.PARAMETER LogsDir
    Directory containing log files (overrides Source parameter)
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("list-crashes", "get-crash", "format-issue")]
    [string]$Action,

    [ValidateSet("Steam", "Editor", "Both")]
    [string]$Source = "Steam",

    [int]$HoursBack = 24,

    [string]$LogPath = "",

    [string]$LogsDir = "",

    # Enable Sentry API integration for enriched crash data
    [switch]$UseSentry
)

$ErrorActionPreference = "Stop"

# ============================================================================
# SENTRY API INTEGRATION
# ============================================================================

function Get-SentryCredentials {
    $envPath = Join-Path $PSScriptRoot "..\..\..\credentials\sentry.env"
    if (-not (Test-Path $envPath)) {
        # Try alternate path
        $envPath = "D:\s2_\.claude\credentials\sentry.env"
    }

    if (-not (Test-Path $envPath)) {
        return $null
    }

    $creds = @{}
    Get-Content $envPath | ForEach-Object {
        if ($_ -match "^\s*([A-Z_]+)\s*=\s*(.+)\s*$") {
            $creds[$Matches[1]] = $Matches[2]
        }
    }

    if ($creds.SENTRY_URL -and $creds.SENTRY_AUTH_TOKEN -and $creds.SENTRY_ORG -and $creds.SENTRY_PROJECT) {
        return $creds
    }
    return $null
}

function Get-SentryRecentIssues {
    param(
        [hashtable]$Creds,
        [int]$Limit = 10
    )

    $headers = @{ Authorization = "Bearer $($Creds.SENTRY_AUTH_TOKEN)" }
    $url = "$($Creds.SENTRY_URL)/api/0/projects/$($Creds.SENTRY_ORG)/$($Creds.SENTRY_PROJECT)/issues/?query=is:unresolved&limit=$Limit"

    try {
        $issues = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
        return $issues
    } catch {
        Write-Host "SENTRY_WARNING: Failed to fetch issues - $($_.Exception.Message)"
        return @()
    }
}

function Find-SentryMatchingEvent {
    param(
        [hashtable]$Creds,
        [datetime]$CrashTime,
        [string]$ErrorMessage,
        [string]$CrashType = "",
        [string[]]$StackKeywords = @(),
        [int]$ToleranceHours = 24
    )

    $headers = @{ Authorization = "Bearer $($Creds.SENTRY_AUTH_TOKEN)" }

    # Get recent issues
    $issues = Get-SentryRecentIssues -Creds $Creds -Limit 50

    $bestMatch = $null
    $bestScore = 0

    foreach ($issue in $issues) {
        $score = 0

        # Check time proximity (within tolerance window)
        try {
            $issueTime = [datetime]::Parse($issue.lastSeen)
            $timeDiff = [Math]::Abs(($issueTime - $CrashTime).TotalHours)
            if ($timeDiff -le $ToleranceHours) {
                $score += 10 - [Math]::Min(10, $timeDiff)  # Higher score for closer time
            } else {
                continue  # Skip if too old
            }
        } catch {
            continue
        }

        # Match crash type keywords in issue title
        $title = $issue.title.ToLower()
        if ($CrashType -and $title -match $CrashType.ToLower()) {
            $score += 20
        }

        # Match error message keywords
        if ($ErrorMessage) {
            $errorKeywords = @("access_violation", "vectorvm", "niagara", "ensure", "assert", "fatal")
            foreach ($kw in $errorKeywords) {
                if ($ErrorMessage.ToLower() -match $kw -and $title -match $kw) {
                    $score += 15
                }
            }
        }

        # Match stack keywords (function names from local callstack)
        foreach ($kw in $StackKeywords) {
            if ($title -match [regex]::Escape($kw)) {
                $score += 25
            }
        }

        # Common crash patterns
        if ($title -match "RaiseException" -and $CrashType -match "Exception|Violation") {
            $score += 10
        }

        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $issue
        }
    }

    if ($bestMatch -and $bestScore -ge 10) {
        # Get events for this issue within time window
        $eventsUrl = "$($Creds.SENTRY_URL)/api/0/organizations/$($Creds.SENTRY_ORG)/issues/$($bestMatch.shortId)/events/?limit=10"
        try {
            $events = Invoke-RestMethod -Uri $eventsUrl -Headers $headers -ErrorAction Stop

            # Find event closest to crash time
            $closestEvent = $null
            $closestDiff = [double]::MaxValue

            foreach ($ev in $events) {
                try {
                    $evTime = [datetime]::Parse($ev.dateCreated)
                    $diff = [Math]::Abs(($evTime - $CrashTime).TotalMinutes)
                    if ($diff -lt $closestDiff) {
                        $closestDiff = $diff
                        $closestEvent = $ev
                    }
                } catch { continue }
            }

            if ($closestEvent) {
                return @{
                    IssueId = $bestMatch.shortId
                    IssueTitle = $bestMatch.title
                    EventId = $closestEvent.eventID
                    MatchScore = $bestScore
                    TimeDiffMinutes = $closestDiff
                }
            }
        } catch {
            Write-Host "SENTRY_WARNING: Failed to fetch events for $($bestMatch.shortId)"
        }
    }

    return $null
}

function Get-SentryEventDetails {
    param(
        [hashtable]$Creds,
        [string]$IssueId,
        [string]$EventId
    )

    $headers = @{ Authorization = "Bearer $($Creds.SENTRY_AUTH_TOKEN)" }
    $url = "$($Creds.SENTRY_URL)/api/0/organizations/$($Creds.SENTRY_ORG)/issues/$IssueId/events/$EventId/"

    try {
        $event = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop

        $result = @{
            EventId = $EventId
            IssueId = $IssueId
            Breadcrumbs = @()
            Stacktrace = @()
            Tags = @{}
            Contexts = @{}
            Message = ""
        }

        # Extract breadcrumbs
        if ($event.entries) {
            $breadcrumbEntry = $event.entries | Where-Object { $_.type -eq "breadcrumbs" }
            if ($breadcrumbEntry -and $breadcrumbEntry.data.values) {
                $result.Breadcrumbs = $breadcrumbEntry.data.values | Select-Object -Last 20 | ForEach-Object {
                    "[$($_.timestamp)] [$($_.category)] $($_.message)"
                }
            }

            # Extract stacktrace from exception
            $exceptionEntry = $event.entries | Where-Object { $_.type -eq "exception" }
            if ($exceptionEntry -and $exceptionEntry.data.values) {
                foreach ($ex in $exceptionEntry.data.values) {
                    $result.Message = "$($ex.type): $($ex.value)"
                    if ($ex.stacktrace -and $ex.stacktrace.frames) {
                        $frames = $ex.stacktrace.frames | Select-Object -Last 30
                        foreach ($f in $frames) {
                            $func = if ($f.function) { $f.function } else { "<unknown>" }
                            $file = if ($f.filename) { $f.filename } else { "" }
                            $line = if ($f.lineNo) { ":$($f.lineNo)" } else { "" }
                            $result.Stacktrace += "  $func [$file$line]"
                        }
                    }
                }
            }
        }

        # Extract tags
        if ($event.tags) {
            foreach ($t in $event.tags) {
                $result.Tags[$t.key] = $t.value
            }
        }

        # Extract contexts (GPU, OS, UE version, etc.)
        if ($event.contexts) {
            $result.Contexts = $event.contexts
        }

        return $result
    } catch {
        Write-Host "SENTRY_WARNING: Failed to fetch event details - $($_.Exception.Message)"
        return $null
    }
}

# ============================================================================
# STEAM LIBRARY DETECTION
# ============================================================================

# Get Steam library folders from libraryfolders.vdf
function Get-SteamLibraryFolders {
    $steamPaths = @()

    # Default Steam installation path
    $defaultSteam = "${env:ProgramFiles(x86)}\Steam"
    if (Test-Path $defaultSteam) {
        $steamPaths += $defaultSteam
    }

    # Parse libraryfolders.vdf to find additional library locations
    $vdfPath = "$defaultSteam\steamapps\libraryfolders.vdf"
    if (Test-Path $vdfPath) {
        $content = Get-Content $vdfPath -Raw
        # Match "path" entries in the VDF file
        $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
        foreach ($match in $matches) {
            $libPath = $match.Groups[1].Value -replace '\\\\', '\'
            if ((Test-Path $libPath) -and ($steamPaths -notcontains $libPath)) {
                $steamPaths += $libPath
            }
        }
    }

    # Also check common custom library locations on other drives
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
    foreach ($drive in $drives) {
        $commonPaths = @(
            "$($drive.Root)SteamLibrary",
            "$($drive.Root)Steam",
            "$($drive.Root)Games\Steam",
            "$($drive.Root)Games\SteamLibrary"
        )
        foreach ($path in $commonPaths) {
            if ((Test-Path $path) -and ($steamPaths -notcontains $path)) {
                $steamPaths += $path
            }
        }
    }

    return $steamPaths
}

# Find Huli game logs in Steam libraries
function Find-SteamGameLogs {
    $steamLibs = Get-SteamLibraryFolders
    $gamePaths = @(
        "steamapps\common\Huli\S2\Saved\Logs",
        "steamapps\common\Huli\Saved\Logs"
    )

    foreach ($lib in $steamLibs) {
        foreach ($gamePath in $gamePaths) {
            $fullPath = Join-Path $lib $gamePath
            if (Test-Path $fullPath) {
                return $fullPath
            }
        }
    }

    return $null
}

# Resolve ALL logs directories - returns array of [path, source] pairs
# Respects the global $Source parameter: Steam, Editor, or Both
function Resolve-AllLogsDirectories {
    param([string]$ProvidedPath)

    $results = @()

    # User-provided path takes priority (overrides Source filter)
    if ($ProvidedPath -and (Test-Path $ProvidedPath)) {
        $results += @{ Path = $ProvidedPath; Source = "Custom" }
        return $results
    }

    # Get Editor paths if Source is Editor or Both
    if ($Source -eq "Editor" -or $Source -eq "Both") {
        # Try relative to current working directory (dev environment)
        $cwdLogs = Join-Path (Get-Location) "Saved\Logs"
        if (Test-Path $cwdLogs) {
            $results += @{ Path = $cwdLogs; Source = "Editor" }
        }

        # Try relative to script location (go up to project root)
        $scriptLogs = Join-Path $PSScriptRoot "..\..\..\..\Saved\Logs"
        if (Test-Path $scriptLogs) {
            $resolved = (Resolve-Path $scriptLogs).Path
            if (-not ($results | Where-Object { $_.Path -eq $resolved })) {
                $results += @{ Path = $resolved; Source = "Editor" }
            }
        }

        # Try D:\s2_ explicitly as fallback (dev project)
        $defaultLogs = "D:\s2_\Saved\Logs"
        if ((Test-Path $defaultLogs) -and -not ($results | Where-Object { $_.Path -eq $defaultLogs })) {
            $results += @{ Path = $defaultLogs; Source = "Editor" }
        }
    }

    # Get Steam paths if Source is Steam or Both
    if ($Source -eq "Steam" -or $Source -eq "Both") {
        $steamLogs = Find-SteamGameLogs
        if ($steamLogs -and -not ($results | Where-Object { $_.Path -eq $steamLogs })) {
            $results += @{ Path = $steamLogs; Source = "Steam" }
        }
    }

    return $results
}

# Legacy function for backward compatibility
function Resolve-LogsDirectory {
    param([string]$ProvidedPath)

    $all = Resolve-AllLogsDirectories -ProvidedPath $ProvidedPath
    if ($all.Count -gt 0) {
        return $all[0].Path
    }
    return $null
}

# Crash detection patterns
$CrashPatterns = @(
    "Fatal error",
    "Assertion failed",
    "Unhandled Exception",
    "Critical error",
    "GPU crashed",
    "D3D Device Lost",
    "TDR detected",
    "Access violation",
    "Stack overflow",
    "Pure virtual function",
    "LogSentrySdk.*Callstack",
    "\[Callstack\]",
    "appError called",
    "Crash in runnable",
    "HandleError.*Assertion"
)

$CrashRegex = ($CrashPatterns | ForEach-Object { "($_)" }) -join "|"

function Get-RecentLogs {
    param([int]$Hours, [string]$Directory)

    $cutoffTime = (Get-Date).AddHours(-$Hours)
    $allDirs = Resolve-AllLogsDirectories -ProvidedPath $Directory

    if ($allDirs.Count -eq 0) {
        Write-Host "ERROR: Could not find any logs directory"
        return @()
    }

    $allLogs = @()
    foreach ($dir in $allDirs) {
        $logs = Get-ChildItem $dir.Path -Filter "S2*.log" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt $cutoffTime }

        foreach ($log in $logs) {
            # Add source info to log object
            $log | Add-Member -NotePropertyName "Source" -NotePropertyValue $dir.Source -Force
            $log | Add-Member -NotePropertyName "SourcePath" -NotePropertyValue $dir.Path -Force
            $allLogs += $log
        }
    }

    return $allLogs | Sort-Object LastWriteTime -Descending
}

function Test-LogHasCrash {
    param([string]$FilePath)

    # Read last 500 lines for crash detection (crashes are at the end)
    $content = Get-Content $FilePath -Tail 500 -ErrorAction SilentlyContinue
    if (-not $content) { return $false }

    $contentText = $content -join "`n"
    return $contentText -match $CrashRegex
}

function Get-CrashDetails {
    param(
        [string]$FilePath,
        [switch]$IncludeSentryData
    )

    $content = Get-Content $FilePath -Tail 500 -ErrorAction SilentlyContinue
    if (-not $content) { return $null }

    $result = @{
        LogFile = (Get-Item $FilePath).Name
        LogPath = $FilePath
        Timestamp = (Get-Item $FilePath).LastWriteTime
        CrashType = "Unknown"
        ErrorMessage = ""
        RootCauseFunction = ""
        RootCauseFile = ""
        Callstack = @()
        SentryCallstack = @()
        RelevantLogs = @()
        # Sentry API data
        SentryEventId = ""
        SentryIssueId = ""
        SentryBreadcrumbs = @()
        SentryFullStacktrace = @()
        SentryTags = @{}
        SentryContexts = @{}
    }

    $callstackLines = @()
    $sentryLines = @()
    $errorLines = @()

    foreach ($line in $content) {
        # Detect crash type and error message
        if ($line -match "Fatal error[:\s]+(.+)") {
            $result.CrashType = "Fatal Error"
            $result.ErrorMessage = $Matches[1]
        }
        elseif ($line -match "Assertion failed[:\s]+(.+)") {
            $result.CrashType = "Assertion"
            $result.ErrorMessage = $Matches[1]
        }
        elseif ($line -match "(check|verify|ensure)\s*failed[:\s]*(.*)") {
            $result.CrashType = "Assertion ($($Matches[1]))"
            if ($Matches[2]) { $result.ErrorMessage = $Matches[2] }
        }
        elseif ($line -match "Access violation[:\s]*(.*)") {
            $result.CrashType = "Access Violation"
            $result.ErrorMessage = if ($Matches[1]) { $Matches[1] } else { "Memory access violation" }
        }
        elseif ($line -match "(GPU crashed|D3D Device Lost|TDR)") {
            $result.CrashType = "GPU Crash"
            $result.ErrorMessage = $line
        }
        elseif ($line -match "Unhandled Exception[:\s]+(.+)") {
            $result.CrashType = "Unhandled Exception"
            $result.ErrorMessage = $Matches[1]
        }

        # Sentry callstack (GOLD - has real symbols with file:line)
        if ($line -match "LogSentrySdk.*\[Callstack\]") {
            $sentryLines += $line

            # Extract function and file from Sentry frame
            # Format: [Callstack] 0x... Module.dll!FunctionName() [FilePath:Line]
            if ($line -match "!([A-Za-z_][A-Za-z0-9_:<>]*)\(\).*\[([^\]]+):(\d+)\]") {
                $funcName = $Matches[1]
                $filePath = $Matches[2]

                # Skip system/engine frames to find root cause in project code
                if (-not $result.RootCauseFunction -and
                    ($filePath -match "\\Source\\S2\\" -or
                     $filePath -match "\\Plugins\\Frameworks\\Sipher" -or
                     $filePath -match "\\Plugins\\GameFeatures\\" -or
                     $filePath -match "\\Plugins\\EditorTools\\")) {
                    $result.RootCauseFunction = $funcName
                    $result.RootCauseFile = "$filePath`:$($Matches[3])"
                }
            }
        }

        # Standard UE callstack
        if ($line -match "^\s*(0x[0-9a-fA-F]+\s+|#\d+|\[\d+\])") {
            $callstackLines += $line
        }

        # Relevant error/warning logs (exclude noisy shader logs)
        if ($line -match "(Error|Warning|Fatal|Critical)" -and
            $line -notmatch "LogShaderCompilers" -and
            $line -notmatch "ShaderPipelineCache") {
            $errorLines += $line
        }
    }

    # If no error message found, try to extract from first Sentry frame
    if (-not $result.ErrorMessage -and $result.RootCauseFunction) {
        $result.ErrorMessage = "Crash in $($result.RootCauseFunction)"
    }

    $result.Callstack = $callstackLines | Select-Object -First 30
    $result.SentryCallstack = $sentryLines | Select-Object -First 50
    $result.RelevantLogs = $errorLines | Select-Object -Last 20

    # Fetch additional data from Sentry API if requested
    if ($IncludeSentryData) {
        $sentryCreds = Get-SentryCredentials
        if ($sentryCreds) {
            Write-Host "SENTRY: Searching for matching event..."

            # Extract key function names from local callstack for matching
            $stackKeywords = @()
            foreach ($line in $sentryLines) {
                if ($line -match "!([A-Za-z_][A-Za-z0-9_]+)::([A-Za-z_][A-Za-z0-9_]+)") {
                    $stackKeywords += $Matches[2]  # Method name
                }
            }
            $stackKeywords = $stackKeywords | Select-Object -Unique -First 5

            $match = Find-SentryMatchingEvent -Creds $sentryCreds `
                -CrashTime $result.Timestamp `
                -ErrorMessage $result.ErrorMessage `
                -CrashType $result.CrashType `
                -StackKeywords $stackKeywords `
                -ToleranceHours 24

            if ($match) {
                Write-Host "SENTRY: Found matching issue $($match.IssueId) (score: $($match.MatchScore), time diff: $([Math]::Round($match.TimeDiffMinutes, 1)) min)"
                $result.SentryIssueId = $match.IssueId
                $result.SentryEventId = $match.EventId

                $eventDetails = Get-SentryEventDetails -Creds $sentryCreds -IssueId $match.IssueId -EventId $match.EventId
                if ($eventDetails) {
                    $result.SentryBreadcrumbs = $eventDetails.Breadcrumbs
                    $result.SentryFullStacktrace = $eventDetails.Stacktrace
                    $result.SentryTags = $eventDetails.Tags
                    $result.SentryContexts = $eventDetails.Contexts

                    # Use Sentry message if we don't have a local one
                    if (-not $result.ErrorMessage -and $eventDetails.Message) {
                        $result.ErrorMessage = $eventDetails.Message
                    }
                    Write-Host "SENTRY: Retrieved $($eventDetails.Breadcrumbs.Count) breadcrumbs, $($eventDetails.Stacktrace.Count) stack frames"
                }
            } else {
                Write-Host "SENTRY: No matching event found within time window"
            }
        } else {
            Write-Host "SENTRY: Credentials not configured (skipping API enrichment)"
        }
    }

    return $result
}

function Format-GithubIssue {
    param([hashtable]$CrashData)

    $title = "Crash: $($CrashData.CrashType)"
    if ($CrashData.RootCauseFunction) {
        $title = "Crash: $($CrashData.CrashType) in $($CrashData.RootCauseFunction)"
    }
    elseif ($CrashData.ErrorMessage) {
        $msgShort = $CrashData.ErrorMessage.Substring(0, [Math]::Min(60, $CrashData.ErrorMessage.Length))
        $title = "Crash: $($CrashData.CrashType) - $msgShort"
    }

    $body = @"
## Crash Report

**Type:** $($CrashData.CrashType)
**Time:** $($CrashData.Timestamp)
**Log File:** ``$($CrashData.LogFile)``
"@

    if ($CrashData.RootCauseFunction) {
        $body += @"

**Root Cause:** ``$($CrashData.RootCauseFunction)``
**Location:** ``$($CrashData.RootCauseFile)``
"@
    }

    $body += @"

## Error Message

``````
$($CrashData.ErrorMessage)
``````

"@

    if ($CrashData.SentryCallstack.Count -gt 0) {
        $body += @"

## Callstack (Symbolicated)

``````
$($CrashData.SentryCallstack -join "`n")
``````

"@
    }

    if ($CrashData.Callstack.Count -gt 0) {
        $body += @"

## Callstack (Raw)

``````
$($CrashData.Callstack -join "`n")
``````

"@
    }

    if ($CrashData.RelevantLogs.Count -gt 0) {
        $body += @"

## Relevant Logs

``````
$($CrashData.RelevantLogs -join "`n")
``````

"@
    }

    # Sentry API data sections
    if ($CrashData.SentryBreadcrumbs.Count -gt 0) {
        $body += @"

## Breadcrumbs (Sentry)

Events leading to the crash:

``````
$($CrashData.SentryBreadcrumbs -join "`n")
``````

"@
    }

    if ($CrashData.SentryFullStacktrace.Count -gt 0) {
        $body += @"

## Full Stacktrace (Sentry)

``````
$($CrashData.SentryFullStacktrace -join "`n")
``````

"@
    }

    # Environment section with Sentry context
    $envSection = @"

## Environment

- **Platform:** Windows
- **Branch:** $(git rev-parse --abbrev-ref HEAD 2>$null)
- **Commit:** $(git rev-parse --short HEAD 2>$null)
"@

    if ($CrashData.SentryTags.Count -gt 0) {
        if ($CrashData.SentryTags["gpu.name"]) {
            $envSection += "`n- **GPU:** $($CrashData.SentryTags["gpu.name"])"
        }
        if ($CrashData.SentryTags["os.name"]) {
            $envSection += "`n- **OS:** $($CrashData.SentryTags["os.name"])"
        }
        if ($CrashData.SentryTags["unreal.config"]) {
            $envSection += "`n- **Build Config:** $($CrashData.SentryTags["unreal.config"])"
        }
        if ($CrashData.SentryTags["device.model"]) {
            $envSection += "`n- **Device:** $($CrashData.SentryTags["device.model"])"
        }
    }

    if ($CrashData.SentryIssueId) {
        $envSection += "`n- **Sentry Issue:** $($CrashData.SentryIssueId)"
    }

    $body += $envSection

    $body += @"

---
*Auto-generated crash report*
"@

    return @{
        Title = $title
        Body = $body
        Labels = @("bug", "crash")
    }
}

# Main execution
switch ($Action) {
    "list-crashes" {
        $logs = Get-RecentLogs -Hours $HoursBack -Directory $LogsDir
        $crashes = @()

        foreach ($log in $logs) {
            if (Test-LogHasCrash -FilePath $log.FullName) {
                $details = Get-CrashDetails -FilePath $log.FullName
                $msgLen = if ($details.ErrorMessage) { [Math]::Min(100, $details.ErrorMessage.Length) } else { 0 }
                $crashes += @{
                    File = $log.Name
                    Path = $log.FullName
                    Time = $log.LastWriteTime
                    Type = $details.CrashType
                    Source = $log.Source
                    RootCause = $details.RootCauseFunction
                    Message = if ($msgLen -gt 0) { $details.ErrorMessage.Substring(0, $msgLen) } else { "" }
                }
            }
        }

        # Show which directories were scanned
        $allDirs = Resolve-AllLogsDirectories -ProvidedPath $LogsDir
        Write-Host "LOG_SOURCES=$($allDirs.Count)"
        foreach ($dir in $allDirs) {
            Write-Host "  [$($dir.Source)] $($dir.Path)"
        }
        Write-Host ""

        if ($crashes.Count -eq 0) {
            Write-Host "NO_CRASHES_FOUND"
            Write-Host "Checked $($logs.Count) logs from the last $HoursBack hours"
        } else {
            Write-Host "CRASHES_FOUND=$($crashes.Count)"
            Write-Host ""
            $i = 1
            foreach ($crash in $crashes) {
                Write-Host "[$i] [$($crash.Source)] $($crash.Time.ToString('yyyy-MM-dd HH:mm'))"
                Write-Host "    Type: $($crash.Type)"
                Write-Host "    File: $($crash.File)"
                if ($crash.RootCause) {
                    Write-Host "    Root Cause: $($crash.RootCause)"
                }
                if ($crash.Message) {
                    Write-Host "    Message: $($crash.Message)"
                }
                Write-Host "    Path: $($crash.Path)"
                Write-Host ""
                $i++
            }
        }
    }

    "get-crash" {
        if (-not $LogPath) {
            # Get most recent crash log
            $logs = Get-RecentLogs -Hours $HoursBack -Directory $LogsDir
            foreach ($log in $logs) {
                if (Test-LogHasCrash -FilePath $log.FullName) {
                    $LogPath = $log.FullName
                    break
                }
            }
        }

        if (-not $LogPath -or -not (Test-Path $LogPath)) {
            Write-Host "ERROR: No crash log found"
            exit 1
        }

        $details = Get-CrashDetails -FilePath $LogPath -IncludeSentryData:$UseSentry
        Write-Host "CRASH_TYPE=$($details.CrashType)"
        Write-Host "CRASH_TIME=$($details.Timestamp)"
        Write-Host "LOG_FILE=$($details.LogFile)"
        Write-Host "ERROR_MESSAGE=$($details.ErrorMessage)"
        if ($details.RootCauseFunction) {
            Write-Host "ROOT_CAUSE_FUNCTION=$($details.RootCauseFunction)"
            Write-Host "ROOT_CAUSE_FILE=$($details.RootCauseFile)"
        }
        Write-Host ""
        Write-Host "=== SENTRY CALLSTACK (from log) ==="
        $details.SentryCallstack | ForEach-Object { Write-Host $_ }
        Write-Host ""
        Write-Host "=== RAW CALLSTACK ==="
        $details.Callstack | ForEach-Object { Write-Host $_ }
        Write-Host ""
        Write-Host "=== RELEVANT LOGS ==="
        $details.RelevantLogs | ForEach-Object { Write-Host $_ }

        # Sentry API data
        if ($details.SentryIssueId) {
            Write-Host ""
            Write-Host "=== SENTRY API DATA ==="
            Write-Host "SENTRY_ISSUE=$($details.SentryIssueId)"
            Write-Host "SENTRY_EVENT=$($details.SentryEventId)"

            if ($details.SentryBreadcrumbs.Count -gt 0) {
                Write-Host ""
                Write-Host "=== BREADCRUMBS (Sentry API) ==="
                $details.SentryBreadcrumbs | ForEach-Object { Write-Host $_ }
            }

            if ($details.SentryFullStacktrace.Count -gt 0) {
                Write-Host ""
                Write-Host "=== FULL STACKTRACE (Sentry API) ==="
                $details.SentryFullStacktrace | ForEach-Object { Write-Host $_ }
            }

            if ($details.SentryTags.Count -gt 0) {
                Write-Host ""
                Write-Host "=== TAGS (Sentry) ==="
                foreach ($key in $details.SentryTags.Keys) {
                    Write-Host "  $key`: $($details.SentryTags[$key])"
                }
            }
        }
    }

    "format-issue" {
        if (-not $LogPath) {
            $logs = Get-RecentLogs -Hours $HoursBack -Directory $LogsDir
            foreach ($log in $logs) {
                if (Test-LogHasCrash -FilePath $log.FullName) {
                    $LogPath = $log.FullName
                    break
                }
            }
        }

        if (-not $LogPath -or -not (Test-Path $LogPath)) {
            Write-Host "ERROR: No crash log found"
            exit 1
        }

        $details = Get-CrashDetails -FilePath $LogPath -IncludeSentryData:$UseSentry
        $issue = Format-GithubIssue -CrashData $details

        Write-Host "ISSUE_TITLE=$($issue.Title)"
        Write-Host "ISSUE_LABELS=$($issue.Labels -join ',')"
        Write-Host ""
        Write-Host "=== ISSUE_BODY_START ==="
        Write-Host $issue.Body
        Write-Host "=== ISSUE_BODY_END ==="
    }
}
