echo installing Mozilla Firefox
winget install Mozilla.Firefox.de

echo installing Mozilla Thunderbird
winget install Mozilla.Thunderbird.de

echo installing Microsoft Visual C++ Redistributable 2015+
winget install Microsoft.VCRedist.2015+.x64

echo installing Microsoft Visual C++ Redistributable 2015+
winget install Microsoft.VCRedist.2015+.x86

echo installing VideoLAN VLC
winget install VideoLAN.VLC

echo installing WinRAR
winget install RARLab.WinRAR

echo installing The Document Foundation LibreOffice
winget install TheDocumentFoundation.LibreOffice

echo installing Adobe Acrobat Reader DC
:: https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2500120577/AcroRdrDCx642500120577_MUI.exe
winget install Adobe.Acrobat.Reader.64-bit

timeout /t 1 /nobreak
exit
