# WinConfigHelper v4 - UI Script

# --- Window Configuration ---
# Set optimal window size and center it
function Set-WindowSize {
    try {
        # Get screen dimensions
        $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
        $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
        
        # Set desired window dimensions (adjust as needed)
        $windowWidth = 45
        $windowHeight = 25
        
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

# Apply window configuration
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Set-WindowSize

# --- Import Required Functions ---
try {
    . "$PSScriptRoot\Write-Menu.ps1"
} catch {
    Write-Error "Failed to import 'Write-Menu.ps1'. Make sure the file is in the same directory as this script. Error: $($_.Exception.Message)"
    exit
}

# --- Script Definitions ---
# Define the scripts that can be selected.
$scripts = @(
    [pscustomobject]@{ Name = 'Create Restore Point'; File = 'CreateRestorePoint.ps1' },
    [pscustomobject]@{ Name = 'Wallpaper + Remotesoftw.'; File = 'PreSetup.bat' },
    [pscustomobject]@{ Name = 'Essential Tweaks'; File = 'Essential_Tweaks.ps1' },
    [pscustomobject]@{ Name = 'Optimizer'; File = 'Optimizer\_OptimizeHelper.bat' },
    [pscustomobject]@{ Name = 'PC-Spezialist Main Script'; File = 'PC_Spezialist.ps1' },
    [pscustomobject]@{ Name = 'Remove MS Bloat'; File = 'Tools\metro_Microsoft_modern_apps_to_target_by_name.ps1' },
    [pscustomobject]@{ Name = 'Remove 3rd Party Bload'; File = 'Tools\metro_3rd_party_modern_apps_to_target_by_name.ps1' },
    [pscustomobject]@{ Name = 'Uninstall OneDrive'; File = 'OneDriveRemover\_OneDriveRemover.bat' },
    [pscustomobject]@{ Name = 'Uninstall MS Edge'; File = 'EdgeRemover\RemoveEdge.bat' },
    [pscustomobject]@{ Name = 'Disables Bitlocker'; File = 'DisableBitlocker.ps1' },
    [pscustomobject]@{ Name = 'Adjust Appearance'; File = 'VisualEffects.bat' },
    [pscustomobject]@{ Name = 'Enable Gamebar'; File = 'EnableGamebar.bat' },
    [pscustomobject]@{ Name = 'Fix Window Snapping'; File = 'SnapAssist.bat' },
    [pscustomobject]@{ Name = 'Installs Firefox, VLC, etc'; File = 'Program_Installer.bat' },
    [pscustomobject]@{ Name = 'Set FireFox, VLC, etc as default'; File = 'default_apps.bat' },
    [pscustomobject]@{ Name = 'TempCleanup'; File = 'stage_1_tempclean\stage_1_tempclean.bat' },
    [pscustomobject]@{ Name = 'Deeper Cleanup'; File = 'privacy_clean.bat' }
)

# --- Main Logic ---



function Show-SelectionMenu {
    # Get an array of script names to display in the menu
    $scriptNames = $scripts.Name
    
    # Display the menu and get the user's selections
    $selectedNames = Write-Menu -Title "PC-Spezialist Config v2`n  Tab = Confirm`n  A=Select All | U=Unselect All" -Entries $scriptNames -MultiSelect
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
            if ($script.File.EndsWith('.ps1')) {
                Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`"" -Verb RunAs -Wait
            } elseif ($script.File.EndsWith('.bat')) {
                Start-Process cmd.exe -ArgumentList "/c `"$scriptPath`"" -Verb RunAs -Wait
            }
            Write-Host "  SUCCESS: $($script.Name) completed." -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Failed to run $($script.Name)." -ForegroundColor Red
            Write-Host "     $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    Write-Host "All selected scripts have been processed." -ForegroundColor Cyan
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    [System.Console]::ReadKey($true) | Out-Null
}

# Main program loop
$selectedNames = Show-SelectionMenu

if ($null -eq $selectedNames -or $selectedNames.Count -eq 0) {
    #Clear-Host
    Write-Host "No scripts selected. Exiting." -ForegroundColor Yellow
} else {
    # Filter the original script list to get the full objects for the selected names
    $selectedScripts = $scripts | Where-Object { $_.Name -in $selectedNames }
    
    # Run the selected scripts immediately
    Invoke-SelectedScripts $selectedScripts
}

#Write-Host "Press any key to exit..."
#[System.Console]::ReadKey($true) | Out-Null
