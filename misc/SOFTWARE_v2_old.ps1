#Requires -RunAsAdministrator
# ============================================================================
# Software Installation Script (German)
# Downloads and installs latest versions using aria2c or curl
# Optimized for slow internet connections
# Checks for existing installations and skips if up-to-date
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-SafeTempPath {
    $rootTemp = "$env:SystemDrive\Temp\SoftwareInstall"
    $programDataTemp = "$env:ProgramData\SoftwareInstall"
    $windowsTemp = "$env:SystemRoot\Temp\SoftwareInstall"
    
    foreach ($path in @($rootTemp, $programDataTemp, $windowsTemp)) {
        try {
            $testPath = Split-Path $path -Parent
            if (Test-Path $testPath) {
                $isAscii = $path -match '^[\x00-\x7F]+$'
                if ($isAscii) { return $path }
            }
        }
        catch { }
    }
    return "C:\Temp\SoftwareInstall"
}

function Get-ShortPath {
    param([string]$LongPath)
    if (!(Test-Path $LongPath)) { return $LongPath }
    try {
        $fso = New-Object -ComObject Scripting.FileSystemObject
        if (Test-Path $LongPath -PathType Container) {
            $shortPath = $fso.GetFolder($LongPath).ShortPath
        }
        else {
            $shortPath = $fso.GetFile($LongPath).ShortPath
        }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($fso) | Out-Null
        if ($shortPath) { return $shortPath }
    }
    catch { }
    return $LongPath
}

function New-SafeDirectory {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    return (Get-ShortPath $Path)
}

function Compare-Versions {
    param([string]$InstalledVersion, [string]$LatestVersion)
    if ([string]::IsNullOrEmpty($InstalledVersion) -or [string]::IsNullOrEmpty($LatestVersion)) { return $null }
    try {
        $installed = ($InstalledVersion -replace '[^\d\.]', '' -replace '\.+', '.').TrimEnd('.')
        $latest = ($LatestVersion -replace '[^\d\.]', '' -replace '\.+', '.').TrimEnd('.')
        $installedParts = @($installed.Split('.') | ForEach-Object { [int]$_ })
        $latestParts = @($latest.Split('.') | ForEach-Object { [int]$_ })
        $maxLength = [Math]::Max($installedParts.Count, $latestParts.Count)
        while ($installedParts.Count -lt $maxLength) { $installedParts += 0 }
        while ($latestParts.Count -lt $maxLength) { $latestParts += 0 }
        for ($i = 0; $i -lt $maxLength; $i++) {
            if ($installedParts[$i] -lt $latestParts[$i]) { return -1 }
            elseif ($installedParts[$i] -gt $latestParts[$i]) { return 1 }
        }
        return 0
    }
    catch { return $null }
}

function Get-InstalledSoftware {
    param([string]$SoftwareName, [string[]]$AlternativeNames = @())
    $searchNames = @($SoftwareName) + $AlternativeNames
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($regPath in $registryPaths) {
        try {
            $entries = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            foreach ($entry in $entries) {
                foreach ($name in $searchNames) {
                    if ($entry.DisplayName -like "*$name*") {
                        return @{ Name = $entry.DisplayName; Version = $entry.DisplayVersion }
                    }
                }
            }
        }
        catch { }
    }
    return $null
}

function Get-VLCInstalledVersion {
    $installed = Get-InstalledSoftware -SoftwareName "VLC media player" -AlternativeNames @("VLC", "VideoLAN")
    if ($installed -and $installed.Version) { return $installed.Version }
    $paths = @("$env:ProgramFiles\VideoLAN\VLC\vlc.exe", "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try { return (Get-Item $path).VersionInfo.ProductVersion } catch { }
        }
    }
    return $null
}

function Get-FirefoxInstalledVersion {
    $installed = Get-InstalledSoftware -SoftwareName "Mozilla Firefox" -AlternativeNames @("Firefox")
    if ($installed -and $installed.Version) { return $installed.Version }
    $paths = @("$env:ProgramFiles\Mozilla Firefox\firefox.exe", "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try { return (Get-Item $path).VersionInfo.ProductVersion } catch { }
        }
    }
    return $null
}

function Get-ThunderbirdInstalledVersion {
    $installed = Get-InstalledSoftware -SoftwareName "Mozilla Thunderbird" -AlternativeNames @("Thunderbird")
    if ($installed -and $installed.Version) { return $installed.Version }
    $paths = @("$env:ProgramFiles\Mozilla Thunderbird\thunderbird.exe", "${env:ProgramFiles(x86)}\Mozilla Thunderbird\thunderbird.exe")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try { return (Get-Item $path).VersionInfo.ProductVersion } catch { }
        }
    }
    return $null
}

function Get-LibreOfficeInstalledVersion {
    $installed = Get-InstalledSoftware -SoftwareName "LibreOffice" -AlternativeNames @("LibreOffice ")
    if ($installed -and $installed.Version) { return $installed.Version }
    $loPaths = @()
    foreach ($basePath in @("$env:ProgramFiles", "${env:ProgramFiles(x86)}")) {
        $loPaths += "$basePath\LibreOffice\program\soffice.exe"
        Get-ChildItem -Path $basePath -Directory -Filter "LibreOffice*" -ErrorAction SilentlyContinue | ForEach-Object {
            $loPaths += "$($_.FullName)\program\soffice.exe"
        }
    }
    foreach ($path in $loPaths) {
        if (Test-Path $path) {
            try { return (Get-Item $path).VersionInfo.ProductVersion } catch { }
        }
    }
    return $null
}

function Get-WinRARInstalledVersion {
    $installed = Get-InstalledSoftware -SoftwareName "WinRAR" -AlternativeNames @("WinRAR archiver")
    if ($installed -and $installed.Version) { return $installed.Version }
    $paths = @("$env:ProgramFiles\WinRAR\WinRAR.exe", "${env:ProgramFiles(x86)}\WinRAR\WinRAR.exe")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try { return (Get-Item $path).VersionInfo.ProductVersion } catch { }
        }
    }
    return $null
}

function Get-CDBurnerXPInstalledVersion {
    $installed = Get-InstalledSoftware -SoftwareName "CDBurnerXP" -AlternativeNames @("CDBurner")
    if ($installed -and $installed.Version) { return $installed.Version }
    $paths = @("$env:ProgramFiles\CDBurnerXP\cdbxpp.exe", "${env:ProgramFiles(x86)}\CDBurnerXP\cdbxpp.exe")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try { return (Get-Item $path).VersionInfo.ProductVersion } catch { }
        }
    }
    return $null
}

function Test-ValidExecutable {
    param([string]$FilePath, [string]$ExpectedType = "EXE")
    if (!(Test-Path $FilePath)) {
        Write-Host "[ERROR] File does not exist" -ForegroundColor Red
        return $false
    }
    $fileSize = (Get-Item $FilePath).Length
    $minSize = switch ($ExpectedType) { "EXE" { 500000 } "MSI" { 1000000 } "ZIP" { 50000 } default { 10000 } }
    if ($fileSize -lt $minSize) {
        Write-Host "[ERROR] File too small ($([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Red
        try {
            $content = Get-Content $FilePath -First 3 -ErrorAction SilentlyContinue
            if (($content -join "") -match '<|html|HTML|DOCTYPE') {
                Write-Host "[ERROR] File is HTML (error page)" -ForegroundColor Red
            }
        }
        catch { }
        return $false
    }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath) | Select-Object -First 16
        $valid = switch ($ExpectedType) {
            "EXE" { $bytes[0] -eq 0x4D -and $bytes[1] -eq 0x5A }
            "MSI" { $bytes[0] -eq 0xD0 -and $bytes[1] -eq 0xCF -and $bytes[2] -eq 0x11 -and $bytes[3] -eq 0xE0 }
            "ZIP" { $bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B }
            default { $true }
        }
        if ($valid) {
            Write-Host "[OK] Valid $ExpectedType ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green
            return $true
        }
        Write-Host "[ERROR] Invalid $ExpectedType signature" -ForegroundColor Red
        return $false
    }
    catch {
        Write-Host "[WARN] Could not validate: $_" -ForegroundColor Yellow
        return $false
    }
}

function Get-CurlPath {
    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curl) { return $curl.Source }
    $sys32 = "$env:SystemRoot\System32\curl.exe"
    if (Test-Path $sys32) { return $sys32 }
    return $null
}

# ============================================================================
# Initialize
# ============================================================================
$TempDirLong = Get-SafeTempPath
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$TempDirLong = "$TempDirLong`_$timestamp"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Software Installation Script (German)" -ForegroundColor Cyan
Write-Host " With Version Check & Update Support" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$TempDir = New-SafeDirectory -Path $TempDirLong
Write-Host "[INFO] Temp directory: $TempDir" -ForegroundColor Gray

$aria2Path = "$TempDir\aria2c.exe"
$curlPath = Get-CurlPath

if ($curlPath) { Write-Host "[INFO] Found curl: $curlPath" -ForegroundColor Gray }
else { Write-Host "[WARN] curl.exe not found" -ForegroundColor Yellow }

$script:LatestVersions = @{}

# ============================================================================
# Download Functions
# ============================================================================

function Get-LatestAria2cUrl {
    Write-Host "[INFO] Fetching latest aria2c version..." -ForegroundColor Yellow
    try {
        $apiUrl = "https://api.github.com/repos/aria2/aria2/releases/latest"
        if ($curlPath) {
            $jsonFile = "$TempDir\aria2_release.json"
            $null = Start-Process -FilePath $curlPath -ArgumentList "-s -L -k -o `"$jsonFile`" -H `"Accept: application/vnd.github.v3+json`" -H `"User-Agent: PowerShell`" `"$apiUrl`"" -Wait -PassThru -NoNewWindow
            if (Test-Path $jsonFile) {
                $release = Get-Content $jsonFile -Raw | ConvertFrom-Json
                Remove-Item $jsonFile -Force -ErrorAction SilentlyContinue
                if ($release.tag_name) {
                    $version = $release.tag_name -replace '^release-', ''
                    Write-Host "[INFO] Latest aria2c: $version" -ForegroundColor Cyan
                    $asset = $release.assets | Where-Object { $_.name -match 'aria2-[\d\.]+-win-64bit.*\.zip$' } | Select-Object -First 1
                    if ($asset.browser_download_url) {
                        return @{ Url = $asset.browser_download_url; Version = $version }
                    }
                    return @{ Url = "https://github.com/aria2/aria2/releases/download/release-$version/aria2-$version-win-64bit-build1.zip"; Version = $version }
                }
            }
        }
    }
    catch { Write-Host "[WARN] Could not fetch aria2c version" -ForegroundColor Yellow }
    return $null
}

function Get-FileWithCurl {
    param([string]$Url, [string]$OutputPath, [string]$Description, [switch]$InsecureSSL)
    if (!$curlPath) { return $false }
    Write-Host "[INFO] Downloading: $Description" -ForegroundColor Yellow
    Write-Host "[INFO] URL: $Url" -ForegroundColor Gray
    $sslFlag = if ($InsecureSSL) { "-k" } else { "" }
    $batchFile = "$TempDir\run_curl.cmd"
    $batchContent = "@echo off`r`nchcp 65001 >nul 2>&1`r`n`"$curlPath`" -L $sslFlag -o `"$OutputPath`" -C - --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 60 --max-time 0 -# -A `"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36`" `"$Url`"`r`nexit /b %errorlevel%"
    [System.IO.File]::WriteAllText($batchFile, $batchContent, [System.Text.Encoding]::ASCII)
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -Wait -PassThru -NoNewWindow
    Remove-Item $batchFile -Force -ErrorAction SilentlyContinue
    if ($process.ExitCode -eq 0 -and (Test-Path $OutputPath)) {
        if ((Get-Item $OutputPath).Length -gt 1000) { return $true }
    }
    return $false
}

function Get-FileWithAria2c {
    param([string]$Url, [string]$OutputPath, [string]$Description)
    if (!(Test-Path $aria2Path)) { return $false }
    Write-Host "[INFO] Downloading: $Description" -ForegroundColor Yellow
    Write-Host "[INFO] URL: $Url" -ForegroundColor Gray
    $outputDir = Get-ShortPath (Split-Path $OutputPath -Parent)
    $outputFile = Split-Path $OutputPath -Leaf
    $aria2Short = Get-ShortPath $aria2Path
    $batchFile = "$TempDir\run_aria2c.cmd"
    $batchContent = "@echo off`r`nchcp 65001 >nul 2>&1`r`n`"$aria2Short`" --dir=`"$outputDir`" --out=`"$outputFile`" --max-connection-per-server=16 --split=16 --min-split-size=1M --continue=true --max-tries=0 --retry-wait=5 --timeout=600 --connect-timeout=60 --auto-file-renaming=false --allow-overwrite=true --check-certificate=false --user-agent=`"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36`" --console-log-level=notice `"$Url`"`r`nexit /b %errorlevel%"
    [System.IO.File]::WriteAllText($batchFile, $batchContent, [System.Text.Encoding]::ASCII)
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -Wait -PassThru -NoNewWindow
    Remove-Item $batchFile -Force -ErrorAction SilentlyContinue
    $finalPath = Join-Path (Split-Path $OutputPath -Parent) $outputFile
    return ($process.ExitCode -eq 0 -and (Test-Path $finalPath))
}

function Install-Aria2c {
    Write-Host "[INFO] Checking for aria2c..." -ForegroundColor Yellow
    if (Test-Path $aria2Path) {
        Write-Host "[OK] aria2c already present" -ForegroundColor Green
        return $true
    }
    $aria2Info = Get-LatestAria2cUrl
    if ($null -eq $aria2Info) {
        Write-Host "[ERROR] Could not find aria2c download URL" -ForegroundColor Red
        return $false
    }
    $aria2Zip = "$TempDir\aria2.zip"
    Write-Host "[INFO] Downloading aria2c v$($aria2Info.Version)..." -ForegroundColor Yellow
    $downloaded = $false
    if ($curlPath) { $downloaded = Get-FileWithCurl -Url $aria2Info.Url -OutputPath $aria2Zip -Description "aria2c" -InsecureSSL }
    if (!$downloaded) {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0")
            $wc.DownloadFile($aria2Info.Url, $aria2Zip)
            $wc.Dispose()
            $downloaded = $true
        }
        catch { }
    }
    if (!$downloaded -or !(Test-Path $aria2Zip) -or !(Test-ValidExecutable -FilePath $aria2Zip -ExpectedType "ZIP")) {
        Write-Host "[ERROR] Failed to download aria2c" -ForegroundColor Red
        return $false
    }
    Write-Host "[INFO] Extracting aria2c..." -ForegroundColor Yellow
    try { Expand-Archive -Path $aria2Zip -DestinationPath $TempDir -Force -ErrorAction Stop }
    catch {
        $shell = New-Object -ComObject Shell.Application
        $shell.NameSpace($TempDir).CopyHere($shell.NameSpace($aria2Zip).Items(), 16 + 4)
        Start-Sleep -Seconds 3
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
    $extracted = Get-ChildItem -Path $TempDir -Directory -Filter "aria2-*" | Select-Object -First 1
    if ($extracted) {
        $src = Join-Path $extracted.FullName "aria2c.exe"
        if (Test-Path $src) { Copy-Item $src $aria2Path -Force }
        Remove-Item $extracted.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $aria2Zip -Force -ErrorAction SilentlyContinue
    if (Test-Path $aria2Path) {
        Write-Host "[OK] aria2c ready" -ForegroundColor Green
        return $true
    }
    return $false
}

function Get-FileWithValidation {
    param([string]$Url, [string]$OutputPath, [string]$Description, [string]$ExpectedType = "EXE")
    Write-Host "" 
    Write-Host "[INFO] === Downloading $Description ===" -ForegroundColor Cyan
    $outputDir = Split-Path $OutputPath -Parent
    $outputFile = (Split-Path $OutputPath -Leaf) -replace '[^a-zA-Z0-9\.\-_]', '_'
    $finalPath = Join-Path $outputDir $outputFile
    Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
    
    if (Test-Path $aria2Path) {
        if ((Get-FileWithAria2c -Url $Url -OutputPath $finalPath -Description $Description) -and (Test-ValidExecutable -FilePath $finalPath -ExpectedType $ExpectedType)) {
            return $finalPath
        }
        Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
    }
    if ($curlPath) {
        if ((Get-FileWithCurl -Url $Url -OutputPath $finalPath -Description $Description -InsecureSSL) -and (Test-ValidExecutable -FilePath $finalPath -ExpectedType $ExpectedType)) {
            return $finalPath
        }
        Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[ERROR] Download failed" -ForegroundColor Red
    return $null
}

function Start-InstallerSafe {
    param([string]$InstallerPath, [string[]]$Arguments, [string]$Description, [switch]$IsMSI)
    if (!(Test-Path $InstallerPath)) {
        Write-Host "[ERROR] Installer not found" -ForegroundColor Red
        return $false
    }
    Write-Host "[INFO] Installing $Description..." -ForegroundColor Yellow
    $short = Get-ShortPath $InstallerPath
    try {
        if ($IsMSI) {
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList (@("/i", "`"$short`"") + $Arguments) -Wait -PassThru
        }
        else {
            $batch = "$TempDir\run_install.cmd"
            [System.IO.File]::WriteAllText($batch, "@echo off`r`n`"$short`" $($Arguments -join ' ')`r`nexit /b %errorlevel%", [System.Text.Encoding]::ASCII)
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batch`"" -Wait -PassThru
            Remove-Item $batch -Force -ErrorAction SilentlyContinue
        }
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010 -or $process.ExitCode -eq 1641) {
            Write-Host "[OK] $Description installed" -ForegroundColor Green
            return $true
        }
        Write-Host "[WARN] Exit code: $($process.ExitCode)" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[ERROR] Installation failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-OpticalDrive {
    try {
        $drives = Get-CimInstance -ClassName Win32_CDROMDrive -ErrorAction Stop
        if ($drives) {
            Write-Host "[INFO] Found optical drive: $(($drives | ForEach-Object { $_.Caption }) -join ', ')" -ForegroundColor Cyan
            return $true
        }
    }
    catch { }
    try {
        if (Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 5 }) {
            Write-Host "[INFO] Found optical drive" -ForegroundColor Cyan
            return $true
        }
    }
    catch { }
    return $false
}

function Test-UpdateNeeded {
    param([string]$AppName, [string]$InstalledVersion, [string]$LatestVersion)
    if ([string]::IsNullOrEmpty($InstalledVersion)) {
        Write-Host "[INFO] $AppName not installed" -ForegroundColor Yellow
        return $true
    }
    Write-Host "[INFO] Installed: $InstalledVersion | Latest: $LatestVersion" -ForegroundColor Gray
    if ($LatestVersion -eq "unknown") {
        Write-Host "[WARN] Cannot determine latest version" -ForegroundColor Yellow
        return $true
    }
    $cmp = Compare-Versions -InstalledVersion $InstalledVersion -LatestVersion $LatestVersion
    if ($null -eq $cmp -or $cmp -lt 0) {
        Write-Host "[INFO] Update available" -ForegroundColor Yellow
        return $true
    }
    Write-Host "[OK] Up to date" -ForegroundColor Green
    return $false
}

# ============================================================================
# Software Download Info Functions
# ============================================================================

function Get-VLCDownloadInfo {
    Write-Host "[INFO] Fetching VLC version..." -ForegroundColor Yellow
    $version = $null
    if ($curlPath) {
        try {
            $html = "$TempDir\vlc.html"
            $null = Start-Process -FilePath $curlPath -ArgumentList "-s -L -k -o `"$html`" -A `"Mozilla/5.0`" `"https://www.videolan.org/vlc/download-windows.html`"" -Wait -PassThru -NoNewWindow
            if (Test-Path $html) {
                $content = Get-Content $html -Raw
                if ($content -match 'vlc-(\d+\.\d+\.\d+)-win64\.exe') { $version = $Matches[1] }
                Remove-Item $html -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }
    }
    if (!$version) { $version = "3.0.21" }
    Write-Host "[INFO] VLC version: $version" -ForegroundColor Cyan
    $script:LatestVersions["VLC"] = $version
    return @{ Url = "https://mirror.init7.net/videolan/vlc/$version/win64/vlc-$version-win64.exe"; Version = $version }
}

function Get-FirefoxDownloadInfo {
    Write-Host "[INFO] Fetching Firefox version..." -ForegroundColor Yellow
    $version = "unknown"
    if ($curlPath) {
        try {
            $json = "$TempDir\ff.json"
            $null = Start-Process -FilePath $curlPath -ArgumentList "-s -L -k -o `"$json`" `"https://product-details.mozilla.org/1.0/firefox_versions.json`"" -Wait -PassThru -NoNewWindow
            if (Test-Path $json) {
                $version = (Get-Content $json -Raw | ConvertFrom-Json).LATEST_FIREFOX_VERSION
                Remove-Item $json -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }
    }
    Write-Host "[INFO] Firefox version: $version" -ForegroundColor Cyan
    $script:LatestVersions["Firefox"] = $version
    return @{ Url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=de"; Version = $version }
}

function Get-ThunderbirdDownloadInfo {
    Write-Host "[INFO] Fetching Thunderbird version..." -ForegroundColor Yellow
    $version = "unknown"
    if ($curlPath) {
        try {
            $json = "$TempDir\tb.json"
            $null = Start-Process -FilePath $curlPath -ArgumentList "-s -L -k -o `"$json`" `"https://product-details.mozilla.org/1.0/thunderbird_versions.json`"" -Wait -PassThru -NoNewWindow
            if (Test-Path $json) {
                $version = (Get-Content $json -Raw | ConvertFrom-Json).LATEST_THUNDERBIRD_VERSION
                Remove-Item $json -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }
    }
    Write-Host "[INFO] Thunderbird version: $version" -ForegroundColor Cyan
    $script:LatestVersions["Thunderbird"] = $version
    return @{ Url = "https://download.mozilla.org/?product=thunderbird-latest-ssl&os=win64&lang=de"; Version = $version }
}

function Get-LibreOfficeDownloadInfo {
    Write-Host "[INFO] Fetching LibreOffice version..." -ForegroundColor Yellow
    $version = $null
    if ($curlPath) {
        try {
            $html = "$TempDir\lo.html"
            $null = Start-Process -FilePath $curlPath -ArgumentList "-s -L -k -o `"$html`" -A `"Mozilla/5.0`" `"https://download.documentfoundation.org/libreoffice/stable/`"" -Wait -PassThru -NoNewWindow
            if (Test-Path $html) {
                $content = Get-Content $html -Raw
                $versions = [regex]::Matches($content, 'href="(\d+\.\d+\.\d+)/"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object { [version]$_ } -Descending
                if ($versions.Count -gt 0) { $version = $versions[0] }
                Remove-Item $html -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }
    }
    if (!$version) { $version = "24.2.7" }
    Write-Host "[INFO] LibreOffice version: $version" -ForegroundColor Cyan
    $script:LatestVersions["LibreOffice"] = $version
    return @{ Url = "https://download.documentfoundation.org/libreoffice/stable/$version/win/x86_64/LibreOffice_${version}_Win_x86-64.msi"; Version = $version }
}

function Get-WinRARDownloadInfo {
    Write-Host "[INFO] Fetching WinRAR version..." -ForegroundColor Yellow
    $version = $null
    $versionCode = $null
    if ($curlPath) {
        try {
            $html = "$TempDir\rar.html"
            $null = Start-Process -FilePath $curlPath -ArgumentList "-s -L -k -o `"$html`" -A `"Mozilla/5.0`" `"https://www.rarlab.com/download.htm`"" -Wait -PassThru -NoNewWindow
            if (Test-Path $html) {
                $content = Get-Content $html -Raw
                if ($content -match 'winrar-x64-(\d+)d?\.exe') {
                    $versionCode = $Matches[1]
                    $version = if ($versionCode.Length -eq 3) { "$($versionCode[0]).$($versionCode.Substring(1))" } else { $versionCode }
                }
                Remove-Item $html -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }
    }
    if (!$versionCode) { $versionCode = "711"; $version = "7.11" }
    Write-Host "[INFO] WinRAR version: $version (German)" -ForegroundColor Cyan
    $script:LatestVersions["WinRAR"] = $version
    return @{ Url = "https://www.rarlab.com/rar/winrar-x64-${versionCode}d.exe"; Version = $version }
}

# ============================================================================
# CDBurnerXP - Using PowerFolder as primary source
# ============================================================================

function Get-CDBurnerXPInstaller {
    param([string]$OutputPath)
    
    Write-Host ""
    Write-Host "[INFO] === Downloading CDBurnerXP ===" -ForegroundColor Cyan
    Write-Host "[INFO] Fetching CDBurnerXP..." -ForegroundColor Yellow
    
    $version = "4.5.8.7128"
    $script:LatestVersions["CDBurnerXP"] = $version
    
    $outputDir = Split-Path $OutputPath -Parent
    $outputFile = Split-Path $OutputPath -Leaf
    $finalPath = Join-Path $outputDir $outputFile
    
    # PowerFolder self-hosted as primary, with fallbacks
    $sources = @(
        @{
            Name = "PowerFolder (Official)"
            Url = "https://drive.powerfolder.com/dl/fi3bHeD2CaRqgR9p5egiCBbt/cdbxp_setup_4.5.8.7128_x64_minimal.exe"
        },
        @{
            Name = "MajorGeeks Mirror 1"
            Url = "https://www.majorgeeks.com/mg/getmirror/cdburnerxp_64_bit,1.html"
        },
        @{
            Name = "MajorGeeks Mirror 2"
            Url = "https://www.majorgeeks.com/mg/getmirror/cdburnerxp_64_bit,2.html"
        },
        @{
            Name = "SourceForge"
            Url = "https://sourceforge.net/projects/cdburnerxp/files/latest/download"
        }
    )
    
    foreach ($source in $sources) {
        Write-Host "[INFO] Trying: $($source.Name)" -ForegroundColor Yellow
        Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
        
        # Try aria2c first
        if (Test-Path $aria2Path) {
            $downloaded = Get-FileWithAria2c -Url $source.Url -OutputPath $finalPath -Description "CDBurnerXP"
            if ($downloaded -and (Test-ValidExecutable -FilePath $finalPath -ExpectedType "EXE")) {
                Write-Host "[OK] Downloaded from $($source.Name)" -ForegroundColor Green
                return @{ Path = $finalPath; Version = $version }
            }
            Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
        }
        
        # Try curl
        if ($curlPath) {
            $downloaded = Get-FileWithCurl -Url $source.Url -OutputPath $finalPath -Description "CDBurnerXP" -InsecureSSL
            if ($downloaded -and (Test-ValidExecutable -FilePath $finalPath -ExpectedType "EXE")) {
                Write-Host "[OK] Downloaded from $($source.Name)" -ForegroundColor Green
                return @{ Path = $finalPath; Version = $version }
            }
            Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "[WARN] Failed: $($source.Name)" -ForegroundColor Yellow
    }
    
    Write-Host "[ERROR] All download sources failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "[INFO] Please download manually from:" -ForegroundColor Yellow
    Write-Host "       https://drive.powerfolder.com/getlink/fi3bHeD2CaRqgR9p5egiCBbt/cdbxp_setup_4.5.8.7128_x64_minimal.exe" -ForegroundColor White
    Write-Host "       https://www.majorgeeks.com/files/details/cdburnerxp_64_bit.html" -ForegroundColor White
    Write-Host "       https://cdburnerxp.se/en/download" -ForegroundColor White
    
    return $null
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Write-Host ""

if (!(Install-Aria2c)) {
    if (!$curlPath) {
        Write-Host "[FATAL] No download tools available" -ForegroundColor Red
        #Read-Host "Press Enter to exit"
        #exit 1
    }
    Write-Host "[WARN] Using curl only" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Checking Installed Software" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$vlcInstalled = Get-VLCInstalledVersion
$firefoxInstalled = Get-FirefoxInstalledVersion
$thunderbirdInstalled = Get-ThunderbirdInstalledVersion
$libreofficeInstalled = Get-LibreOfficeInstalledVersion
$winrarInstalled = Get-WinRARInstalledVersion
$cdburnerInstalled = Get-CDBurnerXPInstalledVersion

Write-Host "Currently Installed:" -ForegroundColor White
Write-Host "  VLC:         $(if($vlcInstalled){$vlcInstalled}else{'Not installed'})" -ForegroundColor Gray
Write-Host "  Firefox:     $(if($firefoxInstalled){$firefoxInstalled}else{'Not installed'})" -ForegroundColor Gray
Write-Host "  Thunderbird: $(if($thunderbirdInstalled){$thunderbirdInstalled}else{'Not installed'})" -ForegroundColor Gray
Write-Host "  LibreOffice: $(if($libreofficeInstalled){$libreofficeInstalled}else{'Not installed'})" -ForegroundColor Gray
Write-Host "  WinRAR:      $(if($winrarInstalled){$winrarInstalled}else{'Not installed'})" -ForegroundColor Gray
Write-Host "  CDBurnerXP:  $(if($cdburnerInstalled){$cdburnerInstalled}else{'Not installed'})" -ForegroundColor Gray

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Starting Installation/Update" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$installedApps = @()
$updatedApps = @()
$skippedApps = @()
$failedApps = @()

# VLC
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " [1/6] VLC Media Player" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$vlcInfo = Get-VLCDownloadInfo
if (Test-UpdateNeeded -AppName "VLC" -InstalledVersion $vlcInstalled -LatestVersion $vlcInfo.Version) {
    $inst = Get-FileWithValidation -Url $vlcInfo.Url -OutputPath "$TempDir\vlc.exe" -Description "VLC" -ExpectedType "EXE"
    if ($inst) {
        if (Start-InstallerSafe -InstallerPath $inst -Arguments @("/L=1031","/S") -Description "VLC") {
            if ($vlcInstalled) { $updatedApps += "VLC ($vlcInstalled -> $($vlcInfo.Version))" }
            else { $installedApps += "VLC ($($vlcInfo.Version))" }
        } else { $failedApps += "VLC" }
    } else { $failedApps += "VLC (download)" }
} else { $skippedApps += "VLC ($vlcInstalled)" }

# Firefox
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " [2/6] Mozilla Firefox" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$ffInfo = Get-FirefoxDownloadInfo
if (Test-UpdateNeeded -AppName "Firefox" -InstalledVersion $firefoxInstalled -LatestVersion $ffInfo.Version) {
    $inst = Get-FileWithValidation -Url $ffInfo.Url -OutputPath "$TempDir\firefox.exe" -Description "Firefox" -ExpectedType "EXE"
    if ($inst) {
        if (Start-InstallerSafe -InstallerPath $inst -Arguments @("/S") -Description "Firefox") {
            if ($firefoxInstalled) { $updatedApps += "Firefox ($firefoxInstalled -> $($ffInfo.Version))" }
            else { $installedApps += "Firefox ($($ffInfo.Version))" }
        } else { $failedApps += "Firefox" }
    } else { $failedApps += "Firefox (download)" }
} else { $skippedApps += "Firefox ($firefoxInstalled)" }

# Thunderbird
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " [3/6] Mozilla Thunderbird" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$tbInfo = Get-ThunderbirdDownloadInfo
if (Test-UpdateNeeded -AppName "Thunderbird" -InstalledVersion $thunderbirdInstalled -LatestVersion $tbInfo.Version) {
    $inst = Get-FileWithValidation -Url $tbInfo.Url -OutputPath "$TempDir\thunderbird.exe" -Description "Thunderbird" -ExpectedType "EXE"
    if ($inst) {
        if (Start-InstallerSafe -InstallerPath $inst -Arguments @("/S") -Description "Thunderbird") {
            if ($thunderbirdInstalled) { $updatedApps += "Thunderbird ($thunderbirdInstalled -> $($tbInfo.Version))" }
            else { $installedApps += "Thunderbird ($($tbInfo.Version))" }
        } else { $failedApps += "Thunderbird" }
    } else { $failedApps += "Thunderbird (download)" }
} else { $skippedApps += "Thunderbird ($thunderbirdInstalled)" }

# LibreOffice
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " [4/6] LibreOffice" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$loInfo = Get-LibreOfficeDownloadInfo
if (Test-UpdateNeeded -AppName "LibreOffice" -InstalledVersion $libreofficeInstalled -LatestVersion $loInfo.Version) {
    $inst = Get-FileWithValidation -Url $loInfo.Url -OutputPath "$TempDir\libreoffice.msi" -Description "LibreOffice" -ExpectedType "MSI"
    if ($inst) {
        Write-Host "[INFO] This may take several minutes..." -ForegroundColor Yellow
        if (Start-InstallerSafe -InstallerPath $inst -Arguments @("/passive","/norestart","ALLUSERS=1","UI_LANGS=de","ADDLOCAL=ALL") -Description "LibreOffice" -IsMSI) {
            if ($libreofficeInstalled) { $updatedApps += "LibreOffice ($libreofficeInstalled -> $($loInfo.Version))" }
            else { $installedApps += "LibreOffice ($($loInfo.Version))" }
        } else { $failedApps += "LibreOffice" }
    } else { $failedApps += "LibreOffice (download)" }
} else { $skippedApps += "LibreOffice ($libreofficeInstalled)" }

# WinRAR
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " [5/6] WinRAR" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$rarInfo = Get-WinRARDownloadInfo
if (Test-UpdateNeeded -AppName "WinRAR" -InstalledVersion $winrarInstalled -LatestVersion $rarInfo.Version) {
    $inst = Get-FileWithValidation -Url $rarInfo.Url -OutputPath "$TempDir\winrar.exe" -Description "WinRAR" -ExpectedType "EXE"
    if ($inst) {
        if (Start-InstallerSafe -InstallerPath $inst -Arguments @("/S") -Description "WinRAR") {
            if ($winrarInstalled) { $updatedApps += "WinRAR ($winrarInstalled -> $($rarInfo.Version))" }
            else { $installedApps += "WinRAR ($($rarInfo.Version))" }
        } else { $failedApps += "WinRAR" }
    } else { $failedApps += "WinRAR (download)" }
} else { $skippedApps += "WinRAR ($winrarInstalled)" }

# CDBurnerXP
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " [6/6] CDBurnerXP" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

$hasOpticalDrive = Test-OpticalDrive

if ($hasOpticalDrive) {
    $cdbVersion = "4.5.8.7128"
    $script:LatestVersions["CDBurnerXP"] = $cdbVersion
    
    if (Test-UpdateNeeded -AppName "CDBurnerXP" -InstalledVersion $cdburnerInstalled -LatestVersion $cdbVersion) {
        $cdbResult = Get-CDBurnerXPInstaller -OutputPath "$TempDir\cdburnerxp.exe"
        if ($cdbResult -and $cdbResult.Path) {
            if (Start-InstallerSafe -InstallerPath $cdbResult.Path -Arguments @("/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART","/SP-","/LANG=german") -Description "CDBurnerXP") {
                if ($cdburnerInstalled) { $updatedApps += "CDBurnerXP ($cdburnerInstalled -> $($cdbResult.Version))" }
                else { $installedApps += "CDBurnerXP ($($cdbResult.Version))" }
            } else { $failedApps += "CDBurnerXP" }
        } else { $failedApps += "CDBurnerXP (download)" }
    } else { $skippedApps += "CDBurnerXP ($cdburnerInstalled)" }
} else {
    Write-Host "[SKIP] No optical drive" -ForegroundColor Yellow
}

# Cleanup
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host " Cleanup" -ForegroundColor White
Write-Host "--------------------------------------------" -ForegroundColor White

Start-Sleep -Seconds 3
try {
    Remove-Item $TempDirLong -Recurse -Force -ErrorAction Stop
    Write-Host "[OK] Temp files removed" -ForegroundColor Green
}
catch { Write-Host "[WARN] Could not remove temp files" -ForegroundColor Yellow }

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($installedApps.Count -gt 0) {
    Write-Host "Newly Installed:" -ForegroundColor Green
    $installedApps | ForEach-Object { Write-Host "  [+] $_" -ForegroundColor Green }
    Write-Host ""
}
if ($updatedApps.Count -gt 0) {
    Write-Host "Updated:" -ForegroundColor Cyan
    $updatedApps | ForEach-Object { Write-Host "  [^] $_" -ForegroundColor Cyan }
    Write-Host ""
}
if ($skippedApps.Count -gt 0) {
    Write-Host "Already Up-to-Date:" -ForegroundColor Gray
    $skippedApps | ForEach-Object { Write-Host "  [=] $_" -ForegroundColor Gray }
    Write-Host ""
}
if ($failedApps.Count -gt 0) {
    Write-Host "Failed:" -ForegroundColor Red
    $failedApps | ForEach-Object { Write-Host "  [X] $_" -ForegroundColor Red }
    Write-Host ""
}

Write-Host "--------------------------------------------" -ForegroundColor White
Write-Host "Installed: $($installedApps.Count) | Updated: $($updatedApps.Count) | Skipped: $($skippedApps.Count) | Failed: $($failedApps.Count)" -ForegroundColor White
Write-Host ""

if ($failedApps.Count -eq 0) { Write-Host "[OK] All operations completed!" -ForegroundColor Green }
else { Write-Host "[WARN] Some operations failed" -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
#Write-Host "Press any key to exit..."
#$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Output "----- Change Order of Desktop Icons -----"
try {
  . "$PSScriptRoot\REICON.ps1"
} catch {
  Write-Output "FUCK, the Module wont load ... DAMIT"
}
$PublicDesktop = "$env:PUBLIC\Desktop"
Remove-Item "$PublicDesktop\Microsoft Edge.lnk" -Force
Set-IconPositionWithSwap -Name "Dieser PC" -X 36 -Y 2
Set-IconPositionWithSwap -Name "Papierkorb" -X 36 -Y 102
Set-IconPositionWithSwap -Name "Firefox" -X 36 -Y 202
Set-IconPositionWithSwap -Name "Thunderbird" -X 36 -Y 302
Set-IconPositionWithSwap -Name "LibreOffice" -X 36 -Y 402
Set-IconPositionWithSwap -Name "Adobe Acrobat" -X 36 -Y 502
Set-IconPositionWithSwap -Name "VLC media player" -X 36 -Y 602
Set-IconPositionWithSwap -Name "PCSpezialist Fernwartung" -X 1836 -Y 2
Set-IconPositionWithSwap -Name "CDBurnerXP" -X 36 -Y 702