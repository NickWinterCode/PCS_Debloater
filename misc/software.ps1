#Requires -RunAsAdministrator
# ============================================
# MULTI-SOFTWARE DOWNLOADER & INSTALLER
# Downloads and installs German versions
# Using curl.exe for reliable downloads
# ============================================

# Configuration
$destination = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Use the system's temp path - works with ALL usernames (ÖÜÄ, spaces, symbols, etc.)
$tempFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "SoftwareDownloads_Temp"
$cleanupAfterInstall = $true

# LOAD SOFTWARE CONFIGURATION
# ============================================

$configPath = Join-Path $destination "software_config.json"
$softwareConfig = $null

if (Test-Path $configPath) {
    try {
        $softwareConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "Loaded software configuration from config file" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error reading config file, using defaults (install all)" -ForegroundColor Yellow
        $softwareConfig = $null
    }
}
else {
    Write-Host "No config file found, installing all software by default" -ForegroundColor Cyan
}

# Helper function to check if software should be installed
function Test-SoftwareEnabled {
    param([string]$Name)
    
    # If no config, install all by default
    if ($null -eq $softwareConfig) {
        return $true
    }
    
    # Check if the property exists and is true
    if ($softwareConfig.PSObject.Properties.Name -contains $Name) {
        return $softwareConfig.$Name -eq $true
    }
    
    # Default to true if not specified
    return $true
}

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Software Configuration (Full list)
$allSoftware = @(
    @{
        Name = "Firefox"
        Url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=de"
        FileName = "Firefox_Setup_DE.exe"
        InstallArgs = "-ms"
        MinSize = 50
        RequiresOpticalDrive = $false
        IsMSI = $false
    },
    @{
        Name = "Thunderbird"
        Url = "https://download.mozilla.org/?product=thunderbird-latest-ssl&os=win64&lang=de"
        FileName = "Thunderbird_Setup_DE.exe"
        InstallArgs = "-ms"
        MinSize = 50
        RequiresOpticalDrive = $false
        IsMSI = $false
    },
    @{
        Name = "LibreOffice"
        Url = $null
        FileName = $null
        InstallArgs = "/qn /norestart ALLUSERS=1"
        MinSize = 100
        IsMSI = $true
        RequiresOpticalDrive = $false
    },
    @{
        Name = "VLC"
        Url = $null
        FileName = $null
        InstallArgs = "/S /L=1031"
        MinSize = 40
        RequiresOpticalDrive = $false
        IsMSI = $false
    },
    @{
        Name = "WinRAR"
        Url = $null
        FileName = $null
        InstallArgs = "/S"
        MinSize = 3
        RequiresOpticalDrive = $false
        IsMSI = $false
    },
    @{
        Name = "CDBurnerXP"
        Url = "https://drive.powerfolder.com/dl/fi3bHeD2CaRqgR9p5egiCBbt/cdbxp_setup_4.5.8.7128_x64_minimal.exe"
        FileName = "cdbxp_setup_x64.exe"
        InstallArgs = "/VERYSILENT /LANG=de /LANG=German"
        MinSize = 5
        RequiresOpticalDrive = $true
        IsMSI = $false
    }
)

# Filter software based on configuration
$software = @()
$skippedByConfig = @()

foreach ($app in $allSoftware) {
    if (Test-SoftwareEnabled -Name $app.Name) {
        $software += $app
    }
    else {
        $skippedByConfig += $app.Name
    }
}

# Show what's enabled/disabled
if ($skippedByConfig.Count -gt 0) {
    Write-Host "`nSoftware disabled by configuration:" -ForegroundColor Yellow
    foreach ($name in $skippedByConfig) {
        Write-Host "  [-] $name" -ForegroundColor DarkGray
    }
}

if ($software.Count -gt 0) {
    Write-Host "`nSoftware enabled for installation:" -ForegroundColor Green
    foreach ($app in $software) {
        Write-Host "  [+] $($app.Name)" -ForegroundColor Green
    }
}
else {
    Write-Host "`nNo software selected for installation!" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    [System.Console]::ReadKey($true) | Out-Null
    exit 0
}

Write-Host ""

# HELPER FUNCTIONS
# ============================================

function Show-Banner {
    Clear-Host
    
    # Build dynamic software list for banner
    $enabledNames = ($software | ForEach-Object { $_.Name }) -join " | "
    
    Write-Host @"

  +============================================+
  |   SOFTWARE DOWNLOADER & INSTALLER (DE)    |
  +============================================+
  Selected: $enabledNames

"@ -ForegroundColor Cyan
}

function Test-AdminRights {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-OpticalDrive {
    try {
        $cdDrives = @(Get-CimInstance -ClassName Win32_CDROMDrive -ErrorAction SilentlyContinue)
        if ($cdDrives.Count -gt 0) {
            return @{ Detected = $true; Count = $cdDrives.Count; Message = "Found $($cdDrives.Count) optical drive(s)" }
        }
        return @{ Detected = $false; Count = 0; Message = "No optical drive detected" }
    }
    catch {
        return @{ Detected = $false; Count = 0; Message = "Error detecting optical drives" }
    }
}

function Compare-Version {
    param([string]$Installed, [string]$Latest)
    
    if ([string]::IsNullOrWhiteSpace($Installed) -or [string]::IsNullOrWhiteSpace($Latest)) {
        return "Unknown"
    }
    
    try {
        $installedClean = ($Installed -replace '[^\d\.]', '').Trim('.')
        $latestClean = ($Latest -replace '[^\d\.]', '').Trim('.')
        
        $instParts = @($installedClean.Split('.') | Where-Object { $_ -ne '' })
        $latParts = @($latestClean.Split('.') | Where-Object { $_ -ne '' })
        $maxParts = [Math]::Max($instParts.Count, $latParts.Count)
        
        for ($i = 0; $i -lt $maxParts; $i++) {
            $instNum = 0; $latNum = 0
            if ($i -lt $instParts.Count) { [int]::TryParse($instParts[$i], [ref]$instNum) | Out-Null }
            if ($i -lt $latParts.Count) { [int]::TryParse($latParts[$i], [ref]$latNum) | Out-Null }
            
            if ($instNum -lt $latNum) { return "Outdated" }
            if ($instNum -gt $latNum) { return "Newer" }
        }
        return "Current"
    }
    catch { return "Unknown" }
}

function Get-InstalledVersion {
    param([string]$AppName)
    
    try {
        switch ($AppName) {
            "Firefox" {
                $paths = @("HKLM:\SOFTWARE\Mozilla\Mozilla Firefox", "HKLM:\SOFTWARE\WOW6432Node\Mozilla\Mozilla Firefox")
                foreach ($path in $paths) {
                    if (Test-Path $path) {
                        $version = (Get-ItemProperty $path -ErrorAction SilentlyContinue).CurrentVersion
                        if ($version -match '(\d+[\.\d]*)') { return $matches[1] }
                    }
                }
                $exe = "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
                if (Test-Path $exe) { return (Get-Item $exe).VersionInfo.ProductVersion }
            }
            "Thunderbird" {
                $paths = @("HKLM:\SOFTWARE\Mozilla\Mozilla Thunderbird", "HKLM:\SOFTWARE\WOW6432Node\Mozilla\Mozilla Thunderbird")
                foreach ($path in $paths) {
                    if (Test-Path $path) {
                        $version = (Get-ItemProperty $path -ErrorAction SilentlyContinue).CurrentVersion
                        if ($version -match '(\d+[\.\d]*)') { return $matches[1] }
                    }
                }
                $exe = "$env:ProgramFiles\Mozilla Thunderbird\thunderbird.exe"
                if (Test-Path $exe) { return (Get-Item $exe).VersionInfo.ProductVersion }
            }
            "LibreOffice" {
                $paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
                foreach ($path in $paths) {
                    $app = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*LibreOffice*" } | Select-Object -First 1
                    if ($app.DisplayVersion) { return $app.DisplayVersion }
                }
            }
            "VLC" {
                $regPath = "HKLM:\SOFTWARE\VideoLAN\VLC"
                if (Test-Path $regPath) {
                    $version = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).Version
                    if ($version) { return $version }
                }
                $exe = "$env:ProgramFiles\VideoLAN\VLC\vlc.exe"
                if (Test-Path $exe) { return (Get-Item $exe).VersionInfo.ProductVersion }
            }
            "WinRAR" {
                $exe = "$env:ProgramFiles\WinRAR\WinRAR.exe"
                if (Test-Path $exe) {
                    $ver = (Get-Item $exe).VersionInfo.ProductVersion
                    if ($ver -match '(\d+\.\d+)') { return $matches[1] }
                }
            }
            "CDBurnerXP" {
                $paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
                foreach ($path in $paths) {
                    $app = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*CDBurnerXP*" } | Select-Object -First 1
                    if ($app.DisplayVersion) { return $app.DisplayVersion }
                }
            }
        }
        return $null
    }
    catch { return $null }
}

function Get-LatestVersion {
    param([string]$AppName)
    
    try {
        switch ($AppName) {
            "Firefox" {
                $response = Invoke-RestMethod -Uri "https://product-details.mozilla.org/1.0/firefox_versions.json" -TimeoutSec 15
                return $response.LATEST_FIREFOX_VERSION
            }
            "Thunderbird" {
                $response = Invoke-RestMethod -Uri "https://product-details.mozilla.org/1.0/thunderbird_versions.json" -TimeoutSec 15
                return $response.LATEST_THUNDERBIRD_VERSION
            }
            "LibreOffice" {
                $response = Invoke-WebRequest -Uri "https://www.libreoffice.org/download/download/" -UseBasicParsing -TimeoutSec 15
                if ($response.Content -match 'data-version="(\d+\.\d+\.\d+)"') { return $matches[1] }
                if ($response.Content -match 'Version (\d+\.\d+\.\d+)') { return $matches[1] }
                if ($response.Content -match '/(\d+\.\d+\.\d+)/') { return $matches[1] }
                return "26.2.0"
            }
            "VLC" {
                $response = Invoke-WebRequest -Uri "https://download.videolan.org/pub/videolan/vlc/last/win64/" -UseBasicParsing -TimeoutSec 15
                $link = $response.Links | Where-Object { $_.href -match "vlc-(.+)-win64\.exe$" } | Select-Object -First 1
                if ($link -and $link.href -match "vlc-(.+)-win64\.exe") { return $matches[1] }
                return "3.0.23"
            }
            "WinRAR" {
                try {
                    $info = & winget show RARLab.WinRAR --accept-package-agreements --accept-source-agreements 2>$null | Out-String
                    if ($info -match 'Version[:\s]+(\d+\.\d+)') { return $matches[1] }
                }
                catch { }
                return "7.20"
            }
            "CDBurnerXP" { return "4.5.8.7128" }
        }
    }
    catch {
        switch ($AppName) {
            "Firefox" { return "138.0" }
            "Thunderbird" { return "138.0" }
            "LibreOffice" { return "24.8.4" }
            "VLC" { return "3.0.21" }
            "WinRAR" { return "7.20" }
            "CDBurnerXP" { return "4.5.8.7128" }
        }
    }
    return $null
}

# GET DOWNLOAD INFO FUNCTIONS
# ============================================

function Get-LibreOfficeDownloadInfo {
    Write-Host "  Fetching LibreOffice version..." -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri "https://www.libreoffice.org/download/download/" -UseBasicParsing -TimeoutSec 15
        
        $version = $null
        if ($response.Content -match 'data-version="(\d+\.\d+\.\d+)"') { $version = $matches[1] }
        elseif ($response.Content -match 'Version (\d+\.\d+\.\d+)') { $version = $matches[1] }
        elseif ($response.Content -match '/(\d+\.\d+\.\d+)/') { $version = $matches[1] }
        
        if (-not $version) { throw "Version not found" }
        
        Write-Host "  Found version: $version" -ForegroundColor Green
    }
    catch {
        Write-Host "  Could not detect version, using fallback..." -ForegroundColor Yellow
        $version = "24.8.4"
    }
    
    $filename = "LibreOffice_${version}_Win_x86-64.msi"
    $url = "https://download.documentfoundation.org/libreoffice/stable/$version/win/x86_64/$filename"
    
    return @{
        Version  = $version
        Url      = $url
        FileName = $filename
    }
}

function Get-VLCDownloadInfo {
    Write-Host "  Fetching VLC version..." -ForegroundColor Gray
    
    try {
        $baseUrl = "https://download.videolan.org/pub/videolan/vlc/last/win64/"
        $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec 15
        $link = $response.Links | Where-Object { $_.href -match "vlc-.+-win64\.exe$" } | Select-Object -First 1
        
        if ($link) {
            $fileName = $link.href
            $version = if ($fileName -match "vlc-(.+)-win64\.exe") { $matches[1] } else { "unknown" }
            
            Write-Host "  Found version: $version" -ForegroundColor Green
            
            return @{
                Version  = $version
                Url      = $baseUrl + $fileName
                FileName = $fileName
            }
        }
        throw "VLC not found"
    }
    catch {
        throw "Failed to get VLC info: $_"
    }
}

function Get-WinRARDownloadInfo {
    param([string]$Version)
    
    Write-Host "  Fetching WinRAR version..." -ForegroundColor Gray
    
    if (-not $Version) {
        try {
            $info = & winget show RARLab.WinRAR 2>$null | Out-String
            if ($info -match 'Version[:\s]+(\d+)\.(\d+)') {
                $Version = "$($matches[1]).$($matches[2])"
            }
        }
        catch { }
        
        if (-not $Version) { $Version = "7.20" }
    }
    
    Write-Host "  Found version: $Version" -ForegroundColor Green
    
    $parts = $Version.Split('.')
    $versionCode = "$($parts[0])$($parts[1].PadLeft(2,'0'))"
    $filename = "winrar-x64-${versionCode}d.exe"
    
    return @{
        Version  = $Version
        Url      = "https://www.win-rar.com/fileadmin/winrar-versions/winrar/$filename"
        FileName = $filename
    }
}

# DOWNLOAD FUNCTION (USING CURL)
# ============================================

function Start-Download {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$DisplayName
    )
    
    Write-Host ""
    Write-Host "  Downloading $DisplayName..." -ForegroundColor Yellow
    Write-Host "  URL: $Url" -ForegroundColor Gray
    Write-Host "  Destination: $OutFile" -ForegroundColor Gray
    Write-Host ""
    
    # Escape the output path for curl - handles spaces, umlauts, and special characters
    $escapedOutFile = $OutFile -replace '"', '\"'
    
    # Use Start-Process to properly handle paths with special characters
    $curlArgs = @(
        '-L'
        $Url
        '-o'
        "`"$escapedOutFile`""
        '--progress-bar'
        '--connect-timeout'
        '60'
        '--retry'
        '3'
    )
    
    # Execute curl with proper argument handling
    $process = Start-Process -FilePath "curl.exe" -ArgumentList $curlArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0 -and (Test-Path -LiteralPath $OutFile)) {
        $fileSize = (Get-Item -LiteralPath $OutFile).Length / 1MB
        if ($fileSize -gt 1) {
            Write-Host ""
            Write-Host "  Download completed: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  Download failed - file too small" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "  Download failed" -ForegroundColor Red
        return $false
    }
}
# INSTALL FUNCTION
# ============================================

function Install-Software {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [string]$Name,
        [bool]$IsMSI = $false
    )
    
    Write-Host "  Installing $Name..." -ForegroundColor Yellow
    
    try {
        if ($IsMSI) {
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$FilePath`" $Arguments" -Wait -PassThru -NoNewWindow
        }
        else {
            $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        }
        
        # Exit codes: 0 = success, 3010 = success + reboot needed, 1641 = success + reboot initiated
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010 -or $process.ExitCode -eq 1641) {
            Write-Host "  Installation completed successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  Installation finished with exit code: $($process.ExitCode)" -ForegroundColor Yellow
            return $true  # Many installers use non-zero codes for success
        }
    }
    catch {
        Write-Host "  Installation error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# MAIN EXECUTION
# ============================================

Show-Banner

# Check admin rights
if (-not (Test-AdminRights)) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check for curl
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: curl.exe not found!" -ForegroundColor Red
    Write-Host "curl.exe is required for downloads (included in Windows 10+)" -ForegroundColor Yellow
    exit 1
}

# Check for optical drives (only if CDBurnerXP is in the list)
$opticalDriveInfo = @{ Detected = $true; Count = 0; Message = "Not checked" }
$hasCDBurnerXP = $software | Where-Object { $_.Name -eq "CDBurnerXP" }

if ($hasCDBurnerXP) {
    Write-Host "Checking hardware..." -ForegroundColor Yellow
    $opticalDriveInfo = Test-OpticalDrive

    if ($opticalDriveInfo.Detected) {
        Write-Host "[OK] $($opticalDriveInfo.Message)" -ForegroundColor Green
    }
    else {
        Write-Host "[--] $($opticalDriveInfo.Message) - CDBurnerXP will be skipped" -ForegroundColor Yellow
    }
}

# Filter software based on optical drive
$softwareToProcess = @()
$skippedOptical = @()

foreach ($app in $software) {
    if ($app.RequiresOpticalDrive -and -not $opticalDriveInfo.Detected) {
        $skippedOptical += $app
    }
    else {
        $softwareToProcess += $app
    }
}

# Check if anything left to install
if ($softwareToProcess.Count -eq 0) {
    Write-Host "`nNo software to install after filtering!" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    [System.Console]::ReadKey($true) | Out-Null
    exit 0
}

# VERSION CHECK
# ============================================

Write-Host "`nChecking installed versions..." -ForegroundColor Cyan
Write-Host ("-" * 60) -ForegroundColor Gray

$versionInfo = @{}
$toInstall = @()
$upToDate = @()

foreach ($app in $softwareToProcess) {
    $name = $app.Name
    Write-Host "  $($name.PadRight(15)) : " -NoNewline
    
    $installedVersion = Get-InstalledVersion -AppName $name
    $latestVersion = Get-LatestVersion -AppName $name
    
    $versionInfo[$name] = @{
        Installed = $installedVersion
        Latest    = $latestVersion
    }
    
    if ($installedVersion) {
        $comparison = Compare-Version -Installed $installedVersion -Latest $latestVersion
        
        switch ($comparison) {
            "Current" {
                Write-Host "v$installedVersion " -NoNewline -ForegroundColor Green
                Write-Host "(up to date)" -ForegroundColor Green
                $upToDate += $name
            }
            "Newer" {
                Write-Host "v$installedVersion " -NoNewline -ForegroundColor Cyan
                Write-Host "(newer than $latestVersion)" -ForegroundColor Cyan
                $upToDate += $name
            }
            "Outdated" {
                Write-Host "v$installedVersion " -NoNewline -ForegroundColor Yellow
                Write-Host "-> v$latestVersion" -ForegroundColor Yellow
                $toInstall += $app
            }
            default {
                Write-Host "v$installedVersion " -NoNewline -ForegroundColor Yellow
                Write-Host "(latest: $latestVersion)" -ForegroundColor Gray
                $toInstall += $app
            }
        }
    }
    else {
        Write-Host "Not installed " -NoNewline -ForegroundColor Red
        Write-Host "(v$latestVersion available)" -ForegroundColor Gray
        $toInstall += $app
    }
}

Write-Host ("-" * 60) -ForegroundColor Gray

# Summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Up to date:      $($upToDate.Count)" -ForegroundColor Green
Write-Host "  To install:      $($toInstall.Count)" -ForegroundColor Yellow
if ($skippedByConfig.Count -gt 0) {
    Write-Host "  Disabled:        $($skippedByConfig.Count) (by configuration)" -ForegroundColor DarkGray
}
if ($skippedOptical.Count -gt 0) {
    Write-Host "  Skipped:         $($skippedOptical.Count) (no optical drive)" -ForegroundColor Gray
}

# Exit if nothing to install
if ($toInstall.Count -eq 0) {
    Write-Host "`n+============================================+" -ForegroundColor Green
    Write-Host "|     All software is already up to date!   |" -ForegroundColor Green
    Write-Host "+============================================+" -ForegroundColor Green
    
    # Run icon arrangement
    & "$PSScriptRoot\Arrange-DesktopIcons.ps1" -InstalledSoftware $softwareToProcess.Name
    exit 0
}

# Confirm
Write-Host ""
$confirm = 'Y'
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Create temp folder - use -LiteralPath for special characters
if (-not (Test-Path -LiteralPath $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
}

Write-Host "`nDownload folder: $tempFolder" -ForegroundColor Cyan

# Results tracking
$results = @{
    Installed = @()
    Failed    = @()
    Skipped   = @()
    UpToDate  = $upToDate
}

foreach ($skip in $skippedOptical) {
    $results.Skipped += "$($skip.Name) (no optical drive)"
}

foreach ($skip in $skippedByConfig) {
    $results.Skipped += "$skip (disabled in config)"
}

# PROCESS EACH SOFTWARE
# ============================================

$totalCount = $toInstall.Count
$currentCount = 0

foreach ($app in $toInstall) {
    $currentCount++
    $name = $app.Name
    
    Write-Host "`n=============================================" -ForegroundColor Cyan
    Write-Host "[$currentCount/$totalCount] $($name.ToUpper())" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    $latVer = $versionInfo[$name].Latest
    $instVer = $versionInfo[$name].Installed
    
    if ($instVer) {
        Write-Host "  Updating: v$instVer -> v$latVer" -ForegroundColor Yellow
    }
    else {
        Write-Host "  New installation: v$latVer" -ForegroundColor Yellow
    }
    
    # Get download info
    $downloadUrl = $app.Url
    $fileName = $app.FileName
    
    try {
        switch ($name) {
            "LibreOffice" {
                $info = Get-LibreOfficeDownloadInfo
                $downloadUrl = $info.Url
                $fileName = $info.FileName
                $versionInfo[$name].Latest = $info.Version
            }
            "VLC" {
                $info = Get-VLCDownloadInfo
                $downloadUrl = $info.Url
                $fileName = $info.FileName
                $versionInfo[$name].Latest = $info.Version
            }
            "WinRAR" {
                $info = Get-WinRARDownloadInfo -Version $latVer
                $downloadUrl = $info.Url
                $fileName = $info.FileName
                $versionInfo[$name].Latest = $info.Version
            }
        }
    }
    catch {
        Write-Host "  [X] Failed to get download info: $($_.Exception.Message)" -ForegroundColor Red
        $results.Failed += "$name (URL error)"
        continue
    }
    
    if (-not $downloadUrl -or -not $fileName) {
        Write-Host "  [X] No download URL available" -ForegroundColor Red
        $results.Failed += "$name (no URL)"
        continue
    }
    
    # In the main processing loop, use Join-Path and -LiteralPath
    $filePath = Join-Path -Path $tempFolder -ChildPath $fileName

    # Download
    $downloadSuccess = Start-Download -Url $downloadUrl -OutFile $filePath -DisplayName $name

    if ($downloadSuccess -and (Test-Path -LiteralPath $filePath)) {
        $fileSize = (Get-Item -LiteralPath $filePath).Length / 1MB
            
        if ($fileSize -ge $app.MinSize) {
            # Install
            $installSuccess = Install-Software -FilePath $filePath -Arguments $app.InstallArgs -Name $name -IsMSI $app.IsMSI
            
            if ($installSuccess) {
                $results.Installed += $name
            }
            else {
                $results.Failed += "$name (install error)"
            }
        }
        else {
            Write-Host "  [X] File too small ($([math]::Round($fileSize,1)) MB < $($app.MinSize) MB)" -ForegroundColor Red
            $results.Failed += "$name (incomplete download)"
        }
    }
    else {
        $results.Failed += "$name (download error)"
    }
}

# CLEANUP
# ============================================

if ($cleanupAfterInstall) {
    Write-Host "`nCleaning up temporary files..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Remove-Item -LiteralPath $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Done." -ForegroundColor Green
}

Write-Host "`n+============================================+" -ForegroundColor Cyan
Write-Host "|            INSTALLATION SUMMARY           |" -ForegroundColor Cyan
Write-Host "+============================================+" -ForegroundColor Cyan

if ($results.UpToDate.Count -gt 0) {
    Write-Host "`nAlready Up to Date ($($results.UpToDate.Count)):" -ForegroundColor Cyan
    foreach ($item in $results.UpToDate) {
        Write-Host "  [=] $item v$($versionInfo[$item].Installed)" -ForegroundColor Cyan
    }
}

if ($results.Installed.Count -gt 0) {
    Write-Host "`nInstalled/Updated ($($results.Installed.Count)):" -ForegroundColor Green
    foreach ($item in $results.Installed) {
        Write-Host "  [OK] $item v$($versionInfo[$item].Latest)" -ForegroundColor Green
    }
}

if ($results.Skipped.Count -gt 0) {
    Write-Host "`nSkipped ($($results.Skipped.Count)):" -ForegroundColor Yellow
    foreach ($item in $results.Skipped) {
        Write-Host "  [--] $item" -ForegroundColor Yellow
    }
}

if ($results.Failed.Count -gt 0) {
    Write-Host "`nFailed ($($results.Failed.Count)):" -ForegroundColor Red
    foreach ($item in $results.Failed) {
        Write-Host "  [X] $item" -ForegroundColor Red
    }
}

Write-Host "`n=============================================" -ForegroundColor Cyan

if ($results.Failed.Count -eq 0) {
    Write-Host "All operations completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "Some items failed. See details above." -ForegroundColor Yellow
}

# DESKTOP ICON ARRANGEMENT
# ============================================

Write-Output "`n----- Change Order of Desktop Icons -----"
try {
    . "$PSScriptRoot\REICON.ps1"
}
catch {
    Write-Output "Warning: Could not load REICON module"
}

$PublicDesktop = "$env:PUBLIC\Desktop"
Remove-Item "$PublicDesktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
Set-IconPositionWithSwap -Name "Dieser PC" -X 36 -Y 2
Set-IconPositionWithSwap -Name "Papierkorb" -X 36 -Y 102
Set-IconPositionWithSwap -Name "Firefox" -X 36 -Y 202
Set-IconPositionWithSwap -Name "Thunderbird" -X 36 -Y 302
Set-IconPositionWithSwap -Name "LibreOffice" -X 36 -Y 402
Set-IconPositionWithSwap -Name "Adobe Acrobat" -X 36 -Y 502
Set-IconPositionWithSwap -Name "VLC media player" -X 36 -Y 602
Set-IconPositionWithSwap -Name "PCSpezialist Fernwartung" -X 1836 -Y 2
Set-IconPositionWithSwap -Name "CDBurnerXP" -X 36 -Y 702

Write-Host ""