@echo off
setlocal
call :setESC

echo %ESC%[92m----- Enable Performance Tweaks -----%ESC%[0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "Append Completion" /t REG_SZ /d "yes" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest" /t REG_SZ /d "yes" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d 3 /f
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f
reg add "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /ve /d "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /f
reg add "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /ve /d "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" /f
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d "1000" /f
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
sc config "RemoteRegistry" start= disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\diagsvc" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\diagnosticshub.standardcollector.service" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "AlwaysOn" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation" /v "EnableFrameServerMode" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "GPU Priority" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Priority" /t REG_DWORD /d 8 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "SFIO Priority" /t REG_SZ /d "High" /f

echo %ESC%[92m----- Disable Bing Search in Start Menu -----%ESC%[0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f

echo %ESC%[92m----- Enable NumLock on Startup -----%ESC%[0m
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

echo %ESC%[92m----- Enable Verbose Status During Logon and Shutdown -----%ESC%[0m
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "VerboseStatus" /t REG_DWORD /d 1 /f

echo %ESC%[92m----- Enable Mouse Acceleration -----%ESC%[0m
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f

echo %ESC%[92m----- Disable StickyKeys -----%ESC%[0m
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "58" /f

echo %ESC%[92m----- Disable "Try the new Outlook" toggle -----%ESC%[0m
reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences" /v "UseNewOutlook" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Office\16.0\Outlook\Options\General" /v "HideNewOutlookToggle" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General" /v "DoNewOutlookAutoMigration" /t REG_DWORD /d 0 /f
REG DELETE "HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences" /v "NewOutlookMigrationUserSetting" /f

echo %ESC%[92m----- Enable Search Icon on Taskbar -----%ESC%[0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 1 /f

echo %ESC%[92m----- Hide Task View Button -----%ESC%[0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f

echo %ESC%[92m----- Disable Widgets in Taskbar -----%ESC%[0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f

echo %ESC%[92m----- Disable Cross-Device Resume -----%ESC%[0m
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" /v "IsResumeAllowed" /t REG_DWORD /d 0 /f

echo %ESC%[92m----- Disable Windows Consumer Features -----%ESC%[0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f

echo %ESC%[92m----- Disable Scheduled Tasks -----%ESC%[0m
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

echo %ESC%[92m----- Disable Telemetry and Data Collection -----%ESC%[0m
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

echo %ESC%[92m----- Misc. Tweaks -----%ESC%[0m
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

echo %ESC%[92m----- Debloat Microsoft Edge -----%ESC%[0m
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

echo %ESC%[92m----- DisableEdgeTelemetry -----%ESC%[0m
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

echo %ESC%[92m----- DisableEdgeDiscoverBar -----%ESC%[0m
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "WebWidgetAllowed" /t REG_DWORD /d 0 /f

echo %ESC%[92m----- DisableCoPilotAI -----%ESC%[0m
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DefaultBrowserSettingsCampaignEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "ComposeInlineEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f

echo %ESC%[92m----- Turning on Hibernation -----%ESC%[0m
powercfg /hibernate on

echo %ESC%[92m----- Set Services to demand -----%ESC%[0m
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

echo %ESC%[92m----- Disable Exploer Automatic Folder Discovery -----%ESC%[0m
REG DELETE "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f
REG DELETE "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f

echo %ESC%[92m----- Enable Snap-Assistent -----%ESC%[0m
reg add "HKCU\Control Panel\Desktop" /v "WindowArrangementActive" /t REG_SZ /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableSnapAssistFlyout" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapAssist" /t REG_DWORD /d 1 /f

echo %ESC%[92m----- EnableAutomaticUpdates -----%ESC%[0m
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" /v "SystemSettingsDownloadMode" /f
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "UxOption" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /f

echo %ESC%[92m----- DisableStartMenuAds -----%ESC%[0m
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

echo -----Show all active Windows on every Taskbar-----
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "MMTaskbarMode" /t REG_DWORD /d "0" /f

echo -----Enabling scrolling on inactive windows-----
reg add "HKCU\Control Panel\Desktop" /v "MouseWheelRouting" /t REG_DWORD /d 2 /f

echo %ESC%[92m----- Set time automatically -----%ESC%[0m
net start w32time 2>nul
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
w32tm /config /update
w32tm /resync

echo Restarting Explorer to apply settings...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo %ESC%[92m----- Tweaks applied successfully! -----%ESC%[0m

::%ESC%[92mYellow%ESC%[0m
:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)