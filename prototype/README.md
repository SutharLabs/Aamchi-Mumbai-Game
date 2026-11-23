# Aamchi Mumbai Game · Phase 1 playtest

Walk and drive around Ranwar, Bandra West, in present-day Mumbai. A new profile arrives as Omkar, a worker new to the city, at the St Peter’s Church BEST stop. A loan motorcycle is parked near the stop. Follow Hill Road west to the practice yard and job board. There are twelve parked vehicles, up to four civilian traffic cars on desktop and three on mobile, and a separate patrol when police respond. [Route and source notes](world/README.md) · [District facilities](../docs/BANDRA_FACILITIES.md)

Play as **Omkar Shirodkar (ओंकार शिरोडकर)**, wearing an indigo sadara, an ivory dhotar and Kolhapuri-style chappals. His original skinned mesh uses the captured idle, walk and jog clips. Two pedestrians use the same captured walk along the western Hill Road sidewalk and eastern frontage. [100STYLE motion credits](character/motion/100STYLE-ATTRIBUTION.txt)

Open `project.godot` in Godot 4.7.2 standard and press **F5** to open the title screen. Press **F6** from `phase1.tscn` for direct scene testing. Use the editor to try changes from the current checkout. The earlier **0.0.2** local playtest packages are retained under `../builds/dev/0.0.2/`. [Published 0.0.1 playtest](https://github.com/SutharLabs/Aamchi-Mumbai-Game/releases/tag/v0.0.1)

The title menu provides Play, Profiles, Settings, Help, Credits and Quit. Profiles store a local display name and the active selection. The game stores volume, fullscreen, camera sensitivity and control bindings in `user://preferences.json`. On desktop, open **Settings → Control bindings** to remap keyboard keys or gamepad buttons and axes, or restore defaults. Open **Pause → Map** to see the Ranwar driving loop, the Nagrana Lane walking shortcut and your position on foot or in a vehicle. Open **Help → Controls** in either menu for the platform-specific guide. Gameplay shows short interaction prompts, feedback and vehicle speed when relevant. Credits in both menus cover map data, motion capture, the engine and the Marathi font. [Title and credits research](../research/STARTUP_AND_CREDITS.md)

| Default input | Action |
|---|---|
| **WASD** or **arrows** | Walk, or steer and control speed while driving. |
| **Shift** with movement | Jog on foot. |
| **Mouse** | Look around. |
| **Esc** | Pause or resume. Return from a menu page to the preceding menu. |
| **E** | Talk to a nearby pedestrian or get into the nearest vehicle. Stop and press again to exit a vehicle. |
| **Space** | Jump on foot or brake while driving. |
| **R** | Return on foot and reset the vehicles and pedestrians. |
| Windows gamepad | Left stick to move or drive, right stick to look, X to jog, A to interact, LB to jump or brake, Y to reset, Start to pause and B to go back. |
| Touch controls | Walk or drive with the left stick and drag the right side to look. On foot the action button reads Jump, and while driving it reads Brake. Interact, Reset and Pause remain available. |

To follow the ambient traffic circuit, take western Waroda Road from the start toward Veronica. Continue on eastern Waroda to Chapel, take St Peter's Road to Hill Road, then follow Hill Road past the church back toward the start. The Nagrana shortcut has a narrow bollard gap for walking. The handling yard west of the spawn includes a raised ramp, a curb and a barrier. For the road topology and coordinates, see [layout.json](world/layout.json).

Walk up to Mira or Rafiq on Hill Road and press **E** or **A** on a gamepad, or tap **Interact**, when the talk prompt appears. Each pauses to face you and offers a short route tip, then continues walking. Pedestrians yield when their route is blocked and are solid to the player and all four vehicles.

To try the curb crossing, drive slowly across the raised west-side curb on Hill Road. All four can climb the curb and come down to street or yard level. The handling yard also has a 22 cm test curb and a solid impact wall. The driving camera softens changes in height as the vehicle crosses the curb. [Vehicle handling notes](vehicle/README.md)

## Arrival, street traffic and vehicle access

Approach a vehicle and use **Interact**. The prompt shows **Unlock** for loan vehicles with keys and **Steal** for other vehicles. A stopped traffic vehicle can transfer to your control. Its driver or a nearby witness can raise the police alert. **Recover** takes you back to the practice yard. Later visits from the title also start there once this profile’s arrival has been recorded.

The hood, roof, lamp and tail shapes vary across four car silhouettes, an auto-rickshaw, four motorcycles and two scooters. The parked roster and traffic mix use the same collision, damage and rider systems as the original playtest. [Vehicle catalogue and manufacturer references](../research/OPEN_MODEL_CATALOGUE.md) · [Vehicle notes](vehicle/README.md)

The lower-right **live map** follows Omkar or the vehicle he is driving and shows nearby routes and objectives. Health, cash, police alert and vehicle condition have their own HUD readouts. Use **Settings → Live map → Apply** to turn the map off. **Pause → Map → District services** shows the real positions of mapped transport and public services beyond the playable stop. [Bandra map scope and sources](../docs/BANDRA_FACILITIES.md)

## Surface and collision playtest

At walking speed, check the asphalt, concrete, façades, roofs and timber around the Ranwar loop and Nagrana Lane. The Windows scene uses a daylight sky and nearby sun shadows. Open the world notes for the material sources and placement. [Ranwar world and texture sources](world/README.md)

On Hill Road, look for the red paan kiosk beside **Grocery & Daily Needs**. At the Hill Road end of Nagrana Lane, **Meena at 82 Hill Road** stands across the road. Meena’s footprint and level count come from the saved OpenStreetMap extract. Its height per floor and façade details are authored estimates. [Kiosk provenance](world/props/SOURCES.md) · [Site controls and capture checklist](../docs/RANWAR_REFERENCE_CHECKLIST.md)

Use the handling yard’s impact wall to compare a slow tap with a faster crash in the hatchback. A hard impact can dent the affected bodywork, break a lamp and lower the vehicle’s condition. Damage affects handling until **Recover**. Moderate vehicle contacts can stagger a pedestrian. Harder impacts select a recorded forward or backward fall by contact direction, while the collision capsule controls movement and ground contact. Jumping uses a recorded takeoff, flight and landing, with the capsule preserving ceiling and ground collisions. [Vehicle damage details](vehicle/README.md) · [Motion capture and sources](character/motion/README.md)

## Ranwar Parcel Run

Launch with **F5 → Play**. Walk to the orange job marker by the vehicle bays and interact. Pick up the parcel on foot at the Hill Road end of Nagrana Lane, then follow the lane to the Waroda Road end to drop it off. You can use any practice vehicle to reach the lane, then leave it to make the handoff. The HUD shows the current destination and distance. **Pause → Map** shows an orange diamond for the next stop.

Deliver the parcel to earn **₹500** and unlock **Mira’s lead** on Hill Road. Follow the orange marker and talk to Mira to learn about the print-shop ledger. The payout is awarded once per profile, and the cash balance and story lead appear in the pause menu. Existing completed parcel runs receive the payout when loaded.

**Recover** returns you to the starting point and interrupts an active job. Interact at the job board to retry the last objective. To start over, choose **Pause → Abandon job**. Objective changes save automatically to the active profile. **Main menu → Play** reopens the saved stage at the starting point.

High-speed impacts can injure Omkar. First aid near the vehicle bays costs **₹60** and restores health. Incapacitation returns Omkar to the recovery point and charges up to **₹100**. Hard collisions with pedestrians or moving traffic can draw a marked patrol. A nearby patrol can detain you while stopped, and **Recover** during an alert also invokes detention. The fine is up to **₹150**. Returning to the title keeps health and alert state for the running session. [Gameplay research and full rules](../research/GTA_GAMEPLAY_REFERENCES.md)

## Local smoke checks

From the repository root with the downloaded portable editor and its matching standard templates in `.toolchain`:

```powershell
$editor = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& $editor --headless --path prototype --editor --import
& $editor --headless --path prototype --fixed-fps 60 --quit-after 300 --script res://tests/startup_smoke.gd -- --touch-preview
& $editor --headless --path prototype --fixed-fps 60 --quit-after 6500 --script res://tests/phase1_smoke.gd -- --touch-preview
& $editor --headless --path prototype --fixed-fps 60 --quit-after 6200 --script res://tests/ranwar_parcel_playtest.gd -- --touch-preview
& $editor --headless --path prototype --fixed-fps 60 --quit-after 1800 --script res://tests/vehicle_damage_smoke.gd
& $editor --headless --path prototype --fixed-fps 60 --quit-after 1900 --script res://tests/pedestrian_impact_smoke.gd
& $editor --headless --path prototype --fixed-fps 60 --quit-after 1300 --script res://tests/mocap_actions_smoke.gd -- --touch-preview
& $editor --headless --path prototype --fixed-fps 60 --quit-after 1100 --script res://tests/ranwar_arrival_ownership_smoke.gd
```

The startup smoke exercises menu navigation, profile reload, settings, Help, credits, pause and the Ranwar map. The gameplay smoke exercises locomotion, pedestrian conversations and collision, all four vehicles, steering and braking, exit clearance, reset, curbs, ramps and simulated concurrent touch. The parcel playtest uses isolated profiles and exercises the title-to-delivery loop, checkpoint reload and the shortcut in both directions. `--touch-preview` enables the overlay on a desktop build. When preparing an explicitly requested release, include the project license and the Godot, OpenStreetMap, 100STYLE and Noto notices. [Project license](../LICENSE)

The car, auto-rickshaw, motorcycle and scooter use shaped, unbranded vehicle models. The two-wheelers have distinct skinned rider poses, with hands following the steering grips and visual lean on upright arcade collision bodies. The user reported a successful Android 0.0.1 run. Detailed native-touch, minimum-spec performance and fresh-player testing remain open. [Vehicle notes](vehicle/README.md) · [Phase tracker](../docs/PHASE_PROGRESS.md)

## Ranwar route benchmark

Run the car lap with real rendering for a repeatable developer baseline. Close competing renders, record the machine and driver, and use the same resolution, FPS limit and scene for each comparison. The harness disables ambient traffic to keep the route repeatable. It reports scene setup and wall-clock frame times, long frames, engine allocation, sampled draw calls and the number of active backdrop meshes. Its physics statistic summarizes Godot's peak tick duration across one-second windows.

```powershell
& $editor --path prototype --disable-vsync --max-fps 60 --resolution 1280x720 --script res://tests/phase1_route_benchmark.gd
```

For a quick streaming comparison, run this command twice with `--time-scale 2` among the Godot options, appending `-- --stream-visual-chunks` to the second run. Record both separately and retain the same settings. [Ranwar streaming experiment and results](world/README.md#visual-streaming-experiment)

For the Windows 10 minimum-device check, use a matching exported build at 1280x720 on the low preset and measure uncapped after warm-up at normal gameplay speed with traffic enabled. Repeated runs on the named Windows and Android devices should also cover riding all four vehicles, curb crossings, exits and recovery by hand. Record frame time and memory along with route, device and OS, and note touch issues and sustained phone behavior. [Device acceptance and fresh-player checks](../docs/PHASE_PROGRESS.md#remaining-work-to-close-g1)

## Local debug exports

Refresh the stable Windows playtest at `builds/local/Aamchi Mumbai Game.exe` from the repository root. The command exports to a staging folder, verifies startup, and replaces the playable EXE after it passes. It writes the build identity alongside the executable. [Development build and release workflow](../docs/BUILD_WORKFLOW.md)

```powershell
.\tools\make-dev.ps1
```

To export for Android, use the **Android Debug** preset with the matching Godot 4.7.2 standard templates. Set the Java SDK and Android SDK paths in Godot's editor settings. This Windows build used project-local Eclipse Temurin 17 and AOSP tools for APK signing and ADB. The debug certificate stays with the local toolchain. [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

```powershell
New-Item -ItemType Directory -Force -Path '.\builds\local' | Out-Null
$apk = Join-Path (Get-Location) 'builds\local\Aamchi-Mumbai-Game-Android-arm64.apk'
& $editor --headless --path prototype --export-debug 'Android Debug' $apk
```

The earlier signed **0.0.2** APK is ARM64, with Android API 24 as its minimum and API 36 as its target. It retains the package identifier `com.sutharlabs.aamchimumbai` and the 0.0.1 playtest signing certificate. Internal version code **3** supports updating the 0.0.1 build, which used code 2. The Android ZIP includes the same APK, the project license and the third-party notices.

The selected Android test phone is the **Redmi Note 9 Pro Max (India)**. The user reported that 0.0.1 ran as expected on this phone. For the 0.0.2 follow-up, record the installed Android and MIUI versions and RAM variant. Check launch and landscape menus, Help readability, simultaneous movement and camera touch, talking with Mira or Rafiq, and entering, driving and exiting a vehicle. Record any touch or performance issue with the location and action that triggered it. [Xiaomi India device specifications](https://www.mi.com/in/redmi-note-9-pro-max/specs)
