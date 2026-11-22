# Phase 1 arcade car

`preload("res://vehicle/phase1_car.gd").new()` constructs the entire car, including its original primitive placeholder and collision shape. No imported assets, plugins, file/network access, credentials, or external dependencies are used.

The car faces local **-Z**. A spawn origin around **y = 0.55 m** places the chassis just above a flat road at y = 0. Collision is a 1.64 × 0.92 × 3.80 m box centered at local y = -0.04 m: local bounds x ±0.82, y -0.50…0.42, z ±1.90 m. The visual roof extends above the collider, to local y ≈0.95. Wheels extend to approximately x ±0.93.

API:

- `set_driver_active(bool)`: enables controls; disabling parks horizontal movement immediately.
- `set_controls(throttle: float, steering: float, brake: bool)`: throttle -1 reverse / +1 forward; steering -1 left / +1 right. Values are finite-checked and clamped. Input mapping and touch UI belong to the caller.
- `get_speed_mps() -> float`: absolute horizontal speed.
- `reset_to(Transform3D)`: zeros motion and controls, preserves the supplied heading while restoring upright orientation. The caller supplies an unobstructed grounded pose. Invalid transforms are rejected. The latest reset pose becomes the fall-recovery pose.

Physics layer values: world **1**, walking player **2**, car **4**. The car is on layer 4 and checks mask 1|2. The caller must remove/disable the mounted walking player's collision so the driver does not collide with the car.

Initial tuning: 18 m/s forward (64.8 km/h), 5 m/s reverse, 8 m/s² acceleration, 16 m/s² braking, 2.8 m/s² coasting drag. Steering is speed-scaled, softer at high speed, reversed while backing, and disabled at rest/in air. Gravity, floor snap, and `move_and_slide()` provide grounded collision without a drivetrain/suspension simulation. A fall below y=-25 returns to the last known reset pose.

Meaningful acceptance cases: positive throttle travels along local -Z; right steering turns toward local +X; backing reverses steering response; braking from maximum speed stops in roughly 1.13 s / 10.1 m on flat ground before collision effects; walls remove retained forward speed; blocked contacts remain finite; reset clears motion and driver deactivation parks the car. Repeat at 30/60 rendering FPS with the same physics rate, over slopes and the planned narrow passages. Placeholder body identity is not accepted historical vehicle art or proof of a period-specific model.

## Focused check receipt — 22 November 2026

Godot 4.7.2 standard console passed `--check-only` on this script. An isolated headless floor/wall fixture passed at fixed rendering cadences of 30 and 60 with the same physics rate. At both cadences: 180 forward ticks reached z=-33.9000 m and 18.0 m/s; braking stopped within 9.9756 m; reverse capped at 5.0 m/s with opposite yaw response; right steering moved toward +X; a wall centered at z=-8 stopped the car center at z=-5.5733. Upright/zero-velocity reset, non-finite control rejection, fall recovery, and parking on driver deactivation passed. The temporary harness is under `.toolchain/car_contract_check.gd` and is not a runtime dependency.

These checks exercise the standalone movement contract, not the final neighborhood, rendered appearance, slope handling, Android touch controls, or minimum-device frame pacing. Those need the integrated prototype and real devices.
