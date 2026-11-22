# Aamchi Mumbai Game · Phase 1 playtest

Walk and drive around Ranwar, Bandra West, in present-day Mumbai. Four drivable vehicles start in marked bays near the starting point. From the car, head left past the auto-rickshaw to find the motorcycle and scooter. The route includes a walking shortcut and an open handling yard. [Route and source notes](world/README.md)

The player uses captured idle, walk and jog clips on an original skinned humanoid. Two pedestrians use the same captured walk along the western Hill Road sidewalk and eastern frontage. [100STYLE motion credits](character/motion/100STYLE-ATTRIBUTION.txt)

Open `project.godot` in Godot 4.7.2 standard and press **F6** from `phase1.tscn` or **F5** to run the project. The local Windows debug export is `../builds/phase-1/Aamchi Mumbai Game.exe`.

| Input | Action |
|---|---|
| **WASD** or **arrows** | Walk, or steer and control speed while driving. |
| **Shift** with movement | Jog on foot. |
| **Mouse** | Look around. Escape releases the pointer and a click captures it again. |
| **E** | Get in or mount the nearest vehicle. Stop and press again to exit. |
| **Space** | Brake while driving. |
| **R** | Return on foot and put all four vehicles back in their bays. |
| Touch controls | Walk or drive with the left stick, drag the right side to look, and use Interact, Brake and Reset. |

Follow Hill Road from the start toward St Peter's approach, turn onto St Peter's Road and follow Waroda Road back. The Nagrana shortcut has a narrow bollard gap for walking. The handling yard west of the spawn includes a raised ramp, a curb and a barrier. For the road topology and coordinates, see [layout.json](world/layout.json).

To try the curb crossing, drive slowly across the raised west-side curb on Hill Road. All four can climb the curb and come down to street or yard level. The handling yard also has a 22 cm test curb and a solid impact wall. The driving camera softens changes in height as the vehicle crosses the curb. [Vehicle handling notes](vehicle/README.md)

## Local smoke check and export

From the repository root with the downloaded portable editor and its matching standard templates in `.toolchain`:

```powershell
$editor = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& $editor --headless --path prototype --fixed-fps 60 --quit-after 5000 --script res://tests/phase1_smoke.gd -- --touch-preview
New-Item -ItemType Directory -Force -Path '.\builds\phase-1' | Out-Null
$exe = Join-Path (Get-Location) 'builds\phase-1\Aamchi Mumbai Game.exe'
& $editor --headless --path prototype --export-debug 'Windows Desktop' $exe
Copy-Item 'prototype/character/motion/100STYLE-ATTRIBUTION.txt' 'builds/phase-1/'
```

The smoke script exercises captured locomotion, all four vehicles, steering and braking, exit clearance, reset, the ramp, road clearances and simulated concurrent touch. `--touch-preview` also enables the overlay on a desktop build. Keep the Godot, OpenStreetMap and 100STYLE notices with the executable.

The car, auto-rickshaw, motorcycle and scooter use shaped, unbranded vehicle models. The two-wheelers have distinct skinned rider poses, with hands following the steering grips and visual lean on upright arcade collision bodies. Android export, physical-device touch, minimum-spec performance and fresh-player testing remain open. [Vehicle notes](vehicle/README.md) · [Phase tracker](../docs/PHASE_PROGRESS.md)
