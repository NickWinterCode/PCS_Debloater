Title Hosts v2.1
REM Checkfolder
setlocal enabledelayedexpansion

takeown /f "%SystemRoot%\System32\drivers\etc\hosts" /a
icacls "%SystemRoot%\System32\drivers\etc\hosts" /grant administrators:F
attrib -h -r -s "%SystemRoot%\System32\drivers\etc\hosts"

:: Define the path to your hosts file
set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"

:: Define the path to your text file containing the domains
set "domainsFile=%~dp0domains.txt"

:: Create a temporary file to store unique domains
set "tempFile=%temp%\uniqueDomains.txt"
if exist "%tempFile%" del "%tempFile%"

:: Copy all unique entries from the hosts file to the temporary file
for /F "delims=" %%i in ('type "%hostsFile%"') do (
 echo %%i >> "%tempFile%"
)

:: Loop through the lines in the domains file
for /F "delims=" %%i in (%domainsFile%) do (
 :: Check if the domain already exists in the temporary file
 findstr /m /c:"%%i" "%tempFile%" >nul || echo 0.0.0.0 %%i >> "%tempFile%"
)

:: Replace the original hosts file with the temporary file
move /y "%tempFile%" "%hostsFile%"

attrib +h +r +s "%SystemRoot%\system32\drivers\etc\hosts"
endlocal
exit