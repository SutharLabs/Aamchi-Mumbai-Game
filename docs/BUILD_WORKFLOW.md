# Development builds and releases

Steamworks assigns builds to private test branches and a separate public default branch. Selecting a branch updates the existing installation. GitHub Releases packages a particular tagged revision and its release notes for distribution. The local workflow applies that separation to this checkout. Godot supplies distinct debug and release export commands. [Steamworks builds](https://partner.steamgames.com/doc/store/application/builds) · [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases) · [Godot command line exports](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#exporting)

## Local Windows playtest

Use **F5** in the editor for the fastest iteration. To refresh the Windows playtest, run the development build command from the repository root with the pinned Godot 4.7.2 editor and Windows export templates installed.

```powershell
.\tools\make-dev.ps1
```

Always launch `builds/local/Aamchi Mumbai Game.exe`. The command exports into a staging directory and launches that executable headlessly with isolated app data. It checks that the packed title scene loads cleanly and then replaces the stable executable on the same volume. Export or startup failures preserve the existing playable build. Close the game before updating it. The command reports the SHA-256 hash.

- `builds/local/windows-build.json` records the source commit, whether the Godot project had local edits, build time, engine version and executable hash. Check the hash when identifying a copied executable.
- `builds/local/windows-build.log` records the most recent export and startup attempt.
- `.\tools\make-dev.ps1 -CheckOnly` runs the same export and startup check and removes the staged executable after validation.

The startup check verifies that the executable opens its title scene. Record manual route, gameplay and physical-device acceptance separately. Historical builds remain available in their original directories. [Playtest checks](../prototype/README.md) · [Phase progress](PHASE_PROGRESS.md)

## Distribution builds

1. Start packaging when the project owner requests a release. Choose the version and freeze the reviewed source revision.
2. Export the platform packages into a fresh versioned directory under `builds/release/`. Use Godot’s release export with the agreed release presets and existing platform credentials. Preserve the package identifier and signing key when issuing an Android update. Keep the Windows executable name stable within each package.
3. Test the packaged Windows executable and signed Android build. Record the source revision, platform status, SHA-256 hashes, release notes and required notices alongside the artifacts.
4. Publish the approved packages from the authorized Ubuntu VM using a versioned Git tag and GitHub Release. Use the tested packages for distribution and rebuild a successor version if their contents change. [Repository publishing rules](../AGENTS.md#mandatory-git-commit-and-push-workflow)

Android local playtesting still uses the `Android Debug` preset and its stable APK path. Keep local signing and export credentials in the ignored toolchain and Godot credentials configuration. [Android local export](../prototype/README.md#local-debug-exports) · [Godot export configuration](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#configuration-files)
