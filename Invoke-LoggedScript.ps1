<#
.SYNOPSIS
    Runs a specified PowerShell or batch script and logs all its console output to a uniquely named file,
    while also displaying the output to the user in real-time.

.DESCRIPTION
    This script provides a wrapper function, Invoke-LoggedScript, to execute other scripts.
    It automatically creates a log file in a specified directory (or a default location).
    The log file is named using the target script's name, the current date, and time,
    ensuring that no logs are overwritten.

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

        if ($logRoot) {
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

            Write-Host "--------------------------------------------------------" -ForegroundColor Green
            Write-Host "Starting script:" -ForegroundColor Cyan " $ScriptPath"
            Write-Host "Output will be logged to:" -ForegroundColor Cyan " $logFullPath"
            Write-Host "You will see the live output below." -ForegroundColor Green
            Write-Host "--------------------------------------------------------"

            Start-Transcript -Path $logFullPath -Force
            try {
                # Check if the script is a batch file
                $scriptExtension = (Get-Item -Path $ScriptPath).Extension
                if ($scriptExtension -in @('.bat', '.cmd')) {
                    # For batch files, stream output live to host
                    Write-Host "Executing batch file: $ScriptPath" -ForegroundColor Cyan
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
                Write-Host "--------------------------------------------------------" -ForegroundColor Green
                Write-Host "Script execution finished."
                Write-Host "Log file complete:" -ForegroundColor Cyan " $logFullPath"
                Write-Host "--------------------------------------------------------"
            }
        } else {
            Write-Host "No _USBDATA folder found on any drive root. Logging is disabled for this session." -ForegroundColor Yellow
            Write-Host "Running script without logging..."
            & $ScriptPath @ArgumentList
            Write-Host "--------------------------------------------------------" -ForegroundColor Green
            Write-Host "Script execution finished (NO LOG FILE)."
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