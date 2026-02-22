cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File .\Uninstall-OneDrive_Optimizer.ps1
call "%~dp0OneDrive_Uninstaller_Optimizer.cmd"
call "%~dp0OneDriveUninstaller_privacy.sexy.bat"
exit /b 0