#Requires -RunAsAdministrator
# ============================================================================
# Software Installation Script (German)
# Downloads and installs latest versions using aria2c
# ASCII only version - Safe for special characters in paths
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ============================================================================
# Use a safe temp directory that avoids username path issues
# Using C:\Temp or ProgramData to avoid umlauts in username paths
# ============================================================================

# Try to find a safe temp location without special characters
function Get-SafeTempPath {
    # Priority 1: Root temp folder (safest, no username involved)
    $rootTemp = "$env:SystemDrive\Temp\SoftwareInstall"
    
    # Priority 2: ProgramData (usually C:\ProgramData, no username)
    $programDataTemp = "$env:ProgramData\SoftwareInstall"
    
    # Priority 3: Windows Temp (C:\Windows\Temp)
    $windowsTemp = "$env:SystemRoot\Temp\SoftwareInstall"
    
    # Test which one we can use
    foreach ($path in @($rootTemp, $programDataTemp, $windowsTemp)) {
        try {
            $testPath = Split-Path $path -Parent
            if (Test-Path $testPath) {
                # Check if path contains only ASCII characters
                $isAscii = $path -match '^[\x00-\x7F]+$'
                if ($isAscii) {
                    return $path
                }
            }
        }
        catch { }
    }
    
    # Fallback: Use C:\Temp directly
    return "C:\Temp\SoftwareInstall"
}

# ============================================================================
# Function: Get 8.3 short path name (for compatibility)
# ============================================================================
function Get-ShortPath {
    param([string]$LongPath)
    
    if (!(Test-Path $LongPath)) {
        return $LongPath
    }
    
    try {
        # Use FileSystemObject to get short path
        $fso = New-Object -ComObject Scripting.FileSystemObject
        
        if (Test-Path $LongPath -PathType Container) {
            $folder = $fso.GetFolder($LongPath)
            $shortPath = $folder.ShortPath
        }
        else {
            $file = $fso.GetFile($LongPath)
            $shortPath = $file.ShortPath
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($fso) | Out-Null
        
        if ($shortPath -and $shortPath.Length -gt 0) {
            return $shortPath
        }
    }
    catch { }
    
    return $LongPath
}

# ============================================================================
# Function: Create directory and return short path
# ============================================================================
function New-SafeDirectory {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    
    return (Get-ShortPath $Path)
}

# ============================================================================
# Initialize safe temp directory
# ============================================================================
$TempDirLong = Get-SafeTempPath
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$TempDirLong = "$TempDirLong`_$timestamp"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Software Installation Script (German)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create and get short path for temp directory
$TempDir = New-SafeDirectory -Path $TempDirLong
Write-Host "[INFO] Temp directory: $TempDir" -ForegroundColor Gray

$aria2Path = "$TempDir\aria2c.exe"

# ============================================================================
# Function: Download aria2c if not present
# ============================================================================
function Install-Aria2c {
    Write-Host "[INFO] Checking for aria2c..." -ForegroundColor Yellow
    
    if (Test-Path $aria2Path) {
        Write-Host "[OK] aria2c already present" -ForegroundColor Green
        return $true
    }
    
    try {
        $aria2Url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
        $aria2Zip = "$TempDir\aria2.zip"
        
        Write-Host "[INFO] Downloading aria2c..." -ForegroundColor Yellow
        
        # Use .NET WebClient for more reliable download with encoding handling
        $webClient = New-Object System.Net.WebClient
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        $webClient.DownloadFile($aria2Url, $aria2Zip)
        $webClient.Dispose()
        
        Write-Host "[INFO] Extracting aria2c..." -ForegroundColor Yellow
        
        # Use Shell.Application for extraction (more compatible)
        $shell = New-Object -ComObject Shell.Application
        $zipFile = $shell.NameSpace($aria2Zip)
        $destFolder = $shell.NameSpace($TempDir)
        $destFolder.CopyHere($zipFile.Items(), 16 + 4) # 16=Yes to All, 4=No UI
        
        Start-Sleep -Seconds 2
        
        # Find extracted folder and copy aria2c.exe
        $aria2Extracted = Get-ChildItem -Path $TempDir -Directory -Filter "aria2-*" | Select-Object -First 1
        if ($aria2Extracted) {
            $aria2Source = Join-Path $aria2Extracted.FullName "aria2c.exe"
            if (Test-Path $aria2Source) {
                Copy-Item $aria2Source $aria2Path -Force
            }
            Remove-Item $aria2Extracted.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Remove-Item $aria2Zip -Force -ErrorAction SilentlyContinue
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        
        if (Test-Path $aria2Path) {
            Write-Host "[OK] aria2c ready" -ForegroundColor Green
            return $true
        }
        else {
            throw "aria2c.exe not found after extraction"
        }
    }
    catch {
        Write-Host "[ERROR] Failed to download aria2c: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# Function: Download file using aria2c (with safe paths)
# ============================================================================
function Get-FileWithAria2 {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description
    )
    
    Write-Host "[INFO] Downloading $Description..." -ForegroundColor Yellow
    
    # Get short paths to avoid encoding issues
    $outputDir = Split-Path $OutputPath -Parent
    $outputDirShort = Get-ShortPath $outputDir
    $outputFile = Split-Path $OutputPath -Leaf
    
    # Ensure output filename is ASCII-safe
    $outputFile = $outputFile -replace '[^a-zA-Z0-9\.\-_]', '_'
    $finalOutputPath = Join-Path $outputDir $outputFile
    
    # Get short path for aria2c executable
    $aria2Short = Get-ShortPath $aria2Path
    
    # Build argument string (avoid special characters)
    $argList = "--dir=`"$outputDirShort`" --out=`"$outputFile`" --allow-overwrite=true --auto-file-renaming=false --max-connection-per-server=16 --min-split-size=1M --split=16 --continue=true --max-tries=5 --retry-wait=3 --connect-timeout=60 --timeout=600 --console-log-level=warn `"$Url`""
    
    # Create a batch file to run aria2c (avoids PowerShell encoding issues)
    $batchFile = "$TempDir\run_aria2c.cmd"
    $batchContent = "@echo off`r`nchcp 65001 >nul 2>&1`r`n`"$aria2Short`" $argList`r`nexit /b %errorlevel%"
    [System.IO.File]::WriteAllText($batchFile, $batchContent, [System.Text.Encoding]::ASCII)
    
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -Wait -PassThru -NoNewWindow -WorkingDirectory $outputDirShort
    
    Remove-Item $batchFile -Force -ErrorAction SilentlyContinue
    
    if ($process.ExitCode -eq 0 -and (Test-Path $finalOutputPath)) {
        Write-Host "[OK] Download complete: $Description" -ForegroundColor Green
        return $finalOutputPath
    }
    else {
        Write-Host "[ERROR] Download failed: $Description (Exit: $($process.ExitCode))" -ForegroundColor Red
        return $null
    }
}

# ============================================================================
# Function: Run installer safely (using short paths)
# ============================================================================
function Start-InstallerSafe {
    param(
        [string]$InstallerPath,
        [string[]]$Arguments,
        [string]$Description,
        [switch]$IsMSI
    )
    
    if (!(Test-Path $InstallerPath)) {
        Write-Host "[ERROR] Installer not found: $InstallerPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "[INFO] Installing $Description..." -ForegroundColor Yellow
    
    # Get short path to avoid encoding issues
    $installerShort = Get-ShortPath $InstallerPath
    
    try {
        if ($IsMSI) {
            # MSI installation
            $msiArgs = @("/i", "`"$installerShort`"") + $Arguments
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
        }
        else {
            # EXE installation - use batch file to avoid encoding issues
            $batchFile = "$TempDir\run_install.cmd"
            $argString = $Arguments -join " "
            $batchContent = "@echo off`r`n`"$installerShort`" $argString`r`nexit /b %errorlevel%"
            [System.IO.File]::WriteAllText($batchFile, $batchContent, [System.Text.Encoding]::ASCII)
            
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -Wait -PassThru -NoNewWindow
            
            Remove-Item $batchFile -Force -ErrorAction SilentlyContinue
        }
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "[OK] $Description installed successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[WARN] $Description installation may have issues (Exit: $($process.ExitCode))" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Host "[ERROR] Installation failed: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# Function: Check for optical drive (CD/DVD)
# ============================================================================
function Test-OpticalDrive {
    $drives = Get-CimInstance -ClassName Win32_CDROMDrive -ErrorAction SilentlyContinue
    if ($drives) {
        $driveCount = @($drives).Count
        Write-Host "[INFO] Found $driveCount optical drive(s)" -ForegroundColor Cyan
        return $true
    }
    return $false
}

# ============================================================================
# Function: Get latest VLC version
# ============================================================================
function Get-VLCDownloadUrl {
    try {
        $response = Invoke-WebRequest -Uri "https://www.videolan.org/vlc/download-windows.html" -UseBasicParsing
        if ($response.Content -match 'vlc-(\d+\.\d+\.\d+)-win64\.exe') {
            $version = $Matches[1]
            return "https://get.videolan.org/vlc/$version/win64/vlc-$version-win64.exe"
        }
    }
    catch { }
    return "https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe"
}

# ============================================================================
# Function: Get latest LibreOffice version
# ============================================================================
function Get-LibreOfficeDownloadUrl {
    try {
        $response = Invoke-WebRequest -Uri "https://www.libreoffice.org/download/download-libreoffice/" -UseBasicParsing
        if ($response.Content -match 'libreoffice/stable/(\d+\.\d+\.\d+)/') {
            $version = $Matches[1]
            return "https://download.documentfoundation.org/libreoffice/stable/$version/win/x86_64/LibreOffice_${version}_Win_x86-64.msi"
        }
    }
    catch { }
    return "https://download.documentfoundation.org/libreoffice/stable/24.2.7/win/x86_64/LibreOffice_24.2.7_Win_x86-64.msi"
}

# ============================================================================
# Function: Get latest WinRAR version (German)
# ============================================================================
function Get-WinRARDownloadUrl {
    try {
        $response = Invoke-WebRequest -Uri "https://www.rarlab.com/download.htm" -UseBasicParsing
        if ($response.Content -match 'winrar-x64-(\d+)d\.exe') {
            $version = $Matches[1]
            return "https://www.rarlab.com/rar/winrar-x64-${version}d.exe"
        }
    }
    catch { }
    return "https://www.rarlab.com/rar/winrar-x64-711d.exe"
}

# ============================================================================
# Function: Get latest CDBurnerXP version
# ============================================================================
function Get-CDBurnerXPDownloadUrl {
    try {
        $response = Invoke-WebRequest -Uri "https://cdburnerxp.se/de/download" -UseBasicParsing
        if ($response.Content -match 'cdbxp_setup_x64[_-]?([\d\.]+)\.exe') {
            $filename = $Matches[0]
            return "https://download.cdburnerxp.se/$filename"
        }
    }
    catch { }
    return "https://download.cdburnerxp.se/cdbxp_setup_x64_4.5.8.7128.exe"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Step 1: Install aria2c
if (!(Install-Aria2c)) {
    Write-Host "[FATAL] Cannot continue without aria2c" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Starting Software Installation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$installedApps = @()

# ============================================================================
# Install VLC Media Player
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " VLC Media Player" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$vlcUrl = Get-VLCDownloadUrl
$vlcInstaller = Get-FileWithAria2 -Url $vlcUrl -OutputPath "$TempDir\vlc-installer.exe" -Description "VLC Media Player"

if ($vlcInstaller) {
    # /L=1031 = German LCID
    if (Start-InstallerSafe -InstallerPath $vlcInstaller -Arguments @("/L=1031", "/S") -Description "VLC") {
        $installedApps += "VLC Media Player (German)"
    }
}

Write-Host ""

# ============================================================================
# Install Firefox (German)
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " Mozilla Firefox (German)" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$firefoxUrl = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=de"
$firefoxInstaller = Get-FileWithAria2 -Url $firefoxUrl -OutputPath "$TempDir\firefox-installer.exe" -Description "Firefox (German)"

if ($firefoxInstaller) {
    if (Start-InstallerSafe -InstallerPath $firefoxInstaller -Arguments @("/S") -Description "Firefox") {
        $installedApps += "Mozilla Firefox (German)"
    }
}

Write-Host ""

# ============================================================================
# Install Thunderbird (German)
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " Mozilla Thunderbird (German)" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$thunderbirdUrl = "https://download.mozilla.org/?product=thunderbird-latest-ssl&os=win64&lang=de"
$thunderbirdInstaller = Get-FileWithAria2 -Url $thunderbirdUrl -OutputPath "$TempDir\thunderbird-installer.exe" -Description "Thunderbird (German)"

if ($thunderbirdInstaller) {
    if (Start-InstallerSafe -InstallerPath $thunderbirdInstaller -Arguments @("/S") -Description "Thunderbird") {
        $installedApps += "Mozilla Thunderbird (German)"
    }
}

Write-Host ""

# ============================================================================
# Install LibreOffice (German)
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " LibreOffice (German)" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$libreOfficeUrl = Get-LibreOfficeDownloadUrl
$libreOfficeInstaller = Get-FileWithAria2 -Url $libreOfficeUrl -OutputPath "$TempDir\libreoffice-installer.msi" -Description "LibreOffice"

if ($libreOfficeInstaller) {
    $msiArgs = @(
        "/qb",
        "/norestart",
        "ADDLOCAL=ALL",
        "UI_LANGS=de",
        "REGISTER_ALL_MSO_TYPES=1"
    )
    
    if (Start-InstallerSafe -InstallerPath $libreOfficeInstaller -Arguments $msiArgs -Description "LibreOffice" -IsMSI) {
        $installedApps += "LibreOffice (German)"
    }
}

Write-Host ""

# ============================================================================
# Install WinRAR (German)
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " WinRAR (German)" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$winrarUrl = Get-WinRARDownloadUrl
$winrarInstaller = Get-FileWithAria2 -Url $winrarUrl -OutputPath "$TempDir\winrar-installer.exe" -Description "WinRAR (German)"

if ($winrarInstaller) {
    if (Start-InstallerSafe -InstallerPath $winrarInstaller -Arguments @("/S") -Description "WinRAR") {
        $installedApps += "WinRAR (German)"
    }
}

Write-Host ""

# ============================================================================
# Install CDBurnerXP (German) - Only if optical drive is present
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " CDBurnerXP (German)" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

if (Test-OpticalDrive) {
    $cdburnerUrl = Get-CDBurnerXPDownloadUrl
    $cdburnerInstaller = Get-FileWithAria2 -Url $cdburnerUrl -OutputPath "$TempDir\cdburnerxp-installer.exe" -Description "CDBurnerXP"
    
    if ($cdburnerInstaller) {
        # INNO Setup silent installation with German language
        $cbArgs = @("/VERYSILENT", "/LANG=german", "/NORESTART", "/SUPPRESSMSGBOXES")
        if (Start-InstallerSafe -InstallerPath $cdburnerInstaller -Arguments $cbArgs -Description "CDBurnerXP") {
            $installedApps += "CDBurnerXP (German)"
        }
    }
}
else {
    Write-Host "[SKIP] No CD/DVD drive detected - Skipping CDBurnerXP" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# Cleanup
# ============================================================================
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " Cleanup" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

Write-Host "[INFO] Removing temporary files..." -ForegroundColor Yellow

# Wait a moment for installers to release files
Start-Sleep -Seconds 2

try {
    # Try to remove temp directory
    if (Test-Path $TempDirLong) {
        Remove-Item $TempDirLong -Recurse -Force -ErrorAction Stop
        Write-Host "[OK] Temporary files removed" -ForegroundColor Green
    }
    elseif (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force -ErrorAction Stop
        Write-Host "[OK] Temporary files removed" -ForegroundColor Green
    }
}
catch {
    Write-Host "[WARN] Could not remove all temporary files: $TempDir" -ForegroundColor Yellow
    Write-Host "       You may delete this folder manually later." -ForegroundColor Yellow
}

# Also try to clean up parent folder if empty
try {
    $parentDir = Split-Path $TempDirLong -Parent
    $items = Get-ChildItem $parentDir -ErrorAction SilentlyContinue
    if ($items.Count -eq 0) {
        Remove-Item $parentDir -Force -ErrorAction SilentlyContinue
    }
}
catch { }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Installation Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($installedApps.Count -gt 0) {
    Write-Host "Successfully installed applications:" -ForegroundColor White
    foreach ($app in $installedApps) {
        Write-Host "  [+] $app" -ForegroundColor Green
    }
}
else {
    Write-Host "[WARN] No applications were installed" -ForegroundColor Yellow
}

#Write-Host ""
#Write-Host "Press any key to exit..."
#$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")