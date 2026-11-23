[CmdletBinding()]
param([switch]$CheckOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-RegularPath {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Build output path is a reparse point: $Path"
    }
}

function Assert-GameClosed {
    param([string]$Exe)
    $processName = [IO.Path]::GetFileNameWithoutExtension($Exe)
    $running = Get-Process -Name $processName -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq $Exe }
    if ($running) {
        throw "Close the running game and retry to update $Exe"
    }
}

function Invoke-BuildProcess {
    param(
        [string]$File,
        [string[]]$ProcessArguments,
        [string]$WorkingDirectory,
        [string]$Log,
        [int]$TimeoutSeconds,
        [string]$ProfileDirectory = ''
    )
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $File
    # Every argument is a fixed flag or an absolute Windows path. No shell parses it.
    $info.Arguments = ($ProcessArguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    if ($ProfileDirectory) {
        $info.EnvironmentVariables['APPDATA'] = $ProfileDirectory
    }

    $process = [Diagnostics.Process]::Start($info)
    try {
        $standardOutput = $process.StandardOutput.ReadToEndAsync()
        $standardError = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            $process.Kill()
            if (-not $process.WaitForExit(5000)) {
                throw "Timed out waiting for $File to exit. See $Log."
            }
        }
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($standardOutput, $standardError), 5000)) {
            throw "The build process did not close its output streams. See $Log."
        }
        $output = $standardOutput.GetAwaiter().GetResult()
        $errors = $standardError.GetAwaiter().GetResult()
        Add-Content -LiteralPath $Log -Encoding UTF8 -Value @($output, $errors)
        if ($timedOut) {
            throw "Build step timed out after $TimeoutSeconds seconds. See $Log."
        }
        if ($process.ExitCode -ne 0) {
            throw "Build step exited with code $($process.ExitCode). See $Log."
        }
    } finally {
        $process.Dispose()
    }
}

function Publish-StagedFile {
    param([string]$Source, [string]$Destination)
    Assert-RegularPath $Destination
    if ([IO.File]::Exists($Destination)) {
        $backup = $Source + '.previous'
        $waits = @(500, 1000, 2000, 3500, 5000)
        for ($attempt = 0; $attempt -le $waits.Length; $attempt++) {
            try {
                [IO.File]::Replace($Source, $Destination, $backup)
                return
            } catch {
                if ([IO.File]::Exists($backup) -and -not [IO.File]::Exists($Destination)) {
                    [IO.File]::Move($backup, $Destination)
                    throw
                }
                # Startup verification can leave a scanner briefly holding the staged EXE.
                $windowsError = $_.Exception.GetBaseException().HResult -band 0xFFFF
                if ($windowsError -notin 32, 33 -or $attempt -eq $waits.Length -or
                    [IO.File]::Exists($backup) -or -not [IO.File]::Exists($Source) -or -not [IO.File]::Exists($Destination)) {
                    throw
                }
                Start-Sleep -Milliseconds $waits[$attempt]
            }
        }
    } else {
        [IO.File]::Move($Source, $Destination)
    }
}

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.FullName
$project = Join-Path $root 'prototype'
$editor = Join-Path $root '.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $editor -PathType Leaf)) {
    throw "Install the pinned Godot 4.7.2 Windows editor and matching export templates. Expected $editor"
}
$projectSettings = Get-Content -LiteralPath (Join-Path $project 'project.godot') -Raw
$startup = [regex]::Match($projectSettings, '(?m)^run/main_scene="res://([^"]+\.tscn)"\s*$')
if (-not $startup.Success) {
    throw 'The project must declare a res:// startup scene to verify the exported game.'
}
$sceneStem = [regex]::Escape([IO.Path]::GetFileNameWithoutExtension($startup.Groups[1].Value))
$commit = git -C $root rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Could not read the build source revision.' }
$projectChanges = @(git -C $root status --porcelain -- prototype)
if ($LASTEXITCODE -ne 0) { throw 'Could not read project worktree status.' }

$builds = Join-Path $root 'builds'
$local = Join-Path $builds 'local'
foreach ($directory in @($builds, $local)) {
    Assert-RegularPath $directory
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}
$outputExe = Join-Path $local 'Aamchi Mumbai Game.exe'
$lockPath = Join-Path $local '.windows-build.lock'
$log = Join-Path $local 'windows-build.log'
foreach ($output in @($outputExe, $lockPath, $log)) { Assert-RegularPath $output }
try {
    $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
} catch {
    throw "Could not acquire the Windows build lock. Ensure no other build is using $local."
}

$stage = Join-Path $local ('.stage-' + [guid]::NewGuid().ToString('N'))
$stagedExe = Join-Path $stage 'Aamchi Mumbai Game.exe'
try {
    if (-not $CheckOnly) { Assert-GameClosed $outputExe }
    [IO.Directory]::CreateDirectory($stage) | Out-Null
    $startupLog = Join-Path $stage 'startup.log'
    $testProfile = Join-Path $stage 'profile'
    [IO.Directory]::CreateDirectory($testProfile) | Out-Null
    Set-Content -LiteralPath $log -Encoding UTF8 -Value "Windows debug export from $commit"

    Write-Host 'Exporting a staged Windows build'
    Invoke-BuildProcess $editor @('--headless', '--path', $project, '--export-debug', 'Windows Desktop', $stagedExe) $root $log 180
    if (-not [IO.File]::Exists($stagedExe) -or [IO.File]::Exists([IO.Path]::ChangeExtension($stagedExe, 'pck'))) {
        throw "Expected one EXE with embedded game data. See $log."
    }

    Write-Host 'Checking startup with an isolated game profile'
    try {
        Invoke-BuildProcess $stagedExe @('--headless', '--verbose', '--quit-after', '120', '--log-file', $startupLog) $stage $log 45 $testProfile
    } finally {
        if ([IO.File]::Exists($startupLog)) {
            $startupOutput = [IO.File]::ReadAllText($startupLog)
            Add-Content -LiteralPath $log -Encoding UTF8 -Value $startupOutput
        } else {
            $startupOutput = ''
        }
    }
    if ($startupOutput -notmatch '(?m)^Godot Engine v4\.7\.2\.stable\b' -or
        $startupOutput -notmatch "(?m)^\s*Loading resource: .*[/\-]$sceneStem\.(?:tscn|scn)\b" -or
        $startupOutput -match '(?m)^\s*(?:SCRIPT )?ERROR:') {
        throw "The staged executable did not load the title scene cleanly. See $log."
    }

    $hash = (Get-FileHash -LiteralPath $stagedExe -Algorithm SHA256).Hash
    if ($CheckOnly) {
        Write-Host "Staged Windows build passed validation. SHA-256 $hash"
        return
    }

    $receipt = Join-Path $local 'windows-build.json'
    $stagedReceipt = Join-Path $stage 'windows-build.json'
    [ordered]@{
        artifact = [IO.Path]::GetFileName($outputExe)
        channel = 'local-dev'
        source_commit = $commit
        prototype_worktree_dirty = $projectChanges.Count -gt 0
        godot = '4.7.2 stable'
        created_utc = [DateTimeOffset]::UtcNow.ToString('o')
        sha256 = $hash
        startup_check = 'passed'
    } | ConvertTo-Json | Set-Content -LiteralPath $stagedReceipt -Encoding UTF8

    Assert-GameClosed $outputExe
    try {
        Publish-StagedFile $stagedExe $outputExe
    } catch {
        throw "Could not replace $outputExe. Close the game or other program holding the file, then retry. $($_.Exception.Message)"
    }
    try {
        Publish-StagedFile $stagedReceipt $receipt
    } catch {
        Write-Warning "The executable updated, but its build receipt could not be saved. SHA-256 $hash"
    }
    Write-Host "Windows development build ready at $outputExe"
    Write-Host "SHA-256 $hash"
} finally {
    try {
        $stageItem = Get-Item -LiteralPath $stage -ErrorAction SilentlyContinue
        if ($null -ne $stageItem -and $stageItem.Parent.FullName -eq $local -and
            -not ($stageItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            $recoveryCopy = $stagedExe + '.previous'
            if ([IO.File]::Exists($recoveryCopy) -and -not [IO.File]::Exists($outputExe)) {
                Write-Warning "The previous executable is available for recovery at $recoveryCopy"
            } else {
                Remove-Item -LiteralPath $stageItem.FullName -Recurse -Force
            }
        }
    } finally {
        $lock.Dispose()
    }
}
