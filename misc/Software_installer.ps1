<#
.SYNOPSIS
    Installs a suite of common applications using winget, with Chocolatey as a fallback.
    This version uses a robust method to ensure the winget progress bar is visible.

.DESCRIPTION
    This script provides a resilient method for installing a predefined list of software.
    It explicitly uses Start-Process to ensure winget's native UI, including the
    progress bar, is rendered correctly in a proper terminal (like Windows Terminal).

.NOTES
    Author: Your Name
    Date:   October 26, 2023
    Requires: PowerShell 5.1 or later, running as an Administrator.
    IMPORTANT: For the progress bar to be visible, run this script in Windows Terminal
               or a standard PowerShell console, NOT the PowerShell ISE.
#>

#requires -RunAsAdministrator

# --- Script Configuration ---
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Define the List of Applications to Install ---
$applications = @(
    [PSCustomObject]@{
        Name     = "Mozilla Firefox"
        WingetId = "Mozilla.Firefox"
        ChocoId  = "firefox"
    },
    [PSCustomObject]@{
        Name     = "Mozilla Thunderbird"
        WingetId = "Mozilla.Thunderbird"
        ChocoId  = "thunderbird"
    },
    [PSCustomObject]@{
        Name     = "LibreOffice"
        WingetId = "TheDocumentFoundation.LibreOffice"
        ChocoId  = "libreoffice-fresh"
    },
    [PSCustomObject]@{
        Name     = "VLC media player"
        WingetId = "VideoLAN.VLC"
        ChocoId  = "vlc"
    },
    [PSCustomObject]@{
        Name     = "WinRAR"
        WingetId = "RARLab.WinRAR"
        ChocoId  = "winrar"
    }
)

# --- Helper Function to Invoke Winget and Show Progress ---
function Invoke-WingetWithProgress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WingetId
    )

    Write-Host "Executing winget for '$WingetId'..." -ForegroundColor Gray
    
    # Construct the arguments for winget.exe
    $ArgumentList = "install --id $WingetId --source winget --silent --accept-package-agreements --accept-source-agreements"

    # Use Start-Process, which is more reliable for console UI rendering
    $process = Start-Process -FilePath "winget" -ArgumentList $ArgumentList -Wait -NoNewWindow -PassThru
    
    # Check the exit code. A non-zero code indicates failure.
    if ($process.ExitCode -ne 0) {
        # Throw a terminating error to be caught by the calling function's try/catch block
        throw "Winget failed with exit code $($process.ExitCode) for package '$WingetId'."
    }
}

# --- Reusable Installation Function ---
function Install-Application {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$App
    )

    Write-Host "--------------------------------------------------" -ForegroundColor Magenta
    Write-Host "Processing: $($App.Name)" -ForegroundColor Magenta
    Write-Host "--------------------------------------------------"

    # Step 1: Check if installed
    Write-Host "Step 1: Checking if $($App.Name) is already installed..." -ForegroundColor Cyan
    $installedPackage = Get-Package -Name "*$($App.Name)*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$($App.Name)*" } | Select-Object -First 1

    if ($installedPackage) {
        Write-Host "SUCCESS: $($App.Name) is already installed (Version: $($installedPackage.Version)). Skipping." -ForegroundColor Green
        return "Skipped"
    } else {
        Write-Host "$($App.Name) not found. Proceeding with installation."
    }

    # Step 2: Try installing with winget
    try {
        Write-Host "`nStep 2: Attempting to install with winget (progress bar enabled)..." -ForegroundColor Cyan
        
        # --- KEY CHANGE IS HERE ---
        # Call our robust helper function instead of calling winget directly.
        Invoke-WingetWithProgress -WingetId $App.WingetId

    } catch {
        # This block catches the 'throw' from our helper function or other errors
        Write-Warning "winget installation failed for $($App.Name). $_"
        Write-Warning "Falling back to Chocolatey."

        # Step 3: Fallback to Chocolatey
        try {
            Write-Host "`nStep 3: Attempting to install with Chocolatey..." -ForegroundColor Cyan

            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                Write-Host "Chocolatey not found. Installing it now..." -ForegroundColor Yellow
                Set-ExecutionPolicy Bypass -Scope Process -Force;
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }

            Write-Host "Executing: choco install $($App.ChocoId) -y"
            choco install $App.ChocoId -y
        } catch {
            Write-Error "FATAL: Chocolatey installation also failed for $($App.Name)."
            return "Failed"
        }
    }

    # Step 4: Final Verification
    Write-Host "`nStep 4: Verifying installation of $($App.Name)..." -ForegroundColor Cyan
    $finalCheck = Get-Package -Name "*$($App.Name)*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$($App.Name)*" } | Select-Object -First 1
    if ($finalCheck) {
        Write-Host "SUCCESS: $($App.Name) was installed successfully (Version: $($finalCheck.Version))." -ForegroundColor Green
        return "Installed"
    } else {
        Write-Error "FAILURE: Both winget and Chocolatey methods failed to install $($App.Name)."
        return "Failed"
    }
}

# --- Main Script Execution ---
$installedApps = [System.Collections.Generic.List[string]]::new()
$skippedApps = [System.Collections.Generic.List[string]]::new()
$failedApps = [System.Collections.Generic.List[string]]::new()

foreach ($app in $applications) {
    try {
        $status = Install-Application -App $app
        switch ($status) {
            "Installed" { $installedApps.Add($app.Name) }
            "Skipped"   { $skippedApps.Add($app.Name) }
            "Failed"    { $failedApps.Add($app.Name) }
        }
    } catch {
        Write-Error "A critical error occurred while processing $($app.Name): $_"
        $failedApps.Add($app.Name)
    }
}

# --- Final Summary Report ---
Write-Host "`n==================================================" -ForegroundColor Yellow
Write-Host "               Installation Summary" -ForegroundColor Yellow
Write-Host "=================================================="
if ($installedApps.Count -gt 0) {
    Write-Host "`nSuccessfully Installed:" -ForegroundColor Green
    $installedApps | ForEach-Object { Write-Host " - $_" }
}
if ($skippedApps.Count -gt 0) {
    Write-Host "`nSkipped (Already Installed):" -ForegroundColor Cyan
    $skippedApps | ForEach-Object { Write-Host " - $_" }
}
if ($failedApps.Count -gt 0) {
    Write-Host "`nFailed to Install:" -ForegroundColor Red
    $failedApps | ForEach-Object { Write-Host " - $_" }
}

Write-Host "`nScript execution finished."