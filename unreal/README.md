# Aamchi Mumbai Game in Unreal

The Unreal Engine 5.8 playtest starts at St Peter's BEST stop with the original Omkar rig and the mapped Ranwar street loop. Talk to Anjali, visit the Hill Road job board, and finish the parcel run for INR 500. You can walk through both shops or drive a hatchback, auto-rickshaw, motorcycle, or scooter. Ambient traffic follows the registered left-hand route. [Remote development and editor setup](REMOTE_DEVELOPMENT.md) · [Ranwar street exchange](ContentSource/RANWAR_STREET.md)

## Windows development build

Install the Windows edition of Unreal Engine 5.8 through Epic Games Launcher, with Visual Studio C++ Build Tools and the Windows SDK. Prepare the [Ranwar exchange](ContentSource/RANWAR_STREET.md#build-the-exchange), then run this command from the repository root.

```powershell
powershell -NoProfile -File .\unreal\Tools\make-dev.ps1
```

Launch `builds/local/unreal-windows/Windows/AamchiMumbaiUnreal.exe` from its complete `Windows` folder. The other files in that folder contain the native game, cooked content, dependencies, and notices. Pass `-RefreshMap` when the generated level or its imported assets need rebuilding. Use `-EngineRoot` for an installation the script cannot find through Epic Games Launcher.

The Windows playtest defaults to DirectX 11 and Shader Model 5. Its graphics quality and VSync settings are available from the startup and pause menus. Verify rendered performance on the intended Windows 10 device.

## Separate Sea Link study

The first Unreal study uses the 600 m Bandra channel section of the Bandra–Worli Sea Link. It has a first-person walking controller and a separate editor script that imports the bridge, creates carriageway collision and lights an isolated daylight level. The bridge uses original geometry informed by engineering references.

The span uses the operator's 50 + 250 + 250 + 50 m arrangement, twin four-lane carriageways and a 20 m navigation clearance. The engineering paper informed the paired pylons and stay cables. The model treats the deck as straight and level, uses authored finish details, and omits the connecting approach roads. The walking route is a closed pilot environment. [MSRDC bridge summary](https://msrdc.in/Site/Common/ProjectListDetails.aspx?ID=66&MainId=18) · [MSRDC RFP Schedule A](https://msrdc.in/Site/Upload/GR/3_RGSL%20RFP%20Vol%20III%20-%20Schedule%20-18-10-2013%20R8.pdf) · [Bandra cable-stayed bridge engineering paper](https://doi.org/10.2749/222137813808627587)

## Source and exchange files

- `AamchiMumbaiUnreal.uproject` and `Source/` own the Unreal pilot. The project targets the UE 5.8 family and the 5.8.4 stable hotfix for the initial test. [Epic hotfix announcement](https://forums.unrealengine.com/t/5-8-4-hotfix-released/2842775)
- `Tools/build_sea_link.py` generates the original bridge model in metres. The FBX brings the bridge alone into Unreal, with embedded asphalt and concrete colour tiles. The GLB is a second exchange format. The PNG is a Blender Cycles render with a separately lit sea and horizon. The JSON receipt identifies the exported geometry and the Blender reimport check.
- `Tools/create_sea_link_level.py` reads `builds/local/unreal-pilot/sea-link-main-span.fbx` and writes `/Game/Pilot/SeaLinkWalk` into the Unreal project. It checks the imported bridge dimensions in centimetres and protects an existing level from replacement. Exchange files, generated Unreal content and build caches are local outputs.

From the game repository root with Blender 5.3.0 available, regenerate the exchange files with this command.

```powershell
blender -b --python-exit-code 1 --python unreal/Tools/build_sea_link.py -- builds/local/unreal-pilot
```

The remote workflow uses the MotionGraphics checkout's `.github/skills/remote-render/SKILL.md` and `scripts/remote.ps1`. Both nodes provide headless Blender 5.3.0. The 24-vCPU epyc24 node has direct internet and the 32-vCPU xeon32 node uses the MotionGraphics relay. Use `status` before submission and the detached `run` command for modeling. The launcher manages one heavy job per node. A raw `run` targets the remote node.

The job uses a dedicated `projects/amg-unreal-bridge-pilot` folder under MotionGraphics. Copy the current `unreal/Tools/build_sea_link.py` into that folder before running the command below from MotionGraphics. Run `poll` to collect the files. Copy the results from the project folder's `out/` into `builds/local/unreal-pilot/` in the game checkout. The optional `-Node xeon32` flag pins the fallback node. The first pilot was modeled and rendered on epyc24.

```powershell
.\scripts\remote.ps1 status
.\scripts\remote.ps1 run amg-unreal-bridge-pilot -Detach -Pull out/sea-link-main-span.fbx -Pull out/sea-link-main-span.glb -Pull out/sea-link-main-span.png -Pull out/sea-link-main-span.json -Pull out/sea-link-road-level.png -Pull out/sea-link-concrete.png -Pull out/sea-link-asphalt.png -- '/root/motion/.tools/blender-5.3.0/blender -b --python-exit-code 1 --python build_sea_link.py -- out'
.\scripts\remote.ps1 poll amg-unreal-bridge-pilot
```

## First Unreal Editor check

An Epic-authenticated Unreal Engine 5.8.4 installation and the matching Windows C++ toolchain are required to build and run this project. Epic recommends 32 GB of system RAM and 8 GB of graphics memory for development. The current Windows test machine has Intel Iris Xe and the two CPU modeling nodes have only virtual graphics. Use a Lumen-capable Windows GPU for the visual comparison. [Epic installation guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/install-unreal-engine) · [Visual Studio setup](https://dev.epicgames.com/documentation/en-us/unreal-engine/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine) · [Unreal hardware and feature requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/hardware-and-software-specifications-for-unreal-engine)

With Unreal and the C++ prerequisites installed, run the following from the repository root. Adjust the editor installation path to match the installed copy.

```powershell
$engine = 'C:\Program Files\Epic Games\UE_5.8\Engine'
$project = (Resolve-Path 'unreal/AamchiMumbaiUnreal.uproject').Path
$script = (Resolve-Path 'unreal/Tools/create_sea_link_level.py').Path
& "$engine\Build\BatchFiles\Build.bat" AamchiMumbaiUnrealEditor Win64 Development "-Project=$project" -WaitMutex
if ($LASTEXITCODE -ne 0) { throw 'Unreal editor target failed to compile.' }
& "$engine\Binaries\Win64\UnrealEditor.exe" $project "-ExecutePythonScript=$script" -log
```

After the editor script saves the map, open `Content/Pilot/SeaLinkWalk` in the Content Browser and press **Play**. The pilot uses **WASD**, mouse look and **Space**. First acceptance covers imported scale, first spawn, walking and jumping on the collision deck, and daylight under the four planes of cables. Capture an Unreal frame and measure frame time in a Windows development package before expanding to a Bandra road loop. [Unreal editor Python](https://dev.epicgames.com/documentation/en-us/unreal-engine/scripting-the-unreal-editor-using-python) · [Unreal FBX static mesh import](https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine)

For the Redmi Note 9 Pro Max, a later Unreal comparison would need its own mobile renderer, asset budgets and physical-device test. Its Adreno 618 has a different graphics feature profile from Epic's documented mobile Lumen devices. The native Unreal build, Unreal rendering and phone performance measurements remain open. [Xiaomi device specification](https://www.mi.com/in/redmi-note-9-pro-max/specs) · [Epic mobile Lumen requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-lumen-global-illumination-on-mobile-in-unreal-engine)
