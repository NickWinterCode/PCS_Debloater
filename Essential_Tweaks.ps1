# Relaunch the script with administrator privileges
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -WorkingDirectory $pwd -Verb RunAs
    Exit
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-Host "SUCCESS" "- $Path\$Name = $Value"
    }
    catch {
        Write-Host "ERROR" "Failed to set $Path\$Name : $($_.Exception.Message)"
    }
}

function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        if (Test-Path $Path) {
            $existingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($existingValue) {
                Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
                Write-Host "SUCCESS" "- Removed $Path\$Name"
            }
        }
    }
    catch {
        Write-Host "ERROR" "Failed to remove $Path\$Name : $($_.Exception.Message)"
    }
}

function Remove-RegistryKey {
    param(
        [string]$Path
    )

    try {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "SUCCESS" "- Removed key $Path"
        }
    }
    catch {
        Write-Host "ERROR" "Failed to remove key $Path : $($_.Exception.Message)"
    }
}

Write-Host ' -- Setting up power plan' -ForegroundColor Green "INFO"

$customPlanGuid = "69696969-6969-6969-6969-696969696969"

$existingPlan = powercfg /query $customPlanGuid 2>&1
$planExists = $LASTEXITCODE -eq 0

if ($planExists) {
    Write-Host ' -- Power plan already exists, using existing plan' "INFO"
}
else {
    Write-Host ' -- Creating new power plan' -ForegroundColor Green "INFO"
    $planCreated = $false

    $sourceSchemes = @(
        @{ Name = "Balanced"; Guid = "381b4222-f694-41f0-9685-ff5bb260df2e" },
        @{ Name = "Ultimate Performance"; Guid = "e9a42b02-d5df-448d-aa00-03f14749eb61" },
        @{ Name = "High Performance"; Guid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
    )

    foreach ($scheme in $sourceSchemes) {
        Write-Host ' -- Attempting to duplicate from $($scheme.Name)' -ForegroundColor Green "INFO"
        $result = powercfg /duplicatescheme $($scheme.Guid) $customPlanGuid 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host ' -- Successfully created from $($scheme.Name)' "SUCCESS"
            powercfg /changename $customPlanGuid "Balanced PC-Spezialist" | Out-Null
            $planCreated = $true
            break
        }
    }

    if (-not $planCreated) {
        Write-Host ' -- Failed to create power plan' "ERROR"
    }
}

Write-Host ' -- Enabling hidden power settings' -ForegroundColor Green "INFO"
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
            Set-ItemProperty -Path $regPath -Name 'Attributes' -Value 0 -Type Dword -ErrorAction Stop
            $enabledCount++
        }
    }
    catch {
    }
}
Write-Host ' -- Enabled $enabledCount hidden power settings' "SUCCESS"

Write-Host ' -- Applying power settings' -ForegroundColor Green "INFO"

$settings = @(
    @{ S = "7516b95f-f776-4464-8c53-06167f40cc99"; G = "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"; AC = 0; DC = 300; N = "Specifies the period of inactivity before Windows turns off the display" },
    @{ S = "0012ee47-9041-4b5d-9b77-535fba8b1442"; G = "6738e2c4-e8a5-4a42-b16a-e040e769756e"; AC = 0; DC = 600; N = "Specifies the period of inactivity before Windows turns off the hard disk" },
    @{ S = "0d7dbae2-4294-402a-ba8e-26777e8488cd"; G = "309dce9b-bef4-4119-9921-a851fb12f0f4"; AC = 0; DC = 1; N = "Allow or prevent Windows from rotating through multiple wallpaper images" },
    @{ S = "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1"; G = "12bbebe6-58d6-4636-95bb-3217ef867c1a"; AC = 0; DC = 2; N = "Balance wireless network performance with battery life by adjusting adapter power usage" },
    @{ S = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; G = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da"; AC = 0; DC = 900; N = "Specifies the period of inactivity before Windows puts the computer to sleep" },
    @{ S = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; G = "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d"; AC = 0; DC = 0; N = "Allow scheduled tasks and applications to wake your computer from sleep" },
    @{ S = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; G = "9d7815a6-7ee4-497e-8888-515a05f02364"; AC = 0; DC = 0; N = "Specifies the period of inactivity before Windows hibernates the computer" },
    @{ S = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; G = "94ac6d29-73ce-41a6-809f-6363ba21b47e"; AC = 0; DC = 1; N = "Combines sleep and hibernate by saving your session to disk while staying in low-power mode for faster wake" },
    @{ S = "2a737441-1930-4402-8d77-b2bebba308a3"; G = "0853a681-27c8-4100-a2fd-82013e970683"; AC = 0; DC = 1000; N = "Set how long USB hubs wait idle before powering down to save energy" },
    @{ S = "2a737441-1930-4402-8d77-b2bebba308a3"; G = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"; AC = 0; DC = 1; N = "Allow Windows to power down individual USB ports when devices are idle to save energy" },
    @{ S = "2a737441-1930-4402-8d77-b2bebba308a3"; G = "d4e98f31-5ffe-4ce1-be31-1b38b384c009"; AC = 0; DC = 2; N = "Control how aggressively USB 3.0 ports enter low-power states when devices are idle" },
    @{ S = "4f971e89-eebd-4455-a8de-9e59040e7347"; G = "7648efa3-dd9c-4e3e-b566-50f929386280"; AC = 0; DC = 0; N = "Choose what happens when you press the physical power button on your computer" },
    @{ S = "4f971e89-eebd-4455-a8de-9e59040e7347"; G = "96996bc0-ad50-47ec-923b-6f41874dd9eb"; AC = 0; DC = 0; N = "Choose what happens when you press the dedicated sleep button on your keyboard or computer" },
    @{ S = "501a4d13-42af-4429-9fd1-a8218c268e20"; G = "ee12f906-d277-404b-b6da-e5fa1a576df5"; AC = 0; DC = 2; N = "Control power savings for PCIe devices like graphics cards, SSDs, and expansion cards" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "893dee8e-2bef-41e0-89c6-b55d0929964c"; AC = 5; DC = 5; N = "Set the lowest CPU speed allowed as a percentage of maximum frequency" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "bc5038f7-23e0-4960-96da-33abaf5935ec"; AC = 100; DC = 100; N = "Set the highest CPU speed allowed as a percentage of maximum frequency" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "94d3a615-a899-4ac5-ae2b-e4d8f634367f"; AC = 1; DC = 1; N = "Choose whether to slow down the processor first (passive) or speed up fans first (active) when hot" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "be337238-0d82-4146-a960-4f3749d470c7"; AC = 2; DC = 1; N = "Control how aggressively your CPU boosts above base frequency for demanding tasks" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "465e1f50-b610-473a-ab58-00d1077dc418"; AC = 2; DC = 0; N = "Control how quickly CPU ramps up speed when workload increases (for legacy non-HWP processors)" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "40fbefc7-2e9d-4d25-a185-0cfd8574bac6"; AC = 1; DC = 2; N = "Control how quickly CPU reduces speed when workload decreases (for legacy non-HWP processors)" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "0cc5b647-c1df-4637-891a-dec35c318583"; AC = 0; DC = 0; N = "Set the minimum percentage of CPU cores that must remain active and responsive" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "ea062031-0e34-4ff1-9b6d-eb1059334028"; AC = 100; DC = 100; N = "Set the maximum percentage of CPU cores allowed to be active (100% for best performance)" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863"; AC = 0; DC = 50; N = "Balance power efficiency and performance for modern CPUs with HWP (0 = max performance, 100 = max efficiency)" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "06cadf0e-64ed-448a-8927-ce7bf90eb35d"; AC = 10; DC = 30; N = "Set CPU usage percentage that triggers speed increase (lower = more responsive, for legacy non-HWP CPUs)" },
    @{ S = "54533251-82be-4824-96c1-47b60b740d00"; G = "12a0ab44-fe28-4fa9-b3bd-4b64f44960a6"; AC = 8; DC = 20; N = "Set CPU usage percentage that triggers speed reduction (lower = maintains performance longer, for legacy non-HWP CPUs)" },
    @{ S = "9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; G = "03680956-93bc-4294-bba6-4e0f09bb717f"; AC = 1; DC = 1; N = "Control whether your PC can sleep while streaming media to other devices on your network" },
    @{ S = "9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; G = "10778347-1370-4ee0-8bbd-33bdacaade49"; AC = 1; DC = 1; N = "Prioritize smooth video playback over battery life when watching videos" },
    @{ S = "9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; G = "34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4"; AC = 0; DC = 0; N = "Balance video quality and power consumption during video playback" },
    @{ S = "c763b4ec-0e50-4b6b-9bed-2b92a6ee884e"; G = "7ec1751b-60ed-4588-afb5-9819d3d77d90"; AC = 3; DC = 1; N = "Balance AMD laptop performance and battery life with quick power mode selection" }
)

$appliedCount = 0
$targetPlanGuid = "69696969-6969-6969-6969-696969696969"
foreach ($setting in $settings) {
    try {
        powercfg /setacvalueindex $targetPlanGuid $setting.S $setting.G $setting.AC 2>$null
        if ($LASTEXITCODE -eq 0) {
            powercfg /setdcvalueindex $targetPlanGuid $setting.S $setting.G $setting.DC 2>$null
            if ($LASTEXITCODE -eq 0) {
                $appliedCount++
            }
        }
    }
    catch {
    }
}
Write-Host ' -- Applied $appliedCount power settings' "SUCCESS"

Write-Host ' -- Activating power plan' -ForegroundColor Green "INFO"
powercfg /setactive 69696969-6969-6969-6969-696969696969 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host ' -- Power plan activated successfully' "SUCCESS"
}
else {
    Write-Host ' -- Failed to activate power plan' "WARNING"
}

Write-Host ' -- Disabling Consumer Features' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Type DWord -Value 1

Write-Host ' -- Disabling Recall' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'AllowRecallEnablement' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'TurnOffSavingSnapshots' -Type DWord -Value 1
$RecallFeature = Get-WindowsOptionalFeature -Online -FeatureName "Recall"
if ($RecallFeature.State -eq "Enabled") {
    DISM /Online /Disable-Feature /FeatureName:Recall
    Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove -NoRestart
}
else {
    Write-Host 'Recall is already disabled.'
}

Write-Host ' -- Debloating Edge' -ForegroundColor Green
# Disable Microsoft Edge recommendations, feedback popups, MSN news feed, sponsored links, shopping assistant, and more.
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeEnhanceImagesEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PersonalizationReportingEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ShowRecommendationsEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HideFirstRunExperience' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'UserFeedbackAllowed' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ConfigureDoNotTrack' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'AlternateErrorPagesEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeCollectionsEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeFollowEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeShoppingAssistantEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'MicrosoftEdgeInsiderPromotionEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'RelatedMatchesCloudServiceEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ShowMicrosoftRewards' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'WebWidgetAllowed' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'MetricsReportingEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'StartupBoostEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'BingAdsSuppression' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'NewTabPageHideDefaultTopSites' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PromotionalTabsEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SendSiteInfoToImproveServices' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SpotlightExperiencesAndRecommendationsEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'DiagnosticData' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'EdgeAssetDeliveryServiceEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'CryptoWalletEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'WalletDonationEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'NewTabPageContentEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'TabServicesEnabled' -Type DWord -Value 0

Write-Host ' -- Removing Copilot' -ForegroundColor Green
Get-AppxPackage "Microsoft.CoPilot" | Remove-AppxPackage
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'AutoOpenCopilotLargeScreens' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot' -Name 'CopilotDisabledReason' -Type String -Value 'IsEnabledForGeographicRegionFailed'
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsCopilot' -Name 'AllowCopilotRuntime' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}' -Type String -Value ''
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot' -Name 'IsCopilotAvailable' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat' -Name 'IsUserEligible' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'HubsSidebarEnabled' -Type DWord -Value 0

#Write-Host ' -- Uninstalling Widgets' -ForegroundColor Green
Write-Host ' -- Disable Widgets' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Type DWord -Value 0
#Get-AppxPackage *WebExperience* | Remove-AppxPackage
#Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy"
#reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy" /f

Write-Host ' -- Disabling Taskbar Widgets' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests' -Name 'value' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds' -Type DWord -Value 0

Write-Host ' -- Disabling Auto Map Downloads' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps' -Name 'AllowUntriggeredNetworkTrafficOnSettingsPage' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps' -Name 'AutoDownloadAndUpdateMapData' -Type DWord -Value 0

Write-Host ' -- Deleting Default0 User' -ForegroundColor Green
net user defaultuser0 /delete

Write-Host ' -- Disabling Windows Telemetry' -ForegroundColor Green
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Autochk\Proxy" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Maps\MapsUpdateTask" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE > NUL 2>&1'
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowDesktopAnalyticsProcessing' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowDeviceNameInTelemetry' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'MicrosoftEdgeDataOptIn' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowWUfBCloudProcessing' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowUpdateComplianceProcessing' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowCommercialDataPipeline' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\SQMClient\Windows' -Name 'CEIPEnable' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name 'DisableOneSettingsDownloads' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform' -Name 'NoGenTicket' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting' -Name 'Disabled' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' -Name 'Disabled' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent' -Name 'DefaultConsent' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent' -Name 'DefaultOverrideBehavior' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting' -Name 'DontSendAdditionalData' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\Windows Error Reporting' -Name 'LoggingDisabled' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'OemPreInstalledAppsEnabled' -Value 0 -Type DWord
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEnabled' -Value 0 -Type DWord
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEverEnabled' -Value 0 -Type DWord
# Automatic Installation of Suggested Apps
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0 -Type DWord
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0 -Type DWord
# Disable Show me notifications in the Settings app
Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications' -Name 'EnableAccountNotifications' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications' -Name 'EnableAccountNotifications' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NOC_GLOBAL_SETTING_TOASTS_ENABLED' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\EdgeUI' -Name 'DisableMFUTracking' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI' -Name 'DisableMFUTracking' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice' -Name 'Start' -Type DWord -Value 4
# Improve Inking & Typing Recognition
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Type DWord -Value 0
# Disable Let Windows improve Start and search results by tracking app launches
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Type DWord -Value 0
# Set Feedback Frequency to Never
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -Type DWord -Value 0
Remove-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'PeriodInNanoSeconds'

Write-Host ' -- Disabling Windows Search Telemetry' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchPrivacy' -Type DWord -Value 3
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchHistory' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowSearchToUseLocation' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'EnableDynamicContentInWSB' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWeb' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableWebSearch' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'PreventUnwantedAddIns' -Type String -Value ''
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'PreventRemoteQueries' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AlwaysUseAutoLangDetection' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowIndexingEncryptedStoresOrItems' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaInAmbientMode' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCortanaButton' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CanCortanaBeEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWebOverMeteredConnections' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortanaAboveLock' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana' -Name 'value' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'AllowSearchToUseLocation' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'ModelDownloadAllowed' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDeviceSearchHistoryEnabled' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'VoiceActivationOn' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'VoiceActivationEnableAboveLockscreen' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -Name 'DisableVoice' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'DeviceHistoryEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'HistoryViewEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Speech_OneCore\Preferences' -Name 'VoiceActivationDefaultOn' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsMSACloudSearchEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsAADCloudSearchEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCloudSearch' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'VoiceShortcut' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Type DWord -Value 0

Write-Host ' -- Disabling Application Experience telemetry' -ForegroundColor Green
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Application Experience\StartupAppTask" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" /DISABLE > NUL 2>&1'
cmd /c 'schtasks /change /TN "\Microsoft\Windows\Application Experience\MareBackup" /DISABLE > NUL 2>&1'

Write-Host ' -- Disabling Targeted Ads and Data Collection' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableTailoredExperiencesWithDiagnosticData' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'DisabledByGroupPolicy' -Type DWord -Value 1
# Show me suggested content in the Settings app
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338393Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353694Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353696Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353698Enabled' -Type DWord -Value 0

# Occasionally show suggestions in Start
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Type DWord -Value 0
# Show recommendations for tips, shortcuts, new apps, and more in start
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_IrisRecommendations' -Type DWord -Value 0
# Get tips, tricks, and suggestions as you use Windows
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Type DWord -Value 0
# Show me the Windows welcome experience after updates and occasionally when I sign in to highlight what's new and suggested
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SoftLandingEnabled' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall' -Name 'DisablePushToInstall' -Type DWord -Value 1
Remove-RegistryValue -Path 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
Remove-RegistryValue -Path 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerAccountStateContent' -Type DWord -Value 1
# Suggest ways I can finish setting up my device to get the most out of Windows
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Type DWord -Value 0
# Sync provider ads
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Type DWord -Value 0
# Disable "Suggested" app notifications (Ads for MS services)
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested' -Name 'Enabled' -Type DWord -Value 0
# Disable Show me suggestions for using my mobile device with Windows (Phone Link suggestions)
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Mobility' -Name 'OptedIn' -Type DWord -Value 0
# Disable Show account-related notifications
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_AccountNotifications' -Type DWord -Value 0
# Disable Windows Backup reminder notifications
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.BackupReminder' -Name 'Enabled' -Type DWord -Value 0

Write-Host ' -- Opting out of privacy consent' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Type DWord -Value 0

Write-Host ' -- Disabling Manual Services' -ForegroundColor Green
# Array of services to set to MANUAL (Start=Demand)
$servicesManual = @(
    "ALG", "AppMgmt", "AppReadiness", "Appinfo", "AxInstSV",
    "BDESVC", "BTAGService", "BcastDVRUserService", "BluetoothUserService", "Browser",
    "CDPSvc", "COMSysApp", "CaptureService", "CertPropSvc", "ConsentUxUserSvc",
    "CscService", "DevQueryBroker", "DeviceAssociationService", "DeviceInstall",
    "DevicePickerUserSvc", "DevicesFlowUserSvc", "DisplayEnhancementService",
    "DmEnrollmentSvc", "DsSvc", "DsmSvc", "EFS", "EapHost", "EntAppSvc",
    "FDResPub", "FrameServer", "FrameServerMonitor", "GraphicsPerfSvc", "HvHost",
    "IEEtwCollectorService", "InstallService", "InventorySvc", "IpxlatCfgSvc",
    "KtmRm", "LicenseManager", "LxpSvc", "MSDTC", "MSiSCSI", "McpManagementService",
    "MicrosoftEdgeElevationService", "MsKeyboardFilter", "NPSMSvc", "NaturalAuthentication",
    "NcaSvc", "NcbService", "NcdAutoSetup", "NetSetupSvc", "Netman", "NgcCtnrSvc",
    "NgcSvc", "NlaSvc", "PNRPAutoReg", "PcaSvc", "PeerDistSvc", "PenService",
    "PerfHost", "PhoneSvc", "PimIndexMaintenanceSvc", "PlugPlay", "PolicyAgent",
    "PrintNotify", "PushToInstall", "QWAVE", "RasAuto", "RasMan", "RetailDemo",
    "RmSvc", "RpcLocator", "SCPolicySvc", "SCardSvr", "SDRSVC", "SEMgrSvc",
    "SNMPTRAP", "SNMPTrap", "SSDPSRV", "ScDeviceEnum", "SensorDataService",
    "SensorService", "SensrSvc", "SessionEnv", "SharedAccess", "SmsRouter",
    "SstpSvc", "StiSvc", "StorSvc", "TapiSrv", "TextInputManagementService",
    "TieringEngineService", "TokenBroker", "TroubleshootingSvc", "TrustedInstaller",
    "UdkUserSvc", "UmRdpService", "UserDataSvc", "UsoSvc", "VSS", "VacSvc",
    "WEPHOSTSVC", "WFDSConMgrSvc", "WMPNetworkSvc", "WManSvc", "WPDBusEnum",
    "WalletService", "WarpJITSvc", "WbioSrvc", "WdNisSvc", "WdiServiceHost",
    "WdiSystemHost", "WebClient", "Wecsvc", "WiaRpc", "WinRM",
    "WpcMonSvc", "WpnService", "WwanSvc", "autotimesvc", "bthserv", "camsvc",
    "cbdhsvc", "cloudidsvc", "dcsvc", "defragsvc", "dot3svc",
    "edgeupdate", "edgeupdatem", "embeddedmode", "fdPHost", "fhsvc", "hidserv",
    "icssvc", "lfsvc", "lltdsvc", "lmhosts", "msiserver", "netprofm", "p2pimsvc",
    "p2psvc", "perceptionsimulation", "pla", "seclogon", "smphost", "svsvc",
    "swprv", "upnphost", "vds", "vmicguestinterface", "vmicheartbeat",
    "vmickvpexchange", "vmicrdv", "vmicshutdown", "vmictimesync", "vmicvmsession",
    "vmicvss", "vmvss", "wbengine", "wcncsvc", "webthreatdefsvc",
    "wisvc", "wlidsvc", "wlpasvc", "wmiApSrv", "workfolderssvc", "wuauserv", "wudfsvc"
)

# Array of services to set to DISABLED
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

function Set-ServiceConfig {
    param ($List, $Type)
    foreach ($svc in $List) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Set-Service -Name $svc -StartupType $Type -ErrorAction SilentlyContinue
            Write-Host "Set $svc to $Type" -ForegroundColor Green
        }
        else {
            Write-Host "Skipped $svc (Not found)" -ForegroundColor Gray
        }
    }
}
Set-ServiceConfig -List $servicesManual -Type "Manual"
Set-ServiceConfig -List $servicesDisabled -Type "Disabled"

Write-Host ' -- Disabling Mouse Delay Times' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value 0
Set-RegistryValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseHoverTime' -Type String -Value 0

Write-Host ' -- Enabling Verbose Logon' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'VerboseStatus' -Type DWord -Value 1

Write-Host ' -- Restricting Update Delivery to LAN only' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Type DWord -Value 1

Write-Host ' -- Disabling Remote Assistance' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name 'fAllowToGetHelp' -Type DWord -Value 0

Write-Host ' -- Task Manager Details' -ForegroundColor Green
If ((get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild -lt 22557) {
    $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
    Do {
        Start-Sleep -Milliseconds 100
        $preferences = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager' -Name 'Preferences' -ErrorAction SilentlyContinue
    } Until ($preferences)
    Stop-Process $taskmgr
    $preferences.Preferences[28] = 0
    Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager' -Name 'Preferences' -Type Binary -Value $preferences.Preferences
}
Write-Host ' -- Expanding file copy details by default' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Name 'EnthusiastMode' -Type DWord -Value 1

Write-Host ' -- Disabling "My People" on Taskbar' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People' -Name 'PeopleBand' -Type DWord -Value 0

Write-Host ' -- Enable Search Icon on Taskbar' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Type DWord -Value 1

#Write-Host ' -- Setting Explorer to open "This PC"' -ForegroundColor Green
#Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Type DWord -Value 1

Write-Host ' -- Hide 3D Objects Folder' -ForegroundColor Green
Remove-RegistryKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
Remove-RegistryKey -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'

Write-Host ' -- Performance Tweaks and More Telemetry' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' -Name 'SearchOrderConfig' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Type DWord -Value 10
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Type DWord -Value 10
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'WaitToKillServiceTimeout' -Type String -Value 2000
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value 1
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'WaitToKillAppTimeout' -Type String -Value 5000
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Type String -Value 4000
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Type String -Value 1
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'LowLevelHooksTimeout' -Type String -Value 1000
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'ClearPageFileAtShutdown' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseHoverTime' -Type DWord -Value 10

# Network Tweaks
Write-Host ' -- Optimizing Network File Sharing buffer' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'IRPStackSize' -Type DWord -Value 20

Write-Host ' -- Group svchost.exe processes' -ForegroundColor Green
$ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -Type DWord -Value $ram -Force

Write-Host ' -- Remove "News and Interest" from taskbar' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' -Name 'ShellFeedsTaskbarViewMode' -Type DWord -Value 2

Write-Host ' -- remove "Meet Now" button from taskbar' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAMeetNow' -Type DWord -Value 1

Write-Host ' -- Blocking DiagTrack logging' -ForegroundColor Green
$autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
    Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
}
icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null

Write-Host ' -- Disabling Wi-Fi Sense' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' -Name 'Value' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' -Name 'Value' -Type DWord -Value 0

Write-Host ' -- Disabling Activity History' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Type DWord -Value 0

Write-Host ' -- Disabling Location Tracking' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Type String -Value "Deny"
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}' -Name 'SensorPermissionState' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration' -Name 'Status' -Type DWord -Value 0

Set-RegistryValue -Path 'HKLM:\SYSTEM\Maps' -Name 'AutoUpdateEnabled' -Type DWord -Value 0

Write-Host ' -- Disabling Storage Sense' -ForegroundColor Green
Remove-RegistryKey -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'

Write-Host ' -- Enabling Power Throttling' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name 'PowerThrottlingOff' -Type DWord -Value 00000000
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Type DWord -Value 0000001

Write-Host ' -- Enabling NumLock after startup' -ForegroundColor Green
If (!(Test-Path "HKU:")) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}
Set-RegistryValue -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Type String -Value 2147483650
Set-RegistryValue -Path 'HKCU:\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Type String -Value 2147483650

Write-Host ' -- Setting BIOS time to UTC' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'RealTimeIsUniversal' -Type DWord -Value 1

Write-Host ' -- Enabling Clipboard History' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowClipboardHistory' -Type DWord -Value 1

# Prevent installation of Teams
Write-Host ' -- Preventing installation of Teams' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Teams' -Name 'DisableInstallation' -Type DWord -Value 1

Write-Host ' -- Try the new Outlook' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences' -Name 'UseNewOutlook' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\General' -Name 'HideNewOutlookToggle' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General' -Name 'DoNewOutlookAutoMigration' -Type DWord -Value 0
Remove-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences' -Name 'NewOutlookMigrationUserSetting'

# Disable Chat icon
Write-Host ' -- Disabling Chat icon' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Name 'ChatIcon' -Type DWord -Value 3
Set-RegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Type DWord -Value 0

# Prevent installation of DevHome and Outlook
Write-Host ' -- Preventing installation of DevHome and Outlook' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Mail' -Name 'PreventRun' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' -Name 'workCompleted' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' -Name 'workCompleted' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' -Name 'workCompleted' -Type DWord -Value 1
Remove-RegistryKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
Remove-RegistryKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'

# Prevent installation of Teams
Write-Host ' -- Preventing installation of Teams' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Teams' -Name 'DisableInstallation' -Type DWord -Value 1

# Prevent installation of New Outlook
Write-Host ' -- Preventing installation of New Outlook' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Mail' -Name 'PreventRun' -Type DWord -Value 1

Write-Host ' -- Disable Modern Standby Networking' -ForegroundColor Green
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9' -Name 'ACSettingIndex' -Type DWord -Value 0
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9' -Name 'DCSettingIndex' -Type DWord -Value 0

Write-Host ' -- Disable Click to Do' -ForegroundColor Green
Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo' -Type DWord -Value 1
Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo' -Type DWord -Value 1

Write-Host ' -- Disable Password expiration' -ForegroundColor Green
net.exe accounts /maxpwage:UNLIMITED