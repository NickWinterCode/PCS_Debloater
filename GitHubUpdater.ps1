#requires -Version 3.0

Set-StrictMode -Version Latest

function Test-InternetAvailable {
    param(
        [string]$HostName = 'raw.githubusercontent.com',
        [int]$Port = 443,
        [int]$TimeoutMs = 2000
    )

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            $client.Close()
            return $false
        }
        $client.EndConnect($iar)
        $client.Close()
        return $true
    }
    catch {
        return $false
    }
}

function New-HttpClient {
    param(
        [int]$TimeoutSeconds = 20
    )

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate

    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $null = $client.DefaultRequestHeaders.UserAgent.ParseAdd('PCS-Debloater-Updater')
    return $client
}

function Get-HttpBytes {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 20
    )

    $client = $null
    try {
        $client = New-HttpClient -TimeoutSeconds $TimeoutSeconds
        $task = $client.GetByteArrayAsync($Url)
        return $task.GetAwaiter().GetResult()
    }
    finally {
        if ($client) { $client.Dispose() }
    }
}

function Get-HttpStringUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 20
    )

    $bytes = Get-HttpBytes -Url $Url -TimeoutSeconds $TimeoutSeconds
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Test-SafeRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }

    $p = $Path.Replace('\\', '/').Replace('\', '/')

    if ($p.StartsWith('/')) { return $false }
    if ($p -match '^[a-zA-Z]:') { return $false }
    if ($p -match '(^|/)\.\.(?=/|$)') { return $false }

    return $true
}

function Write-FileBytesAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    $dir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }

    $tmp = "$TargetPath.tmp"
    [System.IO.File]::WriteAllBytes($tmp, $Bytes)
    try {
        Move-Item -Path $tmp -Destination $TargetPath -Force
    }
    catch {
        try { Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue } catch { }
        throw
    }
}

function Invoke-GitHubAutoUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoOwner,
        [Parameter(Mandatory = $true)][string]$RepoName,
        [Parameter(Mandatory = $true)][string]$Branch,
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$EntryScriptRelativePath,
        [switch]$Quiet
    )

    $ErrorActionPreference = 'Stop'

    if (-not (Test-InternetAvailable)) {
        if (-not $Quiet) { Write-Host "[UPDATE] Offline - skipping update check" -ForegroundColor DarkGray }
        return
    }

    $manifestUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$ManifestPath"

    $manifestText = $null
    try {
        if (-not $Quiet) { Write-Host "[UPDATE] Checking for updates..." -ForegroundColor DarkGray }
        $manifestText = Get-HttpStringUtf8 -Url $manifestUrl -TimeoutSeconds 20
    }
    catch {
        if (-not $Quiet) { Write-Host "[UPDATE] Could not fetch manifest - skipping" -ForegroundColor DarkGray }
        return
    }

    $manifest = $null
    try {
        $manifest = $manifestText | ConvertFrom-Json
    }
    catch {
        if (-not $Quiet) { Write-Host "[UPDATE] Manifest JSON invalid - skipping" -ForegroundColor DarkGray }
        return
    }

    if ($null -eq $manifest.files) {
        if (-not $Quiet) { Write-Host "[UPDATE] Manifest missing 'files' - skipping" -ForegroundColor DarkGray }
        return
    }

    $entryScript = $null
    if (-not [string]::IsNullOrWhiteSpace($EntryScriptRelativePath)) {
        $entryScript = $EntryScriptRelativePath.Replace('\\', '/').Replace('\', '/')
    }

    $pendingSelfUpdate = $false
    $selfUpdateRepoPath = $null
    $selfUpdateTempFile = $null

    $updatedAny = $false
    $updatedList = New-Object System.Collections.Generic.List[string]

    foreach ($entry in $manifest.files.PSObject.Properties) {
        $repoRelPath = [string]$entry.Name
        $expectedHash = ([string]$entry.Value).ToLowerInvariant()

        if (-not (Test-SafeRelativePath -Path $repoRelPath)) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($expectedHash)) {
            continue
        }

        $localRel = $repoRelPath.Replace('/', '\')
        $localFull = Join-Path $ProjectRoot $localRel

        $localHash = $null
        if (Test-Path $localFull) {
            try {
                $localHash = (Get-FileHash -Path $localFull -Algorithm SHA256).Hash.ToLowerInvariant()
            }
            catch {
                $localHash = $null
            }
        }

        $needsUpdate = ($null -eq $localHash -or $localHash -ne $expectedHash)
        if (-not $needsUpdate) {
            continue
        }

        $fileUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$repoRelPath"

        try {
            $bytes = Get-HttpBytes -Url $fileUrl -TimeoutSeconds 30
        }
        catch {
            continue
        }

        $isSelf = $false
        if ($entryScript -and ($repoRelPath.Replace('\\', '/').Replace('\', '/') -ieq $entryScript)) { $isSelf = $true }

        if ($isSelf) {
            $pendingSelfUpdate = $true
            $selfUpdateRepoPath = $repoRelPath
            $selfUpdateTempFile = Join-Path $env:TEMP ("pcs_selfupdate_" + [System.Guid]::NewGuid().ToString('N') + ".tmp")
            [System.IO.File]::WriteAllBytes($selfUpdateTempFile, $bytes)
            continue
        }

        try {
            Write-FileBytesAtomic -TargetPath $localFull -Bytes $bytes
            $updatedAny = $true
            $updatedList.Add($repoRelPath) | Out-Null
        }
        catch {
            continue
        }
    }

    if ($updatedAny -and -not $Quiet) {
        Write-Host "[UPDATE] Updated files:" -ForegroundColor DarkGray
        foreach ($p in $updatedList) {
            Write-Host "[UPDATE]  - $p" -ForegroundColor DarkGray
        }
    }

    if ($pendingSelfUpdate -and $selfUpdateTempFile -and (Test-Path $selfUpdateTempFile)) {
        $helper = Join-Path $ProjectRoot 'UpdateHelper.ps1'
        if (Test-Path $helper) {
            if (-not $Quiet) { Write-Host "[UPDATE] Updating entry script and relaunching..." -ForegroundColor DarkGray }
            $startArgs = @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', $helper,
                '-TargetPath', (Join-Path $ProjectRoot $selfUpdateRepoPath.Replace('/', '\')),
                '-NewFilePath', $selfUpdateTempFile,
                '-RelaunchPath', (Join-Path $ProjectRoot $selfUpdateRepoPath.Replace('/', '\')),
                '-ParentProcessId', $PID
            )

            Start-Process -FilePath 'powershell.exe' -ArgumentList $startArgs -WindowStyle Normal | Out-Null
            exit
        }
    }
}
