# Captured locomotion

`phase1_motions.tres` is an adapted subset of the **100STYLE Dataset** by Ian Mason, Sebastian Starke and Taku Komura. Ian Mason's dataset page provides the individual Neutral takes and credits the capture work. The source captures and the adapted clips are available under CC BY 4.0. Include this attribution and the license link when distributing the clips. [Dataset and credits](https://www.ianxmason.com/100style/) · [Archival record](https://zenodo.org/records/8127870) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

| Godot clip | Source take | Source frames (zero-based, inclusive) | Loop duration | Retargeted natural speed |
|---|---|---:|---:|---:|
| `idle` | `Neutral_ID.bvh` | 796–970 | 2.900 s | Stationary |
| `walk` | `Neutral_FW.bvh` | 524–604 | 1.333 s | 0.893 m/s |
| `run` | `Neutral_FR.bvh` | 501–547 | 0.767 s | 1.743 m/s |

The converter trims the takes, retargets their joints to the prototype rig, and samples at 30 Hz from the 60 Hz captures. It removes horizontal root travel and the capture heading, retains vertical pelvis motion, calibrates shoe height and closes the loop seams. Runtime playback uses Godot's `AnimationPlayer` and targets the rig's `Skeleton3D` bone paths. Character movement and collision use the gameplay controller.

## Captured jump and impact falls

Three one-shot clips use a single hop from `TwoFootJump_FW.bvh`. Takeoff uses source frames 710–720, air uses 720–736, and landing uses 736–748, with zero-based inclusive frames. The converter keeps the recorded leg and torso motion while removing travel and aligning the soles to the controller. The walking capsule supplies takeoff, flight and landing. Space or gamepad LB jumps on foot and brakes while driving. The touch button switches between Jump and Brake. Existing control overrides apply in both contexts. [100STYLE attribution](100STYLE-ATTRIBUTION.txt)

`cmu_falls.tres` uses Subject 90 Trial 16 (forward descent and hand contact, frames 415–487) and Trial 17 (backward slip, frames 333–449). The frame indices are one-based and inclusive. Both takes come from the 120 Hz CMU Acclaim recordings. The game samples the recorded spine and limb pose at 30 Hz, driven by the current swept-capsule posture. The collision direction chooses the closest matching fall orientation. The controller retains the knockback and ground contact, relaxes the lifted legs once grounded, and progresses back through the fall pose during recovery. The publisher allows commercial product use and prohibits selling the data directly. [Subject 90 trials](https://mocap.cs.cmu.edu/search.php?subjectnumber=90) · [CMU attribution](CMU-ATTRIBUTION.txt)

## Regenerate

Download the three original Neutral BVH files and `TwoFootJump_FW.bvh` from the dataset page. Download `90.asf`, `90_16.amc` and `90_17.amc` from CMU's Subject 90 page. Put the original files in `.toolchain/mocap-sources` with their filenames intact. From the project root, run the two converters.

```powershell
python tools/mocap/retarget_100style.py .toolchain/mocap-sources
python tools/mocap/retarget_cmu_impacts.py .toolchain/mocap-sources
```

The converter verifies the source files against their reviewed SHA-256 hashes. The game uses the small generated library in this folder. [Converter](../../../tools/mocap/retarget_100style.py)
