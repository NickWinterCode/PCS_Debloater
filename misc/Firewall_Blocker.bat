@echo on
title Firewall Blocker v1.1
for /f "delims=" %%i in ('powershell -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')"') do set datetime=%%i
set "logFolder=%userprofile%\Desktop\%COMPUTERNAME%"
if not exist "%logFolder%" mkdir "%logFolder%"
set "scriptName=%~nx0"
set "log=%logFolder%\%scriptName%_%datetime%.txt"

call :log > %log% 2>&1
::goto :eof
:log
setlocal enabledelayedexpansion

:: Path to the text file containing the IP addresses
set "filepath=%~dp0Firewall_ips.txt"

:: Read the file line by line
for /F "usebackq delims=" %%i in ("%filepath%") do (
 :: Construct the rule name
 set "rulename=Block IP - %%i"

 :: Check if the rule already exists
 netsh advfirewall firewall show rule name="!rulename!" > NUL 2>&1
 IF ERRORLEVEL 1 (
   echo Blocking IP: %%i
   netsh advfirewall firewall add rule name="!rulename!" dir=out action=block remoteip=%%i
   netsh advfirewall firewall add rule name="!rulename!" dir=in action=block remoteip=%%i
 ) ELSE (
   echo Rule !rulename! already exists, skipping.
 )
)

echo Done.
exit