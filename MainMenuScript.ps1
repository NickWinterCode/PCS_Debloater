# PC-Spezialist Debloater v3.4 based on: WinConfigHelper v5.1 - UI Script

# --- Script Definitions ---
$scripts = @(
    # Restore Point
    [pscustomobject]@{ Name = 'Create Restore Point'; File = 'CreateRestorePoint.ps1' },
    [pscustomobject]@{ Name = 'Systeminfo'; File = 'misc/sysinfo.ps1' },
    [pscustomobject]@{ Name = 'Wallpaper + Remotesoftw.'; File = 'misc\PreSetup.ps1' },
    # Performance & Privacy Tweakers
    [pscustomobject]@{ Name = 'Essential Tweaks'; File = 'Essential_Tweaks.ps1' },
    # Debloaters
    [pscustomobject]@{ Name = 'Remove Bloatware'; File = @('Cleanup/Whitelist_AppX_Remover.ps1', 'Cleanup/StartMenu_Ad_Remover.bat') },  
    [pscustomobject]@{ Name = 'Remove OneDrive'; File = 'Cleanup/Uninstall_OneDrive.ps1' },
    [pscustomobject]@{ Name = 'Remove Office'; File = 'Cleanup/OfficeScrubber/OfficeScrubber.cmd' },
    # Fixes & Misc.
    [pscustomobject]@{ Name = 'Disable Bitlocker'; File = 'misc/DisableBitlocker.ps1' },
    [pscustomobject]@{ Name = 'Installs Firefox, VLC, etc'; File = 'misc/SOFTWARE.ps1' },
    [pscustomobject]@{ Name = 'Set FireFox, VLC, etc as default'; File = 'misc/default_apps.bat' },
    [pscustomobject]@{ Name = 'StartMenu & Taskbar Manager'; File = @('misc/StartMenuManager.ps1', 'misc/TaskbarManager.ps1') },
    # Cleaners
    [pscustomobject]@{ Name = 'TempCleanup'; File = 'Cleanup/TempFileCleanup_Tron.bat' }
)

# --- Window Configuration ---
# Set optimal window size and center it
function Set-WindowSize {
    try {
        # Get current buffer size
        $currentBuffer = $host.UI.RawUI.BufferSize
        
        # Set desired window dimensions
        $windowWidth = 45
        $windowHeight = 26
        
        $newBufferWidth = [Math]::Max($windowWidth, $currentBuffer.Width)
        $newBufferHeight = [Math]::Max(3000, $currentBuffer.Height)  # Keep a large buffer height for scrolling
        
        # Set buffer size first (before setting window size)
        $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($newBufferWidth, $newBufferHeight)
        
        # Now set the window size
        $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($windowWidth, $windowHeight)
        
        # Reset window position to top-left (0,0) to avoid position errors
        # The actual centering is handled by the WindowCentering class
        $host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates(0, 0)
        
    } catch {
        # If window sizing fails, continue without it
        Write-Warning "Could not set window size: $($_.Exception.Message)"
    }
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WindowCentering {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public static void CenterWindow(IntPtr hWnd) {
        RECT rect;
        GetWindowRect(hWnd, out rect);
        int windowWidth = rect.Right - rect.Left;
        int windowHeight = rect.Bottom - rect.Top;
        
        int screenWidth = GetSystemMetrics(0);
        int screenHeight = GetSystemMetrics(1);
        
        int x = (screenWidth / 2) - (windowWidth / 2);
        int y = (screenHeight / 2) - (windowHeight / 2);

        MoveWindow(hWnd, x, y, windowWidth, windowHeight, true);
    }

    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);
}
"@

# Helper function to center the console window
function Center-ConsoleWindow {
    $handle = (Get-Process -Id $pid).MainWindowHandle
    if ($handle -ne [IntPtr]::Zero) {
        [WindowCentering]::CenterWindow($handle)
    }
}

# Apply window configuration
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Set-WindowSize
Start-Sleep -Milliseconds 200  # Allow window to fully initialize
Center-ConsoleWindow

# --- Import Required Functions ---
try {
    . "$PSScriptRoot\Write-Menu.ps1"
    . "$PSScriptRoot\Invoke-LoggedScript.ps1"
} catch {
    Write-Error "Failed to import required modules. Make sure Write-Menu.ps1 and Invoke-LoggedScript.ps1 are in the same directory as this script. Error: $($_.Exception.Message)"
    exit
}

# --- Main Logic ---
function Show-MainMenu {
    $scriptNames = $scripts.Name
    
    # Display the menu and get the user's selections
    $selectedNames = Write-Menu -Title "  PC-Spezialist Optimizer v3.4 `n    Enter/Space = Select`n    Tab = Confirm`n    A=all | U=none" -Entries $scriptNames -MultiSelect
    return $selectedNames
}

function Invoke-SelectedScripts($selectedScripts) {
    Clear-Host
    Write-Host "=== Running Selected Scripts ===" -ForegroundColor Green
    Write-Host ""

    foreach ($script in $selectedScripts) {
        Write-Host "Running: $($script.Name)..." -ForegroundColor Yellow
        
        # Check if File is an array or single file
        $filesToRun = @()
        if ($script.File -is [array]) {
            $filesToRun = $script.File
        } else {
            $filesToRun = @($script.File)
        }
        
        # Run each file in the array
        foreach ($file in $filesToRun) {
            $scriptPath = Join-Path $PSScriptRoot $file
            
            if (-not (Test-Path $scriptPath)) {
                Write-Host "  ERROR: Script file not found at $scriptPath" -ForegroundColor Red
                continue
            }

            try {
                Write-Host "  Executing: $file" -ForegroundColor Cyan
                try {
                    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(99, 3000)
                    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(99, 40)
                    $host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates(0, 0)
                } catch {
                    # Continue even if resizing fails
                }
                
                # Re-center window after resize
                Start-Sleep -Milliseconds 100
                Center-ConsoleWindow
                
                Invoke-LoggedScript -ScriptPath $scriptPath
            } catch {
                Write-Host "    ERROR: Failed to run $file." -ForegroundColor Red
                Write-Host "       $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "  COMPLETED: $($script.Name)" -ForegroundColor Green
        Write-Host ""
    }
}

# Main program loop
$selectedNames = Show-MainMenu

if ($null -eq $selectedNames -or $selectedNames.Count -eq 0) {
    Clear-Host
    Write-Host "No scripts selected. Exiting." -ForegroundColor Yellow
} else {
    $selectedScripts = $scripts | Where-Object { $_.Name -in $selectedNames }
    
    # Run the selected scripts immediately
    Invoke-SelectedScripts $selectedScripts
}

Write-Host "Press any key to exit..."
[System.Console]::ReadKey($true) | Out-Null