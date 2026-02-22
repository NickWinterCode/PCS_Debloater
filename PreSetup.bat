:: DO NOT DELTE, IMPORTANT FOR SCRIPT FINDING
cd /d %~dp0

:: Copy Wallpaper to Systems Location and RemoteControl to Users Desktop
copy "misc\PC-Spezialist_BG.jpg" "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg"
copy "misc\PCSpezialist Fernwartung.exe" "%userprofile%\Desktop\PCSpezialist Fernwartung.exe"

:: This PC on desktop
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f

:: Disables Screen Off and Sleepmode in powerplan
powercfg /X monitor-timeout-ac 0
powercfg /X monitor-timeout-dc 0
powercfg /X standby-timeout-ac 0
powercfg /X standby-timeout-dc 0

:: Apply Wallpaper
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "" /f 
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "C:\Windows\Web\4K\Wallpaper\Windows\PC-Spezialist_BG.jpg" /f 
reg delete "HKCU\Software\Microsoft\Internet Explorer\Desktop\General" /v WallpaperStyle /f
reg add "HKCU\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d 10 /f
rundll32.exe user32.dll, UpdatePerUserSystemParameters 1, True
taskkill /im explorer.exe /f & explorer.exe


@set LF=^

@SET command=#
@FOR /F "tokens=*" %%i in ('findstr -bv @ "%~f0"') DO SET command=!command!!LF!%%i
@powershell -noprofile -noexit -command !command! & goto:eof
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