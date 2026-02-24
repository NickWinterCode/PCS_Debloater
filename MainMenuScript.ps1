# PC-Spezialist Debloater v3.4 based on: WinConfigHelper v5.1 - UI Script

# --- Software Selection Configuration ---
$script:SoftwareToInstall = @{
    Firefox     = $true
    Thunderbird = $true
    LibreOffice = $true
    VLC         = $true
    WinRAR      = $true
    CDBurnerXP  = $true
}

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
    [pscustomobject]@{ Name = 'Install Software'; File = 'misc/SOFTWARE.ps1' },
    [pscustomobject]@{ Name = 'Set FireFox, VLC, etc as default'; File = @('misc/default_apps.bat', 'misc/Set-FirefoxHomepage.ps1' ) }, 
    [pscustomobject]@{ Name = 'StartMenu & Taskbar Manager'; File = @('misc/StartMenuManager.ps1', 'misc/TaskbarManager.ps1') },
    # Cleaners
    [pscustomobject]@{ Name = 'TempCleanup'; File = 'Cleanup/CLEANUP.ps1' }
)

# --- Window Configuration ---
function Set-WindowSize {
    try {
        $currentBuffer = $host.UI.RawUI.BufferSize
        $windowWidth = 45
        $windowHeight = 26
        
        $newBufferWidth = [Math]::Max($windowWidth, $currentBuffer.Width)
        $newBufferHeight = [Math]::Max(3000, $currentBuffer.Height)
        
        $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($newBufferWidth, $newBufferHeight)
        $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($windowWidth, $windowHeight)
        $host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates(0, 0)
    } catch {
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

function Set-ConsoleWindowCentered {
    $handle = (Get-Process -Id $pid).MainWindowHandle
    if ($handle -ne [IntPtr]::Zero) {
        [WindowCentering]::CenterWindow($handle)
    }
}

# Apply window configuration
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Set-WindowSize
Start-Sleep -Milliseconds 200
Set-ConsoleWindowCentered

# --- Import Required Functions ---
try {
    . "$PSScriptRoot\Write-Menu.ps1"
    . "$PSScriptRoot\Invoke-LoggedScript.ps1"
} catch {
    Write-Error "Failed to import required modules. Make sure Write-Menu.ps1 and Invoke-LoggedScript.ps1 are in the same directory as this script. Error: $($_.Exception.Message)"
    exit
}

# --- Software Configuration Menu ---
function Show-SoftwareConfigMenu {
    $softwareList = @('Firefox', 'Thunderbird', 'LibreOffice', 'VLC', 'WinRAR', 'CDBurnerXP')
    
    # Pre-select currently enabled software
    $preSelected = @()
    foreach ($sw in $softwareList) {
        if ($script:SoftwareToInstall[$sw]) {
            $preSelected += $sw
        }
    }
    
    # Show selection menu
    $selectedSoftware = @(Write-Menu -Title "  Software Configuration`n    Space/Enter = Toggle`n    Tab = Confirm`n    A=all | U=none | Esc=back" -Entries $softwareList -MultiSelect)
    
    # If user pressed Escape, Write-Menu returns $null — @($null) gives count 1 with a null element
    # So check for actual null BEFORE wrapping, or check content after
    if ($selectedSoftware.Count -eq 1 -and $null -eq $selectedSoftware[0]) {
        return
    }
    
    # Reset all selections to false
    foreach ($key in @($script:SoftwareToInstall.Keys)) {
        $script:SoftwareToInstall[$key] = $false
    }
    
    # Set selected ones to true — no .Count check needed now, foreach handles empty arrays fine
    foreach ($sw in $selectedSoftware) {
        if ($sw -and $script:SoftwareToInstall.ContainsKey($sw)) {
            $script:SoftwareToInstall[$sw] = $true
        }
    }
    
    # Show confirmation
    Clear-Host
    Write-Host ""
    Write-Host "  Software Configuration Saved!" -ForegroundColor Green
    Write-Host "  ==============================" -ForegroundColor Gray
    Write-Host ""
    foreach ($sw in $softwareList) {
        if ($script:SoftwareToInstall[$sw]) {
            Write-Host "  [X] $sw" -ForegroundColor Green
        } else {
            Write-Host "  [ ] $sw" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor Yellow
    [System.Console]::ReadKey($true) | Out-Null
}

function Export-SoftwareConfig {
    # Create config file for SOFTWARE.ps1 to read
    $configPath = Join-Path $PSScriptRoot "misc\software_config.json"
    $script:SoftwareToInstall | ConvertTo-Json | Set-Content -Path $configPath -Force
}

# --- Main Logic ---
function Show-MainMenu {
    $scriptNames = $scripts.Name
    
    $selectedNames = Write-Menu -Title "  PC-Spezialist Optimizer v3.5 `n    Enter/Space = Select`n    Tab = Confirm | C = Config`n    A=all | U=none" -Entries $scriptNames -MultiSelect
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
                } catch { }
                
                Start-Sleep -Milliseconds 100
                Set-ConsoleWindowCentered
                
                # Export software config before running SOFTWARE.ps1
                if ($file -like "*SOFTWARE.ps1*") {
                    Export-SoftwareConfig
                }
                
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

# --- Main Program Loop ---
do {
    $selectedNames = Show-MainMenu

    # Check if user pressed C for config
    if ($selectedNames -eq '__CONFIG__') {
        Show-SoftwareConfigMenu
        continue
    }
    
    # Force into array so .Count always works
    $selectedNames = @($selectedNames)
    
    # Check if user made a selection or cancelled
    if ($selectedNames.Count -eq 0 -or ($selectedNames.Count -eq 1 -and $null -eq $selectedNames[0])) {
        Clear-Host
        Write-Host "No scripts selected. Exiting." -ForegroundColor Yellow
        break
    }
        
    # Run selected scripts
    $selectedScripts = $scripts | Where-Object { $_.Name -in $selectedNames }
    Invoke-SelectedScripts $selectedScripts
    break
    
} while ($true)

Write-Host "Press any key to exit..."
[System.Console]::ReadKey($true) | Out-Null