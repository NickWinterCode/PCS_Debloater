#requires -Version 3.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [Parameter(Mandatory = $true)][string]$NewFilePath,
    [Parameter(Mandatory = $true)][string]$RelaunchPath,
    [int]$ParentProcessId
)

Set-StrictMode -Version Latest

function Wait-ProcessExit {
    param(
        [int]$ProcessId,
        [int]$TimeoutSeconds = 20
    )

    if (-not $ProcessId) { return }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            Get-Process -Id $ProcessId -ErrorAction Stop | Out-Null
            Start-Sleep -Milliseconds 300
        }
        catch {
            return
        }
    }
}

function Copy-BytesReplace {
    param(
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string]$To
    )

    $dir = Split-Path -Parent $To
    if (-not (Test-Path $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }

    $bytes = [System.IO.File]::ReadAllBytes($From)
    $tmp = "$To.tmp"
    [System.IO.File]::WriteAllBytes($tmp, $bytes)
    Move-Item -Path $tmp -Destination $To -Force
}

try {
    if ($ParentProcessId) {
        Wait-ProcessExit -ProcessId $ParentProcessId -TimeoutSeconds 25
    }

    Copy-BytesReplace -From $NewFilePath -To $TargetPath
}
catch {
    try { Start-Sleep -Seconds 1 } catch { }
    try { Copy-BytesReplace -From $NewFilePath -To $TargetPath } catch { }
}
finally {
    try { Remove-Item -Path $NewFilePath -Force -ErrorAction SilentlyContinue } catch { }
}

try {
    $relauchArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $RelaunchPath
    )
    Start-Process -FilePath 'powershell.exe' -ArgumentList $relauchArgs -WindowStyle Normal | Out-Null
}
catch { }
