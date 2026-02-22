@echo off
REM Snap Assistent
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableSnapAssistFlyout /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\Desktop" /v "DockMoving" /t REG_SZ /d "1" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V "SnapFill" /T REG_DWORD /D "0" /F
reg add "HKCU\Control Panel\Desktop" /V "WindowArrangementActive" /D "1" /F
exit