<#
.SYNOPSIS
    Runs a specified PowerShell or batch script and logs all its console output to a uniquely named file,
    while also displaying the output to the user in real-time.

.DESCRIPTION
    This script provides a wrapper function, Invoke-LoggedScript, to execute other scripts.
    It automatically creates a log file in a specified directory (or a default location).
    The log file is named using the target script's name, the current date, and time,
    ensuring that no logs are overwritten.

    Log Location Priority:
    1. _USBDATA\LOGs\ComputerName (if _USBDATA folder found on any drive)
    2. LocalAppData\ScriptLogs\HardwareID (fallback)

    The user sees all output in the console as the script runs, and a complete transcript
    is saved for later review.

.PARAMETER ScriptPath
    The full or relative path to the PowerShell (.ps1) or batch (.bat, .cmd) file you want to run and log.

.PARAMETER ArgumentList
    Any arguments you want to pass to the target script. These are passed directly to the script being called.

.PARAMETER LogDirectory
    The directory where the log file will be created.
    If not specified, it defaults to a 'ScriptLogs' subfolder in your Documents folder.

.EXAMPLE
    # Run a simple PowerShell script with no arguments
    .\Invoke-LoggedScript.ps1 -ScriptPath "C:\Scripts\MyTestScript.ps1"

.EXAMPLE
    # Run a PowerShell script that takes arguments
    .\Invoke-LoggedScript.ps1 -ScriptPath ".\ScriptWithParams.ps1" -Name "World" -Count 3

.EXAMPLE
    # Run a batch file
    .\Invoke-LoggedScript.ps1 -ScriptPath ".\LegacyTask.bat"

.EXAMPLE
    # Run a script and save the log to a custom location
    .\Invoke-LoggedScript.ps1 -ScriptPath ".\MyTestScript.ps1" -LogDirectory "C:\Temp\Logs"
#>

function Get-HardwareID {
    <#
    .SYNOPSIS
        Generates a persistent hardware ID based on system components.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $hardwareComponents = @()
        
        # CPU ID
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu.ProcessorId) { $hardwareComponents += $cpu.ProcessorId }
        
        # Motherboard Serial
        $board = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($board.SerialNumber) { $hardwareComponents += $board.SerialNumber }
        
        # BIOS Serial
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($bios.SerialNumber) { $hardwareComponents += $bios.SerialNumber }
        
        # UUID from Computer System Product
        $uuid = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($uuid.UUID -and $uuid.UUID -ne "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF") { 
            $hardwareComponents += $uuid.UUID 
        }
        
        # First Physical Disk Serial
        $disk = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($disk.SerialNumber) { $hardwareComponents += $disk.SerialNumber.Trim() }
        
        # Combine all hardware info
        $combinedInfo = ($hardwareComponents | Where-Object { $_ }) -join "|"
        
        if ([string]::IsNullOrEmpty($combinedInfo)) {
            throw "No hardware information could be gathered"
        }
        
        # Create SHA256 hash
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combinedInfo))
        $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "")
        
        # Format as XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX (first 32 chars)
        $formatted = ($hashString.Substring(0, 32) -replace '(.{4})', '$1-').TrimEnd('-')
        
        return $formatted
    }
    catch {
        Write-Warning "Failed to generate hardware ID: $_"
        # Return computer name as fallback
        return $env:COMPUTERNAME
    }
}

function Invoke-LoggedScript {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to the script to execute.")]
        [ValidateScript({
            if (Test-Path $_ -PathType Leaf) {
                return $true
            } else {
                throw "File not found at path: $_"
            }
        })]
        [string]$ScriptPath,

        [Parameter(ValueFromRemainingArguments=$true)]
        [object[]]$ArgumentList,

        [string]$LogDirectory = (Join-Path -Path ([System.Environment]::GetFolderPath('MyDocuments')) -ChildPath 'ScriptLogs')
    )

    # --- 1. Prepare Log File Name and Path ---
    try {
        # --- Custom log folder logic: Search for _USBDATA root folder on all drives ---
        $logRoot = $null
        $hwid = $null
        $computerName = $env:COMPUTERNAME
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Free }
        
        foreach ($drive in $drives) {
            $usbdataPath = Join-Path $drive.Root "_USBDATA"
            if (Test-Path $usbdataPath -PathType Container) {
                $logRoot = Join-Path $usbdataPath "LOGs"
                $LogDirectory = Join-Path $logRoot $computerName
                break
            }
        }

        # --- If _USBDATA not found, use LocalAppData folder with Hardware ID ---
        if (-not $logRoot) {
            Write-Verbose "_USBDATA folder not found. Using LocalAppData folder with Hardware ID."
            $hwid = Get-HardwareID
            $localAppData = [System.Environment]::GetFolderPath('LocalApplicationData')
            $LogDirectory = Join-Path $localAppData "$hwid"
            Write-Host "Logging to: $LogDirectory" -ForegroundColor Yellow
        }

        # Ensure the log directory exists
        if (-not (Test-Path -Path $LogDirectory -PathType Container)) {
            Write-Verbose "Log directory not found. Creating it at: $LogDirectory"
            New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        }

        # Get the base name of the script (e.g., "MyScript" from "MyScript.ps1")
        $scriptBaseName = (Get-Item -Path $ScriptPath).BaseName
        $timestamp = Get-Date -Format 'yyyy.MM.dd_HH-mm-ss'
        $logFileName = "$($scriptBaseName)_$($timestamp)_LOG.txt"
        $logFullPath = Join-Path -Path $LogDirectory -ChildPath $logFileName

        Start-Transcript -Path $logFullPath -Force

        try {
            # Check if the script is a batch file
            $scriptExtension = (Get-Item -Path $ScriptPath).Extension
            if ($scriptExtension -in @('.bat', '.cmd')) {
                & cmd.exe /c "call `"$ScriptPath`" $ArgumentList 2>&1" | ForEach-Object {
                    Write-Host $_
                }
            } else {
                # For PowerShell scripts, call directly
                & $ScriptPath @ArgumentList
            }
        }
        finally {
            Stop-Transcript
            Write-Host "--------------------------------------------------------"
            Write-Host "Log saved to: $logFullPath" -ForegroundColor Green
            Write-Host "--------------------------------------------------------"
        }
    }
    catch {
        # Catch any errors from setting up the log file itself
        Write-Error "An error occurred during the logging setup: $($_.Exception.Message)"
    }
}

# This makes the script file directly executable and passes arguments to the function.
# You can call it like: .\Invoke-LoggedScript.ps1 C:\Path\To\YourScript.ps1 -Arg1 "Value"
#Invoke-LoggedScript @PSBoundParameters # Only needed when run standalone