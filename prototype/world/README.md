# Ranwar traversal world

Updated **23 November 2026** for the selected **present-day Mumbai** direction.

`phase1_world.gd` extends `Node3D` and builds local mesh/collision geometry in `_ready()`. Attach it below the game's main scene. The main project supplies lighting, camera, player, vehicles and UI.

New players arrive at the St Peter's Church bus stop on Hill Road. The practice start is `(0, 0.5, 5)`. Car start is `(0, 0.55, 0)`, auto-rickshaw start is `(-3.4, 0.55, 0)`, motorcycle start is `(-6.2, 0.55, 1)`, and scooter start is `(-8.7, 0.55, 1.5)`. The four practice vehicles point along negative Z. Hill Road bends as it extends from the origin. [Bandra facility references](../../docs/BANDRA_FACILITIES.md)

The opening uses an original 9 m red-and-dark city bus inspired by the low-floor electric fleet documented by Mumbai operator Evey Trans and the Olectra iX. The modeled windshield, smoked headlamp housings, wipers, mirrors, door rails and high-contrast step edging use original geometry and materials. Manufacturer and operator photographs are references for shape and color. [Evey Trans Mumbai fleet](https://eveytrans.com/mumbai/) · [Olectra city bus specifications](https://www.olectra.com/)

## Route and provenance

The blockout uses selected bend points from the downloaded modern OpenStreetMap reference loop: A (Hill/Waroda) -> B (Hill/St Peter's) -> C (Chapel/Waroda) -> D (Veronica/Waroda) -> A. Its source polyline is approximately 1,186.7 m. Nagrana E -> F is the approximately 70.5 m source footway. The script projects into a local metric plane and rotates the loop so the first leg starts forward from the spawn. It preserves approximate source scale and junction order; no intentional uniform scale compression is applied. Minor bends are simplified, and approximate coordinates are for gameplay inspection rather than surveying. See `layout.json` for reference waypoints and the handling-yard route.

Authoring changes: 14 m Hill carriageway, 10 m St Peter's approach, 8 m inner streets, 2.4 m footway, simplified junction pads, sidewalks/curbs, footway walls/bollards, a mix of background blockouts and the authored frontage sample, bounded recovery yard and barriers. These dimensions and buildings are gameplay additions, not measured local conditions. The authored sample uses original local building types and invented storefronts. Add `-- --world-debug-labels` to a Godot launch to show the development road and handling-yard labels. Normal play uses the map, objective HUD and physical signs.

The modern source is an acquired mapping snapshot, not a surveyed current streetscape. Road access, authored widths, building frontages and permissions remain unverified. A present-day setting does not make the generic dressing a reconstruction of actual operating shops or named properties. This is a traversal toy, not a completed district.

Map data from **OpenStreetMap contributors**, under **ODbL 1.0**. Retain the raw extract, transformation details and data-offer obligations if distributing this derived layout. The source package includes the extract, attribution, license and candidate layout. [OpenStreetMap reference package](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) The frontage kit uses original geometry and shared materials.

## Map and asset placement

The current playable area covers the Ranwar pocket of Bandra West. The road and footway mesh uses selected bends and junctions from the saved OpenStreetMap extract. All 30 route coordinates were checked against nodes on the corresponding five saved ways. The St Peter's Church site comes from its mapped footprint, with a designed setback and simplified building dimensions. The five fictional shops and seven village-house frontages are placed in authored lots along those streets. The shop parcels, practice bays, handling yard, street widths and curb geometry are authored gameplay elements. **Pause → Map** draws the same projected roads and Nagrana Lane footway with the paused position of Omkar or his active vehicle. Current parcel and street-condition checks are tracked separately. [Source map and acquisition](../../research/BANDRA_REFERENCE_AREA_AND_MAP.md)

The District services page places eight real sites on a north-up map. The Ranwar circuit and the modeled arrival stop are playable. Nearby hospitals, police, fire and transport stations are geographic references for extending the playable streets. [Facility source details](../../docs/BANDRA_FACILITIES.md)

**Pause → Map → Bandra landmarks** locates the Waroda Road wayside cross, St Peter’s Church and Meena along the playable streets. The map also shows Mount Mary Basilica, Bandra Fort and the actual Bandra–Worli Sea Link alignment. Open the Sea Link preview there to inspect an original 3D study of its north channel span. [Landmark geography and modeling references](../../docs/BANDRA_LANDMARKS.md)

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

The default Ranwar scene builds all generic backdrop meshes. To try distance-based streaming, start the game with the user argument `-- --stream-visual-chunks`. The opt-in mode groups the same backdrop in 96 m cells, loads around the camera within 160 m and retains cells out to 224 m to avoid repeated loading near an edge. During ordinary movement it activates at most one cell per 0.2-second update. Camera cuts can activate multiple cells immediately, and distant scenery can visibly appear or disappear. The roads, shared lane graph, ground and backdrop collision, twelve authored frontages, the church and Meena stay loaded.

The smoke test verified that Godot releases mesh references on unload, building collision survives, and visuals return on re-entry. The earlier rendered comparison used 183 generic meshes and Godot 4.7.2 Compatibility on Windows 11 with an Intel i5-1145G7, Iris Xe and 15.7 GiB RAM. Each run completed the same 21 waypoints at 1280×720, capped at 60 FPS, with 2× simulation speed and ambient traffic disabled.

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

The small red paan kiosk beside the fictional Hill Road grocery uses nayan pachori’s **Indian street shop** asset. The 266-triangle shop has one surface, faces Hill Road and has a solid collision box within the setback. Its authored position lies 14.9 m from the road centreline. [Model source, CC BY 4.0 license and adaptation](props/SOURCES.md)

Neutral wayfinding identifies Ranwar / Bandra West and the existing route approaches. St Peter's parish history documents the nearby landmark's background. [St Peter's parish history](https://stpetersbandra.com/about-us/history/)

All four vehicles have dedicated bays with painted outlines and forward arrows. Vehicle names appear in the nearby interaction prompts. Car/auto outlines use amber, the motorcycle uses cyan, and the scooter uses warm white. The auto-rickshaw bay remains centered at `(-3.4, 0, 0)`, width **2.4 m**, length **4.4 m**. Its footprint is x=-4.6..-2.2, z=-2.2..2.2, inside the authored 14 m road. The car bay is 2.8 x 5.4 m at `(0, 0, 0)`.

The motorcycle bay is **1.8 x 3.8 m** at `(-6.2, 0, 1)`; its footprint is x=-7.1..-5.3, z=-0.9..2.9. The scooter bay is **1.7 x 3.4 m** at `(-8.7, 0, 1.5)`; its footprint is x=-9.55..-7.85, z=-0.2..3.2. These two bays sit toward the open handling yard. Lateral center spacing is 2.8 m from auto to motorcycle and 2.5 m from motorcycle to scooter. No bay surface, boundary paint or arrow has a collider, and no pole or street furniture is introduced beside the spawn actors. Final actor-to-actor clearance, mounting, vehicle selection and handling remain integrated checks.

A sparse cyan painted guide at x=-16, z=-8..-21.5 marks a flat practice approach. The nearby quiet test corridor x=-23..-14, z=-8..-28 avoids the ramp, curb-test object and impact wall. It adds no new obstacles or driving-route geometry.

## Photo-based street materials

Ranwar uses shared photo-based material tiles for asphalt, interlocking pavers, worn concrete, painted plaster, clay roof tiles, timber and gravel. Road surfaces join at a common world-space repeat. Normal maps give repeated asphalt, concrete and plaster surfaces low relief under the sun. The frontage, alley and church meshes use metre-scale coordinates and keep one opaque surface per mesh, with material selection stored per face.

The runtime includes 512×512 diffuse tiles and four normal maps with mipmaps. Palette colours still distinguish the authored buildings. Roof and timber surfaces retain their photographed finish colours, with placement variation for plaster. The material pass leaves route dimensions, ground collision and streaming configuration as before. [Photo sources and authors](textures/SOURCES.md)

The Hill Road arrival pass uses a charcoal aggregate and aged interlocking pavers at their photographed 2.5 m and 1.3 m scales, lighter paint wear on the facades, and warm sunlight with cooler sky fill. The footpath gets a shallow paved apron and two original flush roadside drain grates. Their form follows Mumbai footpath and storm-water maintenance guidance. Both geometry inserts are visual, and the exported roads, footway, collision triangles, doors, markers and spawn are identical to the earlier world exchange. The materials and geometry are shared across both engines. Godot and Unreal implement the haze and sky lighting locally. The Godot Compatibility render was checked from the same street-level cameras before and after. Field matching and both minimum-device measurements remain open. [Surface provenance](textures/SOURCES.md#hill-road-surface-pass) · [BMC footpath policy](https://portal.mcgm.gov.in/irj/go/km/docs/documents/MCGM%20Department%20List/Roads%20and%20Traffic/Docs/Pedestrian%20First%20-%20Footpath%20Policy.pdf)

## St Peter's Church exterior

The Hill Road approach now has an exterior landmark based on the Romanesque church. The original mesh uses the yellow stone massing, pediment, round-arched entrance, side turrets and paired palms visible in parish and Archdiocese references. The photographs informed the model and the game ships original geometry. [St Peter's parish history](https://stpetersbandra.com/about-us/history/) · [Archdiocese of Bombay parish photograph](https://www.archdioceseofbombay.org/parishes/stpeter) · [MMR-HCS heritage inventory, entry 609](https://mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf#page=69)

OSM way 511064344 in the [20 November 2026 extract](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) anchors the church on the south side of Hill Road. The game façade faces world negative X at `(27.5, 0.0, -362.6)`. The body is about 23.4 m wide and 25.6 m deep. The parish records the whole building at about 24.4 m wide and 39.6 m long. The model moves the façade back and compresses the nave to fit the authored road and sidewalk while leaving a 4.8 m forecourt. Overlapping generic frontages are omitted inside this lot. The exterior provides a visible landmark and walkable front steps with solid building walls.

The adjacent St Peter’s BEST stop keeps its recorded location and the existing Hill Road pedestrian approach. The shelter is an authored approximation with a sloped steel canopy, gutter, timber bench slats and a small passenger information board. The new paint and seating details stay inside its existing footprint. Its two matte signs use original Marathi and English lettering with the repository’s licensed Noto Sans Devanagari font. The opaque sign textures and the existing simple colliders are captured by the ordinary Ranwar world export. BMC guidance informs the bilingual wayfinding pattern. A current field survey is still needed to confirm the exact shelter construction. [Stop location](../../docs/BANDRA_FACILITIES.md) · [BMC sign guidance](https://portal.mcgm.gov.in/irj/go/km/docs/documents/MCGM%20Department%20List/Roads%20and%20Traffic/Docs/Design%20Codes%20MoUD/Part_IV_Signages.pdf) · [Font license](../startup/art/NotoSansDevanagari-OFL.txt)

The Godot 4.7.2 Windows Compatibility check rendered the front and angled Hill Road views and verified support at the upper step, the solid entrance and clearance at 693 sampled vehicle positions across the road loop. The static model has 2,494 triangles in one opaque mesh surface with the existing shared vertex-color material and seven box colliders. A local recognition review and minimum-device performance measurements remain open.

The next art iteration concentrates on the two facades that frame the shelter. The side wall of St Peter’s has partially recessed glazing, projecting stone sills and divided panes. The parish describes the Romanesque exterior and stained-glass windows. The authored building across the shelter alley has projecting window frames, ground-floor grilles, two wall-mounted condensers and downpipes. BMC identifies roof-water drainage as part of Mumbai building design. The model uses local architectural and service cues at an authored detail scale. Site-specific placements remain open for photo and field matching. [Parish history and stained glass](https://stpetersbandra.com/about-us/history/) · [MMR-HCS church and precinct entries 609 and 612](https://mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf#page=69) · [BMC building requirements, Part VIII](https://portal.mcgm.gov.in/irj/go/km/docs/documents/EODB/Construction%20Permit/Related%20Circulars/DCPR-%202034%20and%20Notification.pdf)

Matched 1280 × 720 Compatibility renders on Intel Iris Xe show window and pipe relief in both the fascia and Hill Road views. The second exchange contains 35,901 visual triangles across 16 visual sections, 5,352 more than the material pass. One new Godot render surface contains the fittings and reuses the shared material. The published exchange check confirms identical 5,864 collision triangles, roads, footway, entry doors, landmarks and player start.

The SandbarCity sample informed the layering of road repairs, drainage covers, and street furniture. Ranwar uses original meshes and the textures already recorded in the surface ledger. Asphalt patches, curb drains and utility covers are grouped into 128 m tiles. The BEST forecourt has two authored shade trees, a planter, a litter bin and a utility cabinet, with a new set of shutters and shallow awnings on nearby Hill Road lots. The fittings follow the existing backdrop residency mode. These details are scenery and use the ordinary Godot-to-Unreal street exchange. [Surface sources](textures/SOURCES.md#hill-road-surface-pass) · [Unreal street exchange](../../unreal/ContentSource/RANWAR_STREET.md)

## Meena on Hill Road

The skyline across Hill Road from Nagrana Lane includes a Meena building study registered to the ten vertices of OSM way 255362104. The study uses the mapped 15 levels and an estimated 3.05 m per level. The textured shell and collider use the same projected footprint, and the generated background buildings give the site space. Current elevation, facade openings and materials remain for field comparison. [Engine site controls](layout.json) · [Capture targets](../../docs/RANWAR_REFERENCE_CHECKLIST.md#current-photo-searches-and-registered-building-pilot) · [OSM data offer and attribution](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/ATTRIBUTION.md)

## Mapped frontage and walk-in shops

The mapped frontage pass uses 38 building footprints from the **20 November 2026** OpenStreetMap extract. It samples Hill Road, St Peter’s Road and both Waroda segments. Overlapping placeholder boxes make way for mapped buildings. The church, Meena, Nagrana Lane and authored showcase frontages retain their approaches. Twenty-three footprints use their projected positions. Fifteen footprints use setbacks of **3–6.5 m** to make room for the wider gameplay streets. The compact house sequence near Chapel and the Waroda junction uses those authored setbacks to narrow the visible gaps without obstructing the sidewalks. The [footprint source](ranwar_building_footprints.gd) lists each offset and the original projected vertices. [Saved OSM data and attribution](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) · [Bandra precinct survey](https://mmrhcs.org.in/images/documents/projects/precinct-studies/Study_of_Bandra_Precinct/Bandra%20vol%20I.pdf)

| Walk-in shop | Find it | Placement and art |
| --- | --- | --- |
| Hill Road Tea Room | Across Hill Road from the St Peter’s stop, a short walk west along the opposite pavement. | Fictional ground-floor tenant at the mapped Libra Tower footprint. The floor plan, access opening, paint and height are game estimates. [OSM building 360291657](https://www.openstreetmap.org/way/360291657) |
| Chapel Corner Grocer | On the Chapel side of the Waroda circuit, before the turn toward St Peter’s Road. | Fictional shop on the map’s Tony Stores parcel with the 6.5 m gameplay setback. The plan and finishes are original art. [OSM building 357472313](https://www.openstreetmap.org/way/357472313) |

Walk through either open doorway to enter and use the same doorway to leave. The pavement and shop floor meet at a shallow ramp. Each building uses a single mesh surface with existing materials. Public rooms add a local light, a nameplate and a menu board. The preview uses floor-level collisions for both rooms and their counters. Nearby homes have solid collision shells. Upper floors of the two shops are exterior scenery. The layout check measures roadway and lane clearance, and the stock Jolt player capsule tests entry and exit at both venues. Street-facing doors, finishes and heights remain estimates where current field evidence is unavailable. [Frontage reference checklist](../../docs/RANWAR_REFERENCE_CHECKLIST.md)

```powershell
$editor = '.\.toolchain\godot-4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& $editor --headless --path prototype --fixed-fps 60 --script res://tests/ranwar_building_smoke.gd
& $editor --path prototype --resolution 1024x576 --disable-vsync --fixed-fps 90 --script res://tests/ranwar_building_smoke.gd -- --capture
```

## Hill Road arrival frontage

The Hill Road Tea Room has recessed displays, an awning and brackets, a rolled steel shutter beside the shop, steel downpipe fittings, and deeper upper-level window details. Its fictional bilingual fascia and notices share one original opaque sign atlas. The visual storefront uses the shared material kit, with separate shaded glazing and lettering surfaces. The existing collision mesh supplies the door, ramp and room. [Mapped storefront and collision](ranwar_mapped_buildings.gd) · [Visual frontage](ranwar_tea_room_frontage.gd) · [Texture credits](textures/SOURCES.md)

St Peter’s BEST shelter has a continuous matte canopy with bracing, a drain outlet, a lamp housing and timber bench details. Nearby shade trees and service fixtures use a shared opaque material. A visual-only ground batch follows the existing curb profile on both sides of the arrival stretch, adding curb joints, gutter wear and an asphalt utility repair. The designs are interpreted for gameplay on the saved street layout. [Shelter](st_peters_shelter.gd) · [Shade trees](ranwar_arrival_greenery.gd) · [Ground finish](ranwar_hill_road_ground.gd)

The art pass applies Riley Brown’s sequence of checking traversal, reusing tiled surfaces, and adding location-specific geometry and wear. The portable assets flow through the project’s existing Godot, Blender and Unreal exchange. [Tutorial](https://www.youtube.com/watch?v=Q9HNRzgRT5E) · [Unreal exchange workflow](../../unreal/ContentSource/RANWAR_STREET.md)

## District façades and roof detail

The mapped street pass revises all 38 OSM footprints and the separate Meena tower. Tall buildings have projecting balconies, differentiated window bays, podium bands, vertical ribs and rooftop service volumes. Low buildings use a smaller kit of frames, sills and trim. Remaining residential masses use one batched visual mesh per lot and release the generated mesh when their optional Godot visual cell unloads. The Unreal horizon adds rooftop setbacks to its existing instanced silhouettes. The Tea Room and Grocer retain their established openings. [Mapped building art](ranwar_mapped_buildings.gd) · [Façade kit](ranwar_facade_kit.gd) · [Background visuals](ranwar_background_facade.gd)

The placed water tanks and condenser pairs use two cleared CC0 GLBs. The façade proportions draw on architectural references from Pali Hill and Carter Road. Their final placements and details are gameplay interpretations of the mapped area. [Prop source and adaptation](props/SOURCES.md#rooftop-props) · [Pali Hill reference](https://sog-design.com/portfolio-items/rustomjee-crescent-pali-hill/) · [Carter Road reference](https://www.madane.in/projects/carter-road)

## Focused world check

The 22 November 2026 isolated Godot 4.7.2 headless probe cleared all five actor-sized spawn volumes against world colliders and confirmed the ground beneath the auto bay. It constructed 564 direct world children. The temporary extended probe used the ignored `.toolchain/world_clearance_check.gd` fixture and added motorcycle/scooter box checks; it was removed after the run. This verifies world startup and environmental clearances, not vehicle-to-vehicle interactions or minimum-device performance. The integrated Phase 1 smoke test owns mounting, controls, steering/lean, recovery and route checks. [Playtest and verification commands](../README.md)

## Implementation boundaries

Only local deterministic geometry is generated. Shared materials and simple static box collisions keep the dependency and material footprint small. Static buildings are numerous enough to make camera/readability checks meaningful, but this has not been profiled on minimum hardware or accepted for mobile performance. Runtime input, saves, networking, secrets and cryptography are outside this world script.
