<#
.SYNOPSIS
    Sets Firefox homepage to google.de without using user.js
.DESCRIPTION
    This script modifies prefs.js directly, allowing users to change
    the homepage later through Firefox's settings GUI.
    If no profile exists, Firefox will be started for 10 seconds to generate one.
.NOTES
    Firefox will be closed automatically if started by this script.
#>

# Function to check if Firefox is running
function Test-FirefoxRunning {
    $firefox = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
    return $null -ne $firefox
}

# Function to find Firefox installation path
function Get-FirefoxPath {
    $possiblePaths = @(
        "${env:ProgramFiles}\Mozilla Firefox\firefox.exe",
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe",
        "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find via registry
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            $firefoxPath = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).'(Default)'
            if ($firefoxPath -and (Test-Path $firefoxPath)) {
                return $firefoxPath
            }
        }
    }
    
    return $null
}

# Function to find Firefox profile directories
function Get-FirefoxProfiles {
    $profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    
    if (Test-Path $profilesPath) {
        $profiles = Get-ChildItem -Path $profilesPath -Directory
        if ($profiles.Count -gt 0) {
            return $profiles
        }
    }
    return $null
}

# Function to close Firefox
function Stop-Firefox {
    param (
        [switch]$Force
    )
    
    $firefoxProcesses = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
    
    if ($firefoxProcesses) {
        if (-not $Force) {
            # Try graceful close first
            foreach ($proc in $firefoxProcesses) {
                $proc.CloseMainWindow() | Out-Null
            }
            Start-Sleep -Seconds 3
        }
        
        # Force close if still running
        if (Test-FirefoxRunning) {
            Stop-Process -Name "firefox" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
    
    return -not (Test-FirefoxRunning)
}

# Function to start Firefox, wait, and close it
function Initialize-FirefoxProfile {
    param (
        [string]$FirefoxPath,
        [int]$WaitSeconds = 10
    )
    
    Write-Host ""
    Write-Host "No Firefox profile found." -ForegroundColor Yellow
    Write-Host "Starting Firefox to generate profile..." -ForegroundColor Yellow
    Write-Host ""
    
    # Start Firefox
    Start-Process -FilePath $FirefoxPath
    
    Write-Host "Firefox started. Waiting $WaitSeconds seconds for profile creation..." -ForegroundColor Cyan
    Write-Host ""
    
    # Countdown timer
    for ($i = $WaitSeconds; $i -gt 0; $i--) {
        $progressPercent = (($WaitSeconds - $i) / $WaitSeconds) * 100
        Write-Progress -Activity "Waiting for Firefox profile creation" `
                       -Status "Closing Firefox in $i seconds..." `
                       -PercentComplete $progressPercent
        Start-Sleep -Seconds 1
    }
    
    Write-Progress -Activity "Waiting for Firefox profile creation" -Completed
    
    Write-Host "Closing Firefox automatically..." -ForegroundColor Yellow
    
    # Close Firefox
    if (Stop-Firefox) {
        Write-Host "Firefox closed successfully." -ForegroundColor Green
        Start-Sleep -Seconds 2
        return $true
    }
    else {
        Write-Host "Warning: Could not close Firefox cleanly." -ForegroundColor Yellow
        # Force close
        Stop-Firefox -Force
        Start-Sleep -Seconds 2
        return -not (Test-FirefoxRunning)
    }
}

# Main script
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Firefox Homepage Changer" -ForegroundColor Cyan
Write-Host "   Setting homepage to: google.de" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find Firefox installation
$firefoxPath = Get-FirefoxPath

if ($null -eq $firefoxPath) {
    Write-Host "ERROR: Firefox is not installed!" -ForegroundColor Red
    Write-Host "Please install Firefox and run this script again." -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "Firefox found at: $firefoxPath" -ForegroundColor Green
Write-Host ""

# Check if Firefox is running
if (Test-FirefoxRunning) {
    Write-Host "Firefox is currently running." -ForegroundColor Yellow
    Write-Host "Closing Firefox..." -ForegroundColor Yellow
    
    if (-not (Stop-Firefox)) {
        Write-Host "ERROR: Could not close Firefox!" -ForegroundColor Red
        Write-Host "Please close Firefox manually and run this script again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Firefox closed successfully." -ForegroundColor Green
    Write-Host ""
}

# Get Firefox profiles
$profiles = Get-FirefoxProfiles

# Check if profiles exist and have prefs.js
$validProfiles = @()
if ($null -ne $profiles) {
    foreach ($profile in $profiles) {
        $prefsFile = Join-Path -Path $profile.FullName -ChildPath "prefs.js"
        if (Test-Path $prefsFile) {
            $validProfiles += $profile
        }
    }
}

# If no valid profiles, start Firefox to create one
if ($validProfiles.Count -eq 0) {
    if (-not (Initialize-FirefoxProfile -FirefoxPath $firefoxPath -WaitSeconds 10)) {
        Write-Host "ERROR: Failed to initialize Firefox profile!" -ForegroundColor Red
        exit 1
    }
    
    # Get profiles again
    $profiles = Get-FirefoxProfiles
    $validProfiles = @()
    
    if ($null -ne $profiles) {
        foreach ($profile in $profiles) {
            $prefsFile = Join-Path -Path $profile.FullName -ChildPath "prefs.js"
            if (Test-Path $prefsFile) {
                $validProfiles += $profile
            }
        }
    }
    
    if ($validProfiles.Count -eq 0) {
        Write-Host "ERROR: No valid profiles found after initialization!" -ForegroundColor Red
        Write-Host "Try running the script again." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Found $($validProfiles.Count) Firefox profile(s) to update:" -ForegroundColor White
Write-Host ""

$successCount = 0

foreach ($profile in $validProfiles) {
    Write-Host "Processing profile: $($profile.Name)" -ForegroundColor Cyan
    
    $prefsFile = Join-Path -Path $profile.FullName -ChildPath "prefs.js"
    
    if (Test-Path $prefsFile) {
        # Create backup
        $backupFile = Join-Path -Path $profile.FullName -ChildPath "prefs.js.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $prefsFile -Destination $backupFile
        Write-Host "  Backup created: $(Split-Path $backupFile -Leaf)" -ForegroundColor Gray
        
        # Read current content
        $content = Get-Content -Path $prefsFile -Raw
        
        if ($null -eq $content) {
            $content = ""
        }
        
        # Homepage URL
        $homepageUrl = "https://www.google.de"
        
        # Set browser.startup.homepage
        $prefName = "browser.startup.homepage"
        $prefValue = "`"$homepageUrl`""
        $pattern = "user_pref\(`"$([regex]::Escape($prefName))`",\s*.*?\);"
        $newPref = "user_pref(`"$prefName`", $prefValue);"
        
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $newPref
            Write-Host "  Updated: $prefName" -ForegroundColor Yellow
        }
        else {
            if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
                $content += "`n"
            }
            $content += "$newPref`n"
            Write-Host "  Added: $prefName" -ForegroundColor Green
        }
        
        # Set browser.startup.page to 1 (show homepage)
        $prefName = "browser.startup.page"
        $prefValue = "1"
        $pattern = "user_pref\(`"$([regex]::Escape($prefName))`",\s*.*?\);"
        $newPref = "user_pref(`"$prefName`", $prefValue);"
        
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $newPref
            Write-Host "  Updated: $prefName" -ForegroundColor Yellow
        }
        else {
            if (-not $content.EndsWith("`n")) {
                $content += "`n"
            }
            $content += "$newPref`n"
            Write-Host "  Added: $prefName" -ForegroundColor Green
        }
        
        # Write the modified content back
        Set-Content -Path $prefsFile -Value $content -NoNewline -Encoding UTF8
        
        Write-Host "  Homepage set successfully!" -ForegroundColor Green
        $successCount++
    }
    else {
        Write-Host "  prefs.js not found in this profile" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Profiles found: $($validProfiles.Count)" -ForegroundColor White
Write-Host "  Successfully updated: $successCount" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "SUCCESS! Homepage has been set to google.de" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now start Firefox." -ForegroundColor White
    Write-Host "Users can change this setting later in:" -ForegroundColor Gray
    Write-Host "  Settings > Home > Homepage and new windows" -ForegroundColor Gray
}
else {
    Write-Host "No profiles were updated." -ForegroundColor Yellow
}

Write-Host ""