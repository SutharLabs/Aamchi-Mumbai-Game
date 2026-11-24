# Development builds and releases

Steamworks assigns builds to private test branches and a separate public default branch. Selecting a branch updates the existing installation. GitHub Releases packages a particular tagged revision and its release notes for distribution. Use the stable local install for playtesting and a versioned package when a release is requested. [Steamworks builds](https://partner.steamgames.com/doc/store/application/builds) · [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

## Godot-first iteration and Unreal acceptance

1. **Iterate in Godot.** Open `prototype/project.godot` in Godot 4.7.2 and press **F5**. Check the actual gameplay camera and run the focused smoke command for the changed feature. Use `.\tools\make-dev.ps1 -CheckOnly` when an exported startup check is relevant. [Godot playtest and smoke commands](../prototype/README.md#local-smoke-checks)
2. **Hand off the approved revision.** Record the source commit, asset IDs, source and exchange hashes, import settings and known exceptions. Regenerate only the affected exchange inputs under `builds/local/unreal-ranwar/` using the scripts documented for the street, Omkar, vehicles and arrival. The existing street importer uses generated FBX section meshes, collision, PNG textures and its JSON manifest. [Exchange commands](../unreal/ContentSource/RANWAR_STREET.md#build-the-exchange)
3. **Integrate and validate in Unreal.** Recheck import scale and axes, pivots, material slots, bone hierarchy, rest pose, weights and clip playback. Reapply engine-local material or shader settings, collision, physics assets, retargeting and animation state. Port gameplay, UI and input changes in the Unreal implementation. After an exchange change, use `powershell -NoProfile -File .\unreal\Tools\make-dev.ps1 -RefreshMap -SmokeTest`. Run the rendered route in the packaged build and record results separately for each engine and target device. The Windows 10 and Android 12 performance and input gates still need their own native Unreal evidence. [Unreal import options](https://dev.epicgames.com/documentation/unreal-engine/interchange-import-reference-in-unreal-engine) · [Phase progress](PHASE_PROGRESS.md)

| Asset | Canonical source and handoff |
| --- | --- |
| Models and animation | Keep an editable `.blend` or the existing deterministic generator as the authoring source. Exchange portable static and skinned models as self-contained glTF 2.0 `.glb` with named parts, pivots, scale in metres, stable material slots and named animation clips. Document forward/up axes and root motion. [Godot supported 3D formats](https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) |
| Maps | Retain the dated OpenStreetMap source with attribution and versioned JSON or GeoJSON for derived roads, parcels and placed asset IDs. Record projection, units and authored adjustments. [Ranwar map data](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) |
| Images and audio | Retain approved PNG or WebP source images. Exchange portable texture maps and masks as PNG where conversion is needed, with color versus data maps identified. Use PCM WAV for source and audio exchange. Apply import compression and audio settings per engine. |

Keep original project assets under the SutharLabs source-viewing and playtest license. Adopt third-party material only when the exact asset terms allow the intended commercial, cross-engine and distribution uses. Record attribution and modifications. Keep raw or editable files in approved source storage when their terms restrict public redistribution, and include only permitted content and notices in cooked packages. [Project license](../LICENSE) · [Third-party notices](THIRD_PARTY.md)

## Unreal Windows playtest

Use Play In Editor for Unreal integration checks. For final validation in a standalone Unreal 5.8 Windows build, run this command from the repository root.

```powershell
powershell -NoProfile -File .\unreal\Tools\make-dev.ps1 -SmokeTest
```

Launch `builds/local/unreal-windows/Windows/AamchiMumbaiUnreal.exe` with its complete `Windows` folder. The command reuses Unreal's incremental C++ build and cooked content when available, and stages the package directly into its local working directory. It excludes debug symbols from the playtest folder and keeps the engine's compile and derived data caches for the next iteration. A map refresh rescans asset names and bypasses the previous registry cache for that cook. A Development update replaces the Windows payload while retaining the outer installation folder and carries forward its saves and preferences. Use `-RefreshMap` after changing the art or level exchange, `-FullCook` for a fresh cook, and `-Plan` to validate setup and print the proposed action without building. The script regenerates missing required Ranwar assets automatically. [Unreal project setup](../unreal/README.md#unreal-windows-development-build) · [Ranwar exchange](../unreal/ContentSource/RANWAR_STREET.md) · [Epic packaging operations](https://dev.epicgames.com/documentation/en-us/unreal-engine/packaging-your-project) · [Unreal Derived Data Cache](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-derived-data-cache-in-unreal-engine?lang=en-US)

The script validates both executables and the cooked PAK and IoStore files before promotion. `-SmokeTest` runs the staged Development game's `AamchiMumbai.Ranwar.Playable` test with an isolated save directory and includes The Hill Road Ledger via `-RanwarLedgerSmoke`. A failed build or selected test leaves the previous playable package available and restores the previous generated map when applicable. Close the existing playtest before refreshing. Development updates carry forward the installed game's `.sav` slots and `GameUserSettings.ini`. The published `Windows/BuildReceipt.json` records the build configuration, source revision, whether edits were present, executable hashes and smoke result.

The staged smoke process uses the scratch profile as its working directory. Promotion retries a short-lived Windows folder lock and retains a validated candidate in staging if its move into the stable path still fails. The build checks the shared dialogue catalogue, parcel sound and sandal footstep banks before staging them with their provenance notices. [Voice assets](../prototype/shared/dialogue/SOURCES.md) · [Shared world audio](../prototype/shared/audio/SOURCES.md)

| Directory | Use |
| --- | --- |
| `unreal/Source/`, `unreal/Config/`, `unreal/Tools/`, `unreal/ContentSource/` | Versioned project code, configuration, generators and authoring inputs |
| `builds/local/unreal-ranwar/`, `builds/local/unreal-pilot/` | Existing remote and local modeling exchange contracts |
| `unreal/Content/Ranwar/`, `unreal/Binaries/`, `unreal/Intermediate/`, `unreal/Saved/Cooked/` | Generated state reused by Unreal |
| `builds/local/unreal-work/` | Temporary staging, recovery state, isolated test profile and most recent build logs |
| `.toolchain/ranwar-unreal-migration-verification/` | Rendered playtest captures and manual verification evidence |
| `builds/local/unreal-windows/` | Stable Development package |
| `builds/release/<version>/unreal-windows/` | Explicit Windows Shipping package for release review |

## Godot Windows prototype

Use **F5** in the editor for the fastest iteration. To refresh the Windows playtest, run the development build command from the repository root with the pinned Godot 4.7.2 editor and Windows export templates installed.

```powershell
.\tools\make-dev.ps1
```

Always launch `builds/local/Aamchi Mumbai Game.exe`. The command exports into a staging directory and launches that executable headlessly with isolated app data. It checks that the packed title scene loads cleanly and then replaces the stable executable on the same volume. It retries short Windows sharing and lock errors during the replacement. Export or startup failures preserve the existing playable build. Close the game before updating it. The command reports the SHA-256 hash.

- `builds/local/windows-build.json` records the source commit, whether the Godot project had local edits, build time, engine version and executable hash. Check the hash when identifying a copied executable.
- `builds/local/windows-build.log` records the most recent export and startup attempt.
- `.\tools\make-dev.ps1 -CheckOnly` runs the same export and startup check and removes the staged executable after validation.

The startup check verifies that the executable opens its title scene. Record manual route, gameplay and physical-device acceptance separately. [Playtest checks](../prototype/README.md) · [Phase progress](PHASE_PROGRESS.md) · [Godot command line exports](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#exporting)

## Distribution builds

1. Start packaging when the project owner requests a release. Choose the version and freeze the reviewed source revision.
2. Use the configured shipping workflow for each platform. For an Unreal Windows Shipping candidate, run `powershell -NoProfile -File .\unreal\Tools\make-dev.ps1 -ReleaseVersion <version>` from a clean, reviewed commit. The command performs a full cook and writes a fresh versioned directory, rejecting an existing package for that version. Preserve the package identifier and signing key when issuing an Android update.
3. Test the packaged Windows executable and signed Android build. Record the source revision, platform status, SHA-256 hashes, release notes and required notices alongside the artifacts.
4. Publish the approved packages from the authorized Ubuntu VM using a versioned Git tag and GitHub Release. Use the tested packages for distribution and rebuild a successor version if their contents change. [Repository publishing rules](../AGENTS.md#mandatory-git-commit-and-push-workflow)

The existing Godot Android prototype has its own `Android Debug` preset and stable APK path. The Unreal Android package and device acceptance are separate tasks. [Godot Android local export](../prototype/README.md#local-debug-exports) · [Phase progress](PHASE_PROGRESS.md)
