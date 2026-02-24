# PreSetup.ps1 - PowerShell version of PreSetup.bat

# Copy Wallpaper to System Location and RemoteControl to User's Desktop
Copy-Item "misc\PC-Spezialist_BG.jpg" -Destination "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg" -Force
Copy-Item "misc\PCSpezialist Fernwartung.exe" -Destination "$env:USERPROFILE\Desktop\PCSpezialist Fernwartung.exe" -Force

# This PC on desktop
Write-Output "Showing This PC ..."
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f   
cmd.exe /c "taskkill.exe /f /im explorer.exe && start explorer.exe"

# Disables Screen Off and Sleepmode in powerplan
powercfg /X monitor-timeout-ac 0
powercfg /X monitor-timeout-dc 0
powercfg /X standby-timeout-ac 0
powercfg /X standby-timeout-dc 0

Write-Output "----- Adding Orga. to System-Info in setting -----"
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Manufacturer' -PropertyType String -Value "PC-SPEZIALIST GUESTROW" -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'SupportURL'  -PropertyType String -Value 'https://pcspezialist.de/standorte/mv/guestrow-computervertrieb-marco-ast/' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'SupportPhone' -PropertyType String -Value '03843-22700' -Force | Out-Null

Write-Output "----- Apply Wallpaper -----"
# Apply Wallpaper
$imgPath="C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg"
$code = @' 
using System.Runtime.InteropServices; 
namespace Win32{ 
    
     public class Wallpaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
         static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ; 
         
         public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
         }
    }
 } 
'@
add-type $code 

#Apply the Change on the system 
[Win32.Wallpaper]::SetWallpaper($imgPath)

Write-Output "----- Change Order of Desktop Icons -----"
try {
  . "$PSScriptRoot\REICON.ps1"
  Set-IconPositionWithSwap -Name "Dieser PC" -X 36 -Y 2
  Set-IconPositionWithSwap -Name "Papierkorb" -X 36 -Y 102
  Set-IconPositionWithSwap -Name "Microsoft Edge" -X 36 -Y 202
  Set-IconPositionWithSwap -Name "PCSpezialist Fernwartung" -X 1836 -Y 2
} catch {
  Write-Output "FUCK, the Module wont load ... DAMIT"
}
