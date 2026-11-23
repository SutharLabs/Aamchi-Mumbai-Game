# Ranwar Street exchange

The Unreal walking level uses the same OSM-derived Ranwar roads and the same authored neighborhood meshes as the Godot playtest. It starts at St Peter's Church BEST stop on Hill Road, with the Nagrana Lane link, both walk-in shops, and the current district closures. Native Unreal landmark actors identify the arrival stop, public landmarks, shop entrances, and map and asset credits.

## Build the exchange

From the repository root, run the pinned Godot console editor and Blender 5.3.0.

```powershell
$godot = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
$exporter = (Resolve-Path 'unreal/Tools/export_ranwar_source.gd').Path
$exchange = Join-Path (Get-Location).Path 'builds/local/unreal-ranwar'
& $godot --headless --path prototype --script $exporter -- (Join-Path $exchange 'ranwar-source.json')
if ($LASTEXITCODE -ne 0) { throw 'Ranwar source export failed.' }

$blender = 'C:/Program Files/Blender Foundation/Blender 5.3/blender.exe'
& $blender -b --factory-startup --python-exit-code 1 --python unreal/Tools/build_ranwar_exchange.py -- --source "$exchange/ranwar-source.json" --repo-root . --output $exchange
if ($LASTEXITCODE -ne 0) { throw 'Ranwar exchange build failed.' }
```

The remote Blender stage needs only `build_ranwar_exchange.py`, the scene JSON, and the referenced files under `prototype/world/textures/`. Run the Blender command from the remote checkout or set `--repo-root` to a directory with that relative structure. Copy back `ranwar-level.json`, the FBX sections, and the PNG texture folder. The source JSON and the resulting files are working artifacts under the ignored build directory.

## Import the walking level

With the native MumbaiPilot Editor module compiled in UE 5.8, run `unreal/Tools/create_ranwar_level.py` through Unreal Editor Python. The importer looks for `builds/local/unreal-ranwar/ranwar-level.json`, with optional `omkar.glb` next to it. Launch the licensed Unreal editor with the project and `-ExecutePythonScript`, using absolute project and script paths.

```powershell
$project = (Resolve-Path 'unreal/AamchiMumbaiUnreal.uproject').Path
$script = (Resolve-Path 'unreal/Tools/create_ranwar_level.py').Path
& $UnrealEditor $project "-ExecutePythonScript=$script" -log
```

The importer checks each FBX hash, verifies the Unreal axis registration and centimetre scale against the ground mesh and all section bounds, and uses Unreal PBR materials with the supplied textures and vertex tint. It brings in authored wall, floor, doorway, and boundary collision as a dedicated static mesh. The generator creates `/Game/Ranwar/RanwarStreet` and guards an existing map from overwrite. Open that map before using Play In Editor.

The exchange ships static geometry and registration data. Unreal gameplay development includes the separate third-person controller and landmark interaction. The Godot missions, traffic, story timing, and save state need their own migration and acceptance checks.

## Sources

The map and the original geometry preserve the source project attribution and gameplay offsets. The imported material response approximates the Godot surface shader with per-triangle material finishes, vertex tint, UVs, color and normal textures. See the existing [world record](../../prototype/world/README.md), [OpenStreetMap data offer](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/ATTRIBUTION.md), [third-party notices](../../docs/THIRD_PARTY.md), and [Unreal FBX static-mesh pipeline](https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine).
