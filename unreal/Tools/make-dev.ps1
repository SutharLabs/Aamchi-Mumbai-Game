#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$EngineRoot,
    [switch]$RefreshMap,
    [switch]$FullCook,
    [switch]$SmokeTest,
    [switch]$Plan,
    [ValidatePattern('\A[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9]+(?:[.-][a-zA-Z0-9]+)*)?\z')]
    [ValidateLength(5, 50)]
    [string]$ReleaseVersion
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

function Restore-GeneratedAndroidDefaults {
    param([string]$Path, [byte[]]$Before)

    Assert-PlainPath $Path
    $heading = '[/Script/AndroidFileServerEditor.AndroidFileServerRuntimeSettings]'
    $beforeText = [Text.Encoding]::UTF8.GetString($Before).TrimStart([char]0xFEFF)
    if ($beforeText.Contains($heading)) { return }
    $afterText = [IO.File]::ReadAllText($Path)
    $index = $afterText.IndexOf($heading, [StringComparison]::Ordinal)
    if ($index -lt 0 -or $afterText.Substring(0, $index).TrimEnd() -cne $beforeText.TrimEnd()) { return }
    $expectedDefaults = @(
        'bEnablePlugin=True', 'bAllowNetworkConnection=True', 'bIncludeInShipping=False',
        'bAllowExternalStartInShipping=False', 'bCompileAFSProject=False', 'bUseCompression=False',
        'bLogFiles=False', 'bReportStats=False', 'ConnectionType=USBOnly',
        'bUseManualIPAddress=False', 'ManualIPAddress='
    )
    $settings = @($afterText.Substring($index + $heading.Length) -split '\r?\n' | Where-Object { $_ })
    $generatedToken = @($settings | Where-Object { $_ -match '^SecurityToken=[0-9a-f]{32}$' })
    if ($settings.Count -ne $expectedDefaults.Count + 1 -or $generatedToken.Count -ne 1) { return }
    foreach ($expected in $expectedDefaults) {
        if ($expected -cnotin $settings) { return }
    }
    [IO.File]::WriteAllBytes($Path, $Before)
}

function Test-NonemptyFile {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    return ($item -is [IO.FileInfo] -and $item.Length -gt 0)
}

function Get-Sha256FileDigest {
    param([string]$Path)

    $digest = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($Path)
        try {
            return [BitConverter]::ToString($digest.ComputeHash($stream)).Replace('-', '')
        } finally {
            $stream.Dispose()
        }
    } finally {
        $digest.Dispose()
    }
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

function Assert-GameClosed {
    param([string]$Package)

    $runningGame = Get-Process -Name 'AamchiMumbaiUnreal*' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith("$Package\", [StringComparison]::OrdinalIgnoreCase) } |
        Select-Object -First 1
    if ($runningGame) { throw "Close the running development build before replacing $Package" }
}

function Get-ProfileItem {
    param([string]$Path, [switch]$Directory)

    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    } catch [System.Management.Automation.ItemNotFoundException] {
        return $null
    }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
        ($item -is [IO.DirectoryInfo]) -ne $Directory.IsPresent) {
        throw "Unexpected item at the packaged player profile path $Path"
    }
    return $item
}

function Copy-DevelopmentProfile {
    param([string]$PriorWindows, [string]$StagedWindows)

    $saved = 'AamchiMumbaiUnreal\Saved'
    $saves = "$saved\SaveGames"
    $preferences = "$saved\Config\Windows\GameUserSettings.ini"
    # Check each ancestor before reading or writing paths below it.
    foreach ($relativeDirectory in @('', 'AamchiMumbaiUnreal', $saved, $saves, "$saved\Config", "$saved\Config\Windows")) {
        foreach ($package in @($PriorWindows, $StagedWindows)) {
            $profileDirectory = if ($relativeDirectory) { Join-Path $package $relativeDirectory } else { $package }
            $null = Get-ProfileItem $profileDirectory -Directory
        }
    }

    $files = @($preferences)
    $saveDirectory = Join-Path $PriorWindows $saves
    if (Get-ProfileItem $saveDirectory -Directory) {
        $files += Get-ChildItem -LiteralPath $saveDirectory -File -Filter '*.sav' -Force -ErrorAction Stop |
            ForEach-Object { Join-Path $saves $_.Name }
    }
    foreach ($relativeFile in $files) {
        $source = Get-ProfileItem (Join-Path $PriorWindows $relativeFile)
        if ($null -eq $source) { continue }
        $destination = Join-Path $StagedWindows $relativeFile
        if (Get-ProfileItem $destination) { [IO.File]::Delete($destination) }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        [IO.File]::Copy($source.FullName, $destination)
    }
}

function Move-WindowsPayload {
    param([string]$Source, [string]$Destination)

    for ($attempt = 0; $attempt -lt 8; $attempt++) {
        try {
            [IO.Directory]::Move($Source, $Destination)
            return
        } catch {
            if ($attempt -eq 7 -or -not [IO.Directory]::Exists($Source) -or [IO.Directory]::Exists($Destination)) {
                throw
            }
            # Windows indexing or process teardown can retain a short-lived handle.
            Start-Sleep -Milliseconds (250 * ($attempt + 1))
        }
    }
}

function Invoke-StagedSmokeTest {
    param([string]$Executable, [string]$UserDir, [string]$Log)

    [IO.Directory]::CreateDirectory($UserDir) | Out-Null
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable
    $info.WorkingDirectory = $UserDir
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.Arguments = '-unattended -NullRHI -nosound -NoSplash -RanwarLedgerSmoke -UserDir="' + $UserDir + '" -abslog="' + $Log + '" ' +
        '-ExecCmds="Automation RunTests AamchiMumbai.Ranwar.Playable" -TestExit="Automation Test Queue Empty"'
    $process = [Diagnostics.Process]::Start($info)
    try {
        if (-not $process.WaitForExit(90000)) {
            $process.Kill()
            if (-not $process.WaitForExit(5000)) { throw "Timed out closing the staged test process. See $Log" }
            throw "The staged gameplay test timed out. See $Log"
        }
        $passMarker = 'Result={Success} Name={Playable} Path={AamchiMumbai.Ranwar.Playable}'
        if ($process.ExitCode -ne 0 -or -not (Test-NonemptyFile $Log) -or
            -not (Select-String -LiteralPath $Log -Pattern $passMarker -SimpleMatch -Quiet)) {
            throw "The staged gameplay test failed. See $Log"
        }
    } finally {
        $process.Dispose()
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
$work = Join-Path $local 'unreal-work'
$logs = Join-Path $work 'logs'
$uatLogs = Join-Path $logs 'uat'
$incoming = Join-Path $work 'staging'
$previous = Join-Path $work 'previous-windows'
$legacyWorkPrevious = Join-Path $work 'previous-package'
$legacyPrevious = Join-Path $local '.unreal-windows.previous'
$ranwarBackup = Join-Path $work 'previous-ranwar'
$smokeProfile = Join-Path $work 'smoke-profile'
$configuration = 'Development'
$outputParent = $local
$releaseRoot = Join-Path $builds 'release'
if ($ReleaseVersion) {
    if ($SmokeTest) { throw 'The packaged automation suite is available only in Development builds.' }
    $configuration = 'Shipping'
    $outputParent = Join-Path $releaseRoot $ReleaseVersion
}
$output = Join-Path $outputParent 'unreal-windows'
$lockPath = Join-Path $local '.unreal-windows.lock'
$unrealProject = Join-Path $root 'unreal'
$content = Join-Path $unrealProject 'Content'
$ranwar = Join-Path $content 'Ranwar'
$exchange = Join-Path $local 'unreal-ranwar'
$launchExe = 'AamchiMumbaiUnreal.exe'
$vehicleNames = @('Hatchback', 'Rickshaw', 'Motorcycle', 'Scooter')
$arrivalNames = @('BestBus', 'AnjaliKurta', 'Pedestrian', 'Farah', 'Nitin', 'Leena', 'Iqbal', 'Ravi', 'Kavita')
$contactNames = @('Ravi', 'Kavita')
$generatedAssets = @('RanwarStreet.umap', 'UI\TitleBackdrop.uasset', 'UI\TitleMark.uasset') + @(
    @('Omkar', 'OmkarIdle', 'OmkarWalk', 'OmkarRun') | ForEach-Object { "Characters\Omkar\$_.uasset" }
) + @($vehicleNames | ForEach-Object { "Vehicles\$_.uasset" }) + @(
    $arrivalNames | ForEach-Object { "Arrival\$_.uasset" }
) + @(
    $contactNames | ForEach-Object {
        $contact = $_
        @($contact, "${contact}Breath", "${contact}Gesture") | ForEach-Object { "Characters\Contacts\$contact\$_.uasset" }
    }
)
$exchangeFiles = @('ranwar-level.json', 'omkar.glb') + @(
    $vehicleNames | ForEach-Object { "vehicles\$_.glb" }
) + @($arrivalNames | ForEach-Object { "arrival\$_.glb" }) + @($contactNames | ForEach-Object { "contacts\$_.glb" })

foreach ($path in @($builds, $local, $work, $logs, $uatLogs, $lockPath, $incoming, $previous, $legacyWorkPrevious, $legacyPrevious,
        $ranwarBackup, $smokeProfile, $output, $unrealProject, $content, $ranwar)) {
    Assert-PlainPath $path
}
if ($ReleaseVersion) {
    Assert-PlainPath $releaseRoot
    Assert-PlainPath $outputParent
    if (Test-Path -LiteralPath $output) { throw "That release already has a Windows package at $output" }
}
$commit = git -C $root rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Could not read the source revision.' }
$changes = if ($ReleaseVersion) { @(git -C $root status --porcelain) } else { @(git -C $root status --porcelain -- unreal) }
if ($LASTEXITCODE -ne 0) { throw 'Could not read the Git worktree status.' }
if ($ReleaseVersion -and $null -ne $changes) {
    throw 'Build a Shipping candidate from a clean, reviewed commit.'
}

$assetRoot = if ([IO.Directory]::Exists($ranwarBackup)) { $ranwarBackup } else { $ranwar }
$missingAssets = @($generatedAssets | Where-Object { -not (Test-NonemptyFile (Join-Path $assetRoot $_)) })
$needsImport = $RefreshMap -or $missingAssets.Count -gt 0
if ($needsImport) {
    foreach ($exchangeFile in $exchangeFiles) {
        if (-not (Test-NonemptyFile (Join-Path $exchange $exchangeFile))) {
            throw "Missing $exchangeFile in $exchange. Build or collect the Ranwar exchange documented in unreal/ContentSource/RANWAR_STREET.md."
        }
    }
}
$audio = Join-Path $content 'Audio\Ranwar'
$sharedAudio = Join-Path $root 'prototype\shared\audio'
$worldSoundNames = @('parcel-pickup.wav')
foreach ($gait in @('walk', 'run')) {
    foreach ($variant in (1..3)) { $worldSoundNames += "sandal-$gait-$variant.wav" }
}
foreach ($path in @($sharedAudio, (Join-Path $sharedAudio 'SOURCES.md'))) { Assert-PlainPath $path }
foreach ($name in $worldSoundNames) {
    $soundFile = Join-Path $sharedAudio $name
    Assert-PlainPath $soundFile
    if (-not (Test-NonemptyFile $soundFile)) { throw "Missing shared world sound at $soundFile" }
}
$dialogue = Join-Path $root 'prototype\shared\dialogue'
$dialogueCatalog = Join-Path $dialogue 'lines.json'
$dialogueNotice = Join-Path $dialogue 'SOURCES.md'
foreach ($path in @($dialogue, $dialogueCatalog, $dialogueNotice)) { Assert-PlainPath $path }
$dialogueRows = Get-Content -LiteralPath $dialogueCatalog -Raw -Encoding UTF8 | ConvertFrom-Json
if ($dialogueRows -isnot [array] -or $dialogueRows.Count -eq 0) {
    throw "Expected a non-empty array in the shared dialogue catalogue at $dialogueCatalog"
}
$dialogueFiles = @($dialogueCatalog)
$dialogueIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($line in $dialogueRows) {
    if ($line.id -cnotmatch '^[a-z]+(-[a-z]+)+$' -or $line.duration -lt 0.5 -or $line.duration -gt 30 -or
        [string]::IsNullOrWhiteSpace($line.speaker) -or [string]::IsNullOrWhiteSpace($line.text) -or
        -not $dialogueIds.Add($line.id)) {
        throw "Invalid or duplicate dialogue entry in $dialogueCatalog"
    }
    $lineFile = Join-Path $dialogue "$($line.id).wav"
    Assert-PlainPath $lineFile
    if (-not (Test-NonemptyFile $lineFile)) { throw "Missing shared dialogue WAV at $lineFile" }
    $dialogueFiles += $lineFile
}
Assert-PlainPath (Join-Path $content 'Audio')
Assert-PlainPath $audio
foreach ($family in $vehicleNames) {
    foreach ($state in @('idle','loaded')) {
        $sample = Join-Path $audio ('{0}-{1}.wav' -f $family.ToLowerInvariant(), $state)
        Assert-PlainPath $sample
        if (-not (Test-NonemptyFile $sample)) { throw "Missing recorded vehicle audio at $sample" }
    }
}
$incremental = -not ($ReleaseVersion -or $FullCook -or $needsImport)
if ($Plan) {
    Write-Host "Configuration: $configuration"
    Write-Host "Source revision: $commit"
    Write-Host "Regenerate Ranwar: $needsImport"
    Write-Host "Incremental cook: $incremental"
    Write-Host "Packaged gameplay test: $($SmokeTest.IsPresent)"
    Write-Host "Launch path: $(Join-Path $output "Windows\$launchExe")"
    Write-Host "Build work and logs: $work"
    return
}

foreach ($directory in @($builds, $local, $work, $logs)) {
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}
try {
    $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
} catch {
    throw "Could not lock $lockPath. Check whether another Unreal Windows build is running. $($_.Exception.Message)"
}

$ranwarChanged = $false
$keepVerifiedStaging = $false
$engineConfigPath = Join-Path $unrealProject 'Config\DefaultEngine.ini'
$engineConfigBefore = $null
$oldUatLogs = $env:uebp_LogFolder
$oldUatFinalLogs = $env:uebp_FinalLogFolder
try {
    Assert-PlainPath (Join-Path $unrealProject 'Config')
    Assert-PlainPath $engineConfigPath
    $engineConfigBefore = [IO.File]::ReadAllBytes($engineConfigPath)
    $developmentOutput = Join-Path $local 'unreal-windows'
    Assert-PlainPath $developmentOutput
    foreach ($recovery in @($legacyWorkPrevious, $legacyPrevious)) {
        if ([IO.Directory]::Exists($recovery) -and -not [IO.Directory]::Exists($developmentOutput)) {
            [IO.Directory]::Move($recovery, $developmentOutput)
            Write-Host "Restored the previous development build to $developmentOutput"
        }
    }
    $developmentWindows = Join-Path $developmentOutput 'Windows'
    Assert-PlainPath $developmentWindows
    if ([IO.Directory]::Exists($previous) -and -not [IO.Directory]::Exists($developmentWindows)) {
        [IO.Directory]::CreateDirectory($developmentOutput) | Out-Null
        [IO.Directory]::Move($previous, $developmentWindows)
        Write-Host "Restored the previous development payload to $developmentWindows"
    }
    if ($ReleaseVersion) {
        if (Test-Path -LiteralPath $output) { throw "That release already has a Windows package at $output" }
        [IO.Directory]::CreateDirectory($outputParent) | Out-Null
    } else {
        Assert-GameClosed $output
    }
    if ([IO.Directory]::Exists($ranwarBackup)) {
        Remove-BuildDirectory $ranwar $content
        [IO.Directory]::Move($ranwarBackup, $ranwar)
        Write-Host 'Restored the previous generated Ranwar content after an interrupted build.'
    }
    # Unreal owns reusable cook and compile caches under the project. Clean only our staging and per-run logs.
    Remove-BuildDirectory $incoming $work
    Remove-BuildDirectory $logs $work
    Remove-BuildDirectory $smokeProfile $work
    [IO.Directory]::CreateDirectory($uatLogs) | Out-Null
    $env:uebp_LogFolder = $uatLogs
    $env:uebp_FinalLogFolder = $uatLogs

    if ($needsImport) {

        Write-Host 'Building the Unreal editor module for the initial Ranwar import'
        $editorLog = Join-Path $logs 'editor-build.log'
        Invoke-UnrealTool $builder @('AamchiMumbaiUnrealEditor', 'Win64', 'Development', "-Project=$project",
            '-WaitMutex', "-Log=$editorLog")

        Write-Host 'Importing the Ranwar map, Omkar, arrival scene, and vehicles'
        $importer = Join-Path $PSScriptRoot 'create_ranwar_level.py'
        $importLog = Join-Path $logs 'ranwar-import.log'
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
        if (-not (Test-NonemptyFile $importLog) -or
            -not (Select-String -LiteralPath $importLog -Pattern 'Saved /Game/Ranwar/RanwarStreet with' -SimpleMatch -Quiet)) {
            throw "The Ranwar importer did not finish saving the map. See $importLog"
        }
    }

    foreach ($relativeAsset in $generatedAssets) {
        if (-not (Test-NonemptyFile (Join-Path $ranwar $relativeAsset))) {
            throw "Ranwar is missing $relativeAsset. Run again with -RefreshMap after generating the latest exchange."
        }
    }

    [IO.Directory]::CreateDirectory($incoming) | Out-Null
    foreach ($name in $worldSoundNames) {
        $stagedSound = Join-Path $audio $name
        Assert-PlainPath $stagedSound
        Copy-Item -LiteralPath (Join-Path $sharedAudio $name) -Destination $stagedSound -Force
    }
    $stagedDialogue = Join-Path $audio 'Dialogue'
    Assert-PlainPath $stagedDialogue
    [IO.Directory]::CreateDirectory($stagedDialogue) | Out-Null
    foreach ($source in $dialogueFiles) {
        $dialogueFile = Join-Path $stagedDialogue ([IO.Path]::GetFileName($source))
        Assert-PlainPath $dialogueFile
        Copy-Item -LiteralPath $source -Destination $dialogueFile -Force
    }
    Write-Host "Building, cooking, and staging a Win64 $configuration package. Incremental cook: $incremental"
    $uatArguments = @('BuildCookRun', "-project=$project", '-platform=Win64',
        "-clientconfig=$configuration", '-build', '-cook', '-map=/Game/Ranwar/RanwarStreet',
        '-stage', '-pak', '-package', '-prereqs', '-nodebuginfo', "-stagingdirectory=$incoming",
        '-unattended', '-nop4', '-utf8output')
    if ($incremental) { $uatArguments += '-iterativecooking' }
    if ($needsImport) {
        # The refresh replaces the same directory; discover the new asset names from disk.
        $uatArguments += '-AdditionalCookerOptions=-NoAssetRegistryCacheRead'
    }
    Invoke-UnrealTool $runUat $uatArguments

    $staged = Join-Path $incoming 'Windows'
    $nativeFile = if ($ReleaseVersion) { 'AamchiMumbaiUnreal-Win64-Shipping.exe' } else { $launchExe }
    $nativeExe = Join-Path $staged "AamchiMumbaiUnreal\Binaries\Win64\$nativeFile"
    $stagedLauncher = Join-Path $staged $launchExe
    $paks = Join-Path $staged 'AamchiMumbaiUnreal\Content\Paks'
    $pakBase = Join-Path $paks 'AamchiMumbaiUnreal-Windows'
    foreach ($file in @($stagedLauncher, $nativeExe, "$pakBase.pak", "$pakBase.ucas", "$pakBase.utoc")) {
        if (-not (Test-NonemptyFile $file)) { throw "The staged package is missing $file" }
    }
    if ($SmokeTest) {
        Write-Host 'Running the staged Ranwar gameplay smoke test with isolated save data'
        Invoke-StagedSmokeTest $nativeExe $smokeProfile (Join-Path $logs 'ranwar-smoke.log')
    }

    $notices = Join-Path $staged 'Notices'
    [IO.Directory]::CreateDirectory($notices) | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $notices 'LICENSE')
    Copy-Item -LiteralPath (Join-Path $root 'docs\THIRD_PARTY.md') -Destination (Join-Path $notices 'THIRD_PARTY.md')
    Copy-Item -LiteralPath (Join-Path $audio 'SOURCES.md') -Destination (Join-Path $notices 'VehicleAudio.md')
    Copy-Item -LiteralPath (Join-Path $sharedAudio 'SOURCES.md') -Destination (Join-Path $notices 'SharedAudio.md')
    Copy-Item -LiteralPath $dialogueNotice -Destination (Join-Path $notices 'Dialogue.md')
    $motionNotices = Join-Path $root 'prototype\character\motion'
    Copy-Item -LiteralPath (Join-Path $motionNotices '100STYLE-ATTRIBUTION.txt') -Destination $notices
    Copy-Item -LiteralPath (Join-Path $motionNotices 'CMU-ATTRIBUTION.txt') -Destination $notices
    $mapNotices = Join-Path $root 'assets\maps\reference\bandra-ranwar-modern-osm-2026-11-20'
    Copy-Item -LiteralPath (Join-Path $mapNotices 'ATTRIBUTION.md') -Destination (Join-Path $notices 'OpenStreetMap.md')
    Copy-Item -LiteralPath (Join-Path $mapNotices 'ODbL-1.0.txt') -Destination $notices

    [ordered]@{
        build = $configuration
        release_version = $ReleaseVersion
        source_commit = $commit
        worktree_dirty = $null -ne $changes
        unreal_engine = $versionText
        incremental_cook = $incremental
        generated_map_refreshed = $needsImport
        gameplay_smoke = if ($SmokeTest) { 'passed' } else { 'not run' }
        created_utc = [DateTimeOffset]::UtcNow.ToString('o')
        launcher_sha256 = Get-Sha256FileDigest $stagedLauncher
        native_exe_sha256 = Get-Sha256FileDigest $nativeExe
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $staged 'BuildReceipt.json') -Encoding UTF8

    if ($ReleaseVersion) {
        [IO.Directory]::Move($incoming, $output)
    } else {
        Assert-GameClosed $output
        Assert-PlainPath $output
        Assert-PlainPath $developmentWindows
        [IO.Directory]::CreateDirectory($output) | Out-Null
        if ([IO.Directory]::Exists($developmentWindows)) {
            Copy-DevelopmentProfile $developmentWindows $staged
            Assert-GameClosed $output
        }
        Remove-BuildDirectory $previous $work
        # The outer install folder can be open in Explorer. Replace only the Windows payload.
        if ([IO.Directory]::Exists($developmentWindows)) { Move-WindowsPayload $developmentWindows $previous }
        try {
            Move-WindowsPayload $staged $developmentWindows
        } catch {
            $keepVerifiedStaging = [IO.Directory]::Exists($staged)
            if ([IO.Directory]::Exists($previous) -and -not [IO.Directory]::Exists($developmentWindows)) {
                Move-WindowsPayload $previous $developmentWindows
            }
            throw
        }
    }
    $ranwarChanged = $false
    foreach ($discard in @($previous, $ranwarBackup)) {
        try {
            Remove-BuildDirectory $discard $work
        } catch {
            Write-Warning "The new package is ready. The recovery folder remains at $discard. $($_.Exception.Message)"
        }
    }
    Write-Host "Windows $configuration build ready at $(Join-Path $output "Windows\$launchExe")"
} catch {
    if ($ranwarChanged) {
        try {
            Remove-BuildDirectory $ranwar $content
            if ([IO.Directory]::Exists($ranwarBackup)) {
                [IO.Directory]::Move($ranwarBackup, $ranwar)
                Write-Warning "Restored the previous Ranwar content to $ranwar"
            }
        } catch {
            Write-Warning "Could not restore the earlier Ranwar content. Check $ranwar and $ranwarBackup. $($_.Exception.Message)"
        }
    }
    Write-Warning "See the build logs at $logs"
    throw
} finally {
    try {
        if ($keepVerifiedStaging) {
            Write-Warning "The candidate passed validation and remains at $incoming."
        } else {
            Remove-BuildDirectory $incoming $work
        }
    } catch {
        Write-Warning "Could not clean the staging directory at $incoming. $($_.Exception.Message)"
    } finally {
        try {
            if ($null -ne $engineConfigBefore) {
                Restore-GeneratedAndroidDefaults $engineConfigPath $engineConfigBefore
            }
        } catch {
            Write-Warning 'Could not restore the original Unreal project config after the Windows build.'
        } finally {
            $env:uebp_LogFolder = $oldUatLogs
            $env:uebp_FinalLogFolder = $oldUatFinalLogs
            $lock.Dispose()
        }
    }
}
