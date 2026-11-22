# Ranwar traversal world

Updated **22 November 2026** for the selected **present-day Mumbai** direction.

`phase1_world.gd` extends `Node3D` and builds local mesh/collision geometry in `_ready()`. Attach it below the game's main scene. The main project supplies lighting, camera, player, vehicles and UI.

Player start: `(0, 0.5, 5)`. Car start: `(0, 0.55, 0)`. Auto-rickshaw start: `(-3.4, 0.55, 0)`. Motorcycle start: `(-6.2, 0.55, 1)`. Scooter start: `(-8.7, 0.55, 1.5)`. All vehicles point along negative Z. The first road leaves the origin approximately along negative Z; follow its bends rather than driving indefinitely straight.

## Route and provenance

The blockout uses selected bend points from the downloaded modern OpenStreetMap reference loop: A (Hill/Waroda) -> B (Hill/St Peter's) -> C (Chapel/Waroda) -> D (Veronica/Waroda) -> A. Its source polyline is approximately 1,186.7 m. Nagrana E -> F is the approximately 70.5 m source footway. The script projects into a local metric plane and rotates the loop so the first leg starts forward from the spawn. It preserves approximate source scale and junction order; no intentional uniform scale compression is applied. Minor bends are simplified, and approximate coordinates are for gameplay inspection rather than surveying. See `layout.json` for reference waypoints and the handling-yard route.

Authoring changes: 14 m Hill carriageway, 10 m St Peter's approach, 8 m inner streets, 2.4 m footway, simplified junction pads, sidewalks/curbs, footway walls/bollards, a mix of background blockouts and the authored frontage sample, bounded recovery yard and barriers. These dimensions and buildings are gameplay additions, not measured local conditions. The authored sample uses original local building types and invented storefronts. Route labels identify the corresponding real approaches.

The modern source is an acquired mapping snapshot, not a surveyed current streetscape. Road access, authored widths, building frontages and permissions remain unverified. A present-day setting does not make the generic dressing a reconstruction of actual operating shops or named properties. This is a traversal toy, not a completed district.

Map data from **OpenStreetMap contributors**, under **ODbL 1.0**. Retain the raw extract, transformation details and data-offer obligations if distributing this derived layout. The source package includes the extract, attribution, license and candidate layout. [OpenStreetMap reference package](../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) The frontage kit uses original geometry and shared materials.

## Handling area

The open asphalt yard is west of the spawn. A seven-meter-wide test ramp along x = -31 rises from z = -28 to -43 by 1.2 m, has an eight-meter deck to z = -51, then descends to ground at z = -66. Approach from `(−31, 0, −20)` toward negative Z. A separate curb and impact wall allow controlled recovery checks; the outer barriers constrain the traversable ground area. The main controller owns recovery actions. Road, junction, footway and yard surfaces are non-colliding visual overlays above one continuous y=0 collision plane; curbs, sidewalks, ramp and barriers retain collisions.

## Present-day authored dressing and vehicle bays

The Phase 2 frontage checkpoint dresses the first eight Hill Road lots and four western Waroda Road lots within 85 metres of the inner Nagrana mouth. Five mixed-use storefronts use painted fictional signs, shutters, shallow canopies and service details. Seven village-house variants use raised plinths, verandah columns, balustrades, shuttered windows and pitched tile profiles. The house forms draw on the precinct survey and heritage inventory rechecked on 22 November 2026. They are original typology studies at gameplay placements. Present-day parcel and landmark matching remain open. [MMR-HCS Bandra precinct survey, Vol. I, printed p. 5](https://mmrhcs.org.in/images/documents/projects/precinct-studies/Study_of_Bandra_Precinct/Bandra%20vol%20I.pdf) · [MMR-HCS heritage inventory, entries 612 and 619](https://mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf)

Each rendered frontage batches its opaque geometry into one surface with a shared vertex-color material. The twelve models contain 8,966 triangles in total. Shop lettering remains a separate 3D label. All original solid volumes, lot centers, route points, widths and junction placements are preserved. A verandah adds simple colliders for its plinth, entrance step, posts and rails inside the existing lot setback. A world geometry probe confirmed original collider parity, plinth support and no added frontage overlap along the vehicle loop or Nagrana footway. Windows Compatibility renders were reviewed on the Iris Xe development PC. Actual minimum-device measurements remain open.

Neutral wayfinding identifies Ranwar / Bandra West and the existing route approaches. St Peter's parish history documents the nearby landmark's background. [St Peter's parish history](https://stpetersbandra.com/about-us/history/)

All four vehicles have dedicated paint-only bays with compact identifying labels and forward arrows. Car/auto outlines use amber, the motorcycle uses cyan, and the scooter uses warm white. The auto-rickshaw bay remains centered at `(-3.4, 0, 0)`, width **2.4 m**, length **4.4 m**. Its footprint is x=-4.6..-2.2, z=-2.2..2.2, inside the authored 14 m road. The car bay is 2.8 x 5.4 m at `(0, 0, 0)`.

The motorcycle bay is **1.8 x 3.8 m** at `(-6.2, 0, 1)`; its footprint is x=-7.1..-5.3, z=-0.9..2.9. The scooter bay is **1.7 x 3.4 m** at `(-8.7, 0, 1.5)`; its footprint is x=-9.55..-7.85, z=-0.2..3.2. These two bays sit toward the open handling yard. Lateral center spacing is 2.8 m from auto to motorcycle and 2.5 m from motorcycle to scooter. No bay surface, boundary, arrow or label has a collider, and no pole or street furniture is introduced beside the spawn actors. Final actor-to-actor clearance, mounting, vehicle selection and handling remain integrated checks.

A sparse cyan painted guide at x=-16, z=-8..-21.5 marks a flat practice approach. The nearby quiet test corridor x=-23..-14, z=-8..-28 avoids the ramp, curb-test object and impact wall. It adds no new obstacles or driving-route geometry.

## Focused world check

The 22 November 2026 isolated Godot 4.7.2 headless probe cleared all five actor-sized spawn volumes against world colliders and confirmed the ground beneath the auto bay. It constructed 564 direct world children. The temporary extended probe used the ignored `.toolchain/world_clearance_check.gd` fixture and added motorcycle/scooter box checks; it was removed after the run. This verifies world startup and environmental clearances, not vehicle-to-vehicle interactions or minimum-device performance. The integrated Phase 1 smoke test owns mounting, controls, steering/lean, recovery and route checks. [Playtest and verification commands](../README.md)

## Implementation boundaries

Only local deterministic geometry is generated. Shared materials and simple static box collisions keep the dependency and material footprint small. Static buildings are numerous enough to make camera/readability checks meaningful, but this has not been profiled on minimum hardware or accepted for mobile performance. Runtime input, saves, networking, secrets and cryptography are outside this world script.
