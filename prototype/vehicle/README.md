# Phase 1 arcade vehicles

`preload("res://vehicle/phase1_car.gd").new()` and `preload("res://vehicle/phase1_rickshaw.gd").new()` each construct a complete vehicle, original primitive body, and collision shape. Both extend `phase1_vehicle.gd`, which owns the shared typed arcade movement/reset/input contract. No imported assets, plugins, file/network access, credentials, or external dependencies are used.

The car faces local **-Z**. A spawn origin around **y = 0.55 m** places the chassis just above a flat road at y = 0. Collision is a 1.64 × 0.92 × 3.80 m box centered at local y = -0.04 m: local bounds x ±0.82, y -0.50…0.42, z ±1.90 m. The visual roof extends above the collider, to local y ≈0.95. Wheels extend to approximately x ±0.93.

API:

- `set_driver_active(bool)`: enables controls; disabling parks horizontal movement immediately.
- `set_controls(throttle: float, steering: float, brake: bool)`: throttle -1 reverse / +1 forward; steering -1 left / +1 right. Values are finite-checked and clamped. Input mapping and touch UI belong to the caller.
- `get_speed_mps() -> float`: absolute horizontal speed.
- `reset_to(Transform3D)`: zeros motion and controls, preserves the supplied heading while restoring upright orientation. The caller supplies an unobstructed grounded pose. Invalid transforms are rejected. The latest reset pose becomes the fall-recovery pose.
- `vehicle_label: String`, `exit_side_offset: float`, and `follow_distance: float`: integration properties for prompts, safe exit placement, and chase-camera distance. Car values are `Car`, 1.48 m, 6.9 m; auto values are `Auto-rickshaw`, 1.30 m, 6.2 m.

Physics layer values: world **1**, walking player **2**, vehicles **4**. Both vehicles use layer 4 and mask **1|2|4**, including peer vehicles. The caller must remove/disable the mounted walking player's collision so the driver does not collide with the vehicle. Ground/exit raycasts should exclude the vehicle or use only the world layer.

Initial tuning: 18 m/s forward (64.8 km/h), 5 m/s reverse, 8 m/s² acceleration, 16 m/s² braking, 2.8 m/s² coasting drag. Steering is speed-scaled, softer at high speed, reversed while backing, and disabled at rest/in air. Gravity, floor snap, and `move_and_slide()` provide grounded collision without a drivetrain/suspension simulation. A fall below y=-25 returns to the last known reset pose.

Meaningful acceptance cases: positive throttle travels along local -Z; right steering turns toward local +X; backing reverses steering response; braking from maximum speed stops in roughly 1.13 s / 10.1 m on flat ground before collision effects; walls remove retained forward speed; blocked contacts remain finite; reset clears motion and driver deactivation parks the car. Repeat at 30/60 rendering FPS with the same physics rate, over slopes and the planned narrow passages. The car body remains an arcade placeholder. Production art needs a sourced current Mumbai vehicle reference and its own acceptance check.

## Focused check receipt — 22 November 2026

Godot 4.7.2 standard console passed `--check-only` on this script. An isolated headless floor/wall fixture passed at fixed rendering cadences of 30 and 60 with the same physics rate. At both cadences: 180 forward ticks reached z=-33.9000 m and 18.0 m/s; braking stopped within 9.9756 m; reverse capped at 5.0 m/s with opposite yaw response; right steering moved toward +X; a wall centered at z=-8 stopped the car center at z=-5.5733. Upright/zero-velocity reset, non-finite control rejection, fall recovery, and parking on driver deactivation passed. The temporary harness is under `.toolchain/car_contract_check.gd` and is not a runtime dependency.

These checks exercise the standalone movement contract, not the final neighborhood, rendered appearance, slope handling, Android touch controls, or minimum-device frame pacing. Those need the integrated prototype and real devices.

## Contemporary auto-rickshaw

The second original study has a black body, yellow canopy, visibly open side entrances, a driver seat/handlebar, a rear bench, one steered front wheel and two rear wheels. It has no manufacturer badge or copied mesh/texture. Its whole-cabin collider is **1.30 × 1.65 × 2.70 m**, centered at local y=0.325, with local bottom -0.50 and top 1.15. A y=0.55 spawn puts its roof near 1.70 m above the road; the wheels use a 2.0 m front/rear spacing.

Gameplay tuning is intentionally forgiving: 13 m/s forward, 3.5 m/s reverse, 5.8 m/s² acceleration, 12 m/s² braking, and 3.3 m/s² coasting deceleration. It turns more sharply at low speed than the car, softens steering toward maximum speed, cannot pivot while stationary, and remains upright through the kinematic controller. These are **gameplay targets**, not measured Bajaj performance or a three-wheel suspension/rollover simulation.

### Reference evidence checked 22 November 2026

- [Bajaj RE official model page](https://www.bajajauto.com/three-wheelers/re) supplies contemporary passenger-auto imagery and variant information. The search-indexed [specification subpage](https://www.bajajauto.com/three-wheelers/re/specifications) reports 2,635 × 1,300 × 1,700 mm / 2,000 mm wheelbase, but direct retrieval returned 404 during this check. Those indexed values are a reference lead awaiting a selected-variant brochure, not independently verified dimensions of this generic model. The 2.70 m collision length above is a deliberate prototype target.
- [Mumbai airport operator transport guidance](https://csmia-mumbai.adaniairports.com/en/airport-facilities/transport) describes metered autos in Mumbai's suburbs, reaching Bandra west and Sion centrally. This supports a suburban/Bandra context; precise boundary-road permissions still need separate validation.

The model is an original generic contemporary Mumbai auto study. It is not an exact RE replica, a survey, a licensed branded model, or proof of the final reference vehicle's proportions/materials. No reference image was copied into the game. Contemporary references follow the user's latest setting choice; the older period-specific note above describes the earlier car receipt only.

### Shared-controller / auto check receipt

All three scripts pass Godot 4.7.2 `--check-only`. The existing standalone car contract still passes after extraction: 18.0 m/s forward, approximately 9.9756 m braking distance, correct steering/reverse, frontal-wall stop, reset and recovery. The current base preserves the integrated prototype's seam fix: grounded vertical velocity is zero and `floor_constant_speed` is not forced on.

The auto contract passes at fixed 30 and 60 rendering cadences with identical results: 180 forward ticks reach z=-24.5392 m at 13.0 m/s; braking stops in 6.9333 m; reverse caps at 3.5 m/s; right steering moves toward +X. A parked car at z=-12 blocks the auto at z=-8.74955 without moving the parked car. Three-wheel/one-steered-wheel count, upright reset, finite-control rejection, fall recovery, and parking pass. Temporary harness: `.toolchain/rickshaw_contract_check.gd`. Integrated route/ramp/entry-exit tests and actual Windows/Android device performance are separate evidence.
