@echo on

:: BatchGotAdmin

pushd %SystemDrive%
echo.
echo  Starting temp file cleanup
echo  --------------------------
echo.
echo  Cleaning USER temp files...
for /D %%x in ("%USERPROFILES%\*") do (
	del /F /Q "%%x\Documents\*.tmp"
	del /F /Q "%%x\My Documents\*.tmp"
	del /F /S /Q "%%x\*.blf"
	del /F /S /Q "%%x\*.regtrans-ms"
	del /F /S /Q "%%x\AppData\LocalLow\Sun\Java\*"
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\Cache\*"
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\JumpListIconsOld\*"
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\JumpListIcons\*"
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\Local Storage\http*.*"
	del /F /S /Q "%%x\AppData\Local\Google\Chrome\User Data\Default\Media Cache\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Internet Explorer\Recovery\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Terminal Server Client\Cache\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\Caches\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\Explorer\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\History\low\*" /AH
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\INetCache\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\Temporary Internet Files\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\WER\ReportArchive\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\WER\ReportQueue\*"
	del /F /S /Q "%%x\AppData\Local\Microsoft\Windows\WebCache\*"
	del /F /S /Q "%%x\AppData\Local\Temp\*"
	del /F /S /Q "%%x\AppData\Roaming\Adobe\Flash Player\*"
	del /F /S /Q "%%x\AppData\Roaming\Microsoft\Teams\Service Worker\CacheStorage\*"
	del /F /S /Q "%%x\AppData\Roaming\Macromedia\Flash Player\*"
	del /F /S /Q "%%x\Application Data\Adobe\Flash Player\*"
	del /F /S /Q "%%x\Application Data\Macromedia\Flash Player\*"
	del /F /S /Q "%%x\Application Data\Microsoft\Dr Watson\*"
	del /F /S /Q "%%x\Application Data\Microsoft\Windows\WER\ReportArchive\*"
	del /F /S /Q "%%x\Application Data\Microsoft\Windows\WER\ReportQueue\*"
	del /F /S /Q "%%x\Application Data\Sun\Java\*"
	del /F /S /Q "%%x\Local Settings\Application Data\ApplicationHistory\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\Cache\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\JumpListIconsOld\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\JumpListIcons\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\Local Storage\http*.*"
	del /F /S /Q "%%x\Local Settings\Application Data\Google\Chrome\User Data\Default\Media Cache\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Microsoft\Dr Watson\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Microsoft\Internet Explorer\Recovery\*"
	del /F /S /Q "%%x\Local Settings\Application Data\Microsoft\Terminal Server Client\Cache\*"
	del /F /S /Q "%%x\Local Settings\Temp\*"
	del /F /S /Q "%%x\Local Settings\Temporary Internet Files\*"
	del /F /S /Q "%%x\Recent\*"
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
del /F /S /Q "%WINDIR%\TEMP\*"
rmdir /S /Q %SystemDrive%\Temp
for %%i in (bat,cmd,txt,log,jpg,jpeg,tmp,temp,bak,backup,exe) do (
	del /F /Q "%SystemDrive%\*.%%i"
)
for %%i in (NVIDIA,ATI,AMD,Dell,Intel,HP) do (
	rmdir /S /Q "%SystemDrive%\%%i"
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
del /F /Q %WINDIR%\*.log
del /F /Q %WINDIR%\*.txt
del /F /Q %WINDIR%\*.bmp
del /F /Q %WINDIR%\*.tmp
rmdir /S /Q %WINDIR%\Web\Wallpaper\Dell
if exist "%ProgramFiles%\NVIDIA Corporation\Installer" rmdir /s /q "%ProgramFiles%\NVIDIA Corporation\Installer"
if exist "%ProgramFiles%\NVIDIA Corporation\Installer2" rmdir /s /q "%ProgramFiles%\NVIDIA Corporation\Installer2"
if exist "%ProgramFiles(x86)%\NVIDIA Corporation\Installer" rmdir /s /q "%ProgramFiles(x86)%\NVIDIA Corporation\Installer"
if exist "%ProgramFiles(x86)%\NVIDIA Corporation\Installer2" rmdir /s /q "%ProgramFiles(x86)%\NVIDIA Corporation\Installer2"
if exist "%ProgramData%\NVIDIA Corporation\Downloader" rmdir /s /q "%ProgramData%\NVIDIA Corporation\Downloader"
if exist "%ProgramData%\NVIDIA\Downloader" rmdir /s /q "%ProgramData%\NVIDIA\Downloader"
echo %WIN_VER% | findstr /i /c:"server" 
if %ERRORLEVEL%==0 (
	echo.
	echo  ! Server operating system detected.
	echo    Removing built-in media files ^(.wav, .midi, etc^)...
	echo.
	echo.  && echo  ! Server operating system detected. Removing built-in media files ^(.wave, .midi, etc^)... && echo.
	echo    Taking ownership of %WINDIR%\Media in order to delete files... && echo.
	echo    Taking ownership of %WINDIR%\Media in order to delete files...  && echo.
	if exist %WINDIR%\Media takeown /f %WINDIR%\Media /r /d y && echo.
	if exist %WINDIR%\Media icacls %WINDIR%\Media /grant administrators:F /t && echo.
	rmdir /S /Q %WINDIR%\Media
	echo    Done.
	echo.
	echo    Done.
	echo.
)
echo %WIN_VER% | findstr /v /i /c:"Microsoft"  && del /F /Q %WINDIR%\logs\CBS\*
echo   Done. && echo.
timeout /t 1 /nobreak
exit
