echo installing Mozilla Firefox
winget install -e --id Mozilla.Firefox
echo installing Mozilla Thunderbird
winget install -e --id Mozilla.Thunderbird
echo installing Adobe Acrobat Reader DC
winget install -e --id Adobe.Acrobat.Reader.64-bit
echo installing The Document Foundation LibreOffice
winget install -e --id TheDocumentFoundation.LibreOffice
echo installing Microsoft Visual C++ Redistributable 2015+
winget install -e --id Microsoft.VCRedist.2015+.x64
echo installing Microsoft Visual C++ Redistributable 2015+
winget install -e --id Microsoft.VCRedist.2015+.x86
echo installing VideoLAN VLC
winget install -e --id VideoLAN.VLC
echo installing WinRAR
winget install -e --id RARLab.WinRAR
timeout /t 1 /nobreak
exit
