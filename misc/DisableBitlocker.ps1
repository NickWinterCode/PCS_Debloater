Disable-BitLocker -MountPoint "C:"
Clear-BitLockerAutoUnlock
Get-BitLockerVolume | Disable-BitLocker