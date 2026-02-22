#requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$applications = @(
    [PSCustomObject]@{
        Name     = "Mozilla Firefox"
        WingetId = "Mozilla.Firefox.de"
        ChocoId  = "firefox"
    },
    [PSCustomObject]@{
        Name     = "Mozilla Thunderbird"
        WingetId = "Mozilla.Thunderbird.de"
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

function Invoke-WingetWithProgress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WingetId
    )

    Write-Host "Executing winget for '$WingetId'..." -ForegroundColor Gray
    
    $ArgumentList = "install --id $WingetId --source winget --silent --accept-package-agreements --accept-source-agreements"

    $process = Start-Process -FilePath "winget" -ArgumentList $ArgumentList -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -ne 0) {
        throw "Winget failed with exit code $($process.ExitCode) for package '$WingetId'."
    }
}

function Install-Application {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$App
    )

    Write-Host "--------------------------------------------------" -ForegroundColor Magenta
    Write-Host "Processing: $($App.Name)" -ForegroundColor Magenta
    Write-Host "--------------------------------------------------"

    Write-Host "Step 1: Checking if $($App.Name) is already installed..." -ForegroundColor Cyan
    $installedPackage = Get-Package -Name "*$($App.Name)*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$($App.Name)*" } | Select-Object -First 1

    if ($installedPackage) {
        Write-Host "SUCCESS: $($App.Name) is already installed (Version: $($installedPackage.Version)). Skipping." -ForegroundColor Green
        return "Skipped"
    } else {
        Write-Host "$($App.Name) not found. Proceeding with installation."
    }

    try {
        Write-Host "`nStep 2: Attempting to install with winget (progress bar enabled)..." -ForegroundColor Cyan
        
        Invoke-WingetWithProgress -WingetId $App.WingetId

    } catch {
        Write-Warning "winget installation failed for $($App.Name). $_"
        Write-Warning "Falling back to Chocolatey."

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