# BitLocker Complete Disable and Decrypt Script (Updated)
# Run as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "BitLocker Disable and Decrypt Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Get all BitLocker volumes
Write-Host "Scanning for encrypted drives..." -ForegroundColor Yellow
$volumes = Get-BitLockerVolume

if ($volumes.Count -eq 0) {
    Write-Host "No BitLocker volumes found." -ForegroundColor Green
    exit
}

Write-Host "Found $($volumes.Count) volume(s):" -ForegroundColor Green
Write-Host ""

# Display volumes and their status
foreach ($vol in $volumes) {
    Write-Host "Drive: $($vol.MountPoint)" -ForegroundColor Cyan
    Write-Host "  Status: $($vol.VolumeStatus)" -ForegroundColor Yellow
    Write-Host "  Protection: $($vol.ProtectionStatus)" -ForegroundColor Yellow
    Write-Host "  Encryption: $($vol.EncryptionPercentage)%" -ForegroundColor Yellow
    Write-Host ""
}

# Confirmation
Write-Host "========================================" -ForegroundColor Red
Write-Host "WARNING: This will disable BitLocker and" -ForegroundColor Red
Write-Host "decrypt all protected drives." -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

#$confirm = Read-Host "Do you want to proceed? (Type 'YES' to confirm)"
$confirm = 'YES'

if ($confirm -ne "YES") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Starting BitLocker removal process..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$alreadyDecrypted = 0
$errorCount = 0

foreach ($vol in $volumes) {
    $drive = $vol.MountPoint
    Write-Host "Processing drive: $drive" -ForegroundColor Yellow
    
    # Check if already decrypted
    if ($vol.VolumeStatus -eq "FullyDecrypted" -and $vol.ProtectionStatus -eq "Off") {
        Write-Host "  - Drive is already decrypted and protection is off" -ForegroundColor Green
        $alreadyDecrypted++
        Write-Host ""
        continue
    }
    
    try {
        # Disable BitLocker protection
        if ($vol.ProtectionStatus -eq "On") {
            Write-Host "  - Disabling BitLocker protection..." -NoNewline
            Disable-BitLocker -MountPoint $drive -ErrorAction Stop
            Write-Host " Done" -ForegroundColor Green
        }
        
        # Check status
        Start-Sleep -Seconds 2
        $status = Get-BitLockerVolume -MountPoint $drive
        Write-Host "  - Current status: $($status.VolumeStatus)" -ForegroundColor Green
        Write-Host "  - Encryption: $($status.EncryptionPercentage)%" -ForegroundColor Green
        
        $successCount++
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "  - Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# Disable BitLocker service
Write-Host "Disabling BitLocker service..." -ForegroundColor Yellow
try {
    Stop-Service -Name "BDESVC" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "BDESVC" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  BitLocker service stopped and disabled" -ForegroundColor Green
}
catch {
    Write-Host "  Could not disable service" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Process Summary:" -ForegroundColor Cyan
Write-Host "  Successfully processed: $successCount" -ForegroundColor Green
Write-Host "  Already decrypted: $alreadyDecrypted" -ForegroundColor Green
Write-Host "  Failed: $errorCount" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Final verification:" -ForegroundColor Cyan
Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, ProtectionStatus, @{Name="Encryption%";Expression={$_.EncryptionPercentage}} | Format-Table

Write-Host "BitLocker has been completely disabled." -ForegroundColor Green
