$GermanLangTag = 'de-DE'    # German language
$GermanLayoutID = '0407:00000407'  # German keyboard

# Get current language settings
$LangList = Get-WinUserLanguageList

# Add German language if not already present
if ($LangList.LanguageTag -notcontains $GermanLangTag) {
    $GermanLang = New-WinUserLanguageList -Language $GermanLangTag
    $LangList.Add($GermanLang[0])
}

# Remove English (US) language (and its associated US keyboard)
$LangList = $LangList | Where-Object { $_.LanguageTag -ne 'en-US' }

# Set German keyboard for all remaining languages
foreach ($Lang in $LangList) {
    $Lang.InputMethodTips.Clear()
    $Lang.InputMethodTips.Add($GermanLayoutID)
}

# Apply changes system-wide
Set-WinUserLanguageList -LanguageList $LangList -Force