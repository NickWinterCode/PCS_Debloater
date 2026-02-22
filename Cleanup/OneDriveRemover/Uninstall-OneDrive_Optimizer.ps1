# Run as Administrator!

Write-Host "Uninstalling OneDrive..." -ForegroundColor Cyan

# Run OneDrive uninstaller (adjust architecture if needed)
$oneDriveUninstall = "$env:SystemRoot\System32\OneDriveSetup.exe"
if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
    $oneDriveUninstall = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
}

Start-Process -FilePath $oneDriveUninstall -ArgumentList "/uninstall" -Wait

# Disable OneDrive via policy
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord

# Prevent traffic before user sign-in
$oneDrivePath = "HKLM:\SOFTWARE\Microsoft\OneDrive"
New-Item -Path $oneDrivePath -Force | Out-Null
Set-ItemProperty -Path $oneDrivePath -Name "PreventNetworkTrafficPreUserSignIn" -Value 1 -Type DWord

# Remove OneDrive folders
$folders = @(
    "$env:USERPROFILE\OneDrive",
    "$env:SystemDrive\OneDriveTemp",
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:ProgramData\Microsoft OneDrive"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        try {
            Remove-Item $folder -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted: ${folder}"
        } catch {
            Write-Warning "Failed to delete ${folder}: $_"
        }
    }
}

# Delete scheduled tasks
$schedTasks = @(
    "OneDrive Standalone Update Task",
    "OneDrive Standalone Update Task v2"
)

foreach ($task in $schedTasks) {
    schtasks.exe /Delete /TN "$task" /F | Out-Null
}

# Remove OneDrive from Windows Explorer
$clsidPath = "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$attributes = 0xb090010d

New-Item -Path $clsidPath -Force | Out-Null
Set-ItemProperty -Path $clsidPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord

$shellFolderPath = "$clsidPath\ShellFolder"
New-Item -Path $shellFolderPath -Force | Out-Null
Set-ItemProperty -Path $shellFolderPath -Name "Attributes" -Value $attributes -Type DWord

# Remove from startup
try {
    $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty -Path $runKey -Name "OneDriveSetup" -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Failed to remove OneDriveSetup from startup: $_"
}

Write-Host "OneDrive has been uninstalled and cleaned up." -ForegroundColor Green
