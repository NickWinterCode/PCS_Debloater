@echo off

echo Making temporary PowerShell...
for /f "tokens=* delims=" %%a in ('where powershell.exe') do (set "powershellPath=%%a")
for %%A in ("%powershellPath%") do (set "powershellDir=%%~dpA")
set "powershellTemp=%powershellDir%\pwhell%random%%random%%random%%random%.exe"
copy /y "%powershellPath%" "%powershellTemp%" > nul

for /f "usebackq tokens=2 delims=\" %%A in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
	reg query "HKU\%%A" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > NUL 2>&1
		if not errorlevel 1 (
			echo Firefox
			"%powershellTemp%" -NoP -NonI -EP Bypass -File "%~dp0ASSOC.ps1" "Placeholder" "%%A" ".url:FirefoxHTML-308046B0AF4A39CB" "Proto:http:FirefoxHTML-308046B0AF4A39CB" "Proto:https:FirefoxHTML-308046B0AF4A39CB" ".avif:FirefoxHTML-308046B0AF4A39CB" ".htm:FirefoxHTML-308046B0AF4A39CB" ".html:FirefoxHTML-308046B0AF4A39CB" ".pdf:FirefoxHTML-308046B0AF4A39CB" ".shtml:FirefoxHTML-308046B0AF4A39CB" ".svg:FirefoxHTML-308046B0AF4A39CB" ".webp:FirefoxHTML-308046B0AF4A39CB" ".xht:FirefoxHTML-308046B0AF4A39CB" ".xhtml:FirefoxHTML-308046B0AF4A39CB"
			echo VLC
            "%powershellTemp%" -NoP -ExecutionPolicy Bypass -File "%~dp0assoc.ps1" "Placeholder" "%%A" ".264:VLC.264" ".3g2:VLC.3g2" ".3ga:VLC.3ga" ".3gp:VLC.3gp" ".3gp2:VLC.3gp2" ".3gpp:VLC.3gpp" ".669:VLC.669" ".a52:VLC.a52" ".aac:VLC.aac" ".ac3:VLC.ac3" ".adt:VLC.adt" ".adts:VLC.adts" ".aif:VLC.aif" ".aifc:VLC.aifc" ".aiff:VLC.aiff" ".amb:VLC.amb" ".amr:VLC.amr" ".amv:VLC.amv" ".aob:VLC.aob" ".ape:VLC.ape" ".asf:VLC.asf" ".asx:VLC.asx" ".au:VLC.au" ".avi:VLC.avi" ".awb:VLC.awb" ".b4s:VLC.b4s" ".bik:VLC.bik" ".bin:VLC.bin" ".caf:VLC.caf" ".cda:VLC.cda" ".crf:VLC.crf" ".cue:VLC.cue" ".dash:VLC.dash" ".dav:VLC.dav" ".divx:VLC.divx" ".drc:VLC.drc" ".dts:VLC.dts" ".dv:VLC.dv" ".dvr:VLC.dvr" ".dvr-ms:VLC.dvr-ms" ".evo:VLC.evo" ".f4v:VLC.f4v" ".flac:VLC.flac" ".flv:VLC.flv" ".gvi:VLC.gvi" ".gxf:VLC.gxf" ".ifo:VLC.ifo" ".it:VLC.it" ".kar:VLC.kar" ".m1v:VLC.m1v" ".m2t:VLC.m2t" ".m2ts:VLC.m2ts" ".m2v:VLC.m2v" ".m3u:VLC.m3u" ".m3u8:VLC.m3u8" ".m4a:VLC.m4a" ".m4b:VLC.m4b" ".m4p:VLC.m4p" ".m4v:VLC.m4v" ".m5p:VLC.m5p" ".mid:VLC.mid" ".mka:VLC.mka" ".mkv:VLC.mkv" ".mod:VLC.mod" ".mov:VLC.mov" ".mp1:VLC.mp1" ".mp2:VLC.mp2" ".mp2v:VLC.mp2v" ".mp3:VLC.mp3" ".mp4:VLC.mp4" ".mp4v:VLC.mp4v" ".mpa:VLC.mpa" ".mpc:VLC.mpc" ".mpe:VLC.mpe" ".mpeg:VLC.mpeg" ".mpeg1:VLC.mpeg1" ".mpeg2:VLC.mpeg2" ".mpeg4:VLC.mpeg4" ".mpg:VLC.mpg" ".mpga:VLC.mpga" ".mpv2:VLC.mpv2" ".mts:VLC.mts" ".mtv:VLC.mtv" ".mus:VLC.mus" ".mxf:VLC.mxf" ".nsv:VLC.nsv" ".nuv:VLC.nuv" ".oga:VLC.oga" ".ogg:VLC.ogg" ".ogm:VLC.ogm" ".ogv:VLC.ogv" ".ogx:VLC.ogx" ".oma:VLC.oma" ".opus:VLC.opus" ".pls:VLC.pls" ".ps:VLC.ps" ".qcp:VLC.qcp" ".ra:VLC.ra" ".ram:VLC.ram" ".rec:VLC.rec" ".rm:VLC.rm" ".rmi:VLC.rmi" ".rmvb:VLC.rmvb" ".rpl:VLC.rpl" ".s3m:VLC.s3m" ".sdp:VLC.sdp" ".sid:VLC.sid" ".snd:VLC.snd" ".spx:VLC.spx" ".sub:VLC.sub" ".tak:VLC.tak" ".thd:VLC.thd" ".thp:VLC.thp" ".tod:VLC.tod" ".tp:VLC.tp" ".ts:VLC.ts" ".tta:VLC.tta" ".tts:VLC.tts" ".txd:VLC.txd" ".vlc:VLC.vlc" ".vob:VLC.vob" ".voc:VLC.voc" ".vqf:VLC.vqf" ".vro:VLC.vro" ".w64:VLC.w64" ".wav:VLC.wav" ".wax:VLC.wax" ".webm:VLC.webm" ".wm:VLC.wm" ".wma:VLC.wma" ".wmv:VLC.wmv" ".wtv:VLC.wtv" ".wv:VLC.wv" ".wvx:VLC.wvx" ".xa:VLC.xa" ".xesc:VLC.xesc" ".xm:VLC.xm" ".xspf:VLC.xspf" ".zab:VLC.zab" ".wpl:VLC.wpl" ".wsz:VLC.wsz"
            echo WinRAR
            "%powershellTemp%" -NoP -ExecutionPolicy Bypass -File "%~dp0assoc.ps1" "Placeholder" "%%A" ".001:WinRAR" ".7z:WinRAR" ".arj:WinRAR" ".bz:WinRAR" ".bz2:WinRAR" ".cab:WinRAR" ".gz:WinRAR" ".lha:WinRAR" ".lz:WinRAR" ".lzh:WinRAR" ".rar:WinRAR" ".rev:WinRAR" ".tar:WinRAR" ".taz:WinRAR" ".tbz:WinRAR" ".tbz2:WinRAR" ".tgz:WinRAR" ".tlz:WinRAR" ".txz:WinRAR" ".tzst:WinRAR" ".uu:WinRAR" ".uue:WinRAR" ".xxe:WinRAR" ".xz:WinRAR" ".z:WinRAR" ".zip:WinRAR" ".zipx:WinRAR" ".zst:WinRAR"
            echo Thunderbird
            "%powershellTemp%" -NoP -ExecutionPolicy Bypass -File "%~dp0assoc.ps1" "Placeholder" "%%A" "Proto:mailto:Thunderbird.Url.mailto" "Proto:mid:Thunderbird.Url.mid" "Proto:webcal:Thunderbird.Url.webcal" "Proto:webcals:Thunderbird.Url.webcals" ".eml:ThunderbirdEML" ".ics:ThunderbirdICS" ".wdseml:Thunderbirdwdseml"
            echo Adobe Acrobat
            "%powershellTemp%" -NoP -ExecutionPolicy Bypass -File "%~dp0assoc.ps1" "Placeholder" "%%A" ".pdf:Acrobat.Document.DC"
    )
)
echo Deleting temporary PowerShell...
del /f /q "%powershellTemp%" > nul