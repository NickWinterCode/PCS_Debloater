@echo off
REM Snap Assistent
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableSnapAssistFlyout" /t REG_DWORD /d "1" /f
reg add "HKCU\Control Panel\Desktop" /v "DockMoving" /t REG_SZ /d "1" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V "SnapFill" /T REG_DWORD /D "0" /F
reg add "HKCU\Control Panel\Desktop" /V "WindowArrangementActive" /D "1" /F

:: Enable Snap Assist
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SnapAssist /t REG_DWORD /d 1 /f >nul

:: Enable all 5 snap behaviors (Windows 10/11)
reg add "HKCU\Control Panel\Desktop" /v WindowArrangementActive /t REG_SZ /d 1 /f >nul

:: These keys control individual snap features in Settings UI
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SnapFill /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SnapView /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SnapMoveSize /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SnapSizing /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SnapArrange /t REG_DWORD /d 1 /f >nul

:: Also ensure taskbar snap is enabled (affects dragging to edges)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarGlomLevel /t REG_DWORD /d 0 /f >nul

:: Restart Explorer to apply changes immediately
echo Restarting Explorer to apply settings...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

exit