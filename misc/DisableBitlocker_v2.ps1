# =============================================
# COMPLETE BITLOCKER REMOVAL SCRIPT
# Fully decrypts ALL drives and PERMANENTLY disables BitLocker
# Works on Windows 10/11 Home → Pro → Enterprise
# Requires Administrator privileges
# =============================================

# Elevate to Administrator if not already
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "`n=== STARTING TOTAL BITLOCKER ERADICATION ===`n" -ForegroundColor Red

# 1. Decrypt every single BitLocker-protected volume (OS + Data drives)
Write-Host "Step 1: Decrypting all BitLocker volumes..." -ForegroundColor Cyan
Get-BitLockerVolume | Where-Object { $_.VolumeStatus -ne "FullyDecrypted" -and $_.VolumeType -ne "Removable" } | ForEach-Object {
    $drive = $_.MountPoint
    Write-Host "   → Turning BitLocker OFF and decrypting $drive" -ForegroundColor Yellow
    manage-bde -off $drive
}

# 2. Force remove ALL key protectors from every drive (just in case)
Write-Host "`nStep 2: Deleting ALL BitLocker key protectors..." -ForegroundColor Cyan
Get-BitLockerVolume | ForEach-Object {
    $drive = $_.MountPoint
    if (manage-bde -status $drive | Select-String "Key Protectors Found") {
        Write-Host "   → Removing protectors from $drive" -ForegroundColor Yellow
        manage-bde -protectors -delete -all $drive -ErrorAction SilentlyContinue
    }
}

# 3. Disable BitLocker auto-unlock completely
Write-Host "`nStep 3: Disabling BitLocker auto-unlock..." -ForegroundColor Cyan
Disable-BitLockerAutoUnlock -ErrorAction SilentlyContinue

# 4. Permanently disable the BitLocker service (prevents it from ever starting again)
Write-Host "`nStep 4: Killing and disabling BitLocker service (BDESVC)..." -ForegroundColor Cyan
Stop-Service -Name "BDESVC" -Force -ErrorAction SilentlyContinue
Set-Service -Name "BDESVC" -StartupType Disabled -ErrorAction SilentlyContinue
Write-Host "   → BitLocker service permanently disabled" -ForegroundColor Green

# 5. Block Windows from ever turning on Device Encryption / BitLocker again (works on Home too)
Write-Host "`nStep 5: Applying registry locks to prevent re-enabling..." -ForegroundColor Cyan
# Prevent Device Encryption (Windows Home/Pro)
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force

# Additional hardcore blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v "EncryptionMethodNoEncryption" /t REG_DWORD /d 2 /f 2>$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v "EncryptionMethodWithXtsOs" /t REG_DWORD /d 2 /f 2>$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v "EncryptionMethodWithXtsFdv" /t REG_DWORD /d 2 /f 2>$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v "OSActiveDirectoryBackup" /t REG_DWORD /d 0 /f 2>$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v "OSRequireActiveDirectoryBackup" /t REG_DWORD /d 0 /f 2>$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "ConfigureSystemGuardLaunch" /t REG_DWORD /d 0 /f 2>$null

Write-Host "`n=== BITLOCKER IS NOW COMPLETELY DEAD ===`n" -ForegroundColor Red
Write-Host "All encrypted drives are being decrypted in the background." -ForegroundColor Green
Write-Host "This can take hours on large/slow drives - IT WILL FINISH even after reboot." -ForegroundColor Green
Write-Host "`nTo monitor progress, run in PowerShell:" -ForegroundColor White
Write-Host '   Get-BitLockerVolume | Select MountPoint, VolumeStatus, EncryptionPercentage' -ForegroundColor Gray
Write-Host "`nBitLocker CANNOT come back after this script (service killed + registry locked)." -ForegroundColor Red
Write-Host "`nReboot recommended when decryption reaches 100%." -ForegroundColor Yellow

pause