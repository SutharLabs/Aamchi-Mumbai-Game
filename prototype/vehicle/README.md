# Phase 1 arcade vehicles

`phase1_car.gd`, `phase1_rickshaw.gd`, `phase1_motorcycle.gd`, and `phase1_scooter.gd` each construct a vehicle with an original procedural body and collision shape. They share movement, reset and input through `phase1_vehicle.gd`. The motorcycle and scooter also share rider geometry and visual lean through `phase1_two_wheeler.gd`.

The vehicles face local **−Z**. A spawn origin around **y = 0.55 m** places the chassis just above a flat road at y = 0. The car uses a 1.64 × 0.92 × 3.80 m collider centered at local y = −0.04 m. The roof and other fine details use separate render geometry.

API:

- `set_driver_active(bool)`: enables controls; disabling parks horizontal movement immediately.
- `set_controls(throttle: float, steering: float, brake: bool)`: throttle -1 reverse / +1 forward; steering -1 left / +1 right. Values are finite-checked and clamped. Input mapping and touch UI belong to the caller.
- `get_speed_mps() -> float`: absolute horizontal speed.
- `reset_to(Transform3D)`: zeros motion and controls, preserves the supplied heading while restoring upright orientation. The caller supplies an unobstructed grounded pose. Invalid transforms are rejected. The latest reset pose becomes the fall-recovery pose.
- `vehicle_label: String`, `exit_side_offset: float`, and `follow_distance: float`: integration properties for prompts, safe exit placement, and chase-camera distance. Car values are `Car`, 1.48 m, 6.9 m; auto values are `Auto-rickshaw`, 1.30 m, 6.2 m.
- `is_two_wheeler: bool`: false on the car/auto, true on motorcycle/scooter. The two-wheeler class exposes `rider: Node3D`, `lean_visual: Node3D`, and `max_lean_radians: float` for integration and observable checks.

Physics layers use **1** for the world, **2** for the walking player and **4** for every vehicle. Vehicles use mask **1|2|4**, so they collide with parked vehicles too. The caller disables the walking player's collision while driving. Ground and exit raycasts should exclude the vehicle or use only the world layer.

Initial tuning: 18 m/s forward (64.8 km/h), 5 m/s reverse, 8 m/s² acceleration, 16 m/s² braking, 2.8 m/s² coasting drag. Steering is speed-scaled, softer at high speed, reversed while backing, and disabled at rest/in air. Gravity, floor snap, and `move_and_slide()` provide grounded collision without a drivetrain/suspension simulation. A fall below y=-25 returns to the last known reset pose.

Positive throttle travels along local −Z and right steering turns toward local +X. Backing reverses the steering response. A frontal collision removes retained forward speed, vehicle reset clears motion, and deactivation parks the vehicle. The shared controller uses an upright collision body for each of the four families.

## Curb handling

The original chassis stopped at the vertical face of an ordinary curb. The shared controller now checks a short lookahead during grounded travel. A nearby static-world face can trigger an upward sweep, a sweep across the edge, and a downward sweep onto a supported surface. The full chassis stays subject to clearance checks, with a maximum rise of 25 cm and a 28 cm floor snap for descents. A tall wall, a blocked landing, a low ceiling or a peer vehicle stays solid. The chase camera eases the height change across the step. [Godot motion sweeps](https://docs.godotengine.org/en/stable/classes/class_physicsbody3d.html#class-physicsbody3d-method-test-move) · [Godot floor snap](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html#class-characterbody3d-property-floor-snap-length)

The regression route crosses the existing 14 cm Hill Road curb and returns to ground level. The handling yard provides a 22 cm reverse crossing, a low-overhang test fixture and a solid wall. The yard ramp remains part of the smoke test. An automated drive also completed a lap through all 21 Ranwar road waypoints. [World layout](../world/README.md) · [Playtest guide](../README.md)

## Current vehicle art

The render meshes use original shaped profiles, rounded tires, fitted glazing and separate paint, rubber, fabric or metal surfaces. Review them against the [visual direction](../../docs/ASSET_PRODUCTION_PLAN.md#visual-direction-and-review).

- **Car.** A tall urban hatchback with crowned roof, shaped arches, sloped glass and a 2.43 m visual wheelbase. The parked model has 4,900 triangles across 55 mesh instances. [Maruti Suzuki WagonR shape and proportions](https://www.marutisuzuki.com/arena/wagon-r)
- **Auto-rickshaw.** An open-sided passenger auto with a curved yellow canopy, round cowl, visible bench and a 1.99 m visual wheelbase. The parked model has 6,420 triangles across 70 mesh instances. Entering it shows a seated driver using the player rig, adding 2,024 triangles. The export-market open-sided RE brochure supplies a 2.0 m reference wheelbase. [Bajaj RE India](https://www.bajajauto.com/three-wheelers/re) · [Bajaj open-sided RE brochure](https://www.bajajauto.com/en-co/-/media/globalbajajauto/common-media/brochure/3wheelers/bajaj-re-4s-petrol-without-door-xl-brochure.pdf)
- **Motorcycle and scooter.** The motorcycle has an exposed engine, shaped fuel tank and rounded mudguards. The scooter has a curved rear shell, open footwell and rounded front apron. Both have fitted rims, steering-linked front components and a skinned helmeted rider with hand placement tied to the grips. Motorcycle geometry uses 6,420 triangles parked and 8,704 ridden. Scooter geometry uses 4,680 triangles parked and 6,964 ridden. [Hero Splendor+](https://www.heromotocorp.com/en-in/motorcycles/splendor-plus.html) · [Suzuki Access](https://www.suzukimotorcycle.co.in/product-details/all-new-access-125-bluetooth-enabled/features)

The design uses unbranded procedural meshes. The Iris Xe review covered front, side and rear or three-quarter views. Populated-scene and minimum-device performance still require measurement.

## Baseline controller receipt — 22 November 2026

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

## Contemporary motorcycle and scooter

Both new vehicles face local −Z and spawn at y = 0.55 m. The shared controller handles steering and wheel rotation. The visible body and rider lean into the turn while the collision body stays upright. Both vehicles have a slow backward maneuver for parking.

| Vehicle | Collider width × height × length (center Y) | Forward / reverse limit | Acceleration / braking | Visual lean cap | Exit / camera distance |
|---|---|---|---|---|---|
| Motorcycle | 0.74 × 1.88 × 2.05 m (0.44 m) | 20 / 2 m/s | 8.8 / 15 m/s² | 22° | 1.05 / 5.9 m |
| Scooter | 0.70 × 1.90 × 1.90 m (0.45 m) | 14 / 1.8 m/s | 6.8 / 13 m/s² | 16° | 1.00 / 5.6 m |

Both colliders cover the seated rider and extend down to local y = −0.50 m. The motorcycle uses an exposed engine, fuel tank, narrow seat, larger wheels and footpegs. The scooter has smaller wheels, an enclosed rear body, low floorboard and front leg shield. Motorcycle steering softens at speed. The scooter is tuned for tight low-speed turns. The table records prototype handling and collision dimensions.

Each vehicle shows its helmeted rider while `driver_active`. The motorcycle rider straddles the tank with feet on the pegs. The scooter rider sits upright with both feet forward on the floorboard. Hands follow the steering grips. The prototype switches directly between the seated and walking poses. Reset immediately zeros visual lean. Parking eases the vehicle back upright.

### Two-wheeler references checked 22 November 2026

- The Splendor+ informed the red motorcycle's proportions and exposed-engine layout. The manufacturer lists a 2,000 mm length, 720 mm width, 1,052 mm vehicle height, 785 mm saddle height and 1,236 mm wheelbase. [Hero Splendor+ specifications](https://www.heromotocorp.com/en-in/motorcycles/splendor-plus.html)
- The Access informed the blue scooter's step-through layout and smaller wheels. The manufacturer lists a 1,835 mm length, 680 or 690 mm width by variant, 1,155 mm vehicle height and 1,260 mm wheelbase. [Suzuki Access specifications](https://www.suzukimotorcycle.co.in/product-details/all-new-access-125-bluetooth-enabled/features)

Both models are original, unbranded procedural interpretations. Production model selection still needs current Bandra reference evidence.

### Baseline two-wheeler check receipt

All three new scripts pass Godot 4.7.2 parse checks. An isolated constructor/tree check confirms each concrete vehicle attaches its visual/rider tree, sets `is_two_wheeler`, starts with its rider hidden, and frees without orphaned nodes/resources. Constructors call `super()` explicitly through the inheritance chain.

The standalone movement and presentation checks passed at fixed 30 and 60 frame cadences. The motorcycle reached 20.0 m/s, stopped in 13.17 m and showed 21.60° of lean during the steering check. The scooter reached 14.0 m/s, stopped in 7.42 m and showed 15.71° of lean. The tests also covered front steering, wheel roll, parking assist, rider visibility, upright collision, reset and rejection of non-finite inputs. The local harness is `.toolchain/two_wheeler_contract_check.gd`.

Front and side renders on the Iris Xe development PC showed both riders facing forward with their hands on the controls and legs in their intended poses. The local captures are in `.toolchain/two-wheeler-preview/`. Minimum-device frame pacing, Android hardware testing and production rider animation remain open.
