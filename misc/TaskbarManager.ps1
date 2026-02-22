# Run this script as Administrator
$ErrorActionPreference = "Stop"

# Define the apps you want to PIN
# You must provide the exact path to the .lnk (shortcut) files.
$AppsToPin = @(
    "%APPDATA%\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk",
    "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
    "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Thunderbird.lnk", 
    "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\LibreOffice\LibreOffice Writer.lnk", 
    "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word.lnk"
)

$ConfigPath = "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"

$xmlHeader = '<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>'

$xmlFooter = '      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>'

$pinEntries = ""
foreach ($app in $AppsToPin) {
    $pinEntries += "`r`n        <taskbar:DesktopApp DesktopApplicationLinkPath=""$app"" />"
}

$finalXml = $xmlHeader + $pinEntries + $xmlFooter

try {
    Write-Host "Creating LayoutModification.xml at $ConfigPath..." -ForegroundColor Cyan
    $finalXml | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
    Write-Host "Success! The configuration file has been created." -ForegroundColor Green
    Write-Host "NOTE: To see changes, you may need to sign out and sign back in," -ForegroundColor Yellow
    Write-Host "or the system must be a fresh user profile." -ForegroundColor Yellow
}
catch {
    Write-Host "Error writing file: $_" -ForegroundColor Red
}