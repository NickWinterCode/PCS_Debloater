function Get-SystemInfo {
    # This function gathers comprehensive system information and is compatible with PowerShell v2.0+.
    
    param (
        [string[]]$ComputerName = "."
    )

    # --- REGISTRY KEY DECODING SETUP ---
    $hklm = 2147483650
    $regPath = "Software\Microsoft\Windows NT\CurrentVersion"
    $regValue = "DigitalProductId"
    $charsArray = "B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9"

    foreach ($target in $ComputerName) {
        try {
            # --- GATHER ALL WMI DATA ---
            Write-Host "Gathering information from $target..."
            $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $target
            $csInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $target
            $cpuInfo = Get-WmiObject -Class Win32_Processor -ComputerName $target
            $enclosureInfo = Get-WmiObject -Class Win32_SystemEnclosure -ComputerName $target
            $licensingInfo = Get-WmiObject -Class SoftwareLicensingService -ComputerName $target
            $gpuInfo = Get-WmiObject -Class Win32_VideoController -ComputerName $target
            
            # --- SPECIAL HANDLING FOR FULL BIOS INFO ---
            # Capture the formatted output of Win32_BIOS as a single multi-line string
            $biosFormattedString = Get-WmiObject -Class Win32_BIOS -ComputerName $target | Format-List -Property * | Out-String

            # --- PROCESS AND FORMAT THE DATA ---
            $installDate = $osInfo.ConvertToDateTime($osInfo.InstallDate)
            $lastBootUpTime = $osInfo.ConvertToDateTime($osInfo.LastBootUpTime)
            
            $totalRamGB = [math]::Round($csInfo.TotalPhysicalMemory / 1GB, 2)
            $availableRamGB = [math]::Round($osInfo.FreePhysicalMemory / (1024*1024), 2) 
            $ramInfo = "$($totalRamGB) GB Installed ($($availableRamGB) GB Available)"

            $gpuDetails = $gpuInfo | ForEach-Object {
                $vramGB = 0
                if ($_.AdapterRAM) { $vramGB = [math]::Round($_.AdapterRAM / 1GB, 2) }
                "$($_.Name) ($($vramGB) GB VRAM) - Driver: $($_.DriverVersion)"
            }
            $gpuDetails = $gpuDetails -join "`r`n"

            $drives = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $target -Filter "DriveType=3" | ForEach-Object {
                $driveSizeGB = [math]::Round($_.Size / 1GB, 2)
                $freeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
                "$($_.DeviceID) $($driveSizeGB) GB Total, $($freeSpaceGB) GB Free"
            }
            $driveInfo = $drives -join "`r`n"
            
            $netAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $target -Filter "IPEnabled='TRUE'"
            $ipAddresses = ($netAdapters.IPAddress | Where-Object { $_ -like '*.*' }) -join ', '
            $macAddresses = $netAdapters.MACAddress -join ', '

            # --- DECODE REGISTRY PRODUCT KEY ---
            $registryKey = "Not Found in Registry"
            $wmiReg = [WMIClass]"\\$target\root\default:StdRegProv"
            $data = $wmiReg.GetBinaryValue($hklm, $regPath, $regValue)
            if ($data.uValue) {
                # ... (decoding logic is unchanged)
                $binArray = ($data.uValue)[52..66]
                $decodedKey = ""
                for ($i = 24; $i -ge 0; $i--) {
                    $k = 0
                    for ($j = 14; $j -ge 0; $j--) {
                        $k = $k * 256 -bxor $binArray[$j]
                        $binArray[$j] = [math]::truncate($k / 24)
                        $k = $k % 24
                    }
                    $decodedKey = $charsArray[$k] + $decodedKey
                    if (($i % 5 -eq 0) -and ($i -ne 0)) { $decodedKey = "-" + $decodedKey }
                }
                $registryKey = $decodedKey
            }

            # --- ASSEMBLE THE FINAL OBJECT ---
            $obj = New-Object -TypeName PSObject
            $obj | Add-Member -MemberType NoteProperty -Name 'Computer Name' -Value $csInfo.Name
            $obj | Add-Member -MemberType NoteProperty -Name 'System Manufacturer' -Value $csInfo.Manufacturer
            $obj | Add-Member -MemberType NoteProperty -Name 'System Model' -Value $csInfo.Model
            $obj | Add-Member -MemberType NoteProperty -Name 'Serial Number' -Value $enclosureInfo.SerialNumber
            $obj | Add-Member -MemberType NoteProperty -Name 'CPU' -Value $cpuInfo.Name
            $obj | Add-Member -MemberType NoteProperty -Name 'Memory (RAM)' -Value $ramInfo
            $obj | Add-Member -MemberType NoteProperty -Name 'Graphics Card(s)' -Value $gpuDetails
            $obj | Add-Member -MemberType NoteProperty -Name 'Drives' -Value $driveInfo
            $obj | Add-Member -MemberType NoteProperty -Name 'OS_Info_Separator' -Value '--- OS Information ---'
            $obj | Add-Member -MemberType NoteProperty -Name 'OS Caption' -Value $osInfo.Caption
            $obj | Add-Member -MemberType NoteProperty -Name 'OS Architecture' -Value $osInfo.OSArchitecture
            $obj | Add-Member -MemberType NoteProperty -Name 'OS Build Number' -Value $osInfo.BuildNumber
            # ... (rest of the properties)
            $obj | Add-Member -MemberType NoteProperty -Name 'Install Date' -Value $installDate
            $obj | Add-Member -MemberType NoteProperty -Name 'Last Boot Time' -Value $lastBootUpTime
            $obj | Add-Member -MemberType NoteProperty -Name 'Registered To' -Value $osInfo.RegisteredUser
            $obj | Add-Member -MemberType NoteProperty -Name 'Windows Product ID' -Value $osInfo.SerialNumber
            $obj | Add-Member -MemberType NoteProperty -Name 'Licensing_Info_Separator' -Value '--- Licensing Information ---'
            $obj | Add-Member -MemberType NoteProperty -Name 'Firmware Product Key' -Value $licensingInfo.OA3xOriginalProductKey
            $obj | Add-Member -MemberType NoteProperty -Name 'Registry Product Key' -Value $registryKey
            $obj | Add-Member -MemberType NoteProperty -Name 'Network_Info_Separator' -Value '--- Network Information ---'
            $obj | Add-Member -MemberType NoteProperty -Name 'IP Addresses' -Value $ipAddresses
            $obj | Add-Member -MemberType NoteProperty -Name 'MAC Addresses' -Value $macAddresses
            $obj | Add-Member -MemberType NoteProperty -Name 'BIOS_Info_Separator' -Value '--- Full BIOS Information ---'
            $obj | Add-Member -MemberType NoteProperty -Name 'BIOS Information' -Value $biosFormattedString # <-- ADDED THE FULL STRING HERE
            
            # Output the finished object
            $obj
        }
        catch {
            Write-Warning "Failed to get information from computer: $target. Error: $_"
        }
    }
}

# --- SCRIPT EXECUTION AND OUTPUT HANDLING ---

# The rest of the script is unchanged and correct.
$computerName = $env:COMPUTERNAME
$desktopPath  = [System.Environment]::GetFolderPath('Desktop')
$outputFolder = Join-Path -Path $desktopPath -ChildPath $computerName
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFile = Join-Path -Path $outputFolder -ChildPath "SystemInfo-$($computerName)-$($timestamp).txt"
New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
Get-SystemInfo | Format-List | Out-File -FilePath $outputFile
Write-Host "System information has been saved to: $outputFile"