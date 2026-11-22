# Ranwar traversal world

Updated **22 November 2026** for the selected **present-day Mumbai** direction.

`phase1_world.gd` extends `Node3D` and builds local mesh/collision geometry in `_ready()`. Attach it below the game's main scene. The main project supplies lighting, camera, player, vehicles and UI.

Player start: `(0, 0.5, 5)`. Car start: `(0, 0.55, 0)`. Auto-rickshaw start: `(-3.4, 0.55, 0)`. Motorcycle start: `(-6.2, 0.55, 1)`. Scooter start: `(-8.7, 0.55, 1.5)`. All vehicles point along negative Z. The first road leaves the origin approximately along negative Z; follow its bends rather than driving indefinitely straight.

## Route and provenance

The blockout uses selected bend points from the downloaded modern OpenStreetMap reference loop: A (Hill/Waroda) -> B (Hill/St Peter's) -> C (Chapel/Waroda) -> D (Veronica/Waroda) -> A. Its source polyline is approximately 1,186.7 m. Nagrana E -> F is the approximately 70.5 m source footway. The script projects into a local metric plane and rotates the loop so the first leg starts forward from the spawn. It preserves approximate source scale and junction order; no intentional uniform scale compression is applied. Minor bends are simplified, and approximate coordinates are for gameplay inspection rather than surveying. See `layout.json` for reference waypoints and the handling-yard route.

Authoring changes: 14 m Hill carriageway, 10 m St Peter's approach, 8 m inner streets, 2.4 m footway, simplified junction pads, sidewalks/curbs, footway walls/bollards, a mix of background blockouts and the authored frontage sample, bounded recovery yard and barriers. These dimensions and buildings are gameplay additions, not measured local conditions. The authored sample uses original local building types and invented storefronts. Route labels identify the corresponding real approaches.

The modern source is an acquired mapping snapshot, not a surveyed current streetscape. Road access, authored widths, building frontages and permissions remain unverified. A present-day setting does not make the generic dressing a reconstruction of actual operating shops or named properties. This is a traversal toy, not a completed district.

Map data from **OpenStreetMap contributors**, under **ODbL 1.0**. Retain the raw extract, transformation details and data-offer obligations if distributing this derived layout. The source package includes the extract, attribution, license and candidate layout. [OpenStreetMap reference package](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) The frontage kit uses original geometry and shared materials.

## Map and asset placement

The current playable area covers the Ranwar pocket of Bandra West. The road and footway mesh uses selected bends and junctions from the saved OpenStreetMap extract. All 30 coordinate entries used by the game were checked against nodes on the corresponding five saved ways. The St Peter's Church site comes from its mapped footprint, with a designed setback and simplified building dimensions. The five fictional shops and seven village-house frontages are placed in authored lots along those streets. The shop parcels, practice bays, handling yard, street widths and curb geometry are authored gameplay elements. **Pause → Map** draws the same projected roads and Nagrana Lane footway with the paused position of Omkar or his active vehicle. Current parcel and street-condition checks are tracked separately. [Source map and acquisition](../../research/BANDRA_REFERENCE_AREA_AND_MAP.md)

## Left-hand lane graph

The traffic graph derives directed lane centers from the same projected centerlines and authored widths as the street mesh. It places lanes one quarter of the road width to the left of travel and joins legal successive roads through their shared endpoints. Junction turns use short cubic curves. The traffic graph leaves Nagrana as a walking connection. The road mesh uses white broken longitudinal markings on its authored asphalt. The lane convention and paint reference come from Indian guidance, with the exact markings on the modeled Mumbai streets still to be field-checked. [Motor Vehicles (Driving) Regulations, regulation 4](https://morth.gov.in/sites/default/files/Motor-Vehicle-Driving-Regulation-2017.pdf) · [MoRTH pavement marking circular](https://morth.nic.in/sites/default/files/circulars_document/Guidelines_for_Road_Pavement_Marking_circular_dated_07.01.2019.pdf)

| Road | Snapshot tag | Directions in the prototype traffic graph |
|---|---|---|
| Hill Road | Way 1053511374, `oneway=yes` | B to A |
| St Peter's Road | Way 31152959, `oneway=no` | B to C and C to B |
| Waroda east | Way 31152970, `oneway=yes` | D to C |
| Waroda west | Way 431825049, no `oneway` tag, `hgv=no` | D to A and A to D for prototype car traffic |
| Nagrana | Way 31217220, `highway=footway`, `foot=permissive` | Walking connection E to F |

The complete ambient-car circuit follows A to D to C to B to A, using the 20 November 2026 mapping snapshot. Current real-world road access and vehicle permissions still need local verification. [Source and attribution](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md)

The Godot 4.7.2 lane probe passed 22 checks, including directions and junction links, left-side offsets, closed circuits from all four starts, car collision sweeps over all 53 route segments, and clearance from the footway interior.

## Ambient traffic pilot

One hatchback begins on the western Waroda lane, clear of the player and practice bays, and drives the left-hand circuit. It uses the existing arcade chassis, adjusts speed for bends and sweeps the chassis ahead to brake for people, parked vehicles and traffic obstacles. It waits for the lane to clear before resuming. Reset returns the pilot to its starting position when that space is clear, using the actual collision shape to check the spawn.

A second hatchback can join on a clear lane 85–180 m from the camera, at least 30 m from the pilot and outside the buffered view. The traffic manager checks twice per second. The extra car can retire offscreen beyond 225 m, or when it has been blocked for eight seconds and is offscreen and at least 85 m away. The two-car cap bounds the pilot's traffic cost.

Civilian and patrol hatchbacks use seated, right-hand drivers posed against the existing steering wheel. An active police alert can add one marked patrol that follows the same directed circuit and slows near the player. The police response and civilian cap are tracked independently. [Player consequences](../../research/GTA_GAMEPLAY_REFERENCES.md)

The ambient smoke covers startup, driver fit, bounded population, lane and view clearance, yielding, patrol dispatch and approach, full-circuit driving and safe reset. Run the test with the pinned Godot editor from the repository root.

```powershell
& $editor --headless --path prototype --fixed-fps 60 --quit-after 19950 --script res://tests/ambient_traffic_smoke.gd
```

## Visual streaming experiment

The default Ranwar scene builds all 183 generic backdrop meshes. To try distance-based streaming, start the game with the user argument `-- --stream-visual-chunks`. The opt-in mode groups the same backdrop in 96 m cells, loads around the camera within 160 m and retains cells out to 224 m to avoid repeated loading near an edge. During ordinary movement it activates at most one cell per 0.2-second update. Camera cuts can activate multiple cells immediately, and distant scenery can visibly appear or disappear. The roads, shared lane graph, ground and backdrop collision, twelve authored frontages and church stay loaded.

The smoke test verified that Godot releases mesh references on unload, building collision survives, and visuals return on re-entry. The rendered comparison used Godot 4.7.2 Compatibility on Windows 11 with an Intel i5-1145G7, Iris Xe and 15.7 GiB RAM. Each run completed the same 21 waypoints at 1280×720, capped at 60 FPS, with 2× simulation speed and ambient traffic disabled.

| Measurement | Resident | Streamed |
| --- | ---: | ---: |
| Scene setup wall time | 353.0 ms | 241.7 ms |
| Active backdrop meshes, lowest sample to peak | 183–183 | 39–168 |
| Sampled draw calls, p95 | 612 | 571 |
| Frame time, p95 | 17.03 ms | 17.04 ms |
| Longest frame | 42.08 ms | 42.64 ms |
| Peak Godot-tracked allocation | 94.57 MiB | 94.47 MiB |

This comparison supports keeping the resident scene as the default for the current neighborhood. Draw workload fell, while frame times and tracked allocation stayed close. Godot's allocation measurement covers the engine allocator. Target-device memory, GPU use and sustained traversal still need separate measurements. The cause of the long frame recorded in E-28 remains open. [Benchmark command](../README.md#ranwar-route-benchmark) · [Performance tracker](../../docs/PHASE_PROGRESS.md#phase-2--mumbai-neighborhood-and-performance-proof)

Run the focused visual-streaming smoke check with the pinned Godot editor.

```powershell
& $editor --headless --path prototype --fixed-fps 60 --quit-after 2400 --script res://tests/visual_streaming_smoke.gd -- --stream-visual-chunks
```

For larger authored districts, Godot can request a bundled scene in the background and poll its status across frames. Retrieve it when the load completes because retrieving too early can block. Add or remove active scene-tree nodes on the main thread, budget their activation and release live references when a cell leaves the cache. Visibility ranges can keep simplified silhouettes visible across longer sightlines. The Ranwar experiment builds procedural visuals on demand on the main thread. [Godot background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html) · [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html) · [Resource lifetime](https://docs.godotengine.org/en/stable/classes/class_resource.html) · [Visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html)

## Handling area

The open asphalt yard is west of the spawn. A seven-meter-wide test ramp along x = -31 rises from z = -28 to -43 by 1.2 m, has an eight-meter deck to z = -51, then descends to ground at z = -66. Approach from `(−31, 0, −20)` toward negative Z. A separate curb and impact wall allow controlled recovery checks; the outer barriers constrain the traversable ground area. The main controller owns recovery actions. Road, junction, footway and yard surfaces are non-colliding visual overlays above one continuous y=0 collision plane; curbs, sidewalks, ramp and barriers retain collisions.

## Present-day authored dressing and vehicle bays

The Phase 2 frontage checkpoint dresses the first eight Hill Road lots and four western Waroda Road lots within 85 metres of the inner Nagrana mouth. Five mixed-use storefronts use painted fictional signs, shutters, shallow canopies and service details. Seven village-house variants use raised plinths, verandah columns, balustrades, shuttered windows and pitched tile profiles. The house forms draw on the precinct survey and heritage inventory rechecked on 22 November 2026. They are original typology studies at gameplay placements. Present-day parcel matching for individual houses remains open. [MMR-HCS Bandra precinct survey, Vol. I, printed p. 5](https://mmrhcs.org.in/images/documents/projects/precinct-studies/Study_of_Bandra_Precinct/Bandra%20vol%20I.pdf) · [MMR-HCS heritage inventory, entries 612 and 619](https://mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf)

Each rendered frontage batches its opaque geometry into one surface with a shared vertex-color material. The twelve models now contain 9,442 triangles in total. Shop lettering remains a separate 3D label. A verandah adds simple colliders for its plinth, entrance step, posts and rails inside the existing lot setback. The frontage sample's geometry probe confirmed original collider parity, plinth support and no added frontage overlap along the vehicle loop or Nagrana footway. Windows Compatibility renders were reviewed on the Iris Xe development PC. Actual minimum-device measurements remain open.

The Waroda timber gallery study includes a projecting upper gallery, diamond-pattern grilles and an exterior return stair. The model adapts a licensed 2006 Chapel Road photo to an existing gameplay lot about 57 m from Nagrana Lane's Waroda entrance. The original lot dimensions remain authored. The stair and gallery are exterior details behind railings. Two rail colliders were added within the porch. Nagrana's existing corridor now has concrete joints, drain covers and plaster skirting batched into one 560-triangle surface. A Windows Compatibility probe confirmed unchanged road and footway paths, preserved original collision shapes and reviewed matched before-and-after captures. [Photo provenance and current capture requirements](../../docs/RANWAR_REFERENCE_CHECKLIST.md#image-guided-streetscape-pilot)

Neutral wayfinding identifies Ranwar / Bandra West and the existing route approaches. St Peter's parish history documents the nearby landmark's background. [St Peter's parish history](https://stpetersbandra.com/about-us/history/)

All four vehicles have dedicated bays with painted outlines and forward arrows. Vehicle names appear in the nearby interaction prompts. Car/auto outlines use amber, the motorcycle uses cyan, and the scooter uses warm white. The auto-rickshaw bay remains centered at `(-3.4, 0, 0)`, width **2.4 m**, length **4.4 m**. Its footprint is x=-4.6..-2.2, z=-2.2..2.2, inside the authored 14 m road. The car bay is 2.8 x 5.4 m at `(0, 0, 0)`.

The motorcycle bay is **1.8 x 3.8 m** at `(-6.2, 0, 1)`; its footprint is x=-7.1..-5.3, z=-0.9..2.9. The scooter bay is **1.7 x 3.4 m** at `(-8.7, 0, 1.5)`; its footprint is x=-9.55..-7.85, z=-0.2..3.2. These two bays sit toward the open handling yard. Lateral center spacing is 2.8 m from auto to motorcycle and 2.5 m from motorcycle to scooter. No bay surface, boundary paint or arrow has a collider, and no pole or street furniture is introduced beside the spawn actors. Final actor-to-actor clearance, mounting, vehicle selection and handling remain integrated checks.

A sparse cyan painted guide at x=-16, z=-8..-21.5 marks a flat practice approach. The nearby quiet test corridor x=-23..-14, z=-8..-28 avoids the ramp, curb-test object and impact wall. It adds no new obstacles or driving-route geometry.

## St Peter's Church exterior

The Hill Road approach now has an exterior landmark based on the Romanesque church. The original mesh uses the yellow stone massing, pediment, round-arched entrance, side turrets and paired palms visible in parish and Archdiocese references. The photographs informed the model and the game ships original geometry. [St Peter's parish history](https://stpetersbandra.com/about-us/history/) · [Archdiocese of Bombay parish photograph](https://www.archdioceseofbombay.org/parishes/stpeter) · [MMR-HCS heritage inventory, entry 609](https://mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf#page=69)

OSM way 511064344 in the [20 November 2026 extract](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) anchors the church on the south side of Hill Road. The game façade faces world negative X at `(27.5, 0.0, -362.6)`. The body is about 23.4 m wide and 25.6 m deep. The parish records the whole building at about 24.4 m wide and 39.6 m long. The model moves the façade back and compresses the nave to fit the authored road and sidewalk while leaving a 4.8 m forecourt. Overlapping generic frontages are omitted inside this lot. The exterior provides a visible landmark and walkable front steps with solid building walls.

The Godot 4.7.2 Windows Compatibility check rendered the front and angled Hill Road views and verified support at the upper step, the solid entrance and clearance at 693 sampled vehicle positions across the road loop. The static model has 2,494 triangles in one opaque mesh surface with the existing shared vertex-color material and seven box colliders. A local recognition review and minimum-device performance measurements remain open.

## Focused world check

The 22 November 2026 isolated Godot 4.7.2 headless probe cleared all five actor-sized spawn volumes against world colliders and confirmed the ground beneath the auto bay. It constructed 564 direct world children. The temporary extended probe used the ignored `.toolchain/world_clearance_check.gd` fixture and added motorcycle/scooter box checks; it was removed after the run. This verifies world startup and environmental clearances, not vehicle-to-vehicle interactions or minimum-device performance. The integrated Phase 1 smoke test owns mounting, controls, steering/lean, recovery and route checks. [Playtest and verification commands](../README.md)

## Implementation boundaries

Only local deterministic geometry is generated. Shared materials and simple static box collisions keep the dependency and material footprint small. Static buildings are numerous enough to make camera/readability checks meaningful, but this has not been profiled on minimum hardware or accepted for mobile performance. Runtime input, saves, networking, secrets and cryptography are outside this world script.
