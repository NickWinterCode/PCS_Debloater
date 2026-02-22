# Relaunch the script with administrator privileges
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -WorkingDirectory $pwd -Verb RunAs
    Exit
}

function Test-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value
    )

    try {
        # Check if path exists
        if (-not (Test-Path $Path)) {
            Write-Host "[ERROR] MISSING PATH - $Path\$Name (Path does not exist)" -ForegroundColor Red
            return
        }

        # Check if the registry value exists
        $existingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        
        if ($null -eq $existingValue) {
            Write-Host "[ERROR] NOT SET - $Path\$Name (Value does not exist)" -ForegroundColor Red
            return
        }

        # Get the actual value
        $actualValue = $existingValue.$Name
        
        # Compare the value
        if ($actualValue -eq $Value) {
            Write-Host "[OK] CORRECT - $Path\$Name = $Value" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] WRONG VALUE - $Path\$Name = $actualValue (Expected: $Value)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[ERROR] ERROR - Failed to check $Path\$Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-RegistryValueRemoved {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        if (Test-Path $Path) {
            $existingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($existingValue) {
                Write-Host "[GREY] EXISTS - $Path\$Name still exists (Should be removed)" -ForegroundColor Gray
            } else {
                Write-Host "[OK] REMOVED - $Path\$Name is not present" -ForegroundColor Green
            }
        } else {
            Write-Host "[OK] PATH NOT EXISTS - $Path (Path doesn't exist)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[ERROR] ERROR - Failed to check $Path\$Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-RegistryKeyRemoved {
    param(
        [string]$Path
    )

    try {
        if (Test-Path $Path) {
            Write-Host "[GREY] EXISTS - Key $Path still exists (Should be removed)" -ForegroundColor Gray
        } else {
            Write-Host "[OK] REMOVED - Key $Path is not present" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[ERROR] ERROR - Failed to check key $Path : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "POWER PLAN DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$customPlanGuid = "69696969-6969-6969-6969-696969696969"

$existingPlan = powercfg /query $customPlanGuid 2>&1
$planExists = $LASTEXITCODE -eq 0

if ($planExists) {
    Write-Host "[OK] Power plan exists" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Power plan does not exist" -ForegroundColor Red
}

Write-Host "`n -- Checking hidden power settings" -ForegroundColor Cyan
$PowerSettingsBasePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$hiddenSettings = @(
    @{ Subgroup = "2a737441-1930-4402-8d77-b2bebba308a3"; Setting = "0853a681-27c8-4100-a2fd-82013e970683" },
    @{ Subgroup = "2a737441-1930-4402-8d77-b2bebba308a3"; Setting = "d4e98f31-5ffe-4ce1-be31-1b38b384c009" },
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "7648efa3-dd9c-4e3e-b566-50f929386280" },
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "96996bc0-ad50-47ec-923b-6f41874dd9eb" },
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "5ca83367-6e45-459f-a27b-476b1d01c936" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "94d3a615-a899-4ac5-ae2b-e4d8f634367f" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "be337238-0d82-4146-a960-4f3749d470c7" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "465e1f50-b610-473a-ab58-00d1077dc418" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "40fbefc7-2e9d-4d25-a185-0cfd8574bac6" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "0cc5b647-c1df-4637-891a-dec35c318583" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "ea062031-0e34-4ff1-9b6d-eb1059334028" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "06cadf0e-64ed-448a-8927-ce7bf90eb35d" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" }
)

$enabledCount = 0
foreach ($item in $hiddenSettings) {
    $regPath = Join-Path $PowerSettingsBasePath "$($item.Subgroup)\$($item.Setting)"
    try {
        if (Test-Path $regPath) {
            $attrValue = (Get-ItemProperty -Path $regPath -Name 'Attributes' -ErrorAction SilentlyContinue).Attributes
            if ($attrValue -eq 0) {
                $enabledCount++
            } else {
                Write-Host "[GREY] Hidden setting not enabled: $($item.Setting)" -ForegroundColor Gray
            }
        }
    }
    catch {
    }
}
Write-Host "[INFO] $enabledCount of $($hiddenSettings.Count) hidden power settings are enabled" -ForegroundColor Yellow

Write-Host "`n -- Checking power settings" -ForegroundColor Cyan
$settings = @(
    @{ S = "7516b95f-f776-4464-8c53-06167f40cc99"; G = "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"; AC = 0; DC = 300; N = "Display timeout" },
    @{ S = "0012ee47-9041-4b5d-9b77-535fba8b1442"; G = "6738e2c4-e8a5-4a42-b16a-e040e769756e"; AC = 0; DC = 600; N = "Hard disk timeout" },
    @{ S = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; G = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da"; AC = 0; DC = 900; N = "Sleep timeout" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "893dee8e-2bef-41e0-89c6-b55d0929964c"; AC = 5; DC = 5; N = "Min CPU %" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "bc5038f7-23e0-4960-96da-33abaf5935ec"; AC = 100; DC = 100; N = "Max CPU %" }
)

$appliedCount = 0
$targetPlanGuid = "69696969-6969-6969-6969-696969696969"
foreach ($setting in $settings) {
    try {
        $acResult = powercfg /query $targetPlanGuid $setting.S $setting.G 2>$null
        if ($LASTEXITCODE -eq 0) {
            # Parse output to check actual values (simplified check)
            Write-Host "[INFO] Checked: $($setting.N)" -ForegroundColor Yellow
            $appliedCount++
        } else {
            Write-Host "[ERROR] Power setting not found: $($setting.N)" -ForegroundColor Red
        }
    }
    catch {
    }
}

$activePlan = (powercfg /getactivescheme) -match $targetPlanGuid
if ($activePlan) {
    Write-Host "`n[OK] Custom power plan is ACTIVE" -ForegroundColor Green
} else {
    Write-Host "`n[ERROR] Custom power plan is NOT ACTIVE" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "REGISTRY DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "`n -- Checking Consumer Features" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Type DWord -Value 1

Write-Host "`n -- Checking Recall" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'AllowRecallEnablement' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'TurnOffSavingSnapshots' -Type DWord -Value 1

$RecallFeature = Get-WindowsOptionalFeature -Online -FeatureName "Recall" -ErrorAction SilentlyContinue
if ($RecallFeature) {
    if ($RecallFeature.State -eq "Disabled") {
        Write-Host "[OK] Recall feature is disabled" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Recall feature is enabled" -ForegroundColor Red
    }
} else {
    Write-Host "[OK] Recall feature not found (not applicable)" -ForegroundColor Green
}

Write-Host "`n -- Checking Edge Debloat" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeEnhanceImagesEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PersonalizationReportingEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ShowRecommendationsEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HideFirstRunExperience' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'UserFeedbackAllowed' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ConfigureDoNotTrack' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'AlternateErrorPagesEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeCollectionsEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeFollowEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeShoppingAssistantEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'MicrosoftEdgeInsiderPromotionEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'RelatedMatchesCloudServiceEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ShowMicrosoftRewards' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'WebWidgetAllowed' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'MetricsReportingEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'StartupBoostEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'BingAdsSuppression' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'NewTabPageHideDefaultTopSites' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PromotionalTabsEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SendSiteInfoToImproveServices' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SpotlightExperiencesAndRecommendationsEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'DiagnosticData' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeAssetDeliveryServiceEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'CryptoWalletEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'WalletDonationEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'NewTabPageContentEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'TabServicesEnabled' -Type DWord -Value 0

Write-Host "`n -- Checking Copilot" -ForegroundColor Cyan
$copilotApp = Get-AppxPackage "Microsoft.CoPilot" -ErrorAction SilentlyContinue
if ($copilotApp) {
    Write-Host "[ERROR] Copilot app is still installed" -ForegroundColor Red
} else {
    Write-Host "[OK] Copilot app is not installed" -ForegroundColor Green
}
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'AutoOpenCopilotLargeScreens' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot' -Name 'CopilotDisabledReason' -Type String -Value 'IsEnabledForGeographicRegionFailed'
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsCopilot' -Name 'AllowCopilotRuntime' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}' -Type String -Value ''
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot' -Name 'IsCopilotAvailable' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat' -Name 'IsUserEligible' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HubsSidebarEnabled' -Type DWord -Value 0

Write-Host "`n -- Checking Widgets" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Type DWord -Value 0

Write-Host "`n -- Checking Taskbar Widgets" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests' -Name 'value' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds' -Type DWord -Value 0

Write-Host "`n -- Checking Auto Map Downloads" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps' -Name 'AllowUntriggeredNetworkTrafficOnSettingsPage' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps' -Name 'AutoDownloadAndUpdateMapData' -Type DWord -Value 0

Write-Host "`n -- Checking Telemetry" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowDesktopAnalyticsProcessing' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowDeviceNameInTelemetry' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'MicrosoftEdgeDataOptIn' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowWUfBCloudProcessing' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowUpdateComplianceProcessing' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowCommercialDataPipeline' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\SQMClient\Windows' -Name 'CEIPEnable' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name 'DisableOneSettingsDownloads' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform' -Name 'NoGenTicket' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting' -Name 'Disabled' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' -Name 'Disabled' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent' -Name 'DefaultConsent' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent' -Name 'DefaultOverrideBehavior' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting' -Name 'DontSendAdditionalData' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting' -Name 'LoggingDisabled' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'OemPreInstalledAppsEnabled' -Value 0 -Type DWord
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEnabled' -Value 0 -Type DWord
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEverEnabled' -Value 0 -Type DWord
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0 -Type DWord
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0 -Type DWord
Test-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications' -Name 'EnableAccountNotifications' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications' -Name 'EnableAccountNotifications' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NOC_GLOBAL_SETTING_TOASTS_ENABLED' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\EdgeUI' -Name 'DisableMFUTracking' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI' -Name 'DisableMFUTracking' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice' -Name 'Start' -Type DWord -Value 4
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -Type DWord -Value 0
Test-RegistryValueRemoved -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'PeriodInNanoSeconds'

Write-Host "`n -- Checking Search Telemetry" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchPrivacy' -Type DWord -Value 3
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchHistory' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowSearchToUseLocation' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'EnableDynamicContentInWSB' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWeb' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableWebSearch' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'PreventUnwantedAddIns' -Type String -Value ''
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'PreventRemoteQueries' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AlwaysUseAutoLangDetection' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowIndexingEncryptedStoresOrItems' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaInAmbientMode' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCortanaButton' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CanCortanaBeEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWebOverMeteredConnections' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortanaAboveLock' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana' -Name 'value' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'AllowSearchToUseLocation' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'ModelDownloadAllowed' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDeviceSearchHistoryEnabled' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'VoiceActivationOn' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'VoiceActivationEnableAboveLockscreen' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -Name 'DisableVoice' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'DeviceHistoryEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'HistoryViewEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'VoiceActivationDefaultOn' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsMSACloudSearchEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsAADCloudSearchEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCloudSearch' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'VoiceShortcut' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Type DWord -Value 0

Write-Host "`n -- Checking Targeted Ads" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableTailoredExperiencesWithDiagnosticData' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'DisabledByGroupPolicy' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338393Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353694Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353696Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353698Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_IrisRecommendations' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SoftLandingEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall' -Name 'DisablePushToInstall' -Type DWord -Value 1
Test-RegistryValueRemoved -Path 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
Test-RegistryValueRemoved -Path 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerAccountStateContent' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested' -Name 'Enabled' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Mobility' -Name 'OptedIn' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_AccountNotifications' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder' -Name 'Enabled' -Type DWord -Value 0

Write-Host "`n -- Checking Privacy Consent" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Type DWord -Value 0

Write-Host "`n -- Checking Services Configuration" -ForegroundColor Cyan
$servicesManual = @(
    "ALG", "AppMgmt", "AppReadiness", "Appinfo", "AxInstSV",
    "BDESVC", "BTAGService", "BcastDVRUserService", "BluetoothUserService", "Browser",
    "CDPSvc", "COMSysApp", "CaptureService", "CertPropSvc", "ConsentUxUserSvc"
)

$servicesDisabled = @(
    "AppVClient",
    "AssignedAccessManagerSvc",
    "DiagTrack",
    "diagsvc",
    "DialogBlockingService",
    "NetTcpPortSharing",
    "RemoteAccess",
    "RemoteRegistry",
    "dmwappushservice",
    "shpamsvc",
    "ssh-agent",
    "tzautoupdate",
    "wercplsupport",
    "WerSvc"
)

function Test-ServiceConfig {
    param ($List, $ExpectedType, $TypeName)
    $correctCount = 0
    $wrongCount = 0
    $missingCount = 0
    
    foreach ($svc in $List) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service) {
            $actualStartType = (Get-Service -Name $svc).StartType
            if ($actualStartType -eq $ExpectedType) {
                $correctCount++
            } else {
                Write-Host "[ERROR] $svc is $actualStartType (Expected: $ExpectedType)" -ForegroundColor Red
                $wrongCount++
            }
        } else {
            $missingCount++
        }
    }
    Write-Host "[INFO] $TypeName services: $correctCount correct, $wrongCount wrong, $missingCount not found" -ForegroundColor Yellow
}

Test-ServiceConfig -List $servicesManual -ExpectedType "Manual" -TypeName "Manual"
Test-ServiceConfig -List $servicesDisabled -ExpectedType "Disabled" -TypeName "Disabled"

Write-Host "`n -- Checking UI Tweaks" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value 0
Test-RegistryValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseHoverTime' -Type String -Value 0

Write-Host "`n -- Checking Verbose Logon" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'VerboseStatus' -Type DWord -Value 1

Write-Host "`n -- Checking Update Delivery" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Type DWord -Value 1

Write-Host "`n -- Checking Remote Assistance" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name 'fAllowToGetHelp' -Type DWord -Value 0

Write-Host "`n -- Checking Explorer Settings" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Name 'EnthusiastMode' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People' -Name 'PeopleBand' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Type DWord -Value 1

Write-Host "`n -- Checking 3D Objects Folder" -ForegroundColor Cyan
Test-RegistryKeyRemoved -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
Test-RegistryKeyRemoved -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'

Write-Host "`n -- Checking Performance Tweaks" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' -Name 'SearchOrderConfig' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Type DWord -Value 10
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Type DWord -Value 10
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'WaitToKillServiceTimeout' -Type String -Value 2000
Test-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value 1
Test-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'WaitToKillAppTimeout' -Type String -Value 5000
Test-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Type String -Value 4000
Test-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Type String -Value 1
Test-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'LowLevelHooksTimeout' -Type String -Value 1000
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'ClearPageFileAtShutdown' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseHoverTime' -Type DWord -Value 10

Write-Host "`n -- Checking Network Tweaks" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'IRPStackSize' -Type DWord -Value 20

Write-Host "`n -- Checking SvcHost Grouping" -ForegroundColor Cyan
$ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -Type DWord -Value $ram

Write-Host "`n -- Checking Taskbar Items" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' -Name 'ShellFeedsTaskbarViewMode' -Type DWord -Value 2
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAMeetNow' -Type DWord -Value 1

Write-Host "`n -- Checking Wi-Fi Sense" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' -Name 'Value' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' -Name 'Value' -Type DWord -Value 0

Write-Host "`n -- Checking Activity History" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Type DWord -Value 0

Write-Host "`n -- Checking Location Tracking" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Type String -Value "Deny"
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}' -Name 'SensorPermissionState' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration' -Name 'Status' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SYSTEM\Maps' -Name 'AutoUpdateEnabled' -Type DWord -Value 0

Write-Host "`n -- Checking Storage Sense" -ForegroundColor Cyan
Test-RegistryKeyRemoved -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'

Write-Host "`n -- Checking Power Throttling" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name 'PowerThrottlingOff' -Type DWord -Value 00000000
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Type DWord -Value 0000001

Write-Host "`n -- Checking NumLock" -ForegroundColor Cyan
If (!(Test-Path "HKU:")) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}
Test-RegistryValue -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Type String -Value 2147483650
Test-RegistryValue -Path 'HKCU:\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Type String -Value 2147483650

Write-Host "`n -- Checking BIOS Time" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'RealTimeIsUniversal' -Type DWord -Value 1

Write-Host "`n -- Checking Clipboard History" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowClipboardHistory' -Type DWord -Value 1

Write-Host "`n -- Checking Teams Prevention" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Teams' -Name 'DisableInstallation' -Type DWord -Value 1

Write-Host "`n -- Checking Outlook Settings" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences' -Name 'UseNewOutlook' -Type DWord -Value 0
Test-RegistryValue -Path 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\General' -Name 'HideNewOutlookToggle' -Type DWord -Value 1
Test-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General' -Name 'DoNewOutlookAutoMigration' -Type DWord -Value 0
Test-RegistryValueRemoved -Path 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences' -Name 'NewOutlookMigrationUserSetting'

Write-Host "`n -- Checking Chat Icon" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Name 'ChatIcon' -Type DWord -Value 3
Test-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Type DWord -Value 0

Write-Host "`n -- Checking DevHome/Outlook Prevention" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Mail' -Name 'PreventRun' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' -Name 'workCompleted' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' -Name 'workCompleted' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' -Name 'workCompleted' -Type DWord -Value 1
Test-RegistryKeyRemoved -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
Test-RegistryKeyRemoved -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'

Write-Host "`n -- Checking Modern Standby" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9' -Name 'ACSettingIndex' -Type DWord -Value 0
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9' -Name 'DCSettingIndex' -Type DWord -Value 0

Write-Host "`n -- Checking Click to Do" -ForegroundColor Cyan
Test-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo' -Type DWord -Value 1
Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo' -Type DWord -Value 1

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSTIC CHECK COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Legend:" -ForegroundColor Yellow
Write-Host "  [OK] CORRECT - " -ForegroundColor Green -NoNewline
Write-Host "Value is correctly set"
Write-Host "  [ERROR] WRONG VALUE - " -ForegroundColor Red -NoNewline
Write-Host "Value exists but is incorrect"
Write-Host "  [ERROR] NOT SET - " -ForegroundColor Red -NoNewline
Write-Host "Value does not exist"
Write-Host "  [GREY] EXISTS - " -ForegroundColor Gray -NoNewline
Write-Host "Item exists but should be removed"

Read-Host "`nPress Enter to exit"