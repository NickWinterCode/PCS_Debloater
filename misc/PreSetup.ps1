# PreSetup.ps1 - PowerShell version of PreSetup.bat
# DO NOT DELETE, IMPORTANT FOR SCRIPT FINDING
#Set-Location -Path $PSScriptRoot

# Copy Wallpaper to System Location and RemoteControl to User's Desktop
Copy-Item "misc\PC-Spezialist_BG.jpg" -Destination "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg" -Force
Copy-Item "misc\PCSpezialist Fernwartung.exe" -Destination "$env:USERPROFILE\Desktop\PCSpezialist Fernwartung.exe" -Force

# This PC on desktop
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType DWord -Value 0 -Force

# Disables Screen Off and Sleepmode in powerplan
powercfg /X monitor-timeout-ac 0
powercfg /X monitor-timeout-dc 0
powercfg /X standby-timeout-ac 0
powercfg /X standby-timeout-dc 0

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
