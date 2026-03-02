<#
.SYNOPSIS
    Merge main branch into current feature branch with progress and conflict detection.
.DESCRIPTION
    This script handles the git operations for the merge-main skill:
    - Stash detection and auto-stash
    - Switch to main, pull with progress
    - Merge main into feature branch
    - Conflict detection and resolution support
    - Stash restoration
.PARAMETER Action
    The action to perform: validate, stash, pull-main, merge, resolve, commit, restore-stash
.PARAMETER Resolution
    For resolve action: 'ours', 'theirs', or file path for individual resolution
.PARAMETER File
    Specific file to resolve (used with -Resolution)
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('validate', 'stash', 'pull-main', 'merge', 'list-conflicts', 'resolve-all-ours', 'resolve-all-theirs', 'resolve-file', 'commit', 'restore-stash', 'abort')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [ValidateSet('ours', 'theirs', 'skip')]
    [string]$Resolution,

    [Parameter(Mandatory=$false)]
    [string]$File
)

# Colors
$script:Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
    Dim = 'DarkGray'
}

function Write-Status {
    param([string]$Message, [string]$Type = 'Info')
    $color = $script:Colors[$Type]
    Write-Host $Message -ForegroundColor $color
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Get-CurrentBranch {
    $branch = git rev-parse --abbrev-ref HEAD 2>&1
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    return $branch.Trim()
}

function Test-DirtyWorktree {
    git diff-index --quiet HEAD 2>$null
    return $LASTEXITCODE -ne 0
}

function Get-ConflictFiles {
    $files = git diff --name-only --diff-filter=U 2>$null
    if ($files) {
        return $files -split "`n" | Where-Object { $_ -ne '' }
    }
    return @()
}

function Show-PullProgress {
    param([string]$Remote = 'origin', [string]$Branch = 'main')

    Write-Step "Pulling latest from $Remote/$Branch..."

    # Start git pull and show spinner
    $spinChars = @('|', '/', '-', '\')
    $spinIndex = 0

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "git"
    $pinfo.Arguments = "pull $Remote $Branch --progress"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo

    # Capture output
    $stdout = New-Object System.Text.StringBuilder
    $stderr = New-Object System.Text.StringBuilder

    $process.Start() | Out-Null

    # Show spinner while waiting
    while (-not $process.HasExited) {
        $char = $spinChars[$spinIndex % 4]
        Write-Host "`r   [$char] Pulling..." -NoNewline -ForegroundColor Yellow
        $spinIndex++
        Start-Sleep -Milliseconds 100
    }

    # Clear spinner line
    Write-Host "`r                          " -NoNewline
    Write-Host "`r" -NoNewline

    $stdoutText = $process.StandardOutput.ReadToEnd()
    $stderrText = $process.StandardError.ReadToEnd()

    if ($process.ExitCode -ne 0) {
        Write-Status "Pull failed!" Error
        if ($stderrText) { Write-Host $stderrText -ForegroundColor Red }
        return $false
    }

    # Parse and display result
    if ($stdoutText -match "Already up to date") {
        Write-Status "Already up to date." Success
    } else {
        Write-Status "Pull completed successfully." Success
        if ($stderrText -match "(\d+) files? changed") {
            Write-Host $stderrText -ForegroundColor DarkGray
        }
    }

    return $true
}

# Main action switch
switch ($Action) {
    'validate' {
        $branch = Get-CurrentBranch
        if (-not $branch) {
            Write-Status "ERROR: Not a git repository" Error
            exit 1
        }

        if ($branch -eq 'main') {
            Write-Status "ERROR: Already on main branch" Error
            exit 2
        }

        Write-Status "Current branch: $branch" Success
        Write-Host "BRANCH=$branch"
        exit 0
    }

    'stash' {
        if (Test-DirtyWorktree) {
            Write-Step "Stashing uncommitted changes..."
            $result = git stash push -m "merge-main-auto-stash-$(Get-Date -Format 'yyyyMMdd-HHmmss')" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Status "ERROR: Failed to stash changes" Error
                Write-Host $result -ForegroundColor Red
                exit 1
            }
            Write-Status "Changes stashed successfully" Success
            Write-Host "STASHED=true"
        } else {
            Write-Status "Worktree is clean, no stash needed" Info
            Write-Host "STASHED=false"
        }
        exit 0
    }

    'pull-main' {
        $currentBranch = Get-CurrentBranch

        Write-Step "Switching to main branch..."
        git checkout main 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            # Try to fetch main first
            Write-Status "Local main not found, fetching from origin..." Warning
            git fetch origin main:main 2>&1 | Out-Null
            git checkout main 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Status "ERROR: Failed to switch to main" Error
                exit 1
            }
        }
        Write-Status "Switched to main" Success

        # Pull with progress
        $pullSuccess = Show-PullProgress
        if (-not $pullSuccess) {
            Write-Status "Switching back to $currentBranch..." Warning
            git checkout $currentBranch 2>&1 | Out-Null
            exit 1
        }

        Write-Step "Switching back to $currentBranch..."
        git checkout $currentBranch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Status "ERROR: Failed to switch back to $currentBranch" Error
            exit 1
        }
        Write-Status "Back on $currentBranch" Success

        Write-Host "CURRENT_BRANCH=$currentBranch"
        exit 0
    }

    'merge' {
        $branch = Get-CurrentBranch
        Write-Step "Merging main into $branch..."

        $result = git merge main --no-edit 2>&1

        if ($LASTEXITCODE -ne 0) {
            $conflicts = Get-ConflictFiles
            if ($conflicts.Count -gt 0) {
                Write-Status "MERGE CONFLICTS DETECTED ($($conflicts.Count) files)" Warning
                Write-Host "CONFLICTS=true"
                Write-Host "CONFLICT_COUNT=$($conflicts.Count)"
                exit 3  # Special exit code for conflicts
            } else {
                Write-Status "ERROR: Merge failed" Error
                Write-Host $result -ForegroundColor Red
                exit 1
            }
        }

        Write-Status "Merge completed successfully - no conflicts!" Success
        Write-Host "CONFLICTS=false"
        exit 0
    }

    'list-conflicts' {
        $conflicts = Get-ConflictFiles
        if ($conflicts.Count -eq 0) {
            Write-Status "No conflicts found" Success
            exit 0
        }

        Write-Host "`nMERGE CONFLICTS ($($conflicts.Count) files)" -ForegroundColor Yellow
        Write-Host ("=" * 50) -ForegroundColor DarkGray

        $index = 1
        foreach ($file in $conflicts) {
            $ext = [System.IO.Path]::GetExtension($file)
            $isBinary = $ext -in @('.uasset', '.umap', '.png', '.jpg', '.wav', '.mp3', '.fbx')
            $typeLabel = if ($isBinary) { "[binary]" } else { "[text]" }

            # Get diff stats if not binary
            $stats = ""
            if (-not $isBinary) {
                $diffStat = git diff --stat HEAD -- $file 2>$null | Select-Object -Last 1
                if ($diffStat -match '\+(\d+)') { $stats = "+$($Matches[1])" }
                if ($diffStat -match '-(\d+)') { $stats += "/-$($Matches[1])" }
            }

            Write-Host ("{0,3}. {1,-40} {2,-10} {3}" -f $index, $file, $typeLabel, $stats)
            $index++
        }

        Write-Host ""
        exit 0
    }

    'resolve-all-ours' {
        $conflicts = Get-ConflictFiles
        Write-Step "Resolving all conflicts with OURS (current branch)..."

        foreach ($file in $conflicts) {
            git checkout --ours $file 2>&1 | Out-Null
            git add $file 2>&1 | Out-Null
            Write-Status "  Resolved: $file (ours)" Success
        }

        Write-Status "All conflicts resolved with current branch version" Success
        exit 0
    }

    'resolve-all-theirs' {
        $conflicts = Get-ConflictFiles
        Write-Step "Resolving all conflicts with THEIRS (main)..."

        foreach ($file in $conflicts) {
            git checkout --theirs $file 2>&1 | Out-Null
            git add $file 2>&1 | Out-Null
            Write-Status "  Resolved: $file (theirs)" Success
        }

        Write-Status "All conflicts resolved with main branch version" Success
        exit 0
    }

    'resolve-file' {
        if (-not $File -or -not $Resolution) {
            Write-Status "ERROR: -File and -Resolution required" Error
            exit 1
        }

        if ($Resolution -eq 'skip') {
            Write-Status "Skipped: $File (will need manual resolution)" Warning
            exit 0
        }

        $checkoutArg = if ($Resolution -eq 'ours') { '--ours' } else { '--theirs' }
        git checkout $checkoutArg $File 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Status "ERROR: Failed to resolve $File" Error
            exit 1
        }

        git add $File 2>&1 | Out-Null
        Write-Status "Resolved: $File ($Resolution)" Success
        exit 0
    }

    'commit' {
        Write-Step "Committing merge..."

        # Check if there are still unresolved conflicts
        $conflicts = Get-ConflictFiles
        if ($conflicts.Count -gt 0) {
            Write-Status "ERROR: $($conflicts.Count) unresolved conflicts remain" Error
            foreach ($file in $conflicts) {
                Write-Host "  - $file" -ForegroundColor Red
            }
            exit 1
        }

        git commit --no-edit 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Status "ERROR: Commit failed" Error
            exit 1
        }

        Write-Status "Merge committed successfully!" Success
        exit 0
    }

    'restore-stash' {
        Write-Step "Restoring stashed changes..."

        $result = git stash pop 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($result -match "No stash entries found") {
                Write-Status "No stash to restore" Info
            } else {
                Write-Status "WARNING: Failed to restore stash" Warning
                Write-Host $result -ForegroundColor Yellow
                Write-Host "`nYour changes are still in the stash. Run 'git stash list' to see them." -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Status "Stashed changes restored successfully" Success
        }
        exit 0
    }

    'abort' {
        Write-Step "Aborting merge..."
        git merge --abort 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Status "WARNING: No merge to abort or abort failed" Warning
        } else {
            Write-Status "Merge aborted successfully" Success
        }
        exit 0
    }
}
