cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File .\Uninstall-OneDrive.ps1
call "%~dp0OneDrive_Uninstaller.cmd"
call "%~dp0OneDriveUninstaller.bat"
exit /b 0