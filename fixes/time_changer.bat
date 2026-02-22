@echo off
REM Time format
tzutil /s "W. Europe Standard Time"
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sCurrency /t REG_SZ /d "€" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sDate /t REG_SZ /d "." /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sDecimal /t REG_SZ /d "," /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sGrouping /t REG_SZ /d "3;0" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sList /t REG_SZ /d ";" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sLongDate /t REG_SZ /d "dddd, d. MMMM yyyy" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sMonDecimalSep /t REG_SZ /d "," /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sMonGrouping /t REG_SZ /d "3;0" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sMonThousandSep /t REG_SZ /d "." /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sNativeDigits /t REG_SZ /d "0123456789" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sNegativeSign /t REG_SZ /d "-" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sPositiveSign /t REG_SZ /d "" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sShortDate /t REG_SZ /d "dd.MM.yyyy" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sThousand /t REG_SZ /d "." /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sTime /t REG_SZ /d ":" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sTimeFormat /t REG_SZ /d "HH:mm:ss" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sShortTime /t REG_SZ /d "HH:mm" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v sYearMonth /t REG_SZ /d "MMMM yyyy" /f
reg add "HKEY_CURRENT_USER\Control Panel\International" /v iCalendarType /t REG_SZ /d "1" /f

REM Turn ON Set time automatically
echo --- Set NTP (time) server to `pool.ntp.org`
sc config w32time start=demand
:: Configure time source
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
:: Stop time service if running
SC queryex "w32time"|Find "STATE"|Find /v "RUNNING">Nul||(
    net stop w32time
)
:: Start time service and sync now
net start w32time
w32tm /config /update
w32tm /resync /force
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v "Type" /t REG_SZ /d "NTP" /f

exit
