# SAFE VERSION WITH SOUND RECORDER REMOVAL + REGISTRY BLOCKING
# Run as Administrator

param(
    [switch]$WhatIf,
    [switch]$Interactive
)

# Check for admin rights
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Exit
}

# Apps to explicitly ALLOW removal (even if they match protection patterns)
$ForceRemoveApps = @(
    "Microsoft.OutlookForWindows"
)

# Extended whitelist (apps to keep)
$WhiteListedApps = @(
    # Windows essentials
    "Microsoft.WindowsStore",
    "Microsoft.WindowsCalculator", 
    "Microsoft.Paint", 
    "Microsoft.DesktopAppInstaller",  # Required for app installation
    "Microsoft.StorePurchaseApp",     # Required for Store
    "Microsoft.WindowsNotepad", 
    "40459File-New-Project.EarTrumpet", 
    "Microsoft.XboxGamingOverlay", 
    "AppUp.IntelGraphicsExperience", 
    "NVIDIACorp.NVIDIAControlPanel", 
    "AppUp.ThunderboltControlCenter", 
    "Microsoft.Winget.Source", 
    "Microsoft.SecHealthUI", 
    "Microsoft.WindowsTerminal", 
    "Microsoft.GamingApp", 
    "Microsoft.Windows.Photos", 
    "Microsoft.WindowsCamera", 
    "Microsoft.Xbox", 
    "Microsoft.Xbox.TCUI", 
    "Microsoft.XboxGameCallableUI", 
    "Microsoft.XboxGameOverlay", 
    "Microsoft.XboxIdentityProvider", 
    "Microsoft.ScreenSketch",
    
    # Windows Spotlight dependencies
    "Microsoft.Windows.ContentDeliveryManager",  # Required for Spotlight
    "Microsoft.Windows.CloudExperienceHost",     # Cloud content delivery
    "Microsoft.Windows.Search",                  # Search integration
    
    # Microsoft Extensions
    "Microsoft.HEIFImageExtension", 
    "Microsoft.VP9VideoExtensions", 
    "Microsoft.WebpImageExtension", 
    "Microsoft.HEVCVideoExtension", 
    "Microsoft.RawImageExtension", 
    "Microsoft.WebMediaExtensions", 
    "Microsoft.AVCEncoderVideoExtension", 
    "Microsoft.AV1VideoExtension", 
    "Microsoft.MPEG2VideoExtension",
    
    # Lenovo
    "Lenovo.Vantage",           # Battery thresholds / Updates
    "Lenovo.Hotkeys",           # Fn Key support
    "LenovoSettings",
    
    # HP (Hewlett-Packard)
    "HP.Audio",                 # Audio Switch
    "HP.SystemEventUtility",    # OSD / Fn Keys (Critical)
    "HP.Omen",                  # Fan Control (Gaming)
    "AD2F1837",                 # HP Printer Control (Optional, but usually needed)

    # Dell
    "Dell.MobileConnect",       # Phone link (Optional)
    "Dell.HelpAndSupport",      # Often ties into warranty tools
    "Dell.CommandUpdate",       # Driver Updates
    "DellDigitalDelivery",      # Paid software delivery

    # Acer
    "Acer.NitroSense",          # Fan Control
    "Acer.PredatorSense",       # Fan Control
    "Acer.CareCenter",          # Updates
    "Acer.QuickAccess",
    "AcerIncorporated.NitroSenseV31",

    # ASUS
    "B9ECED6F.ArmouryCrate",    # Gaming/Fan Control
    "B9ECED6F.MyASUS",          # Battery/Updates
    "B9ECED6F.ASUSSystemControl",
    
    # Medion
    "Medion.Service",           # Control Center
    "MedionAG",                 # General drivers
    
    # Misc.
    "Spotify"
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  SAFE APP REMOVAL SCRIPT" -ForegroundColor Cyan
Write-Host "  Protecting: Frameworks + OEM Apps" -ForegroundColor Green
Write-Host "  + Registry Block for Reinstalls" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "`nRUNNING IN TEST MODE - No changes will be made" -ForegroundColor Yellow
}

# Function to add registry entry to prevent reinstallation
function Add-DeprovisionedApp {
    param(
        [string]$PackageName
    )
    
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned"
    
    # Create the registry path if it doesn't exist
    if (!(Test-Path $registryPath)) {
        try {
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "Created Deprovisioned registry path" -ForegroundColor DarkGray
        } catch {
            Write-Host "Could not create registry path: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Add the package to the deprovisioned list
    try {
        $keyName = $PackageName -replace '_.*$', ''  # Remove version info
        New-Item -Path "$registryPath\$keyName" -Force | Out-Null
        Write-Host "  Added to registry block list: $keyName" -ForegroundColor DarkYellow
        return $true
    } catch {
        Write-Host "  Could not add to registry: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check if app should be protected
function Test-ProtectApp {
    param($App)
    
    # CHECK FORCE REMOVE LIST FIRST
    if ($App.Name -in $ForceRemoveApps) {
        Write-Host "FORCE REMOVE OVERRIDE: $($App.Name)" -ForegroundColor Magenta
        return $false
    }
    
    # ALWAYS PROTECT FRAMEWORKS
    if ($App.IsFramework) {
        return $true
    }
    
    # Protect system-critical apps
    if ($App.NonRemovable) {
        return $true
    }
    
    # Protect whitelisted apps
    if ($App.Name -in $WhiteListedApps) {
        return $true
    }
    
    # Protect Windows Spotlight related apps
    if ($App.Name -match "ContentDeliveryManager|CloudExperienceHost|Windows\.Search") {
        return $true
    }
    
    # MODIFIED: Don't protect Sound apps if in force remove list
    if ($App.Name -notin $ForceRemoveApps) {
        # Protect driver/hardware apps by name
        if ($App.Name -match "Realtek|Dolby|Audio|Driver|Support|Control|Hardware|Firmware|BIOS|Touchpad|Keyboard|SmartByte|Killer|THX") {
            return $true
        }
    }
    
    # Protect framework dependencies
    if ($App.Name -match "Framework|Runtime|VCLibs|NET\.Native") {
        return $true
    }
    
    return $false
}

# Show protected frameworks first
Write-Host "`nFrameworks detected (PROTECTED):" -ForegroundColor Green
Get-AppxPackage | Where-Object { $_.IsFramework } | ForEach-Object {
    Write-Host "  Framework: $($_.Name)" -ForegroundColor DarkGreen
}

# Show force remove apps
if ($ForceRemoveApps.Count -gt 0) {
    Write-Host "`nApps marked for FORCE REMOVAL:" -ForegroundColor Magenta
    foreach ($app in $ForceRemoveApps) {
        Write-Host "  X $app" -ForegroundColor Magenta
    }
}

# Main removal logic
Write-Host "`nProcessing apps..." -ForegroundColor Yellow

$AppsToRemove = @()
$AppsProtected = @()

Get-AppxPackage -AllUsers | ForEach-Object {
    $app = $_
    
    if (Test-ProtectApp $app) {
        $AppsProtected += $app
        
        # Show why it's protected
        if ($app.IsFramework) {
            Write-Host "PROTECTED (Framework): $($app.Name)" -ForegroundColor Green
        }
        elseif ($app.NonRemovable) {
            Write-Host "PROTECTED (System): $($app.Name)" -ForegroundColor Green
        }
        elseif ($app.Name -match "ContentDeliveryManager|CloudExperienceHost|Windows\.Search") {
            Write-Host "PROTECTED (Spotlight): $($app.Name)" -ForegroundColor Green
        }
        #elseif ($app.Publisher -match "HP|Lenovo|Dell|ASUS|Acer") {
        #    Write-Host "PROTECTED (OEM): $($app.Name)" -ForegroundColor Green
        #}
        elseif ($app.Name -match "Audio|Driver|Support") {
            Write-Host "PROTECTED (Driver/Hardware): $($app.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "PROTECTED (Whitelisted): $($app.Name)" -ForegroundColor Green
        }
    }
    else {
        if ($Interactive) {
            Write-Host "`nApp: $($app.Name)" -ForegroundColor Cyan
            Write-Host "Publisher: $($app.Publisher)" -ForegroundColor Gray
            $response = Read-Host "Remove this app? (Y/N)"
            
            if ($response -eq 'Y' -or $response -eq 'y') {
                $AppsToRemove += $app
                Write-Host "Marked for removal" -ForegroundColor Red
            } else {
                Write-Host "Keeping app" -ForegroundColor Green
            }
        } else {
            $AppsToRemove += $app
            Write-Host "WILL REMOVE: $($app.Name)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "SUMMARY:" -ForegroundColor Yellow
Write-Host "Protected apps: $($AppsProtected.Count)" -ForegroundColor Green
Write-Host "Apps to remove: $($AppsToRemove.Count)" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Cyan

# Remove apps if not in WhatIf mode
if ($AppsToRemove.Count -gt 0 -and !$WhatIf) {
    $confirm = 'YES' #Read-Host "`nProceed with removal? Type YES to confirm"
    
    if ($confirm -eq 'YES') {
        Write-Host "`nRemoving apps..." -ForegroundColor Yellow
        
        $removedApps = @()
        
        # Remove provisioned packages first
        Get-AppxProvisionedPackage -Online | ForEach-Object {
            $provApp = $_
            $shouldRemove = $AppsToRemove | Where-Object { $_.Name -eq $provApp.DisplayName }
            
            if ($shouldRemove) {
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $provApp.PackageName -ErrorAction Stop
                    Write-Host "Removed provisioned: $($provApp.DisplayName)" -ForegroundColor Red
                    
                    # Add to registry block list
                    Add-DeprovisionedApp -PackageName $provApp.DisplayName
                    $removedApps += $provApp.DisplayName
                    
                } catch {
                    Write-Host "Could not remove provisioned: $($provApp.DisplayName)" -ForegroundColor Gray
                }
            }
        }
        
        # Remove installed packages
        $AppsToRemove | ForEach-Object {
            try {
                Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
                Write-Host "Removed: $($_.Name)" -ForegroundColor Red
                
                # Add to registry block list if not already added
                if ($_.Name -notin $removedApps) {
                    Add-DeprovisionedApp -PackageName $_.Name
                }
                
            } catch {
                Write-Host "Could not remove: $($_.Name) - $($_.Exception.Message)" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n=====================================" -ForegroundColor Cyan
        Write-Host "Registry blocks added to prevent reinstallation" -ForegroundColor Green
        Write-Host "Location: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" -ForegroundColor DarkGray
        Write-Host "`nRemoval complete!" -ForegroundColor Green
    } else {
        Write-Host "Removal cancelled" -ForegroundColor Yellow
    }
} elseif ($WhatIf) {
    Write-Host "`nThis was a test run. Run without -WhatIf to actually remove apps." -ForegroundColor Yellow
}

Write-Host "`nScript completed!" -ForegroundColor Cyan

# Optional: Show current Spotlight status
Write-Host "`nWindows Spotlight Status Check:" -ForegroundColor Cyan
$spotlightApps = @(
    "Microsoft.Windows.ContentDeliveryManager",
    "Microsoft.Windows.CloudExperienceHost"
)

$spotlightApps | ForEach-Object {
    $app = Get-AppxPackage -Name $_ -ErrorAction SilentlyContinue
    if ($app) {
        Write-Host "  [OK] $_ is installed (Spotlight should work)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] $_ is missing (Spotlight may not work)" -ForegroundColor Red
    }
}