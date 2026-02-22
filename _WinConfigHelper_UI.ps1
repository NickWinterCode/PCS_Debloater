# PC-Spezialist Debloater v3.2 based on: WinConfigHelper v5.1 - UI Script

# --- Window Configuration ---
# Set optimal window size and center it
function Set-WindowSize {
    try {
        # Get screen dimensions
        $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
        $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
        
        # Set desired window dimensions (adjust as needed)
        $windowWidth = 45
        $windowHeight = 29 
        
        # Calculate center position
        $left = [math]::Floor(($screenWidth / 8 - $windowWidth) / 2)  # Divide by 8 for character width approximation
        $top = [math]::Floor(($screenHeight / 16 - $windowHeight) / 2)  # Divide by 16 for character height approximation
        
        # Ensure minimum values
        if ($left -lt 0) { $left = 0 }
        if ($top -lt 0) { $top = 0 }
        
        # Set window size and position
        $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($windowWidth, $windowHeight)
        $host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates($left, $top)
        
        # Set buffer size to match window size
        $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($windowWidth, $windowHeight)
        
    } catch {
        # If window sizing fails, continue without it
        Write-Warning "Could not set window size: $($_.Exception.Message)"
    }
}
$psWindow = Get-Process -Id $pid | ForEach-Object { $_.MainWindowHandle }
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


# Apply window configuration
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Set-WindowSize
[WindowCentering]::CenterWindow($psWindow)

# --- Import Required Functions ---
try {
    . "$PSScriptRoot\Write-Menu.ps1"
    . "$PSScriptRoot\Invoke-LoggedScript.ps1"
} catch {
    Write-Error "Failed to import required modules. Make sure Write-Menu.ps1 and Invoke-LoggedScript.ps1 are in the same directory as this script. Error: $($_.Exception.Message)"
    exit
}

# --- Script Definitions ---
# Define the scripts that can be selected.
$scripts = @(
    # Restore Point
    [pscustomobject]@{ Name = 'Create Restore Point'; File = 'CreateRestorePoint.ps1' },
    [pscustomobject]@{ Name = 'Systeminfo'; File = 'misc/ProdInfo.ps1' },
    [pscustomobject]@{ Name = 'Wallpaper + Remotesoftw.'; File = 'misc\PreSetup.ps1' },
    # Performance & Privacy Tweakers
    [pscustomobject]@{ Name = 'Essential Tweaks'; File = 'Essential_Tweaks.ps1' },
    [pscustomobject]@{ Name = 'Optimizer Helper v16.7'; File = 'Optimizer/OptimizeHelper_batch.bat' },
    #[pscustomobject]@{ Name = 'PC-Spezialist Main Script'; File = 'PC_Spezialist.ps1' },
    # Debloaters
    [pscustomobject]@{ Name = 'Remove MS Bloat'; File = 'Cleanup/metro_Microsoft_modern_apps_to_target_by_name.ps1' },
    [pscustomobject]@{ Name = 'Remove 3rd Party Bloat'; File = 'Cleanup/metro_3rd_party_modern_apps_to_target_by_name.ps1' },
    [pscustomobject]@{ Name = 'Remove Edge'; File = 'Cleanup/EdgeRemover/RemoveEdge_privacy.sexy.bat' },
    [pscustomobject]@{ Name = 'Remove OneDrive'; File = 'Cleanup/OneDriveRemover/OneDriveRemover.bat' },
    [pscustomobject]@{ Name = 'Remove Office'; File = 'Cleanup/OfficeScrubber/OfficeScrubber.cmd' },
    [pscustomobject]@{ Name = 'StartMenu Ad Remover'; File = 'Cleanup/StartMenu_Ad_Remover.bat' },
    # Fixes & Misc.
    [pscustomobject]@{ Name = 'Disable Bitlocker'; File = 'misc/DisableBitlocker.ps1' },
    #[pscustomobject]@{ Name = 'Visual Effects'; File = 'fixes/VisualEffects.bat' },
    [pscustomobject]@{ Name = 'Installs Firefox, VLC, etc'; File = 'misc/software_installer.ps1' },
    [pscustomobject]@{ Name = 'Set FireFox, VLC, etc as default'; File = 'misc/default_apps.bat' },
    [pscustomobject]@{ Name = 'Zeitanpassung [FIX]'; File = 'fixes/time_changer.bat' },
    [pscustomobject]@{ Name = 'Fix Window Snapping [FIX]'; File = 'fixes/SnapAssist.bat' },
    #[pscustomobject]@{ Name = 'Enable Gamebar [FIX]'; File = 'fixes/EnableGamebar.bat' },
    # Cleaners
    [pscustomobject]@{ Name = 'TempCleanup'; File = 'Cleanup/TempFileCleanup_Tron.bat' },
    [pscustomobject]@{ Name = 'Deeper Cleanup'; File = 'Cleanup/Cleanup_privacy.sexy.bat' }
)

# --- Main Logic ---
function Show-MainMenu {
    $scriptNames = $scripts.Name
    
    # Display the menu and get the user's selections
    $selectedNames = Write-Menu -Title "  PC-Spezialist Optimizer v3.2 `n    Enter/Space = Select`n    Tab = Confirm`n    A=all | U=none" -Entries $scriptNames -MultiSelect
    return $selectedNames
}

function Invoke-SelectedScripts($selectedScripts) {
    Clear-Host
    Write-Host "=== Running Selected Scripts ===" -ForegroundColor Green
    Write-Host ""

    foreach ($script in $selectedScripts) {
        Write-Host "Running: $($script.Name)..." -ForegroundColor Yellow
        $scriptPath = Join-Path $PSScriptRoot $script.File
        
        if (-not (Test-Path $scriptPath)) {
            Write-Host "  ERROR: Script file not found at $scriptPath" -ForegroundColor Red
            continue
        }

        try {
            [console]::windowwidth=99; [console]::windowheight=40; [console]::bufferwidth=[console]::windowwidth
            [WindowCentering]::CenterWindow($psWindow)
            Invoke-LoggedScript -ScriptPath $scriptPath
            #if ($script.File.EndsWith('.ps1')) {
                #Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`"" -Verb RunAs -Wait
            #} elseif ($script.File.EndsWith('.bat')) {
                #Start-Process cmd.exe -ArgumentList "/c `"$scriptPath`"" -Verb RunAs -Wait
            #}
            Write-Host "  SUCCESS: $($script.Name) completed." -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Failed to run $($script.Name)." -ForegroundColor Red
            Write-Host "     $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Main program loop
$selectedNames = Show-MainMenu

if ($null -eq $selectedNames -or $selectedNames.Count -eq 0) {
    Clear-Host
    Write-Host "No scripts selected. Exiting." -ForegroundColor Yellow
} else {
    # Filter the original script list to get the full objects for the selected names
    $selectedScripts = $scripts | Where-Object { $_.Name -in $selectedNames }
    
    # Run the selected scripts immediately
    Invoke-SelectedScripts $selectedScripts
}

Write-Host "Press any key to exit..."
[System.Console]::ReadKey($true) | Out-Null