# Aamchi Mumbai Game · Phase 1 playtest

The first prototype is a walking and driving practice route around the Ranwar reference area. It uses an amber arcade car, simple building masses, a walking shortcut, and a handling yard. The world notes record the road sources and authored dimensions. [Route and source notes](world/README.md)

Open `project.godot` in Godot 4.7.2 standard and press **F6** from `phase1.tscn` or **F5** to run the project. The local Windows debug export is `../builds/phase-1/Aamchi Mumbai Game.exe`.

| Input | Action |
|---|---|
| **WASD** or **arrows** | Walk. In the car, steer, accelerate, or reverse. |
| **Mouse** | Look around. Escape releases the pointer and a click captures it again. |
| **E** | Enter the amber car from nearby. Stop and press again to get out. |
| **Space** | Brake while driving. |
| **R** | Return on foot with the car parked at the start. |
| Touch controls | Walk or drive with the left stick, drag the right side to look, and use Interact, Brake and Reset. |

Follow Hill Road from the start toward St Peter's approach, turn onto St Peter's Road and follow Waroda Road back. The Nagrana shortcut has a narrow bollard gap for walking. The handling yard west of the spawn includes a raised ramp, a curb and a barrier. For the road topology and coordinates, see [layout.json](world/layout.json).

## Local smoke check and export

From the repository root with the downloaded portable editor and its matching standard templates in `.toolchain`:

```powershell
$editor = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& $editor --headless --path prototype --fixed-fps 60 --quit-after 1100 --script res://tests/phase1_smoke.gd -- --touch-preview
New-Item -ItemType Directory -Force -Path '.\builds\phase-1' | Out-Null
$exe = Join-Path (Get-Location) 'builds\phase-1\Aamchi Mumbai Game.exe'
& $editor --headless --path prototype --export-debug 'Windows Desktop' $exe
```

The smoke script exercises the integrated walking/driving loop, moving and blocked exit conditions, reset, ramp climb, route collision clearances and simulated concurrent touch events. `--touch-preview` also enables the overlay on a desktop build. Keep the accompanying Godot and OpenStreetMap notices with the executable.

The current build uses a single original car and an open greybox. The route uses modern OSM geometry and authored clearances. Historical buildings, Android export, physical-device touch behavior, minimum-spec performance and the other vehicle families remain open for later work. [Phase tracker](../docs/PHASE_PROGRESS.md)
