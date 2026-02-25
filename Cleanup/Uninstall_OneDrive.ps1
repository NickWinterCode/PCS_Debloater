# Ensure script is running as Administrator (Required for Registry/Winget operations)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Write-Warning "This script should be run as Administrator for best results." }

Write-Host "Kill OneDrive process"
taskkill.exe /F /IM "OneDrive.exe" 2>$null
taskkill.exe /F /IM "explorer.exe" 2>$null

Write-Host "Remove OneDrive"
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
$OneDriveUninstallString = Get-ItemPropertyValue "$regPath" -Name "UninstallString"
$OneDriveExe, $OneDriveArgs = $OneDriveUninstallString.Split(" ")
Start-Process -FilePath $OneDriveExe -ArgumentList "$OneDriveArgs /silent" -NoNewWindow -Wait

Write-Host "Copy all OneDrive to Root UserProfile"
robocopy "$env:USERPROFILE\OneDrive" "$env:USERPROFILE" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np | Out-Null

Write-Host "Removing OneDrive leftovers"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp"

# check if directory is empty before removing:
If ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:userprofile\OneDrive"
}

Write-Host "Remove Onedrive from explorer sidebar"
if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
}
Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue

Write-Host "Removing run hook for new users"
reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
reg unload "hku\Default"

Write-Host "Removing startmenu entry"
Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

Write-Host "Removing scheduled task"
Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

# Add Shell folders restoring default locations
Write-Host "Shell Fixing"
$shellKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
Set-ItemProperty -Path $shellKey -Name "AppData" -Value "$env:userprofile\AppData\Roaming" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Cache" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCache" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Cookies" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCookies" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Favorites" -Value "$env:userprofile\Favorites" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "History" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\History" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Local AppData" -Value "$env:userprofile\AppData\Local" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "My Music" -Value "$env:userprofile\Music" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "My Video" -Value "$env:userprofile\Videos" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "NetHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Network Shortcuts" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "PrintHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Printer Shortcuts" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Programs" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Recent" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Recent" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "SendTo" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\SendTo" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Start Menu" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Startup" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Templates" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Templates" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "$env:userprofile\Downloads" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Desktop" -Value "$env:userprofile\Desktop" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "My Pictures" -Value "$env:userprofile\Pictures" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "Personal" -Value "$env:userprofile\Documents" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" -Value "$env:userprofile\Documents" -Type ExpandString
Set-ItemProperty -Path $shellKey -Name "{0DDD015D-B06C-45D5-8C4C-F59713854639}" -Value "$env:userprofile\Pictures" -Type ExpandString

Write-Host "Restarting explorer"
Start-Process "explorer.exe"

Write-Host "Waiting for explorer to complete loading"
Write-Host "Please Note - OneDrive folder may still have items in it. You must manually delete it, but all the files should already be copied to the base user folder."
Start-Sleep 3