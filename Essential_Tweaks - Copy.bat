@echo off
setlocal enabledelayedexpansion
REM original from: [https://freetimetech.com/windows-11-debloater-tool-debloat-gui/]
REM Converted from PowerShell to Batch

echo [92m----- Running Essential Tweaks ----- [0m
echo [92m----- Disabling Telemetry ----- [0m
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
:: Disable Content Delivery Manager
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f
:: Disable SIUF
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f
:: Disable Feedback-Notifications
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClient" /Disable
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f
:: Disable Error-Reporting
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable
:: Config Delivery-Optimization to download from LAN
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d 1 /f
:: Disable Diagnostics-Tracking
net stop "DiagTrack"
sc config "DiagTrack" start= disabled
:: Disable Diagnostics-Tracking
net stop "dmwappushservice"
sc config "dmwappushservice" start= disabled
:: Set Legacy Boot
bcdedit /set {current} bootmenupolicy Legacy
:: Disable Remote-Assistance
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f
:: Disable SysMain
net stop "SysMain"
sc config "SysMain" start= disabled

:: Disable Taskbar-Buttons
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" /v "EnthusiastMode" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v "PeopleBand" /t REG_DWORD /d 0 /f
:: Open Explorer in ThisPC
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f
:: Remove MyComputer from Explorer
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" /f

echo [92m----- Performance Tweaks and More Telemetry ----- [0m
:: Disable Driver-Searching
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f
:: Set System-Responsiveness
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 10 /f
:: Set Network-Throttling
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f
:: Set WaitToKillServiceTimeout
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_DWORD /d 2000 /f
:: Set MenuShowDelay
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_DWORD /d 1 /f
:: Set WaitToKillServiceTimeout
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillServiceTimeout" /t REG_DWORD /d 2000 /f
:: Set ClearPageFileAtShutdown
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f
:: Set MouseHoverTime
reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_DWORD /d 10 /f

echo [92m----- Disable 8.3 NTFS names ----- [0m
fsutil behavior set disable8dot3 1

echo [92m----- Network Tweaks ----- [0m
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "IRPStackSize" /t REG_DWORD /d 20 /f

echo [92m----- Group svchost.exe processes ----- [0m

for /f %%a in ('powershell -command "(Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb"') do set ramKB=%%a
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d %ramKB% /f

echo [92m----- Remove 'News and Interest' from taskbar ----- [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f

echo [92m----- Remove 'Meet Now' button from taskbar ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d 1 /f

echo [92m----- Disable Diagnosic Tracking ----- [0m
if exist "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl" (
    del "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"
)
icacls "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\AutoLogger" /deny SYSTEM:(OI)(CI)F

net stop "DiagTrack"
sc config "DiagTrack" start= disabled

echo [92m----- Disabling Wi-Fi Sense ----- [0m
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v "Value" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v "Value" /t REG_DWORD /d 0 /f

echo [92m----- Disabling Activity History ----- [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f

echo [92m----- Disabling Location Tracking ----- [0m
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" /v "Status" /t REG_DWORD /d 0 /f

reg add "HKLM\SYSTEM\Maps" /v "AutoUpdateEnabled" /t REG_DWORD /d 0 /f

echo [92m----- Disabling Storage Sense ----- [0m
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /f

echo [92m----- Enabling Hibernation ----- [0m
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Power" /v "HibernteEnabled" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v "ShowHibernateOption" /t REG_DWORD /d 1 /f

echo [92m----- Disabling GameDVR ----- [0m
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f

::echo [92m----- Disabling Power Throttling ----- [0m
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f

echo [92m----- Restoring Clipboard History ----- [0m
reg add "HKCU\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /f

echo [92m----- Disabling New Outlook ----- [0m
reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences" /v "UseNewOutlook" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Office\16.0\Outlook\Options\General" /v "HideNewOutlookToggle" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General" /v "DoNewOutlookAutoMigration" /t REG_DWORD /d 0 /f
reg delete "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences" /v "NewOutlookMigrationUserSetting" /f

echo [92m----- Enabling Detailed BSoD ----- [0m
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "DisplayParameters" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "DisableEmoticon" /t REG_DWORD /d 1 /f

echo [92m----- Disabling S3 Sleep ----- [0m
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /f

echo [92m----- Enabling NumLock on Startup ----- [0m
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

echo [92m----- Enabling Verbose Messages During Logon ----- [0m
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "VerboseStatus" /t REG_DWORD /d 1 /f

echo [92m----- Disabling Cross-Device Resume ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" /v "IsResumeAllowed" /t REG_DWORD /d 0 /f

echo [92m----- Disabling Sticky Keys ----- [0m
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f

echo [92m----- Removing Settings Home Page ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f


echo [92m----- Creating Custom Power Plan ----- [0m
:: Create and activate custom power plan
powercfg /duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e 99999999-9999-9999-9999-999999999900
powercfg /SETACTIVE 99999999-9999-9999-9999-999999999900

:: Registry modifications
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabledDefault /t REG_DWORD /d 0 /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v ShowLockOption /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v ShowSleepOption /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v ValueMax /t REG_DWORD /d 0 /f
reg add "HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683" /v Attributes /t REG_DWORD /d 2 /f
reg add "HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009" /v Attributes /t REG_DWORD /d 2 /f

:: Modify Power Plan settings
:: Hard Disk - Turn off hard disk after
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0x00000000

:: Desktop Background Settings - Slide show
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 0x00000000

:: Wireless Adapter Settings - Power saving mode
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0x00000000

:: Sleep settings
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0x00000000
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0x00000000
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0x00000000
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0x00000000

:: USB Settings
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0x00000000
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0x00000000
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0x00000000

:: PCI Express - Link State Power Management
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0x00000000

:: Display settings - Turn off Display After setting
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0x00000000
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0x00000000

:: Set display off after 5 minutes (300 seconds) on battery
powercfg /change monitor-timeout-dc 5

:: Set sleep after 15 minutes (900 seconds) on battery
powercfg /change standby-timeout-dc 15

:: Set minimum processor state to 5% on battery
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999900 SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999900 SUB_PROCESSOR PROCTHROTTLEMIN 5

:: Apply the changes
powercfg /setactive 99999999-9999-9999-9999-999999999900

echo [92m----- Recommended Power Settings Applied. ----- [0m

REM Define the list of scheduled tasks to disable
echo [92m----- Disabling scheduled tasks ----- [0m
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClient" /Disable
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\MareBackup" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\PcaPatchDbTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Maps\MapsUpdateTask" /Disable

echo [92m----- Disabling Telemetry and Stuff ----- [0m
:: Disable AutoComplete
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "Append Completion" /t REG_SZ /d "yes" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest" /t REG_SZ /d "yes" /f
:: Enable CrashDumps
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d 3 /f
:: Disable RemoteAssistance
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f
:: Disable Shaking
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f
:: Disable Copy To and Move To context menu
reg add "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /ve /d "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /f
reg add "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /ve /d "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" /f
:: Disable AutoEndTasks
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d "1000" /f
:: Disable LowDiskSpaceChecks
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "LinkResolveIgnoreLinkInfo" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInternetOpenWith" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
net stop "DiagTrack"
net stop "diagsvc"
net stop "diagnosticshub.standardcollector.service"
net stop "dmwappushservice"
sc.exe config "RemoteRegistry" start= disabled
:: Disable Diagnostics
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\diagsvc" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\diagnosticshub.standardcollector.service" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v "Start" /t REG_DWORD /d 4 /f
:: Hide File Extensions
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "AlwaysOn" /t REG_DWORD /d 1 /f
:: Setting Gamemode
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "GPU Priority" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Priority" /t REG_DWORD /d 8 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "SFIO Priority" /t REG_SZ /d "High" /f
:: Disable Media Foundation
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation" /v "EnableFrameServerMode" /t REG_DWORD /d 0 /f

echo [92m----- Disable Bing Search in Start Menu ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f

echo [92m----- Enable NumLock on Startup ----- [0m
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

echo [92m----- Enable Verbose Status During Logon and Shutdown ----- [0m
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "VerboseStatus" /t REG_DWORD /d 1 /f

echo [92m----- Enable Mouse Acceleration ----- [0m
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f

echo [92m----- Disable StickyKeys ----- [0m
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "58" /f

echo [92m----- Disable 'Try the new Outlook' toggle ----- [0m
reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences" /v "UseNewOutlook" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Office\16.0\Outlook\Options\General" /v "HideNewOutlookToggle" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General" /v "DoNewOutlookAutoMigration" /t REG_DWORD /d 0 /f
REG DELETE "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences" /v "NewOutlookMigrationUserSetting" /f

echo [92m----- Enable Search Icon on Taskbar ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 1 /f

echo [92m----- Hide Task View Button ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f

echo [92m----- Disable Widgets in Taskbar ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f

echo [92m----- Disable Cross-Device Resume ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" /v "IsResumeAllowed" /t REG_DWORD /d 0 /f

echo [92m----- Disable Windows Consumer Features ----- [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f

echo [92m----- Disable Scheduled Tasks ----- [0m
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /DISABLE
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClient" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Application Experience\MareBackup" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Application Experience\PcaPatchDbTask" /DISABLE
schtasks /Change /TN "Microsoft\Windows\Maps\MapsUpdateTask" /DISABLE

echo [92m----- Disable Telemetry and Data Collection ----- [0m
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f
REG DELETE "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f

echo [92m----- Misc. Tweaks ----- [0m
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" /v "EnthusiastMode" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v "PeopleBand" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\ControlSet001\Services\Ndu" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "IRPStackSize" /t REG_DWORD /d 30 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f

echo [92m----- Debloat Microsoft Edge ----- [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ShowRecommendationsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HideFirstRunExperience" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "UserFeedbackAllowed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ConfigureDoNotTrack" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "AlternateErrorPagesEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeCollectionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeShoppingAssistantEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "MicrosoftEdgeInsiderPromotionEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ShowMicrosoftRewards" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WebWidgetAllowed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DiagnosticData" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeAssetDeliveryServiceEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "CryptoWalletEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WalletDonationEnabled" /t REG_DWORD /d 0 /f

echo [92m----- DisableEdgeTelemetry ----- [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge" /v "UserFeedbackAllowed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "UserFeedbackAllowed" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "MetricsReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge" /v "MetricsReportingEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\BooksLibrary" /v "EnableExtendedBooksTelemetry" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\MicrosoftEdge\BooksLibrary" /v "EnableExtendedBooksTelemetry" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Edge\SmartScreenEnabled" /ve /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Edge\SmartScreenPuaEnabled" /ve /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ExtensionManifestV2Availability" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "Edge3PSerpTelemetryEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SpotlightExperiencesAndRecommendationsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge" /v "SpotlightExperiencesAndRecommendationsEnabled" /t REG_DWORD /d 0 /f

echo [92m----- DisableEdgeDiscoverBar ----- [0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WebWidgetAllowed" /t REG_DWORD /d 0 /f

echo [92m----- DisableCoPilotAI ----- [0m
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DefaultBrowserSettingsCampaignEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ComposeInlineEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f

echo [92m----- Turning on Hibernation ----- [0m
powercfg /hibernate on

::echo [92m----- Disable Exploer Automatic Folder Discovery ----- [0m
::REG DELETE "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f
::REG DELETE "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f
::reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f

echo [92m----- Enable Snap-Assistent ----- [0m
reg add "HKCU\Control Panel\Desktop" /v "WindowArrangementActive" /t REG_SZ /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableSnapAssistFlyout" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapAssist" /t REG_DWORD /d 1 /f

echo [92m----- EnableAutomaticUpdates ----- [0m
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" /v "SystemSettingsDownloadMode" /f
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "UxOption" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /f

echo [92m----- DisableStartMenuAds ----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Mobility" /v "OptedIn" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000326Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314559Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "AllowOnlineTips" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f

echo [92m----- Show all active Windows on every Taskbar----- [0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "MMTaskbarMode" /t REG_DWORD /d "0" /f

echo [92m----- Enabling scrolling on inactive windows----- [0m
reg add "HKCU\Control Panel\Desktop" /v "MouseWheelRouting" /t REG_DWORD /d 2 /f

echo [92m----- Set time automatically ----- [0m
net start w32time
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
w32tm /config /update
w32tm /resync

echo [92m----- Enable Widnows Spotlight ----- [0m
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightWindowsWelcomeExperience" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnActionCenter" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnSettings" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableThirdPartySuggestions" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d 0 /f

echo [92m----- Disabling Unnecessary Services ----- [0m
sc config "HomeGroupListener" start= demand
sc config "HomeGroupProvider" start= demand
sc config "AJRouter" start= disabled
sc config "ALG" start= demand
sc config "AppIDSvc" start= demand
sc config "AppMgmt" start= demand
sc config "AppReadiness" start= demand
sc config "AppVClient" start= disabled
sc config "Appinfo" start= demand
sc config "AssignedAccessManagerSvc" start= disabled
sc config "AudioEndpointBuilder" start= auto
sc config "AudioSrv" start= auto
sc config "Audiosrv" start= auto
sc config "AxInstSV" start= demand
sc config "BDESVC" start= demand
sc config "BFE" start= auto
sc config "BITS" start= delayed-auto
sc config "BTAGService" start= demand
sc config "BcastDVRUserService" start= demand
sc config "BluetoothUserService" start= demand
sc config "BrokerInfrastructure" start= auto
sc config "Browser" start= demand
sc config "BthHFSrv" start= auto
sc config "CDPSvc" start= demand
sc config "CDPUserSvc" start= auto
sc config "COMSysApp" start= demand
sc config "CaptureService" start= demand
sc config "CertPropSvc" start= demand
sc config "ClipSVC" start= demand
sc config "ConsentUxUserSvc" start= demand
sc config "CoechoessagingRegistrar" start= auto
sc config "CredentialEnrollmentManagerUserSvc" start= demand
sc config "CryptSvc" start= auto
sc config "CscService" start= demand
sc config "DPS" start= auto
sc config "DcomLaunch" start= auto
sc config "DcpSvc" start= demand
sc config "DevQueryBroker" start= demand
sc config "DeviceAssociationBrokerSvc" start= demand
sc config "DeviceAssociationService" start= demand
sc config "DeviceInstall" start= demand
sc config "DevicePickerUserSvc" start= demand
sc config "DevicesFlowUserSvc" start= demand
sc config "Dhcp" start= auto
sc config "DiagTrack" start= disabled
sc config "DialogBlockingService" start= disabled
sc config "DispBrokerDesktopSvc" start= auto
sc config "DisplayEnhancementService" start= demand
sc config "DmEnrollmentSvc" start= demand
sc config "Dnscache" start= auto
sc config "EFS" start= demand
sc config "EapHost" start= demand
sc config "EntAppSvc" start= demand
sc config "EventLog" start= auto
sc config "EventSystem" start= auto
sc config "FDResPub" start= demand
sc config "Fax" start= demand
sc config "FontCache" start= auto
sc config "FrameServer" start= demand
sc config "FrameServerMonitor" start= demand
sc config "GraphicsPerfSvc" start= demand
sc config "HvHost" start= demand
sc config "IEEtwCollectorService" start= demand
sc config "IKEEXT" start= demand
sc config "InstallService" start= demand
sc config "IpxlatCfgSvc" start= demand
sc config "KtmRm" start= demand
sc config "LSM" start= auto
sc config "LanmanServer" start= auto
sc config "LanmanWorkstation" start= auto
sc config "LicenseManager" start= demand
sc config "LxpSvc" start= demand
sc config "MSDTC" start= demand
sc config "MSiSCSI" start= demand
sc config "MapsBroker" start= delayed-auto
sc config "McpManagementService" start= demand
sc config "MessagingService" start= demand
sc config "MicrosoftEdgeElevationService" start= demand
sc config "MixedRealityOpenXRSvc" start= demand
sc config "MpsSvc" start= auto
sc config "MsKeyboardFilter" start= demand
sc config "NPSMSvc" start= demand
sc config "NaturalAuthentication" start= demand
sc config "NcaSvc" start= demand
sc config "NcbService" start= demand
sc config "NcdAutoSetup" start= demand
sc config "NetSetupSvc" start= demand
sc config "NetTcpPortSharing" start= disabled
sc config "Netman" start= demand
sc config "NgcCtnrSvc" start= demand
sc config "NgcSvc" start= demand
sc config "NlaSvc" start= demand
sc config "OneSyncSvc" start= auto
sc config "P9RdrService" start= demand
sc config "PNRPAutoReg" start= demand
sc config "PNRPsvc" start= demand
sc config "PcaSvc" start= demand
sc config "PeerDistSvc" start= demand
sc config "PenService" start= demand
sc config "PerfHost" start= demand
sc config "PhoneSvc" start= demand
sc config "PimIndexMaintenanceSvc" start= demand
sc config "PlugPlay" start= demand
sc config "PolicyAgent" start= demand
sc config "Power" start= auto
sc config "PrintNotify" start= demand
sc config "PrintWorkflowUserSvc" start= demand
sc config "ProfSvc" start= auto
sc config "PushToInstall" start= demand
sc config "QWAVE" start= demand
sc config "RasAuto" start= demand
sc config "RasMan" start= demand
sc config "echooteAccess" start= disabled
sc config "echooteRegistry" start= disabled
sc config "RetailDemo" start= demand
sc config "RmSvc" start= demand
sc config "RpcEptMapper" start= auto
sc config "RpcLocator" start= demand
sc config "RpcSs" start= auto
sc config "SCPolicySvc" start= demand
sc config "SCardSvr" start= demand
sc config "SDRSVC" start= demand
sc config "SEMgrSvc" start= demand
sc config "SENS" start= auto
sc config "SNMPTRAP" start= demand
sc config "SNMPTrap" start= demand
sc config "SSDPSRV" start= demand
sc config "SamSs" start= auto
sc config "ScDeviceEnum" start= demand
sc config "Schedule" start= auto
sc config "SecurityHealthService" start= demand
sc config "Sense" start= demand
sc config "SensorDataService" start= demand
sc config "SensorService" start= demand
sc config "SensrSvc" start= demand
sc config "SessionEnv" start= demand
sc config "SharedAccess" start= demand
sc config "SharedRealitySvc" start= demand
sc config "ShellHWDetection" start= auto
sc config "SmsRouter" start= demand
sc config "Spooler" start= auto
sc config "SstpSvc" start= demand
sc config "StiSvc" start= demand
sc config "StorSvc" start= demand
sc config "SysMain" start= auto
sc config "SystemEventsBroker" start= auto
sc config "TabletInputService" start= demand
sc config "TapiSrv" start= demand
sc config "Themes" start= auto
sc config "TieringEngineService" start= demand
sc config "TimeBroker" start= demand
sc config "TimeBrokerSvc" start= demand
sc config "TokenBroker" start= demand
sc config "TrkWks" start= auto
sc config "TroubleshootingSvc" start= demand
sc config "TrustedInstaller" start= demand
sc config "UI0Detect" start= demand
sc config "UdkUserSvc" start= demand
sc config "UevAgentService" start= disabled
sc config "UmRdpService" start= demand
sc config "UnistoreSvc" start= demand
sc config "UserDataSvc" start= demand
sc config "UserManager" start= auto
sc config "VGAuthService" start= auto
sc config "VMTools" start= auto
sc config "VSS" start= demand
sc config "VacSvc" start= demand
sc config "W32Time" start= demand
sc config "WEPHOSTSVC" start= demand
sc config "WFDSConMgrSvc" start= demand
sc config "WMPNetworkSvc" start= demand
sc config "WManSvc" start= demand
sc config "WPDBusEnum" start= demand
sc config "WSService" start= demand
sc config "WSearch" start= delayed-auto
sc config "WalletService" start= demand
sc config "WarpJITSvc" start= demand
sc config "WbioSrvc" start= demand
sc config "Wcmsvc" start= auto
sc config "WcsPlugInService" start= demand
sc config "WdNisSvc" start= demand
sc config "WdiServiceHost" start= demand
sc config "WdiSystemHost" start= demand
sc config "WebClient" start= demand
sc config "Wecsvc" start= demand
sc config "WerSvc" start= demand
sc config "WiaRpc" start= demand
sc config "WinDefend" start= auto
sc config "WinHttpAutoProxySvc" start= demand
sc config "WinRM" start= demand
sc config "Winmgmt" start= auto
sc config "WpcMonSvc" start= demand
sc config "WpnService" start= demand
sc config "WpnUserService" start= auto
sc config "XblAuthManager" start= demand
sc config "XblGameSave" start= demand
sc config "XboxGipSvc" start= demand
sc config "XboxNetApiSvc" start= demand
sc config "autotimesvc" start= demand
sc config "bthserv" start= demand
sc config "cbdhsvc" start= demand
sc config "cloudidsvc" start= demand
sc config "dcsvc" start= demand
sc config "defragsvc" start= demand
sc config "diagnosticshub.standardcollector.service" start= demand
sc config "diagsvc" start= demand
sc config "dmwappushservice" start= demand
sc config "dot3svc" start= demand
sc config "edgeupdate" start= demand
sc config "edgeupdatem" start= demand
sc config "embeddedmode" start= demand
sc config "fdPHost" start= demand
sc config "fhsvc" start= demand
sc config "gpsvc" start= auto
sc config "hidserv" start= demand
sc config "icssvc" start= demand
sc config "iphlpsvc" start= auto
sc config "lfsvc" start= demand
sc config "lltdsvc" start= demand
sc config "lmhosts" start= demand
sc config "mpssvc" start= auto
sc config "msiserver" start= demand
sc config "netprofm" start= demand
sc config "nsi" start= auto
sc config "p2pimsvc" start= demand
sc config "p2psvc" start= demand
sc config "perceptionsimulation" start= demand
sc config "pla" start= demand
sc config "seclogon" start= demand
sc config "shpamsvc" start= disabled
sc config "smphost" start= demand
sc config "spectrum" start= demand
sc config "sppsvc" start= delayed-auto
sc config "ssh-agent" start= disabled
sc config "svsvc" start= demand
sc config "swprv" start= demand
sc config "tiledatamodelsvc" start= auto
sc config "tzautoupdate" start= disabled
sc config "uhssvc" start= disabled
sc config "upnphost" start= demand
sc config "vds" start= demand
sc config "vm3dservice" start= demand
sc config "vmicguestinterface" start= demand
sc config "vmicheartbeat" start= demand
sc config "vmickvpexchange" start= demand
sc config "vmicrdv" start= demand
sc config "vmicshutdown" start= demand
sc config "vmictimesync" start= demand
sc config "vmicvmsession" start= demand
sc config "vmicvss" start= demand
sc config "vmvss" start= demand
sc config "wbengine" start= demand
sc config "wcncsvc" start= demand
sc config "webthreatdefsvc" start= demand
sc config "webthreatdefusersvc" start= auto
sc config "wercplsupport" start= demand
sc config "wisvc" start= demand
sc config "wlidsvc" start= demand
sc config "wlpasvc" start= demand
sc config "wmiApSrv" start= demand
sc config "workfolderssvc" start= demand
sc config "wscsvc" start= delayed-auto
sc config "wudfsvc" start= demand

set "DemandServices=BcastDVRUserService BluetoothUserService CaptureService ConsentUxUserSvc CredentialEnrollmentManagerUserSvc DeviceAssociationBrokerSvc DevicePickerUserSvc DevicesFlowUserSvc MessagingService NPSMSvc P9RdrService PenService PimIndexMaintenanceSvc PrintWorkflowUserSvc UdkUserSvc UnistoreSvc UserDataSvc cbdhsvc"

set "AutoServices=CDPUserSvc OneSyncSvc WpnUserService webthreatdefusersvc"

for %%p in (%DemandServices%) do (
    set "serviceFound=false"

    for /f "tokens=2" %%s in ('sc queryex type=service state=all ^| find "%%p_"') do (
        sc config "%%s" start= demand >nul
        set "serviceFound=true"
    )

    if "%serviceFound%"=="false" (
        echo [NOT FOUND] No service matching "%%p_*" was found.
    )
    echo.
)

for %%t in (%AutoServices%) do (
    set "serviceFound=false"

    for /f "tokens=2" %%s in ('sc queryex type=service state=all ^| find "%%t_"') do (
        sc config "%%u" start= auto >nul
        set "serviceFound=true"
    )

    if "%serviceFound%"=="false" (
        echo [NOT FOUND] No service matching "%%u_*" was found.
    )
    echo.
)


echo [92m----- Restarting Explorer to apply settings ----- [0m
taskkill /f /im explorer.exe
explorer.exe

echo [92m----- Operation Complete: Essential Tweaks ----- [0m

exit /B 0