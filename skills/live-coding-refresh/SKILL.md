---
name: live-coding-refresh
description: Trigger Unreal Engine Live Coding compilation
---

# Live Coding Refresh Skill

**Role:** Build Engineer - Live Coding Trigger
**Scope:** Trigger Unreal Engine Live Coding compilation
**Engine Version:** UE 5.7+
**Platform:** Windows

## Objective

Trigger Live Coding (Hot Reload) compilation in Unreal Editor by sending Ctrl+Alt+F11 keystroke, allowing code changes to be compiled without restarting the editor.

## Prerequisites

1. Unreal Editor must be running with the project open
2. Live Coding must be enabled in Editor Preferences
3. No compile errors in the code

## Usage

When the user asks to:
- "live reload"
- "hot reload"
- "refresh code"
- "trigger live coding"
- "compile with live coding"

## Workflow

### Step 1: Check if Editor is Running

```powershell
$editor = Get-Process -Name "UnrealEditor" -ErrorAction SilentlyContinue
if (-not $editor) {
    Write-Host "ERROR: Unreal Editor is not running. Please open the editor first."
    exit 1
}
Write-Host "Found Unreal Editor process (PID: $($editor.Id))"
```

### Step 2: Send Ctrl+Alt+F11 Keystroke

```powershell
# Load Windows Forms for SendKeys
Add-Type -AssemblyName System.Windows.Forms

# Find the Unreal Editor window
$editor = Get-Process -Name "UnrealEditor" -ErrorAction SilentlyContinue
if ($editor) {
    # Bring editor to foreground
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@

    $hwnd = $editor.MainWindowHandle
    [Win32]::ShowWindow($hwnd, 9)  # SW_RESTORE
    [Win32]::SetForegroundWindow($hwnd)

    Start-Sleep -Milliseconds 500

    # Send Ctrl+Alt+F11
    [System.Windows.Forms.SendKeys]::SendWait("^%{F11}")

    Write-Host "SUCCESS: Sent Ctrl+Alt+F11 to Unreal Editor"
    Write-Host "Live Coding compilation triggered. Check editor for results."
} else {
    Write-Host "ERROR: Could not find Unreal Editor window"
    exit 1
}
```

## Complete Script

Save as `trigger-live-coding.ps1`:

```powershell
# Trigger Live Coding in Unreal Editor
# Sends Ctrl+Alt+F11 to the editor window

param(
    [switch]$WaitForCompletion
)

# Check if editor is running
$editor = Get-Process -Name "UnrealEditor" -ErrorAction SilentlyContinue
if (-not $editor) {
    Write-Host "ERROR: Unreal Editor is not running." -ForegroundColor Red
    Write-Host "Please open the editor first, or use 'dev-workflow:ue-cpp-build' skill for standalone compilation."
    exit 1
}

Write-Host "Found Unreal Editor (PID: $($editor.Id))" -ForegroundColor Green

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms

# Import Win32 functions
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32User {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

# Store current foreground window to restore later
$previousWindow = [Win32User]::GetForegroundWindow()

# Bring editor to foreground
$hwnd = $editor.MainWindowHandle
if ($hwnd -eq [IntPtr]::Zero) {
    Write-Host "WARNING: Could not get editor window handle. Trying anyway..." -ForegroundColor Yellow
}

[Win32User]::ShowWindow($hwnd, 9)  # SW_RESTORE
[Win32User]::SetForegroundWindow($hwnd)

# Wait for window to come to foreground
Start-Sleep -Milliseconds 300

# Send Ctrl+Alt+F11
Write-Host "Sending Ctrl+Alt+F11..." -ForegroundColor Cyan
[System.Windows.Forms.SendKeys]::SendWait("^%{F11}")

Write-Host "Live Coding triggered!" -ForegroundColor Green
Write-Host ""
Write-Host "Check the Unreal Editor for compilation results."
Write-Host "The Live Coding panel will show compilation progress."

# Restore previous window if requested
if (-not $WaitForCompletion) {
    Start-Sleep -Milliseconds 500
    [Win32User]::SetForegroundWindow($previousWindow)
}

exit 0
```

## Execution Command

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "{ProjectRoot}/./trigger-live-coding.ps1"
```

## Limitations

1. **Cannot capture compilation output** - Live Coding runs inside the editor, so we can't see the compilation results from the command line
2. **No error reporting** - If compilation fails, you need to check the editor's Live Coding panel
3. **Window focus** - Briefly brings editor to foreground to receive the keystroke
4. **Editor must be responsive** - If editor is frozen or in a modal dialog, the keystroke won't work

## When to Use

| Scenario | Use Live Coding | Use /dev-workflow:ue-cpp-build |
|----------|-----------------|------------------|
| Editor is open, small code change | Yes | No |
| Editor is closed | No | Yes |
| Header file changes | No (restart needed) | Yes |
| Adding new UPROPERTY/UFUNCTION | No (restart needed) | Yes |
| Implementation-only changes | Yes | Either |
| Need to see compile output | No | Yes |

## Troubleshooting

### "Editor not running"
- Open the Unreal Editor with your project first
- Use `open-editor` skill to launch it

### "Live Coding failed"
- Check the Live Coding panel in editor (Window > Live Coding)
- Look for compile errors
- Some changes require full editor restart (header changes, new UPROPERTYs)

### "Keystroke not received"
- Editor might be in a modal dialog
- Try clicking on the editor first
- Check if Live Coding is enabled in Editor Preferences

## Related Skills

- `/dev-workflow:ue-cpp-build` - Full compilation when editor is closed
- `open-editor` - Launch Unreal Editor

## Legacy Metadata

```yaml
skill: live-coding-refresh
invoke: /dev-workflow:live-coding-refresh
```
