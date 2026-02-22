$scriptName = [System.IO.Path]::GetFileName($PSCommandPath)
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFolder = Join-Path $env:USERPROFILE "Desktop\$env:COMPUTERNAME"
if (!(Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory | Out-Null }
$logFile = Join-Path $logFolder ("$scriptName-$timestamp.log")

Start-Transcript -Path $logFile -Force
Write-Output "Creating Restore Point incase something bad happens"
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"