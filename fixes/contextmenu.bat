@echo off
setlocal

REM Add "Open Command Prompt here" (current user)

REM Right-click empty space in a folder
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHere" /ve /d "Open Command Prompt here" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHere" /v "Icon" /d "%SystemRoot%\System32\cmd.exe" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHere\command" /ve /d "cmd.exe /s /k pushd ""%%V""" /f

REM Right-click on a folder
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHere" /ve /d "Open Command Prompt here" /f
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHere" /v "Icon" /d "%SystemRoot%\System32\cmd.exe" /f
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHere\command" /ve /d "cmd.exe /s /k pushd ""%%1""" /f

REM Right-click on a drive
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHere" /ve /d "Open Command Prompt here" /f
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHere" /v "Icon" /d "%SystemRoot%\System32\cmd.exe" /f
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHere\command" /ve /d "cmd.exe /s /k pushd ""%%1""" /f

REM Right-click empty space in a folder (Admin)
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHereAdmin" /ve /d "Open Command Prompt here (Admin)" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHereAdmin" /v "Icon" /d "%SystemRoot%\System32\cmd.exe" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHereAdmin" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenCmdHereAdmin\command" /ve /d "powershell.exe -NoProfile -WindowStyle Hidden -Command ""Start-Process cmd.exe -Verb RunAs -ArgumentList '/s','/k','pushd','%%V'""" /f

REM Add "Open Command Prompt here (Admin)"

REM Right-click on a folder (Admin)
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHereAdmin" /ve /d "Open Command Prompt here (Admin)" /f
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHereAdmin" /v "Icon" /d "%SystemRoot%\System32\cmd.exe" /f
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHereAdmin" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCU\Software\Classes\Directory\shell\OpenCmdHereAdmin\command" /ve /d "powershell.exe -NoProfile -WindowStyle Hidden -Command ""Start-Process cmd.exe -Verb RunAs -ArgumentList '/s','/k','pushd','%%1'""" /f

REM Right-click on a drive (Admin)
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHereAdmin" /ve /d "Open Command Prompt here (Admin)" /f
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHereAdmin" /v "Icon" /d "%SystemRoot%\System32\cmd.exe" /f
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHereAdmin" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCU\Software\Classes\Drive\shell\OpenCmdHereAdmin\command" /ve /d "powershell.exe -NoProfile -WindowStyle Hidden -Command ""Start-Process cmd.exe -Verb RunAs -ArgumentList '/s','/k','pushd','%%1'""" /f

REM Add Restart Explorer Context Menu
reg add "HKCR\DesktopBackground\Shell\RestartExplorer" /v "Icon" /t REG_SZ /d "explorer.exe" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer" /v "Position" /t REG_SZ /d "Bottom" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer" /v "SubCommands" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer" /v "MUIVerb" /t REG_SZ /d "Restart Explorer" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer\shell\01Restart" /v "MUIVerb" /t REG_SZ /d "Restart Explorer" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer\shell\01Restart" /v "Icon" /t REG_SZ /d "explorer.exe" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer\shell\01Restart\command" /ve /t REG_EXPAND_SZ /d "cmd.exe /c taskkill /f /im explorer.exe  & start explorer.exe" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer\shell\02RestartWithPause" /v "MUIVerb" /t REG_SZ /d "Restart Explorer with pause" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer\shell\02RestartWithPause" /v "Icon" /t REG_SZ /d "explorer.exe" /f
reg add "HKCR\DesktopBackground\Shell\RestartExplorer\shell\02RestartWithPause\command" /ve /t REG_EXPAND_SZ /d "cmd.exe /c @echo off & echo The explorer.exe process will be terminated & echo. & taskkill /f /im explorer.exe & echo. & echo Done & echo. & echo Press any key to start explorer.exe process & pause>NUL & start explorer.exe & exit" /f

REM Add "Restart Start menu" to Desktop and Explorer background menus

REM Desktop background
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu" /ve /d "Restart Start menu" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu" /v "Icon" /d "%SystemRoot%\explorer.exe" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu" /v "Position" /d "Bottom" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu\command" /ve /d "powershell.exe -NoProfile -WindowStyle Hidden -Command \"Stop-Process -Name StartMenuExperienceHost -Force -ErrorAction SilentlyContinue; Stop-Process -Name ShellExperienceHost -Force -ErrorAction SilentlyContinue\"" /f
REM Folder background (inside File Explorer windows)
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu" /ve /d "Restart Start menu" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu" /v "Icon" /d "%SystemRoot%\explorer.exe" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\RestartStartMenu\command" /ve /d "powershell.exe -NoProfile -WindowStyle Hidden -Command ""Stop-Process -Name StartMenuExperienceHost -Force -ErrorAction SilentlyContinue; Stop-Process -Name ShellExperienceHost -Force -ErrorAction SilentlyContinue""" /f

exit