# Ranwar Street exchange

The Unreal walking level uses the same OSM-derived Ranwar roads and the same authored neighborhood meshes as the Godot playtest. It starts at St Peter's Church BEST stop on Hill Road, with the Nagrana Lane link, both walk-in shops, and the current district closures. Native Unreal landmark actors identify the arrival stop, public landmarks, shop entrances, and map and asset credits.

## Build the exchange

From the repository root, run the pinned Godot console editor and Blender 5.3.0.

```powershell
$godot = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
$exchange = Join-Path (Get-Location).Path 'builds/local/unreal-ranwar'
$exports = @{
    export_ranwar_source = 'ranwar-source.json'
    export_omkar = 'omkar.glb'
    export_ranwar_vehicles = 'vehicles'
    export_ranwar_arrival = 'arrival'
    export_ranwar_contacts = 'contacts'
}
foreach ($name in $exports.Keys) {
    $exporter = (Resolve-Path "unreal/Tools/$name.gd").Path
    & $godot --headless --path prototype --script $exporter -- (Join-Path $exchange $exports[$name])
    if ($LASTEXITCODE -ne 0) { throw "$name failed." }
}

$blender = 'C:/Program Files/Blender Foundation/Blender 5.3/blender.exe'
& $blender -b --factory-startup --python-exit-code 1 --python unreal/Tools/build_ranwar_exchange.py -- --source "$exchange/ranwar-source.json" --repo-root . --output $exchange
if ($LASTEXITCODE -ne 0) { throw 'Ranwar exchange build failed.' }
```

The remote Blender stage needs only `build_ranwar_exchange.py`, the scene JSON, and the referenced files under `prototype/world/textures/`. Run the Blender command from the remote checkout or set `--repo-root` to a directory with that relative structure. Copy back `ranwar-level.json`, the FBX sections, and the PNG texture folder. The source JSON and the resulting files are working artifacts under the ignored build directory.

## Import the playable level

With the native MumbaiPilot Editor module compiled in UE 5.8, run `unreal/Tools/create_ranwar_level.py` through Unreal Editor Python. The importer needs `ranwar-level.json`, the street sections and textures, `omkar.glb`, and the `vehicles/`, `arrival/` and `contacts/` exchanges under `builds/local/unreal-ranwar/`. Launch the licensed Unreal editor with the project and `-ExecutePythonScript`, using absolute project and script paths.

```powershell
$project = (Resolve-Path 'unreal/AamchiMumbaiUnreal.uproject').Path
$script = (Resolve-Path 'unreal/Tools/create_ranwar_level.py').Path
& $UnrealEditor $project "-ExecutePythonScript=$script" -log
```

The importer checks each FBX hash, verifies the Unreal axis registration and centimetre scale against the ground mesh and all section bounds, and uses Unreal PBR materials with the supplied textures and vertex tint. It brings in authored wall, floor, doorway, and boundary collision as a dedicated static mesh. The generator creates `/Game/Ranwar/RanwarStreet` and guards an existing map from overwrite. Open that map before using Play In Editor.

The importer registers mission waypoints, parking bays, the bus and arrival cast against the same streets. It brings over the source road directions for the native ambient traffic. The game saves parcel checkpoints in its own Unreal save directory.

Ravi and Kavita each use the original 21-joint cast rig, one skinned surface and a separate breathing loop and handover motion in `/Game/Ranwar/Characters/Contacts/`. The exporter samples the project's existing idle pose and uses weighted shoe vertices to place both motion clips on the same ground plane. The native contact capsule follows the authored map position and the appearance turns toward nearby visitors. A successful interaction triggers the temporary handover gesture. The saved mission and voiced dialogue still use the common route transitions. The earlier posed contact meshes supply a fallback for existing maps. [Grounded pose generation](../../prototype/character/parcel_contact_motion.gd) · [Native contact actor](../Source/MumbaiPilot/RanwarParcelContact.cpp)

## SandbarCity street furniture and facade finish

Stage the credited CC0 input packages before refreshing the map. The game resolves the original Unreal package paths. An unstaged checkout still uses the existing Ranwar finish and furniture.

```powershell
& '.\unreal\Tools\stage_sandbar_street_assets.ps1' -ContentRoot 'C:\Path\To\SandbarCity\Content'
```

The importer places a timber bench and service cabinet behind the BEST shelter using their DirectX 11 fallback geometry and simple collision. Blender separates photographed plaster, stucco and tower concrete surfaces from the authored palette. Unreal binds each texture set at a maximum 1024 pixels per map. The same exchange plans roof fittings inside the actual footprint polygons, leaves space around authored equipment, and marks street-facing positions for awnings and rain decals. The importer duplicates reviewed Sandbar meshes into the Ranwar namespace and assigns native DirectX 11 materials. The source packages remain byte-for-byte intact. [Third-party ledger](../../docs/THIRD_PARTY.md#sandbarcity-unreal-intake)

## Owned Fab street dressing and Kavita's ponytail

The 25 November Fab intake came from the project owner's My Library on epyc24. Stage the three prepared Quixel GLBs in the ignored `builds/local/unreal-ranwar/street-life/` directory. Match the `fab_wood_ladder`, `fab_canvas_sandbags`, and `fab_coconut` manifest entries to the respective GLB filenames and SHA-256 digests. All three meshes use floor-centered pivots and embedded 1024 px base color, normal and packed occlusion, roughness and metallic maps. The map importer grounds the shopfront dressing against the Ranwar floor and gives it no collision.

The optional `contacts/Kavita-Fab-Ponytail.glb` in the same exchange contains WhiteCap LOD4 hair cards fitted to Kavita's original head joint. Unreal imports it with the canonical contact skeleton, keeps the existing body material and uses a separate masked hair material. The standard contact animations and their bindings are shared. A map refresh without the private Fab inputs uses the existing contact and street dressing. [Asset credits and license](../../docs/THIRD_PARTY.md#adopted-third-party-code-and-shipping-assets)

For a native Fab MetaHuman package, download the original `.mhpkg` through **My Library** on Fab.com. Use **Import** in the Content Browser of a separate UE 5.8 project with the MetaHuman Creator and MetaHuman SDK plugins enabled. Install the optional **MetaHuman Creator Core Data** from the UE 5.8 Launcher's **Options** before importing an editable character so Unreal can resolve its default hair and wardrobe. Review the assembled asset's rig and card-based hair before adapting it to Ranwar's playable character. [Epic Fab MetaHuman workflow](https://dev.epicgames.com/documentation/metahuman/buying-metahumans-from-fab) · [Epic Creator setup](https://dev.epicgames.com/documentation/metahuman/getting-started-with-metahuman-creator-in-unreal-engine?application_version=5.8)

## Detailed two-wheeler visuals

Download the credited Scooter and Street Motorcycle GLBs to a working directory. Generate the optional Unreal visual exchange with Python and Pillow before refreshing the map.

```powershell
python unreal/Tools/build_ranwar_vehicle_visuals.py 'C:\Path\To\VinishSources' builds/local/unreal-ranwar/vehicles/visuals
```

The original four vehicle exchange files are required. The optional visual profiles fit the two detailed models to the existing vehicle chassis and preserve independent steering and wheel rotation. [Vinish model sources and license](https://vinish.dev/free-3d-models/motorcycles)

## Reusable model library and title art

The map refresh imports the 11 documented original model studies, the adopted Indian street shop and the local Bandra-Worli Sea Link study when its exchange file is available. Look for them under `/Game/ModelLibrary` in Unreal Editor. Input GLBs must contain their geometry and images. The importer records the source SHA-256 on each static mesh and reuses the current import when the source is unchanged. The studies stay available for scene dressing and review. Only map references and the explicit cook paths enter the game automatically. Review scale, collision, materials, source credit and placement before assigning a study to the street. [Asset acceptance](../../docs/ASSET_PRODUCTION_PLAN.md) | [Third-party notices](../../docs/THIRD_PARTY.md)

The original Godot title artwork and rickshaw mark supply the Unreal menu. `ContentSource/UI/title-backdrop.jpg` is a JPEG conversion of `prototype/startup/art/mumbai-dusk.webp`. `Content/Splash/Splash.bmp` is a 720 x 405 conversion of the same image for Unreal's Windows startup splash. Both are checked in so normal builds can use them directly. The level rebuild generates the two runtime title textures under `/Game/Ranwar/UI`. [Brand guide](../../docs/BRAND.md)

## Native daylight and practical lights

An unpaused Ranwar session begins at 10:30 and advances one in-game minute per second. The sky atmosphere, sun, cool night fill, camera exposure and height haze transition together. Ten streetlights cover selected points on Hill Road, St Peter’s Road and both Waroda Road segments. Lenses light up at dusk, including the warmer fixture under the BEST shelter. The Hill Road Tea Room and Chapel Corner Grocer each have a shadow-casting ceiling spotlight and a softer entrance fill. Sunlight uses short contact shadows for curbs and door recesses, while painted plaster and stucco have a darker weathered strip near the ground. [Native clock](../Source/MumbaiPilot/RanwarEnvironment.cpp) · [Epic contact shadows](https://dev.epicgames.com/documentation/unreal-engine/contact-shadows-in-unreal-engine)

The importer generates one original 512 × 512 cloud mask and one non-solid batch of distant silhouette buildings. The horizon and light fixtures are authored scenery. Use the existing street, door and parcel routes when reviewing them. [Environment importer](../Tools/create_ranwar_environment.py) · [Epic exponential height fog](https://dev.epicgames.com/documentation/unreal-engine/exponential-height-fog-in-unreal-engine)

For matched development captures, keep the camera and resolution fixed and add `-RanwarTime=630` for 10:30, `-RanwarTime=1050` for 17:30 or `-RanwarTime=1290` for 21:30. The flag freezes the clock for the run. The `AamchiMumbai.Ranwar.Playable` smoke accepts `-RanwarClockSmoke` to exercise the phase transitions, lamp states and live clock on a fresh scratch profile. Run `make-dev.ps1 -RefreshMap -SmokeTest` after editing the environment importer. [Windows build workflow](../../docs/BUILD_WORKFLOW.md)

## Sources

The map and the original geometry preserve the source project attribution and gameplay offsets. The imported material response approximates the Godot surface shader with per-triangle material finishes, vertex tint, UVs, color and normal textures. See the existing [world record](../../prototype/world/README.md), [OpenStreetMap data offer](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/ATTRIBUTION.md), [third-party notices](../../docs/THIRD_PARTY.md), and [Unreal FBX static-mesh pipeline](https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine).

## Native cast assets

The private Unreal cast uses assembled MetaHuman revisions `r004` through `r006`. The project looks for them under `unreal/Content/OmkarAssembled/`. The original Godot-derived rig and cast are available when the private packages are absent. Keep Fab Standard License assets in private project storage alongside the generated Ranwar map and exchange. The public source includes the gameplay and import tools. [Fab Standard License](https://www.fab.com/eula) · [MetaHuman licensing](https://www.metahuman.com/license)
