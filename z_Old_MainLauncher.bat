@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Initialize script selection variables
set restorepoint=1
set script1=1
set script2=1
set script3=1
set script4=1
set script5=1
set script6=1
set script7=1
set script8=1
set script9=1
set script10=1
set script11=1
set script12=1
set script13=1
set script14=1
set script15=1
set script16=1

:MENU
mode con: cols=31 lines=8
cls
set choice=
echo  =============================
echo    WinConfigHelper Main Menu
echo  =============================
echo.
echo  1. Run all scripts
set submenu=
echo  2. Select scripts to run
set /p choice=" Select an option (1 or 2): "
if "%choice%"=="1" goto RUNSELECTED
if "%choice%"=="2" goto SUBMENU
goto MENU

:SUBMENU
:: Initialize script selection variables
set restorepoint=1
set script1=1
set script2=1
set script3=1
set script4=1
set script5=1
set script6=1
set script7=1
set script8=1
set script9=1
set script10=1
set script11=1
set script12=1
set script13=1
set script14=1
set script15=1
set script16=1

:SUBMENU_LOOP
mode con: cols=56 lines=27
cls
setlocal enabledelayedexpansion
echo =============================
echo   Select Scripts to Run
echo.
:SHOW_SCRIPTS
if %restorepoint%==1 (set box0=X) else (set box0= )
echo  [!box0!] 0. Create System Restore Point
if %script1%==1 (set box1=X) else (set box1= )
echo  [!box1!] 1. GamerOS Post Setup
if %script2%==1 (set box2=X) else (set box2= )
echo  [!box2!] 2. UWScript
if %script3%==1 (set box3=X) else (set box3= )
echo  [!box3!] 3. Gaming Debloater V14
if %script4%==1 (set box4=X) else (set box4= )
echo  [!box4!] 4. Windows 11 Debloater V206
if %script5%==1 (set box5=X) else (set box5= )
echo  [!box5!] 5. Advanced Debloater
if %script6%==1 (set box6=X) else (set box6= )
echo  [!box6!] 6. Hosts Setup
if %script7%==1 (set box7=X) else (set box7= )
echo  [!box7!] 7. Firewall Blocker
if %script8%==1 (set box8=X) else (set box8= )
echo  [!box8!] 8. Optimize Helper
if %script9%==1 (set box9=X) else (set box9= )
echo  [!box9!] 9. Time Changer [FIX]
if %script10%==1 (set box10=X) else (set box10= )
echo  [!box10!] 10. Snap Assist [FIX]
if %script11%==1 (set box11=X) else (set box11= )
echo  [!box11!] 11. Win11 VM Fix [FIX]
if %script12%==1 (set box12=X) else (set box12= )
echo  [!box12!] 12. WinAero
if %script13%==1 (set box13=X) else (set box13= )
echo  [!box13!] 13. enable Gamebar [FIX]
if %script14%==1 (set box14=X) else (set box14= )
echo  [!box14!] 14. Context Menu
if %script15%==1 (set box15=X) else (set box15= )
echo  [!box15!] 15. Remove Edge
if %script16%==1 (set box16=X) else (set box16= )
echo  [!box16!] 16. DE Keyboard [FIX]
echo.
echo Enter number (0-16) to toggle
echo S = start
echo B = back
echo A = Check all
echo U = Uncheck all
echo.
endlocal
set /p submenu="Select: "
if /i "%submenu%"=="S" goto RUNSELECTED
if /i "%submenu%"=="B" goto MENU
if /i "%submenu%"=="A" (
  set restorepoint=1
  set script1=1
  set script2=1
  set script3=1
  set script4=1
  set script5=1
  set script6=1
  set script7=1
  set script8=1
  set script9=1
  set script10=1
  set script11=1
  set script12=1
  set script13=1
  set script14=1
  set script15=1
  set script16=1
  goto SUBMENU_LOOP
)
if /i "%submenu%"=="U" (
  set restorepoint=0
  set script1=0
  set script2=0
  set script3=0
  set script4=0
  set script5=0
  set script6=0
  set script7=0
  set script8=0
  set script9=0
  set script10=0
  set script11=0
  set script12=0
  set script13=0
  set script14=0
  set script15=0
  set script16=0
  goto SUBMENU_LOOP
)
if "%submenu%"=="0" (if %restorepoint%==1 (set restorepoint=0) else (set restorepoint=1))
if "%submenu%"=="1" (if %script1%==1 (set script1=0) else (set script1=1))
if "%submenu%"=="2" (if %script2%==1 (set script2=0) else (set script2=1))
if "%submenu%"=="3" (if %script3%==1 (set script3=0) else (set script3=1))
if "%submenu%"=="4" (if %script4%==1 (set script4=0) else (set script4=1))
if "%submenu%"=="5" (if %script5%==1 (set script5=0) else (set script5=1))
if "%submenu%"=="6" (if %script6%==1 (set script6=0) else (set script6=1))
if "%submenu%"=="7" (if %script7%==1 (set script7=0) else (set script7=1))
if "%submenu%"=="8" (if %script8%==1 (set script8=0) else (set script8=1))
if "%submenu%"=="9" (if %script9%==1 (set script9=0) else (set script9=1))
if "%submenu%"=="10" (if %script10%==1 (set script10=0) else (set script10=1))
if "%submenu%"=="11" (if %script11%==1 (set script11=0) else (set script11=1))
if "%submenu%"=="12" (if %script12%==1 (set script12=0) else (set script12=1))
if "%submenu%"=="13" (if %script13%==1 (set script13=0) else (set script13=1))
if "%submenu%"=="14" (if %script14%==1 (set script14=0) else (set script14=1))
if "%submenu%"=="15" (if %script15%==1 (set script15=0) else (set script15=1))
if "%submenu%"=="16" (if %script16%==1 (set script16=0) else (set script16=1))
goto SUBMENU_LOOP

:RUNSELECTED
mode con: cols=120 lines=30
cd %~dp0
if %restorepoint%==1 (
    sc config VSS start= demand
    net start VSS
    sc config swprv start= demand
    net start swprv
    sc config winmgmt start= auto
    net start winmgmt
    :: Enable System Protection for C: if not already enabled
    powershell -ExecutionPolicy Bypass -Command "if (-not (Get-ComputerRestorePoint -ErrorAction SilentlyContinue)) { Enable-ComputerRestore -Drive 'C:\' }"
    :: Create a System Restore Point before running scripts
    powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'WinConfigHelper Restore Point %date% %time%' -RestorePointType 'MODIFY_SETTINGS'"
    if %errorlevel% neq 0 (
        echo Failed to create a system restore point. Continuing anyway...
    ) else (
        echo System restore point created successfully.
    )
) else (
    echo Skipping system restore point creation.
)

if %script1%==1 powershell -ExecutionPolicy Bypass -File .\GamerOS_PostSetup.ps1
if %script2%==1 powershell -ExecutionPolicy Bypass -File .\UWScript.ps1
if %script3%==1 powershell -ExecutionPolicy Bypass -File .\GamingDebloaterV14.ps1
if %script4%==1 powershell -ExecutionPolicy Bypass -File .\Windows11DebloaterV206.ps1
if %script5%==1 powershell -ExecutionPolicy Bypass -File .\advanceddebloater.ps1
if %script6%==1 start /wait %~dp0Hosts.bat
if %script7%==1 start /wait %~dp0Firewall_Blocker.bat
if %script8%==1 start /wait %~dp0Optimizer\OptimizeHelper.bat
if %script9%==1 start /wait %~dp0fixes\time_changer.bat
if %script10%==1 start /wait %~dp0fixes\SnapAssist.bat
if %script11%==1 start /wait %~dp0fixes\Win11DebloaterVMfix.bat
if %script12%==1 start /wait %~dp0fixes\WinAero.bat
if %script13%==1 start /wait %~dp0fixes\enable_Gamebar.bat
if %script14%==1 start /wait %~dp0fixes\contextmenu.bat
if %script15%==1 start /wait %~dp0tools\Edge_Remove.bat
if %script16%==1 powershell -ExecutionPolicy Bypass -File .\fixes\keyboard.ps1
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
