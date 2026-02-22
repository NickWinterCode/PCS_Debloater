@echo off
setlocal EnableExtensions

echo Set Visual Effects to Custom...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f

echo Enable requested effects...
rem Use drop shadows for icon labels on the desktop
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f
rem Show translucent selection rectangle
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f
rem Show window contents while dragging
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f
rem Show shadows under windows
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableShadow /t REG_DWORD /d 1 /f
rem Smooth edges of screen fonts (ClearType)
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f
rem Fade out menu items after clicking
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d 1 /f
rem Fade or slide menus into view
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d 1 /f
rem Show thumbnails instead of icons
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f
rem Slide open combo boxes
reg add "HKCU\Control Panel\Desktop" /v ComboBoxAnimation /t REG_SZ /d 1 /f
rem Smooth-scroll list boxes
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_SZ /d 1 /f
rem Fade or slide ToolTips into view
reg add "HKCU\Control Panel\Desktop" /v ToolTipAnimation /t REG_SZ /d 1 /f
rem Animate controls and elements inside windows
reg add "HKCU\Control Panel\Desktop" /v WindowAnimations /t REG_SZ /d 1 /f

echo Disable everything else...
rem Taskbar animations
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f
rem Animate windows when minimizing and maximizing
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v MinAnimate /t REG_SZ /d 0 /f
rem Aero Peek (Desktop Preview)
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisablePreviewDesktop /t REG_DWORD /d 1 /f
rem Save taskbar thumbnail previews
reg add "HKCU\Software\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f
rem Shadow under mouse pointer
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d 0 /f

echo Applying changes...
rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True

echo Restarting Explorer to apply most settings...
taskkill /f /im explorer.exe >nul 2>&1
start "" explorer.exe

echo Done. Some apps may require sign-out/in or reboot to fully apply.
endlocal