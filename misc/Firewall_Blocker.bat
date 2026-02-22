@echo on
title Firewall Blocker v1.1
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