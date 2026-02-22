@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd %~dp0
copy "PC-Spezialist_BG.jpg" "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg"
powershell -ExecutionPolicy Bypass -File .\01_CreateRestorePoint.ps1
powershell -ExecutionPolicy Bypass -File .\02_Essential_Tweaks.ps1
powershell -ExecutionPolicy Bypass -File .\03_winget_installer.ps1
powershell -ExecutionPolicy Bypass -File .\04_GamerOS_PostSetup.ps1
powershell -ExecutionPolicy Bypass -File .\05_UWScript.ps1
powershell -ExecutionPolicy Bypass -File .\06_PC-Spezialist.ps1
powershell -ExecutionPolicy Bypass -File .\Tools\metro_Microsoft_modern_apps_to_target_by_name.ps1
powershell -ExecutionPolicy Bypass -File .\Tools\metro_3rd_party_modern_apps_to_target_by_name.ps1
start /wait %~dp007_Program_Installer.bat
start /wait %~dp0Optimizer\01_OptimizeHelper.bat
start /wait %~dp008_EnableGamebar.bat
start /wait %~dp009_SnapAssist.bat
start /wait %~dp010_RemoveEdge.bat
start /wait %~dp0stage_1_tempclean\stage_1_tempclean.bat
start /wait %~dp011_TempFileCleanup.bat
move "%systemdrive%\logs" "%userprofile%\Desktop\%COMPUTERNAME%"
cd C:\ 
del *.reg
cls
echo.
echo  Done
:CHOICE
set /p userinp="Press ENTER to reboot, or E to exit: "
if /i "%userinp%"=="E" goto END
if "%userinp%"=="" goto REBOOT
goto CHOICE
:REBOOT
echo Rebooting...
shutdown /r /t 2
exit /b
:END
exit /b
