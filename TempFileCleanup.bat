@echo on
for /f "delims=" %%i in ('powershell -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')"') do set datetime=%%i
set "logFolder=%userprofile%\Desktop\%COMPUTERNAME%"
if not exist "%logFolder%" mkdir "%logFolder%"
set "scriptName=%~nx0"
set "log=%logFolder%\%scriptName%_%datetime%.log"

call :log > %log% 2>&1
:log
:: BatchGotAdmin

pushd %SystemDrive%
echo.
echo  Starting temp file cleanup
echo  --------------------------
echo.
echo  Cleaning USER temp files...
for /D %%x in ("%USERPROFILES%\*") do (
	del /F /Q "%%x\Documents\*.tmp" 2
	del /F /Q "%%x\My Documents\*.tmp" 2
	del /F /S /Q "%%x\*.blf" 2
	del /F /S /Q "%%x\*.regtrans-ms" 2
	del /F /S /Q "%%x\AppData\LocalLow\Sun\Java\*" 2
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\Cache\*" 2
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\JumpListIconsOld\*" 2
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\JumpListIcons\*" 2
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\Local Storage\http*.*" 2
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\Media Cache\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Internet Explorer\Recovery\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Terminal Server Client\Cache\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\Caches\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\Explorer\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\History\low\*" /AH 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\INetCache\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\WER\ReportArchive\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\WER\ReportQueue\*" 2
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\WebCache\*" 2
	del /F /S /Q "%%x\AppData\Local\Temp\*" 2
	del /F /S /Q "%%x\AppData\Roaming\Adobe\Flash Player\*" 2
	del /F /S /Q "%%x\AppData\Roaming\Microsoft\Teams\Service Worker\CacheStorage\*" 2
	del /F /S /Q "%%x\AppData\Roaming\Macromedia\Flash Player\*" 2
	del /F /S /Q "%%x\Application Data\Adobe\Flash Player\*" 2
	del /F /S /Q "%%x\Application Data\Macromedia\Flash Player\*" 2
	del /F /S /Q "%%x\Application Data\Microsoft\Dr Watson\*" 2
	del /F /S /Q "%%x\Application Data\Microsoft\Windows\WER\ReportArchive\*" 2
	del /F /S /Q "%%x\Application Data\Microsoft\Windows\WER\ReportQueue\*" 2
	del /F /S /Q "%%x\Application Data\Sun\Java\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\ApplicationHistory\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\Cache\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\JumpListIconsOld\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\JumpListIcons\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\Local Storage\http*.*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\Media Cache\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Microsoft\Dr Watson\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Microsoft\Internet Explorer\Recovery\*" 2
	del /F /S /Q "%%x\Local Settings\Application Data\Microsoft\Terminal Server Client\Cache\*" 2
	del /F /S /Q "%%x\Local Settings\Temp\*" 2
	del /F /S /Q "%%x\Local Settings\Temporary Internet Files\*" 2
	del /F /S /Q "%%x\Recent\*" 2
)
if exist %SystemDrive%\Windows.old\ (
 takeown /F %SystemDrive%\Windows.old\* /R /A /D Y
 echo y| cacls %SystemDrive%\Windows.old\*.* /C /T /grant administrators:F
 rmdir /S /Q %SystemDrive%\Windows.old\
 )
if exist %SystemDrive%\$Windows.~BT\ (
 takeown /F %SystemDrive%\$Windows.~BT\* /R /A
 icacls %SystemDrive%\$Windows.~BT\*.* /T /grant administrators:F
 rmdir /S /Q %SystemDrive%\$Windows.~BT\
 )
if exist %SystemDrive%\$Windows.~WS (
 takeown /F %SystemDrive%\$Windows.~WS\* /R /A
 icacls %SystemDrive%\$Windows.~WS\*.* /T /grant administrators:F
 rmdir /S /Q %SystemDrive%\$Windows.~WS\
 )
echo   Cleaning SYSTEM temp files...  && echo.
del /F /S /Q "%WINDIR%\TEMP\*" 2
rmdir /S /Q %SystemDrive%\Temp 2
for %%i in (bat,cmd,txt,log,jpg,jpeg,tmp,temp,bak,backup,exe) do (
	del /F /Q "%SystemDrive%\*.%%i" 2
)
for %%i in (NVIDIA,ATI,AMD,Dell,Intel,HP) do (
	rmdir /S /Q "%SystemDrive%\%%i" 2
)
if exist "%ProgramFiles%\Nvidia Corporation\Installer2" rmdir /s /q "%ProgramFiles%\Nvidia Corporation\Installer2"
if exist "%ALLUSERSPROFILE%\NVIDIA Corporation\NetService" del /f /q "%ALLUSERSPROFILE%\NVIDIA Corporation\NetService\*.exe"
if exist %SystemDrive%\MSOCache rmdir /S /Q %SystemDrive%\MSOCache
if exist %SystemDrive%\i386 rmdir /S /Q %SystemDrive%\i386
if exist %SystemDrive%\RECYCLER rmdir /s /q %SystemDrive%\RECYCLER
if exist %SystemDrive%\$Recycle.Bin rmdir /s /q %SystemDrive%\$Recycle.Bin
%REG% del "HKCU\SOFTWARE\Classes\Local Settings\Muicache" /f
echo. >> %LOGPATH%\%LOGFILE%
if exist "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportArchive" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportArchive"
if exist "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportQueue" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportQueue"
if exist "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Scans\History\Results\Quick" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Scans\History\Results\Quick"
if exist "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Scans\History\Results\Resource" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Scans\History\Results\Resource"
if exist "%ALLUSERSPROFILE%\Microsoft\Search\Data\Temp" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Search\Data\Temp"
del /F /Q %WINDIR%\*.log 2
del /F /Q %WINDIR%\*.txt 2
del /F /Q %WINDIR%\*.bmp 2
del /F /Q %WINDIR%\*.tmp 2
rmdir /S /Q %WINDIR%\Web\Wallpaper\Dell 2
if exist "%ProgramFiles%\NVIDIA Corporation\Installer" rmdir /s /q "%ProgramFiles%\NVIDIA Corporation\Installer" 2
if exist "%ProgramFiles%\NVIDIA Corporation\Installer2" rmdir /s /q "%ProgramFiles%\NVIDIA Corporation\Installer2" 2
if exist "%ProgramFiles(x86)%\NVIDIA Corporation\Installer" rmdir /s /q "%ProgramFiles(x86)%\NVIDIA Corporation\Installer" 2
if exist "%ProgramFiles(x86)%\NVIDIA Corporation\Installer2" rmdir /s /q "%ProgramFiles(x86)%\NVIDIA Corporation\Installer2" 2
if exist "%ProgramData%\NVIDIA Corporation\Downloader" rmdir /s /q "%ProgramData%\NVIDIA Corporation\Downloader" 2
if exist "%ProgramData%\NVIDIA\Downloader" rmdir /s /q "%ProgramData%\NVIDIA\Downloader" 2
echo %WIN_VER% | findstr /i /c:"server" 
if %ERRORLEVEL%==0 (
	echo.
	echo  ! Server operating system detected.
	echo    Removing built-in media files ^(.wav, .midi, etc^)...
	echo.
	echo.  && echo  ! Server operating system detected. Removing built-in media files ^(.wave, .midi, etc^)... && echo.
	echo    Taking ownership of %WINDIR%\Media in order to delete files... && echo.
	echo    Taking ownership of %WINDIR%\Media in order to delete files...  && echo.
	if exist %WINDIR%\Media takeown /f %WINDIR%\Media /r /d y 2 && echo.
	if exist %WINDIR%\Media icacls %WINDIR%\Media /grant administrators:F /t  && echo.
	rmdir /S /Q %WINDIR%\Media 2
	echo    Done.
	echo.
	echo    Done.
	echo.
)
echo %WIN_VER% | findstr /v /i /c:"Microsoft"  && del /F /Q %WINDIR%\logs\CBS\* 2
echo   Done. && echo.
timeout /t 1 /nobreak
exit
