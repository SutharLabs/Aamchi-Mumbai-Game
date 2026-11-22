# Aamchi Mumbai Game · Phase 1 playtest

Walk and drive around Ranwar, Bandra West, in present-day Mumbai. Four drivable vehicles start in marked bays near the starting point. From the car, head left past the auto-rickshaw to find the motorcycle and scooter. The route includes a walking shortcut and an open handling yard. [Route and source notes](world/README.md)

The player uses captured idle, walk and jog clips on an original skinned humanoid. Two pedestrians use the same captured walk along the western Hill Road sidewalk and eastern frontage. [100STYLE motion credits](character/motion/100STYLE-ATTRIBUTION.txt)

Open `project.godot` in Godot 4.7.2 standard and press **F5** to open the title screen. Press **F6** from `phase1.tscn` for direct scene testing. The Windows 0.1.1 debug export is `../builds/phase-1/Aamchi Mumbai Game 0.1.1.exe`. The versioned filename avoids reusing the Windows shell icon cache entry from the earlier executable.

The title menu provides Play, Profiles, Settings, Credits and Quit. Profiles store a local display name and the active selection. Master volume, fullscreen and camera sensitivity are device settings saved in `user://preferences.json`. The pause menu also offers Resume and Main menu. Credits in both menus cover map data, motion capture, the engine and the Marathi font. [Title and credits research](../research/STARTUP_AND_CREDITS.md)

| Input | Action |
|---|---|
| **WASD** or **arrows** | Walk, or steer and control speed while driving. |
| **Shift** with movement | Jog on foot. |
| **Mouse** | Look around. |
| **Esc** | Pause or resume. Return from a menu page to the preceding menu. |
| **E** | Talk to a nearby pedestrian or get into the nearest vehicle. Stop and press again to exit a vehicle. |
| **Space** | Brake while driving. |
| **R** | Return on foot and reset the vehicles and pedestrians. |
| Touch controls | Walk or drive with the left stick, drag the right side to look, and use Interact, Brake, Reset and Pause. |

Follow Hill Road from the start toward St Peter's approach, turn onto St Peter's Road and follow Waroda Road back. The Nagrana shortcut has a narrow bollard gap for walking. The handling yard west of the spawn includes a raised ramp, a curb and a barrier. For the road topology and coordinates, see [layout.json](world/layout.json).

Walk up to Mira or Rafiq on Hill Road and press **E** or tap **Interact** when the talk prompt appears. Each pauses to face you and offers a short route tip, then continues walking. Pedestrians yield when their route is blocked and are solid to the player and all four vehicles.

To try the curb crossing, drive slowly across the raised west-side curb on Hill Road. All four can climb the curb and come down to street or yard level. The handling yard also has a 22 cm test curb and a solid impact wall. The driving camera softens changes in height as the vehicle crosses the curb. [Vehicle handling notes](vehicle/README.md)

## Local smoke check and export

From the repository root with the downloaded portable editor and its matching standard templates in `.toolchain`:

```powershell
$editor = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& $editor --headless --path prototype --editor --import
& $editor --headless --path prototype --fixed-fps 60 --quit-after 300 --script res://tests/startup_smoke.gd -- --touch-preview
& $editor --headless --path prototype --fixed-fps 60 --quit-after 5500 --script res://tests/phase1_smoke.gd -- --touch-preview
New-Item -ItemType Directory -Force -Path '.\builds\phase-1' | Out-Null
$exe = Join-Path (Get-Location) 'builds\phase-1\Aamchi Mumbai Game 0.1.1.exe'
& $editor --headless --path prototype --export-debug 'Windows Desktop' $exe
Copy-Item 'prototype/character/motion/100STYLE-ATTRIBUTION.txt' 'builds/phase-1/'
Copy-Item 'prototype/startup/art/NotoSansDevanagari-OFL.txt' 'builds/phase-1/'
```

The startup smoke exercises menu navigation, profile reload, settings, credits and pause. The gameplay smoke exercises locomotion, pedestrian conversations and collision, all four vehicles, steering and braking, exit clearance, reset, curbs, ramps and simulated concurrent touch. `--touch-preview` enables the overlay on a desktop build. Keep the Godot, OpenStreetMap, 100STYLE and Noto notices with the executable.

The car, auto-rickshaw, motorcycle and scooter use shaped, unbranded vehicle models. The two-wheelers have distinct skinned rider poses, with hands following the steering grips and visual lean on upright arcade collision bodies. Physical-device touch, minimum-spec performance and fresh-player testing remain open. [Vehicle notes](vehicle/README.md) · [Phase tracker](../docs/PHASE_PROGRESS.md)

## Android debug export

Use the **Android Debug** preset with the matching Godot 4.7.2 standard templates. Set the Java SDK and Android SDK paths in Godot's editor settings. This Windows build used project-local Eclipse Temurin 17 and AOSP tools for APK signing and ADB. The debug certificate stays with the local toolchain. [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

```powershell
$apk = Join-Path (Get-Location) 'builds\phase-1\Aamchi Mumbai Game 0.1.1 - Phase 1 Android.apk'
& $editor --headless --path prototype --export-debug 'Android Debug' $apk
```

The signed 0.1.1 APK is ARM64 and declares Android API 24 as its minimum and API 36 as its target. The launcher icon, package identifier `com.sutharlabs.aamchimumbai`, landscape orientation and v2/v3 signatures were verified. The companion ZIP contains the APK and the five notices used by the Windows package. Test launch and native inputs on an actual Android 12 ARM64 phone for the phase gate.
