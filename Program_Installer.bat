echo installing Mozilla Firefox
winget install -e --id Mozilla.Firefox
echo installing Mozilla Thunderbird
winget install -e --id Mozilla.Thunderbird
echo installing Microsoft Visual C++ Redistributable 2015+
winget install -e --id Microsoft.VCRedist.2015+.x64
echo installing Microsoft Visual C++ Redistributable 2015+
winget install -e --id Microsoft.VCRedist.2015+.x86
echo installing VideoLAN VLC
winget install -e --id VideoLAN.VLC
echo installing WinRAR
winget install -e --id RARLab.WinRAR
echo installing The Document Foundation LibreOffice
winget install -e --id TheDocumentFoundation.LibreOffice
echo installing Adobe Acrobat Reader DC
:: https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2500120577/AcroRdrDCx642500120577_MUI.exe
winget install -e --id Adobe.Acrobat.Reader.64-bit
timeout /t 1 /nobreak
exit
