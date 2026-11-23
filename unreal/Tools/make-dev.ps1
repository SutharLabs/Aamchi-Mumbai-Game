#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$EngineRoot,
    [switch]$RefreshMap
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-EngineRoot {
    param([string]$RequestedRoot)

    if ($RequestedRoot) { return (Get-Item -LiteralPath $RequestedRoot).FullName }
    if ($env:AMG_UE_INSTALL) { return (Get-Item -LiteralPath $env:AMG_UE_INSTALL).FullName }

    $manifestPath = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Epic\UnrealEngineLauncher\LauncherInstalled.dat'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        foreach ($installation in $manifest.InstallationList) {
            if ($installation.AppName -eq 'UE_5.8' -and
                (Test-Path -LiteralPath $installation.InstallLocation -PathType Container)) {
                return (Get-Item -LiteralPath $installation.InstallLocation).FullName
            }
        }
    }

    $programFiles = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
    $defaultRoot = Join-Path $programFiles 'Epic Games\UE_5.8'
    if (Test-Path -LiteralPath $defaultRoot -PathType Container) { return $defaultRoot }
    throw 'Unreal Engine 5.8 for Windows was not found. Install it in the Epic Games Launcher, then use -EngineRoot or set AMG_UE_INSTALL if needed.'
}

function Assert-PlainPath {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Cannot use the reparse point at $Path for build data."
    }
}

function Test-NonemptyFile {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    return ($item -is [IO.FileInfo] -and $item.Length -gt 0)
}

function Remove-BuildDirectory {
    param([string]$Path, [string]$ExpectedParent)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return }
    if ($item -isnot [IO.DirectoryInfo] -or $item.Parent.FullName -ne $ExpectedParent) {
        throw "Cannot clean $Path outside its expected parent directory."
    }
    Assert-PlainPath $item.FullName
    # Directory.Delete removes nested directory links without following their targets.
    [IO.Directory]::Delete($item.FullName, $true)
}

function Invoke-UnrealTool {
    param([string]$Tool, [string[]]$Arguments)

    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$([IO.Path]::GetFileName($Tool)) exited with code $LASTEXITCODE."
    }
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Run this packaging script on a Windows host.'
}

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$engine = Resolve-EngineRoot $EngineRoot
foreach ($path in @($root, $engine)) {
    # Epic's .bat files forward arguments through cmd.exe.
    if ($path -match '[%!"&^|<>\r\n]') {
        throw "Unreal batch tools cannot safely forward the path $path"
    }
}
$project = Join-Path $root 'unreal\AamchiMumbaiUnreal.uproject'
$versionPath = Join-Path $engine 'Engine\Build\Build.version'
$builder = Join-Path $engine 'Engine\Build\BatchFiles\Build.bat'
$runUat = Join-Path $engine 'Engine\Build\BatchFiles\RunUAT.bat'
$editor = Join-Path $engine 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
foreach ($path in @($project, $versionPath, $builder, $runUat, $editor)) {
    if (-not (Test-NonemptyFile $path)) { throw "Windows packaging requires the missing file $path" }
}
$version = Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json
$versionText = '{0}.{1}.{2}' -f $version.MajorVersion, $version.MinorVersion, $version.PatchVersion
if ($version.MajorVersion -ne 5 -or $version.MinorVersion -ne 8) {
    throw "Ranwar requires Unreal Engine 5.8.x. Found $versionText at $engine"
}
Write-Host "Using Unreal Engine $versionText at $engine"

$builds = Join-Path $root 'builds'
$local = Join-Path $builds 'local'
foreach ($directory in @($builds, $local)) {
    Assert-PlainPath $directory
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}
$attemptId = [guid]::NewGuid().ToString('N')
$output = Join-Path $local 'unreal-windows'
$previous = Join-Path $local '.unreal-windows.previous'
$incoming = Join-Path $local ".unreal-windows.incoming-$attemptId"
$lockPath = Join-Path $local '.unreal-windows.lock'
Assert-PlainPath $lockPath
$ranwarBackup = Join-Path $local "unreal-ranwar-before-refresh-$attemptId"
$ranwarChanged = $false
try {
    $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
} catch {
    throw "Could not lock $lockPath. Check whether another Unreal Windows build is running. $($_.Exception.Message)"
}

try {
    foreach ($directory in @($output, $previous)) { Assert-PlainPath $directory }
    if ([IO.Directory]::Exists($previous) -and -not [IO.Directory]::Exists($output)) {
        [IO.Directory]::Move($previous, $output)
        Write-Host "Restored the previous development build to $output"
    }

    $unrealProject = Join-Path $root 'unreal'
    $content = Join-Path $unrealProject 'Content'
    $ranwar = Join-Path $content 'Ranwar'
    foreach ($directory in @($unrealProject, $content, $ranwar)) { Assert-PlainPath $directory }
    $map = Join-Path $ranwar 'RanwarStreet.umap'
    $vehicleNames = @('Hatchback', 'Rickshaw', 'Motorcycle', 'Scooter')
    $arrivalNames = @('BestBus', 'Anjali', 'Pedestrian')
    if ($RefreshMap -or -not (Test-NonemptyFile $map)) {
        $exchange = Join-Path $local 'unreal-ranwar'
        $exchangeFiles = @('ranwar-level.json', 'omkar.glb') + @(
            $vehicleNames | ForEach-Object { "vehicles\$_.glb" }
        ) + @(
            $arrivalNames | ForEach-Object { "arrival\$_.glb" }
        )
        foreach ($exchangeFile in $exchangeFiles) {
            if (-not (Test-NonemptyFile (Join-Path $exchange $exchangeFile))) {
                throw "Missing $exchangeFile in $exchange. Build or collect the Ranwar exchange documented in unreal/ContentSource/RANWAR_STREET.md."
            }
        }

        Write-Host 'Building the Unreal editor module for the initial Ranwar import'
        Invoke-UnrealTool $builder @('AamchiMumbaiUnrealEditor', 'Win64', 'Development', "-Project=$project", '-WaitMutex')

        Write-Host 'Importing the Ranwar map, Omkar, arrival scene, and vehicles'
        $importer = Join-Path $PSScriptRoot 'create_ranwar_level.py'
        $importLog = Join-Path $local 'unreal-ranwar-import.log'
        Assert-PlainPath $importLog
        if ([IO.File]::Exists($importLog)) { Remove-Item -LiteralPath $importLog }
        if ([IO.Directory]::Exists($ranwar)) {
            $generated = Get-Item -LiteralPath $ranwar -Force
            if ($generated.FullName -ne $ranwar -or $generated.Parent.FullName -ne $content) {
                throw "Cannot back up Ranwar content outside the expected project path $ranwar"
            }
            [IO.Directory]::Move($ranwar, $ranwarBackup)
        }
        $ranwarChanged = $true
        Invoke-UnrealTool $editor @($project, '-run=pythonscript', "-script=$importer",
            '-unattended', '-nosound', '-NoP4', '-NullRHI', '-stdout', '-FullStdOutLogOutput', "-abslog=$importLog")
        if (-not (Test-NonemptyFile $map) -or -not (Test-NonemptyFile $importLog) -or
            -not (Select-String -LiteralPath $importLog -Pattern 'Saved /Game/Ranwar/RanwarStreet with' -SimpleMatch -Quiet)) {
            throw "The Ranwar importer did not finish saving the map. See $importLog"
        }
    }

    $gameplayAssets = @(
        @('Omkar', 'OmkarIdle', 'OmkarWalk', 'OmkarRun') |
            ForEach-Object { "Characters\Omkar\$_.uasset" }
    ) + @(
        $vehicleNames | ForEach-Object { "Vehicles\$_.uasset" }
    ) + @(
        $arrivalNames | ForEach-Object { "Arrival\$_.uasset" }
    )
    foreach ($relativeAsset in $gameplayAssets) {
        if (-not (Test-NonemptyFile (Join-Path $ranwar $relativeAsset))) {
            throw "Ranwar is missing $relativeAsset. Run again with -RefreshMap after generating the latest exchange."
        }
    }

    [IO.Directory]::CreateDirectory($incoming) | Out-Null
    Write-Host 'Building, cooking, and staging a Win64 Development package'
    Invoke-UnrealTool $runUat @('BuildCookRun', "-project=$project", '-platform=Win64',
        '-clientconfig=Development', '-build', '-cook', '-map=/Game/Ranwar/RanwarStreet',
        '-stage', '-pak', '-package', '-prereqs', '-archive', "-archivedirectory=$incoming",
        '-unattended', '-nop4', '-utf8output')

    $staged = Join-Path $incoming 'Windows'
    $launchExe = 'AamchiMumbaiUnreal.exe'
    $nativeExe = Join-Path $staged 'AamchiMumbaiUnreal\Binaries\Win64\AamchiMumbaiUnreal.exe'
    $paks = Join-Path $staged 'AamchiMumbaiUnreal\Content\Paks'
    if (-not (Test-NonemptyFile (Join-Path $staged $launchExe)) -or
        -not (Test-NonemptyFile $nativeExe) -or
        -not (Get-ChildItem -LiteralPath $paks -Filter '*.pak' -File -ErrorAction SilentlyContinue |
            Where-Object Length -gt 0 | Select-Object -First 1)) {
        throw "The staged package at $staged is missing its executable or cooked content."
    }

    $notices = Join-Path $staged 'Notices'
    [IO.Directory]::CreateDirectory($notices) | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $notices 'LICENSE')
    Copy-Item -LiteralPath (Join-Path $root 'docs\THIRD_PARTY.md') -Destination (Join-Path $notices 'THIRD_PARTY.md')
    $mapNotice = 'assets\maps\reference\bandra-ranwar-modern-osm-2026-11-20\ATTRIBUTION.md'
    Copy-Item -LiteralPath (Join-Path $root $mapNotice) -Destination (Join-Path $notices 'OpenStreetMap.md')

    $runningGame = Get-Process -Name 'AamchiMumbaiUnreal*' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith("$output\", [StringComparison]::OrdinalIgnoreCase) } |
        Select-Object -First 1
    if ($runningGame) { throw "Close the running development build before replacing $output" }

    Remove-BuildDirectory $previous $local
    if ([IO.Directory]::Exists($output)) {
        [IO.Directory]::Move($output, $previous)
    }
    try {
        [IO.Directory]::Move($incoming, $output)
    } catch {
        if ([IO.Directory]::Exists($previous) -and -not [IO.Directory]::Exists($output)) {
            [IO.Directory]::Move($previous, $output)
        }
        throw
    }
    $ranwarChanged = $false
    try {
        Remove-BuildDirectory $previous $local
    } catch {
        Write-Warning "The new package is ready. The previous build remains at $previous. $($_.Exception.Message)"
    }
    Write-Host "Windows development build ready at $(Join-Path $output "Windows\$launchExe")"
    if ([IO.Directory]::Exists($ranwarBackup)) {
        Write-Host "Previous generated Ranwar content was saved at $ranwarBackup"
    }
} catch {
    if ($ranwarChanged) {
        try {
            if ([IO.Directory]::Exists($ranwar)) {
                Assert-PlainPath $ranwar
                $failedRanwar = Join-Path $local "unreal-ranwar-failed-import-$attemptId"
                [IO.Directory]::Move($ranwar, $failedRanwar)
                Write-Warning "Preserved the failed Ranwar import at $failedRanwar"
            }
            if ([IO.Directory]::Exists($ranwarBackup)) {
                [IO.Directory]::Move($ranwarBackup, $ranwar)
                Write-Warning "Restored the previous Ranwar content to $ranwar"
            }
        } catch {
            Write-Warning "Could not restore the earlier Ranwar content. Check $ranwar and $ranwarBackup. $($_.Exception.Message)"
        }
    }
    throw
} finally {
    try {
        Remove-BuildDirectory $incoming $local
    } catch {
        Write-Warning "Could not clean the staging directory at $incoming. $($_.Exception.Message)"
    } finally {
        $lock.Dispose()
    }
}
