:: DO NOT DELTE, IMPORTANT FOR SCRIPT FINDING
cd /d %~dp0

:: Copy Wallpaper to Systems Location and RemoteControl to Users Desktop
copy "tools\PC-Spezialist_BG.jpg" "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg"
copy "tools\PCSpezialist Fernwartung.exe" "%userprofile%\Desktop\PCSpezialist Fernwartung.exe"

:: This PC on desktop
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f

:: Disables Screen Off and Sleepmode in powerplan
powercfg /X monitor-timeout-ac 0
powercfg /X monitor-timeout-dc 0
powercfg /X standby-timeout-ac 0
powercfg /X standby-timeout-dc 0

:: Apply Wallpaper
reg add "HKCU\control panel\desktop" /v wallpaper /t REG_SZ /d "" /f 
reg add "HKCU\control panel\desktop" /v wallpaper /t REG_SZ /d "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg" /f 
reg delete "HKCU\Software\Microsoft\Internet Explorer\Desktop\General" /v WallpaperStyle /f
reg add "HKCU\control panel\desktop" /v WallpaperStyle /t REG_SZ /d 2 /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
taskkill /im explorer.exe /f
explorer.exe

powershell -ExecutionPolicy Bypass -File .\tools\ProdInfo.ps1 
exit /b 0