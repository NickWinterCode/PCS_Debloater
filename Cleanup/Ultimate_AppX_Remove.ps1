param(
    [string]$AppListFile,
    [switch]$WhatIf = $false
)

# Set the absolute path for the AppListFile. This is the only reliable way.
$AppListFile = Join-Path $PSScriptRoot "Appslist.txt"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script should be run as Administrator for best results. Some apps may not uninstall without admin rights."
}

# Check if file exists
if (-not (Test-Path $AppListFile)) {
    Write-Error "File '$AppListFile' not found. Please ensure the file exists in the current directory."
    exit 1
}
(Get-AppxPackage).PackageFamilyName | Out-File "$env:SystemRoot\PackagesOld.txt"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     App Removal Script Started" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read the app list file and extract app names (ignore comments and empty lines)
Write-Host "Reading app list from $AppListFile..." -ForegroundColor Yellow
$appsToRemove = Get-Content $AppListFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        # Extract app name (everything before # if comment exists on same line)
        $appName = ($line -split '#')[0].Trim()
        if ($appName) { $appName }
    }
} | Sort-Object -Unique

Write-Host "Found $($appsToRemove.Count) apps in the removal list." -ForegroundColor Green
Write-Host ""

# Get all installed apps (both for current user and all users)
Write-Host "Scanning system for installed apps..." -ForegroundColor Yellow
$installedApps = @()

# Get apps for current user
$currentUserApps = Get-AppxPackage -ErrorAction SilentlyContinue
$installedApps += $currentUserApps

# Get apps for all users (requires admin)
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $allUserApps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    $installedApps += $allUserApps
}

# Remove duplicates based on PackageFullName
$installedApps = $installedApps | Sort-Object PackageFullName -Unique

Write-Host "Found $($installedApps.Count) installed apps on the system." -ForegroundColor Green
Write-Host ""

# Find matches between installed apps and removal list
Write-Host "Matching apps to remove..." -ForegroundColor Yellow
$appsToUninstall = @()

foreach ($appToRemove in $appsToRemove) {
    $matchedApps = $installedApps | Where-Object { $_.Name -like "*$appToRemove*" -or $_.Name -eq $appToRemove }
    if ($matchedApps) {
        $appsToUninstall += $matchedApps
    }
}

# Remove duplicates
$appsToUninstall = $appsToUninstall | Sort-Object PackageFullName -Unique

if ($appsToUninstall.Count -eq 0) {
    Write-Host "No apps from the list are currently installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Script completed!" -ForegroundColor Cyan
    exit 0
}

Write-Host "Found $($appsToUninstall.Count) apps to remove:" -ForegroundColor Yellow
$appsToUninstall | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
Write-Host ""

# Confirm action if not in WhatIf mode
if (-not $WhatIf) {
    $confirmation = 'Y' #Read-Host "Do you want to proceed with uninstalling these apps? (Y/N)"
    if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Starting removal process..." -ForegroundColor Yellow
Write-Host ""
# FUCK TEAMS
Stop-Process -Name "ms-teams*" -Force -ErrorAction SilentlyContinue
Get-AppxPackage -Name "MSTeams*" | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "MSTeams*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
$successCount = 0
$failCount = 0
$counter = 0

foreach ($app in $appsToUninstall) {
    $counter++
    $percentComplete = [int](($counter / $appsToUninstall.Count) * 100)
    Write-Progress -Activity "Removing Apps" -Status "Processing $($app.Name)" -PercentComplete $percentComplete
    
    Write-Host "[$counter/$($appsToUninstall.Count)] Removing: $($app.Name)..." -NoNewline
    
    if ($WhatIf) {
        Write-Host " [SIMULATION - Would be removed]" -ForegroundColor Cyan
        $successCount++
    } else {
        try {
            # Try to remove for current user
            Remove-AppxPackage -Package $app.PackageFullName -ErrorAction Stop
            
            # If admin, also remove provisioned package to prevent reinstallation
            if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Name }
                if ($provisioned) {
                    Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction SilentlyContinue
                }
            }
            
            Write-Host " Success" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host " Failed" -ForegroundColor Red
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
            $failCount++
        }
    }
}

Write-Progress -Activity "Removing Apps" -Completed

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "          Removal Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Successfully removed: $successCount apps" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  Failed to remove: $failCount apps" -ForegroundColor Red
}
if ($WhatIf) {
    Write-Host ""
    Write-Host "  This was a simulation. Run without -WhatIf to actually remove apps." -ForegroundColor Cyan
}


# Disable Consumer Features (prevents automatic app installation)
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}
Set-ItemProperty -Path $registryPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force

# Disable app auto-download
$registryPath2 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-ItemProperty -Path $registryPath2 -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $registryPath2 -Name "ContentDeliveryAllowed" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $registryPath2 -Name "SubscribedContentEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $registryPath2 -Name "PreInstalledAppsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $registryPath2 -Name "PreInstalledAppsEverEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $registryPath2 -Name "OemPreInstalledAppsEnabled" -Value 0 -Type DWord -Force

# Prevent provisioned applications from being reinstalled
# https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update
Write-Host "Preventing removed apps from being reinstalled..." -ForegroundColor Yellow
$oldPackagesFile = "$env:SystemRoot\PackagesOld.txt"
$oldPackages = Get-Content $oldPackagesFile
$currentPackages = (Get-AppxPackage).PackageFamilyName
$removedPackages = Compare-Object -ReferenceObject $oldPackages -DifferenceObject $currentPackages | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject

foreach ($package in $removedPackages) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" -Name $package -Force | Out-Null
}

# Copy PackagesOld.txt to _USBDATA\LOGs\COMPUTERNAME\ with timestamp if _USBDATA folder exists
Write-Host "Searching for _USBDATA folder to backup PackagesOld.txt..." -ForegroundColor Yellow
$usbDataPath = $null
$computerName = $env:COMPUTERNAME

# Get current date and time formatted as YYYY.MM.DD_HH.MM.SS
$timestamp = Get-Date -Format "yyyy.MM.dd_HH.mm.ss"

# Check all available drives for _USBDATA folder
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object {
    $testPath = Join-Path $_.Root "_USBDATA"
    if (Test-Path $testPath) {
        $usbDataPath = $testPath
        Write-Host "Found _USBDATA at: $usbDataPath" -ForegroundColor Green
    }
}

if ($usbDataPath) {
    try {
        # Create destination directory structure
        $logDestination = Join-Path $usbDataPath "LOGs\$computerName"
        if (-not (Test-Path $logDestination)) {
            New-Item -Path $logDestination -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: $logDestination" -ForegroundColor Green
        }
        
        # Copy PackagesOld.txt to the destination with timestamp
        if (Test-Path $oldPackagesFile) {
            $destinationFileName = "PackagesOld_$timestamp.txt"
            $destinationFile = Join-Path $logDestination $destinationFileName
            Copy-Item -Path $oldPackagesFile -Destination $destinationFile -Force
            Write-Host "PackagesOld.txt backed up to: $destinationFile" -ForegroundColor Green
        } else {
            Write-Host "Warning: PackagesOld.txt not found at $oldPackagesFile" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error backing up PackagesOld.txt: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "_USBDATA folder not found on any drive. Skipping backup." -ForegroundColor Yellow
}

Remove-Item $oldPackagesFile -Force -ErrorAction SilentlyContinue
Write-Host "Registry settings applied to prevent reinstallation" -ForegroundColor Green

# Clear caches of Client.CBS and more
# Start menu cache is cleared later
Write-Host "Clearing AppX caches" -ForegroundColor Cyan
Get-AppxPackage -Name "*MicrosoftWindows.Client.CBS*" | ForEach-Object { 
    Remove-Item "$env:LocalAppData\Packages\$($_.PackageFamilyName)\LocalCache" -Recurse -Force -ErrorAction SilentlyContinue
}
Get-AppxPackage -Name "*Microsoft.Windows.Search*" | ForEach-Object { 
    Remove-Item "$env:LocalAppData\Packages\$($_.PackageFamilyName)\LocalCache" -Recurse -Force -ErrorAction SilentlyContinue
}
Get-AppxPackage -Name "*Microsoft.Windows.SecHealthUI*" | ForEach-Object { 
    Remove-Item "$env:LocalAppData\Packages\$($_.PackageFamilyName)\LocalCache" -Recurse -Force -ErrorAction SilentlyContinue
}

$capabilities = @(
    'MathRecognizer', 
    'OpenSSH.Client',
    'Microsoft.Windows.PowerShell.ISE', 
    'App.Support.QuickAssist', 
    'App.StepsRecorder',
    'Media.WindowsMediaPlayer', 
    #'Microsoft.Windows.MSPaint', 
    'Microsoft.Windows.WordPad'
)
Get-WindowsCapability -Online |
Where-Object { $capabilities -contains ($_.Name -split '~')[0] } |
Remove-WindowsCapability -Online -ErrorAction SilentlyContinue  
Dism /Online /Disable-Feature /Featurename:Recall /NoRestart
Write-Host "Pre-installed Features removed successfully..."

Write-Host ""
Write-Host "Script finished!" -ForegroundColor Cyan