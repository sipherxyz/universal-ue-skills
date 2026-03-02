# Trigger Live Coding in Unreal Editor
# Sends Ctrl+Alt+F11 to the editor window

param(
    [switch]$WaitForCompletion,
    [switch]$Silent
)

# Check if editor is running
$editor = Get-Process -Name "UnrealEditor" -ErrorAction SilentlyContinue
if (-not $editor) {
    Write-Host "ERROR: Unreal Editor is not running." -ForegroundColor Red
    Write-Host "Please open the editor first, or use 'dev-workflow:ue-cpp-build' skill for standalone compilation."
    exit 1
}

if (-not $Silent) {
    Write-Host "Found Unreal Editor (PID: $($editor.Id))" -ForegroundColor Green
}

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
    if (-not $Silent) {
        Write-Host "WARNING: Could not get editor window handle. Trying anyway..." -ForegroundColor Yellow
    }
}

[Win32User]::ShowWindow($hwnd, 9)  # SW_RESTORE
[Win32User]::SetForegroundWindow($hwnd)

# Wait for window to come to foreground
Start-Sleep -Milliseconds 300

# Send Ctrl+Alt+F11
if (-not $Silent) {
    Write-Host "Sending Ctrl+Alt+F11..." -ForegroundColor Cyan
}
[System.Windows.Forms.SendKeys]::SendWait("^%{F11}")

if (-not $Silent) {
    Write-Host "Live Coding triggered!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Check the Unreal Editor for compilation results."
    Write-Host "The Live Coding panel will show compilation progress."
}

# Restore previous window if not waiting
if (-not $WaitForCompletion) {
    Start-Sleep -Milliseconds 500
    [Win32User]::SetForegroundWindow($previousWindow)
}

exit 0
