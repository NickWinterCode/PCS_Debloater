$scriptName = [System.IO.Path]::GetFileName($PSCommandPath)
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFolder = Join-Path $env:USERPROFILE "Desktop\$env:COMPUTERNAME"
if (!(Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory | Out-Null }
$logFile = Join-Path $logFolder ("$scriptName-$timestamp.log")

Start-Transcript -Path $logFile -Force
function Install-WinGet {
    [CmdletBinding()]
    param()

    # Check if running as Administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "This script must be run as Administrator. Please run PowerShell as Administrator and try again."
        return
    }

    Write-Host "Starting WinGet installation process..." -ForegroundColor Green

    # Function to get curl command
    function Get-CurlCommand {
        $curl = Get-Command curl -ErrorAction SilentlyContinue
        if ($curl) {
            Write-Host "Using system curl" -ForegroundColor Cyan
            return "curl"
        }
        
        # Check for curl in Tools folder
        $toolsCurl = Join-Path -Path $PSScriptRoot -ChildPath "Tools\curl.exe"
        if (Test-Path $toolsCurl) {
            Write-Host "Using curl from Tools folder" -ForegroundColor Cyan
            return $toolsCurl
        }
        
        throw "curl not found in system PATH or Tools folder. Please ensure curl is available."
    }

    # Function to download file using curl
    function Invoke-WithCurl {
        param(
            [string]$Url,
            [string]$OutputPath,
            [string]$CurlPath
        )
        
        $arguments = @(
            "-L",              # Follow redirects
            "-o", $OutputPath, # Output file
            "-#",              # Progress bar
            $Url
        )
        
        $process = Start-Process -FilePath $CurlPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Failed to download from $Url. Exit code: $($process.ExitCode)"
        }
    }

    try {
        # Get curl command
        $curlCmd = Get-CurlCommand

        # Install NuGet provider if not already installed
        Write-Host "Checking NuGet provider..." -ForegroundColor Yellow
        if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            Write-Host "NuGet provider installed successfully." -ForegroundColor Green
        }

        # Install required dependencies
        Write-Host "Installing dependencies..." -ForegroundColor Yellow
        
        # Install VCLibs
        Write-Host "Downloading VCLibs..." -ForegroundColor Yellow
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcLibsPath = "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Invoke-WithCurl -Url $vcLibsUrl -OutputPath $vcLibsPath -CurlPath $curlCmd
        
        Write-Host "Installing VCLibs..." -ForegroundColor Yellow
        Add-AppxPackage -Path $vcLibsPath
        
        # Install UI.Xaml
        Write-Host "Downloading Microsoft.UI.Xaml..." -ForegroundColor Yellow
        $xamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
        $xamlPath = "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx"
        Invoke-WithCurl -Url $xamlUrl -OutputPath $xamlPath -CurlPath $curlCmd
        
        Write-Host "Installing Microsoft.UI.Xaml..." -ForegroundColor Yellow
        Add-AppxPackage -Path $xamlPath

        # Get the latest WinGet release from GitHub
        Write-Host "Fetching latest WinGet release information..." -ForegroundColor Yellow
        $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $jsonPath = "$env:TEMP\winget-latest.json"
        
        # Download release info
        Invoke-WithCurl -Url $apiUrl -OutputPath $jsonPath -CurlPath $curlCmd
        $latestRelease = Get-Content $jsonPath -Raw | ConvertFrom-Json
        
        # Find assets
        $msixBundleAsset = $latestRelease.assets | Where-Object { $_.name -match "\.msixbundle$" }
        $licenseAsset = $latestRelease.assets | Where-Object { $_.name -match "License.*\.xml$" }

        if (-not $msixBundleAsset) {
            throw "Could not find WinGet msixbundle in the latest release"
        }

        # Download WinGet
        Write-Host "Downloading WinGet version $($latestRelease.tag_name)..." -ForegroundColor Yellow
        $wingetPath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        $licensePath = "$env:TEMP\License.xml"
        
        Invoke-WithCurl -Url $msixBundleAsset.browser_download_url -OutputPath $wingetPath -CurlPath $curlCmd
        
        if ($licenseAsset) {
            Invoke-WithCurl -Url $licenseAsset.browser_download_url -OutputPath $licensePath -CurlPath $curlCmd
        }

        # Install WinGet
        Write-Host "Installing WinGet..." -ForegroundColor Yellow
        if (Test-Path $licensePath) {
            Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $licensePath -ErrorAction Stop
        } else {
            Add-AppxPackage -Path $wingetPath -ErrorAction Stop
        }

        # Clean up temporary files
        Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
        $filesToRemove = @($vcLibsPath, $xamlPath, $wingetPath, $jsonPath)
        if (Test-Path $licensePath) {
            $filesToRemove += $licensePath
        }
        
        foreach ($file in $filesToRemove) {
            if (Test-Path $file) {
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
            }
        }

        # Verify installation
        Write-Host "Verifying installation..." -ForegroundColor Yellow
        $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
        
        if ($wingetCheck) {
            Write-Host "WinGet installed successfully!" -ForegroundColor Green
            Write-Host "Version: $(winget --version)" -ForegroundColor Cyan
            
            # Update sources
            Write-Host "Updating WinGet sources..." -ForegroundColor Yellow
            winget source update
        } else {
            Write-Warning "WinGet appears to be installed but is not available in PATH. You may need to restart your PowerShell session."
        }

    } catch {
        Write-Error "An error occurred during installation: $_"
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        
        # Additional cleanup on error
        $tempFiles = @(
            "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx",
            "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx",
            "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle",
            "$env:TEMP\License.xml",
            "$env:TEMP\winget-latest.json"
        )
        
        foreach ($file in $tempFiles) {
            if (Test-Path $file) {
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Run the installation function
Install-WinGet

