@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
:: DO NOT DELTE, IMPORTANT FOR SCRIPT FINDING
cd %~dp0

:: Copy Wallpaper to Systems Location
copy "PC-Spezialist_BG.jpg" "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg"

:: Run Tweaks
powershell -ExecutionPolicy Bypass -File .\CreateRestorePoint.ps1
powershell -ExecutionPolicy Bypass -File .\Essential_Tweaks.ps1
powershell -ExecutionPolicy Bypass -File .\PC_Spezialist.ps1

:: Run Debloater
powershell -ExecutionPolicy Bypass -File .\Tools\metro_Microsoft_modern_apps_to_target_by_name.ps1
powershell -ExecutionPolicy Bypass -File .\Tools\metro_3rd_party_modern_apps_to_target_by_name.ps1

:: Misc.
start /wait %~dp0Optimizer\_OptimizeHelper.bat
start /wait %~dp0EnableGamebar.bat
start /wait %~dp0SnapAssist.bat
start /wait %~dp0RemoveEdge.bat
start /wait %~dp0Program_Installer.bat
start /wait %~dp0default_apps.bat

:: Run Temp Cleanup
start /wait %~dp0stage_1_tempclean\stage_1_tempclean.bat
start /wait %~dp0TempFileCleanup.bat

:: Move Logs to Desktop
move "%systemdrive%\logs" "%userprofile%\Desktop\%COMPUTERNAME%"

:: Delete Registry Files
cd C:\ 
del *.reg

::DONE 
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
