# Captured locomotion

`phase1_motions.tres` is an adapted subset of the **100STYLE Dataset** by Ian Mason, Sebastian Starke and Taku Komura. Ian Mason's dataset page provides the individual Neutral takes and credits the capture work. The source captures and the adapted clips are available under CC BY 4.0. Include this attribution and the license link when distributing the clips. [Dataset and credits](https://www.ianxmason.com/100style/) · [Archival record](https://zenodo.org/records/8127870) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

| Godot clip | Source take | Source frames (zero-based, inclusive) | Loop duration | Retargeted natural speed |
|---|---|---:|---:|---:|
| `idle` | `Neutral_ID.bvh` | 796–970 | 2.900 s | Stationary |
| `walk` | `Neutral_FW.bvh` | 524–604 | 1.333 s | 0.893 m/s |
| `run` | `Neutral_FR.bvh` | 501–547 | 0.767 s | 1.743 m/s |

The converter trims the takes, retargets their joints to the prototype rig, and samples at 30 Hz from the 60 Hz captures. It removes horizontal root travel and the capture heading, retains vertical pelvis motion, calibrates shoe height and closes the loop seams. Runtime playback uses Godot's `AnimationPlayer` and targets the rig's `Skeleton3D` bone paths. Character movement and collision use the gameplay controller.

## Regenerate

Download the three original Neutral BVH files from the dataset page and put them in `.toolchain/mocap-sources` without renaming them. From the project root, run:

```powershell
python tools/mocap/retarget_100style.py .toolchain/mocap-sources
```

The converter verifies the source files against their reviewed SHA-256 hashes. The game uses the small generated library in this folder. [Converter](../../../tools/mocap/retarget_100style.py)
