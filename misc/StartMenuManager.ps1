#Requires -Version 5.1
#Requires -RunAsAdministrator

#[CmdletBinding()]
#param(
#    [Parameter(Mandatory, ParameterSetName = 'Export')]
#    [switch]$Export,
#
#    [Parameter(Mandatory, ParameterSetName = 'Import')]
#    [switch]$Import
#)

# -------------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------------

$StartBin = "$env:LocalAppData\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
$Store    = "$PSScriptRoot"
$Name     = "BASE_PCS"  # Hardcoded

if (-not (Test-Path $Store)) {
    New-Item -Path $Store -ItemType Directory -Force | Out-Null
}

$LayoutFile = Join-Path $Store "$Name.bin"

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------

function Stop-StartMenu {
    Get-Process StartMenuExperienceHost -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    #Start-Process explorer.exe
    Start-Sleep -Seconds 2
}

# -------------------------------------------------------------------------
# Export
# -------------------------------------------------------------------------

#if ($Export) {
function Export_StartMenu {
    if (-not (Test-Path $StartBin)) {
        Write-Error "start2.bin not found. Open the Start Menu at least once."
        exit 1
    }

    Copy-Item $StartBin $LayoutFile -Force
    Write-Host "[OK] Start Menu layout exported:" -ForegroundColor Green
    Write-Host "  $LayoutFile"
    exit 0
}

# -------------------------------------------------------------------------
# Import
# -------------------------------------------------------------------------

#if ($Import) {
function Import_StartMenu {
    if (-not (Test-Path $LayoutFile)) {
        Write-Error "Layout not found: $LayoutFile"
        exit 1
    }

    Stop-StartMenu
    Copy-Item $LayoutFile $StartBin -Force
    Restart-Explorer

    Write-Host "[OK] Start Menu layout imported:" -ForegroundColor Green
    Write-Host "  $LayoutFile"
    exit 0
}

#Export_StartMenu
Import_StartMenu