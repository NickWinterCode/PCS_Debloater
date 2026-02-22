Disable-BitLocker -MountPoint "C:"
Clear-BitLockerAutoUnlock
Get-BitLockerVolume | Disable-BitLocker
if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker")) {
    New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker' -Name 'PreventDeviceEncryption' -Type DWord -Value 1 -Force
