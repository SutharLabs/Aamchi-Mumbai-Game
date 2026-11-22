# Aamchi Mumbai Game · Phase 1 playtest

Walk and drive around Ranwar, Bandra West, in present-day Mumbai. Four drivable vehicles start in marked bays near the starting point. From the car, head left past the auto-rickshaw to find the motorcycle and scooter. The route includes a walking shortcut and an open handling yard. [Route and source notes](world/README.md)

Open `project.godot` in Godot 4.7.2 standard and press **F6** from `phase1.tscn` or **F5** to run the project. The local Windows debug export is `../builds/phase-1/Aamchi Mumbai Game.exe`.

| Input | Action |
|---|---|
| **WASD** or **arrows** | Walk, or steer and control speed while driving. |
| **Mouse** | Look around. Escape releases the pointer and a click captures it again. |
| **E** | Get in or mount the nearest vehicle. Stop and press again to exit. |
| **Space** | Brake while driving. |
| **R** | Return on foot and put all four vehicles back in their bays. |
| Touch controls | Walk or drive with the left stick, drag the right side to look, and use Interact, Brake and Reset. |

Follow Hill Road from the start toward St Peter's approach, turn onto St Peter's Road and follow Waroda Road back. The Nagrana shortcut has a narrow bollard gap for walking. The handling yard west of the spawn includes a raised ramp, a curb and a barrier. For the road topology and coordinates, see [layout.json](world/layout.json).

## Local smoke check and export

From the repository root with the downloaded portable editor and its matching standard templates in `.toolchain`:

```powershell
$editor = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& $editor --headless --path prototype --fixed-fps 60 --quit-after 5000 --script res://tests/phase1_smoke.gd -- --touch-preview
New-Item -ItemType Directory -Force -Path '.\builds\phase-1' | Out-Null
$exe = Join-Path (Get-Location) 'builds\phase-1\Aamchi Mumbai Game.exe'
& $editor --headless --path prototype --export-debug 'Windows Desktop' $exe
```

The smoke script exercises walking, all four vehicles, steering and braking, exit clearance, reset, the ramp, road clearances and simulated concurrent touch. `--touch-preview` also enables the overlay on a desktop build. Keep the accompanying Godot and OpenStreetMap notices with the executable.

The auto-rickshaw has tighter steering and a lower top speed than the car. The motorcycle has a straddled rider pose and more speed for the open yard. The scooter has a step-through pose and tighter steering for slow turns. Both two-wheelers lean visually through turns and use upright arcade collision bodies. Their procedural geometry and rider poses are placeholders. Android export, physical-device touch, minimum-spec performance, and fresh-player testing remain open. [Vehicle notes](vehicle/README.md) · [Phase tracker](../docs/PHASE_PROGRESS.md)
