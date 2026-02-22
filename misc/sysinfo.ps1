# Hardware and System Information Script with Enhanced Product Key Retrieval
# Run as Administrator for best results

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    SYSTEM INFORMATION REPORT" -ForegroundColor Cyan
Write-Host "    Generated: $(Get-Date)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Add Product Key Decoder Type
Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class ProductKeyDecoder {
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetFirmwareEnvironmentVariable(
        string lpName,
        string lpGuid,
        IntPtr pBuffer,
        uint nSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern uint GetSystemFirmwareTable(
        uint FirmwareTableProviderSignature,
        uint FirmwareTableID,
        IntPtr pFirmwareTableBuffer,
        uint BufferSize);

    // Decode product key from DigitalProductId
    public static string DecodeProductKey(byte[] digitalProductId) {
        const int keyStartIndex = 52;
        const int keyEndIndex = keyStartIndex + 15;
        const string digits = "BCDFGHJKMPQRTVWXY2346789";
        
        if (digitalProductId == null || digitalProductId.Length < keyEndIndex) {
            return null;
        }

        char[] decodedChars = new char[29];
        byte[] hexPid = new byte[15];
        Array.Copy(digitalProductId, keyStartIndex, hexPid, 0, 15);

        for (int i = 28; i >= 0; i--) {
            if ((i + 1) % 6 == 0) {
                decodedChars[i] = '-';
            } else {
                int digitMapIndex = 0;
                for (int j = 14; j >= 0; j--) {
                    int byteValue = (digitMapIndex << 8) | hexPid[j];
                    hexPid[j] = (byte)(byteValue / 24);
                    digitMapIndex = byteValue % 24;
                }
                decodedChars[i] = digits[digitMapIndex];
            }
        }
        return new string(decodedChars);
    }

    // Get key from ACPI MSDM table (OEM keys)
    public static string GetOEMProductKey() {
        try {
            uint firmwareTableID = 0x4D44534D; // 'MSDM' in reverse
            uint acpiSignature = 0x41435049;   // 'ACPI'
            
            // Get required buffer size
            uint bufferSize = GetSystemFirmwareTable(acpiSignature, firmwareTableID, IntPtr.Zero, 0);
            if (bufferSize == 0) return null;

            IntPtr pBuffer = Marshal.AllocHGlobal((int)bufferSize);
            try {
                uint result = GetSystemFirmwareTable(acpiSignature, firmwareTableID, pBuffer, bufferSize);
                if (result == 0) return null;

                byte[] firmwareTable = new byte[bufferSize];
                Marshal.Copy(pBuffer, firmwareTable, 0, (int)bufferSize);

                // MSDM structure: skip header (36 bytes) to get to the key
                if (bufferSize > 56) {
                    int keyOffset = 36; // Standard MSDM table offset
                    uint keyLength = BitConverter.ToUInt32(firmwareTable, 16);
                    
                    if (keyLength > 0 && keyLength < 100 && bufferSize >= keyOffset + keyLength) {
                        return Encoding.ASCII.GetString(firmwareTable, keyOffset, (int)keyLength).Trim('\0');
                    }
                }
            } finally {
                Marshal.FreeHGlobal(pBuffer);
            }
        } catch { }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue

# User Information - Place this at the beginning for context
Write-Host "=== USER INFORMATION ===" -ForegroundColor Yellow
try {
    # Current user information
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    
    Write-Host "Current User:" -ForegroundColor Cyan
    Write-Host "  Username: $($currentUser.Name)"
    Write-Host "  Display Name: $env:USERNAME"
    Write-Host "  User Domain: $env:USERDOMAIN"
    Write-Host "  User Profile: $env:USERPROFILE"
    Write-Host "  Is Administrator: $isAdmin"
    Write-Host "  Authentication Type: $($currentUser.AuthenticationType)"
    
    # Get current user's groups
    Write-Host "  Member of Groups:" -ForegroundColor Gray
    $groups = $currentUser.Groups | ForEach-Object {
        $_.Translate([System.Security.Principal.NTAccount]).Value
    }
    $groups | Select-Object -First 10 | ForEach-Object {
        Write-Host "    - $_"
    }
    if ($groups.Count -gt 10) {
        Write-Host "    ... and $($groups.Count - 10) more groups"
    }
    
    Write-Host ""
    Write-Host "All Local Users:" -ForegroundColor Cyan
    
    # Get all local users
    $users = Get-LocalUser | Sort-Object Name
    foreach ($user in $users) {
        Write-Host "  $($user.Name)"
        Write-Host "    Full Name: $($user.FullName)"
        Write-Host "    Enabled: $($user.Enabled)"
        Write-Host "    Last Logon: $($user.LastLogon)"
        Write-Host "    Password Required: $($user.PasswordRequired)"
        Write-Host "    Password Expires: $($user.PasswordExpires)"
        Write-Host "    Account Expires: $($user.AccountExpires)"
        Write-Host "    Description: $($user.Description)"
        
        # Check if user is in Administrators group
        try {
            $isUserAdmin = (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object {$_.Name -like "*$($user.Name)"}) -ne $null
            if ($isUserAdmin) {
                Write-Host "    [ADMINISTRATOR]" -ForegroundColor Red
            }
        } catch { }
        Write-Host ""
    }
    
    # Get domain users if on domain
    if ($env:USERDOMAIN -ne $env:COMPUTERNAME) {
        Write-Host "Domain Users (Currently Logged In):" -ForegroundColor Cyan
        try {
            $loggedInUsers = Get-CimInstance Win32_LoggedOnUser | Select-Object -Unique Antecedent | ForEach-Object {
                $_.Antecedent.Name
            } | Where-Object {$_ -ne $null} | Sort-Object -Unique
            
            foreach ($domainUser in $loggedInUsers) {
                Write-Host "  - $domainUser"
            }
        } catch {
            Write-Host "  Unable to retrieve domain users"
        }
    }
    
    # Show active sessions
    Write-Host ""
    Write-Host "Active Sessions:" -ForegroundColor Cyan
    try {
        $sessions = quser 2>$null | Select-Object -Skip 1 | ForEach-Object {
            $parts = $_ -split '\s+'
            [PSCustomObject]@{
                Username = $parts[0]
                SessionName = $parts[1]
                ID = $parts[2]
                State = $parts[3]
                IdleTime = $parts[4]
                LogonTime = "$($parts[5]) $($parts[6])"
            }
        }
        
        if ($sessions) {
            foreach ($session in $sessions) {
                Write-Host "  User: $($session.Username)"
                Write-Host "    Session: $($session.SessionName)"
                Write-Host "    State: $($session.State)"
                Write-Host "    Logon Time: $($session.LogonTime)"
                Write-Host ""
            }
        }
    } catch {
        Write-Host "  Unable to retrieve active sessions"
    }
    
} catch {
    Write-Host "Error getting user information: $_" -ForegroundColor Red
}
Write-Host ""

# Windows Installation Information
Write-Host "=== WINDOWS INSTALLATION INFO ===" -ForegroundColor Yellow
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    
    Write-Host "Computer Name: $($cs.Name)"
    Write-Host "Domain/Workgroup: $($cs.Domain)"
    Write-Host "OS Name: $($os.Caption)"
    Write-Host "OS Version: $($os.Version)"
    Write-Host "OS Build: $((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion) (Build $($os.BuildNumber).$((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR))"
    Write-Host "OS Architecture: $($os.OSArchitecture)"
    Write-Host "Install Date: $($os.InstallDate)"
    Write-Host "Last Boot Time: $($os.LastBootUpTime)"
    Write-Host "System Directory: $($os.SystemDirectory)"
    Write-Host "Windows Directory: $($os.WindowsDirectory)"
    Write-Host "Registered User: $($os.RegisteredUser)"
    Write-Host "Product ID: $((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductId)"
    
    # Enhanced Product Key Retrieval
    Write-Host ""
    Write-Host "Product Keys:" -ForegroundColor Cyan
    $foundKey = $false
    
    # Method 1: Try BackupProductKeyDefault (Windows 10/11)
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $backupKey = (Get-ItemProperty -Path $regPath -Name "BackupProductKeyDefault" -ErrorAction Stop).BackupProductKeyDefault
        
        if ($backupKey -and $backupKey -match '^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$') {
            Write-Host "  [Registry] Installed Key: $backupKey" -ForegroundColor Green
            $foundKey = $true
        }
    } catch { }
    
    # Method 2: Get OEM key from UEFI/ACPI MSDM table
    try {
        $oemKey = [ProductKeyDecoder]::GetOEMProductKey()
        if ($oemKey) {
            Write-Host "  [UEFI/OEM] ACPI MSDM Key: $oemKey" -ForegroundColor Magenta
            $foundKey = $true
        }
    } catch { }
    
    # Method 3: Try WMI (alternative method)
    try {
        $key = (Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService").OA3xOriginalProductKey
        if ($key) {
            Write-Host "  [WMI] OA3 Product Key: $key" -ForegroundColor Cyan
            $foundKey = $true
        }
    } catch { }
    
    # Method 4: Partial key from WMI
    #try {
    #    $partialKey = (Get-WmiObject -Class SoftwareLicensingProduct | Where-Object {$_.PartialProductKey -ne $null}).PartialProductKey
    #    if ($partialKey) {
    #        Write-Host "  [WMI] Partial Product Key: ***-$partialKey" -ForegroundColor Gray
    #    }
    #} catch { }
    
    if (-not $foundKey) {
        Write-Host "  No full product key found (may be using digital license)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error getting OS information: $_" -ForegroundColor Red
}
Write-Host ""

# System Information
Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Yellow
try {
    Write-Host "Manufacturer: $($cs.Manufacturer)"
    Write-Host "Model: $($cs.Model)"
    Write-Host "System Type: $($cs.SystemType)"
    Write-Host "Total Physical Memory: $([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB"
    
    $bios = Get-CimInstance Win32_BIOS
    Write-Host "BIOS Version: $($bios.Name)"
    Write-Host "BIOS Manufacturer: $($bios.Manufacturer)"
    Write-Host "BIOS Release Date: $($bios.ReleaseDate)"
    Write-Host "Serial Number: $($bios.SerialNumber)"
} catch {
    Write-Host "Error getting system information: $_" -ForegroundColor Red
}
Write-Host ""

# CPU Information
Write-Host "=== PROCESSOR(S) ===" -ForegroundColor Yellow
try {
    $cpus = Get-CimInstance Win32_Processor
    $cpuIndex = 1
    foreach ($cpu in $cpus) {
        Write-Host "CPU ${cpuIndex}:"
        Write-Host "  Name: $($cpu.Name)"
        Write-Host "  Manufacturer: $($cpu.Manufacturer)"
        Write-Host "  Cores: $($cpu.NumberOfCores)"
        Write-Host "  Logical Processors: $($cpu.NumberOfLogicalProcessors)"
        Write-Host "  Max Clock Speed: $($cpu.MaxClockSpeed) MHz"
        Write-Host "  Current Clock Speed: $($cpu.CurrentClockSpeed) MHz"
        Write-Host "  L2 Cache: $($cpu.L2CacheSize) KB"
        Write-Host "  L3 Cache: $($cpu.L3CacheSize) KB"
        Write-Host "  Virtualization: $($cpu.VirtualizationFirmwareEnabled)"
        $cpuIndex++
    }
} catch {
    Write-Host "Error getting CPU information: $_" -ForegroundColor Red
}
Write-Host ""

# Memory Information
Write-Host "=== MEMORY (RAM) ===" -ForegroundColor Yellow
try {
    $memory = Get-CimInstance Win32_PhysicalMemory
    $totalMemory = 0
    $slotIndex = 1
    foreach ($dimm in $memory) {
        Write-Host "Slot $slotIndex ($($dimm.DeviceLocator)):"
        Write-Host "  Capacity: $([math]::Round($dimm.Capacity / 1GB, 2)) GB"
        Write-Host "  Speed: $($dimm.Speed) MHz"
        Write-Host "  Manufacturer: $($dimm.Manufacturer)"
        Write-Host "  Part Number: $($dimm.PartNumber)"
        Write-Host "  Form Factor: $($dimm.FormFactor)"
        $totalMemory += $dimm.Capacity
        $slotIndex++
    }
    Write-Host "Total Memory: $([math]::Round($totalMemory / 1GB, 2)) GB"
} catch {
    Write-Host "Error getting memory information: $_" -ForegroundColor Red
}
Write-Host ""

# Motherboard Information
Write-Host "=== MOTHERBOARD ===" -ForegroundColor Yellow
try {
    $mb = Get-CimInstance Win32_BaseBoard
    Write-Host "Manufacturer: $($mb.Manufacturer)"
    Write-Host "Product: $($mb.Product)"
    Write-Host "Version: $($mb.Version)"
    Write-Host "Serial Number: $($mb.SerialNumber)"
} catch {
    Write-Host "Error getting motherboard information: $_" -ForegroundColor Red
}
Write-Host ""

# Graphics Card Information
Write-Host "=== GRAPHICS CARD(S) ===" -ForegroundColor Yellow
try {
    $gpus = Get-CimInstance Win32_VideoController
    $gpuIndex = 1
    foreach ($gpu in $gpus) {
        Write-Host "GPU ${gpuIndex}:" -ForegroundColor White
        Write-Host "  Name: $($gpu.Name)"
        Write-Host "  Adapter Compatibility: $($gpu.AdapterCompatibility)"
        
        # Handle VRAM - some cards report 0 or incorrect values
        if ($gpu.AdapterRAM -gt 0 -and $gpu.AdapterRAM -lt 0x100000000) {
            $vram = [math]::Round($gpu.AdapterRAM / 1GB, 2)
            Write-Host "  Adapter RAM: $vram GB"
        } else {
            # Try to get from registry for modern GPUs with >4GB VRAM
            try {
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
                $subKeys = Get-ChildItem $regPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\d{4}$' }
                foreach ($key in $subKeys) {
                    $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                    if ($props.DriverDesc -eq $gpu.Name) {
                        $qwMemorySize = $props.'HardwareInformation.qwMemorySize'
                        if ($qwMemorySize) {
                            $vramGB = [math]::Round($qwMemorySize / 1GB, 2)
                            Write-Host "  Adapter RAM: $vramGB GB"
                            break
                        }
                    }
                }
            } catch {
                Write-Host "  Adapter RAM: Unable to determine"
            }
        }
        
        # Windows Driver Version (raw internal version)
        $winDriverVersion = $gpu.DriverVersion
        Write-Host "  Windows Driver Version: $winDriverVersion" -ForegroundColor Gray
        
        # Detect GPU Vendor and show marketing driver version
        $gpuName = $gpu.Name.ToLower()
        $adapterCompat = if ($gpu.AdapterCompatibility) { $gpu.AdapterCompatibility.ToLower() } else { "" }
        
        # Determine GPU vendor - use explicit vendor detection to avoid conflicts
        $gpuVendor = "Unknown"
        
        if ($gpuName -match "nvidia" -or $adapterCompat -match "nvidia") {
            $gpuVendor = "NVIDIA"
        }
        elseif ($gpuName -match "intel" -or $adapterCompat -match "intel") {
            $gpuVendor = "Intel"
        }
        elseif ($gpuName -match "amd" -or $gpuName -match "radeon" -or $adapterCompat -match "amd" -or $adapterCompat -match "ati" -or $adapterCompat -match "advanced micro") {
            $gpuVendor = "AMD"
        }
        
        #===========================================
        # NVIDIA Driver Version Conversion
        #===========================================
        if ($gpuVendor -eq "NVIDIA") {
            try {
                # Windows format: AA.BB.CC.DDDD (e.g., 32.0.15.9186)
                # NVIDIA format: Combine CC+DDDD, take last 5 digits, insert decimal after 3rd
                # Example: 32.0.15.9186 -> "15" + "9186" = "159186" -> last 5 = "59186" -> "591.86"
                $versionParts = $winDriverVersion.Split('.')
                if ($versionParts.Count -ge 4) {
                    $combined = $versionParts[2] + $versionParts[3]
                    if ($combined.Length -ge 5) {
                        $last5 = $combined.Substring($combined.Length - 5)
                        $nvidiaVersion = $last5.Substring(0, 3) + "." + $last5.Substring(3)
                        Write-Host "  NVIDIA GeForce Driver: $nvidiaVersion" -ForegroundColor Green
                    }
                }
                
                # Also try to get from NVIDIA registry for additional info
                $nvRegPaths = @(
                    "HKLM:\SOFTWARE\NVIDIA Corporation\Installer2\Drivers",
                    "HKLM:\SOFTWARE\NVIDIA Corporation\Global\CoProcManager"
                )
                foreach ($nvPath in $nvRegPaths) {
                    if (Test-Path $nvPath) {
                        $nvProps = Get-ItemProperty -Path $nvPath -ErrorAction SilentlyContinue
                        if ($nvProps.DriverVersion) {
                            Write-Host "  NVIDIA Registry Version: $($nvProps.DriverVersion)" -ForegroundColor DarkGreen
                            break
                        }
                    }
                }
            } catch {
                Write-Host "  NVIDIA Driver: Unable to parse version" -ForegroundColor Yellow
            }
        }
        #===========================================
        # Intel Driver Version Detection
        #===========================================
        elseif ($gpuVendor -eq "Intel") {
            try {
                # Intel typically uses the last portion as the build number
                $versionParts = $winDriverVersion.Split('.')
                if ($versionParts.Count -ge 4) {
                    # Intel format is usually like: 31.0.101.5592
                    # The marketing version is often displayed as the full version or last two parts
                    $intelVersion = "$($versionParts[2]).$($versionParts[3])"
                    Write-Host "  Intel Graphics Driver: $intelVersion" -ForegroundColor Blue
                }
                
                # Try Intel registry
                if (Test-Path "HKLM:\SOFTWARE\Intel\Display") {
                    $intelProps = Get-ItemProperty -Path "HKLM:\SOFTWARE\Intel\Display" -ErrorAction SilentlyContinue
                    if ($intelProps.DriverVersion) {
                        Write-Host "  Intel Registry Version: $($intelProps.DriverVersion)" -ForegroundColor DarkBlue
                    }
                }
            } catch { }
        }
        #===========================================
        # AMD/ATI Driver Version Detection
        #===========================================
        elseif ($gpuVendor -eq "AMD") {
            $amdDriverVersion = $null
            $amdSoftwareVersion = $null
            $amdEdition = $null
            
            try {
                # Primary AMD CN registry location (modern Adrenalin)
                if (Test-Path "HKLM:\SOFTWARE\AMD\CN") {
                    $amdCN = Get-ItemProperty -Path "HKLM:\SOFTWARE\AMD\CN" -ErrorAction SilentlyContinue
                    if ($amdCN.DriverVersion) { 
                        $amdDriverVersion = $amdCN.DriverVersion 
                    }
                    if ($amdCN.RadeonSoftwareVersion) { 
                        $amdSoftwareVersion = $amdCN.RadeonSoftwareVersion 
                    }
                    if ($amdCN.RadeonSoftwareEdition) {
                        $amdEdition = $amdCN.RadeonSoftwareEdition
                    }
                }
                
                # Try WMI for AMD
                if (-not $amdDriverVersion) {
                    $amdWmi = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction SilentlyContinue | 
                        Where-Object { $_.DeviceName -eq $gpu.Name } | Select-Object -First 1
                    if ($amdWmi.DriverVersion) {
                        $amdDriverVersion = $amdWmi.DriverVersion
                    }
                }
                
                # Alternative registry paths
                if (-not $amdSoftwareVersion) {
                    $altPaths = @(
                        "HKLM:\SOFTWARE\AMD\Install",
                        "HKLM:\SOFTWARE\ATI Technologies\CBT"
                    )
                    foreach ($altPath in $altPaths) {
                        if (Test-Path $altPath) {
                            $altProps = Get-ItemProperty -Path $altPath -ErrorAction SilentlyContinue
                            if ($altProps.ReleaseVersion -and -not $amdSoftwareVersion) {
                                $amdSoftwareVersion = $altProps.ReleaseVersion
                            }
                        }
                    }
                }
            } catch { }
            
            # Display AMD versions
            if ($amdDriverVersion) {
                Write-Host "  AMD Driver Version: $amdDriverVersion" -ForegroundColor Red
            }
            if ($amdSoftwareVersion) {
                $editionText = if ($amdEdition) { " ($amdEdition)" } else { "" }
                Write-Host "  AMD Adrenalin Version: $amdSoftwareVersion$editionText" -ForegroundColor Red
            }
            if (-not $amdDriverVersion -and -not $amdSoftwareVersion) {
                Write-Host "  AMD Software: Check Radeon Software for version details" -ForegroundColor Yellow
            }
        }
        
        # Driver Date
        Write-Host "  Driver Date: $($gpu.DriverDate)"
        
        # Video Processor
        if ($gpu.VideoProcessor) {
            Write-Host "  Video Processor: $($gpu.VideoProcessor)"
        }
        
        # Resolution and Refresh Rate
        if ($gpu.CurrentHorizontalResolution -and $gpu.CurrentVerticalResolution) {
            Write-Host "  Current Resolution: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)"
            Write-Host "  Refresh Rate: $($gpu.CurrentRefreshRate) Hz"
        }
        
        # Status
        Write-Host "  Status: $($gpu.Status)"
        
        Write-Host ""
        $gpuIndex++
    }
} catch {
    Write-Host "Error getting GPU information: $_" -ForegroundColor Red
}
Write-Host ""

# Storage Information
Write-Host "=== STORAGE DEVICES ===" -ForegroundColor Yellow
try {
    # Physical Disks
    Write-Host "Physical Disks:" -ForegroundColor Cyan
    $disks = Get-CimInstance Win32_DiskDrive
    foreach ($disk in $disks) {
        Write-Host "  $($disk.Model)"
        Write-Host "    Size: $([math]::Round($disk.Size / 1GB, 2)) GB"
        Write-Host "    Interface: $($disk.InterfaceType)"
        Write-Host "    Media Type: $($disk.MediaType)"
        Write-Host "    Serial: $($disk.SerialNumber)"
    }
    
    Write-Host ""
    Write-Host "Logical Drives:" -ForegroundColor Cyan
    $volumes = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.Size -gt 0}
    foreach ($vol in $volumes) {
        $usedSpace = $vol.Size - $vol.FreeSpace
        $percentUsed = [math]::Round(($usedSpace / $vol.Size) * 100, 2)
        Write-Host "  Drive $($vol.DeviceID)"
        Write-Host "    File System: $($vol.FileSystem)"
        Write-Host "    Total Size: $([math]::Round($vol.Size / 1GB, 2)) GB"
        Write-Host "    Used Space: $([math]::Round($usedSpace / 1GB, 2)) GB ($percentUsed%)"
        Write-Host "    Free Space: $([math]::Round($vol.FreeSpace / 1GB, 2)) GB"
    }
} catch {
    Write-Host "Error getting storage information: $_" -ForegroundColor Red
}
Write-Host ""

# Network Adapters
Write-Host "=== NETWORK ADAPTERS ===" -ForegroundColor Yellow
try {
    $adapters = Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.PhysicalAdapter -eq $true}
    foreach ($adapter in $adapters) {
        Write-Host "Adapter: $($adapter.Name)"
        Write-Host "  Manufacturer: $($adapter.Manufacturer)"
        Write-Host "  MAC Address: $($adapter.MACAddress)"
        Write-Host "  Speed: $($adapter.Speed)"
        Write-Host "  Status: $($adapter.NetConnectionStatus)"
        
        # Get IP Configuration
        $config = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.Index -eq $adapter.Index}
        if ($config.IPAddress) {
            Write-Host "  IP Address(es): $($config.IPAddress -join ', ')"
        }
    }
} catch {
    Write-Host "Error getting network information: $_" -ForegroundColor Red
}
Write-Host ""

# Audio Devices
Write-Host "=== AUDIO DEVICES ===" -ForegroundColor Yellow
try {
    $audio = Get-CimInstance Win32_SoundDevice
    foreach ($device in $audio) {
        Write-Host "Device: $($device.Name)"
        Write-Host "  Manufacturer: $($device.Manufacturer)"
        Write-Host "  Status: $($device.Status)"
    }
} catch {
    Write-Host "Error getting audio information: $_" -ForegroundColor Red
}
Write-Host ""

# Monitor Information
Write-Host "=== MONITORS ===" -ForegroundColor Yellow
try {
    # Use inline C# code for better monitor detection
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class MonitorInfo
{
    [DllImport("user32.dll")]
    static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip,
        MonitorEnumProc lpfnEnum, IntPtr dwData);
    
    delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor,
        ref RECT lprcMonitor, IntPtr dwData);
    
    [StructLayout(LayoutKind.Sequential)]
    struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
    
    public static int GetMonitorCount()
    {
        int count = 0;
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero,
            delegate { count++; return true; }, IntPtr.Zero);
        return count;
    }
}
"@ -ErrorAction SilentlyContinue

    $monitorCount = [MonitorInfo]::GetMonitorCount()
    Write-Host "Number of Monitors: $monitorCount"
    
    # WMI Monitor Information
    $monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue
    if ($monitors) {
        foreach ($monitor in $monitors) {
            $name = ($monitor.UserFriendlyName | ForEach-Object {[char]$_}) -join ''
            $serial = ($monitor.SerialNumberID | ForEach-Object {[char]$_}) -join ''
            $manufacturer = ($monitor.ManufacturerName | ForEach-Object {[char]$_}) -join ''
            
            if ($name) { Write-Host "  Monitor: $name" }
            if ($manufacturer) { Write-Host "    Manufacturer: $manufacturer" }
            if ($serial) { Write-Host "    Serial: $serial" }
        }
    }
} catch {
    Write-Host "Error getting monitor information: $_" -ForegroundColor Red
}
Write-Host ""

# Temperature Sensors (if available)
Write-Host "=== TEMPERATURE SENSORS ===" -ForegroundColor Yellow
try {
    $temps = Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace root\wmi -ErrorAction SilentlyContinue
    if ($temps) {
        foreach ($temp in $temps) {
            $celsius = ($temp.CurrentTemperature - 2732) / 10
            Write-Host "Thermal Zone: $($temp.InstanceName)"
            Write-Host "  Temperature: $celsius °C"
        }
    } else {
        Write-Host "Temperature sensors not accessible (may require admin rights or not supported)"
    }
} catch {
    Write-Host "Temperature information not available"
}
Write-Host ""

# Battery Information (for laptops)
Write-Host "=== BATTERY INFORMATION ===" -ForegroundColor Yellow
try {
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        foreach ($bat in $battery) {
            Write-Host "Battery: $($bat.Name)"
            Write-Host "  Status: $($bat.Status)"
            Write-Host "  Charge Remaining: $($bat.EstimatedChargeRemaining)%"
            Write-Host "  Battery Status: $($bat.BatteryStatus)"
        }
    } else {
        Write-Host "No battery detected (Desktop system or no battery present)"
    }
} catch {
    Write-Host "Battery information not available"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    END OF REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan