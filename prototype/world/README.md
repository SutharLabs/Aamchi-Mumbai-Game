# Phase 1 traversal world

Updated **22 November 2026** for the selected **present-day Mumbai** direction.

`phase1_world.gd` extends `Node3D` and builds local mesh/collision geometry in `_ready()`. Attach it below the game's main scene. The main project supplies lighting, camera, player, vehicles and UI.

Player start: `(0, 0.5, 5)`. Car start: `(0, 0.55, 0)`. Auto-rickshaw start: `(-3.4, 0.55, 0)`. Motorcycle start: `(-6.2, 0.55, 1)`. Scooter start: `(-8.7, 0.55, 1.5)`. All vehicles point along negative Z. The first road leaves the origin approximately along negative Z; follow its bends rather than driving indefinitely straight.

## Route and provenance

The blockout uses selected bend points from the downloaded modern OpenStreetMap reference loop: A (Hill/Waroda) -> B (Hill/St Peter's) -> C (Chapel/Waroda) -> D (Veronica/Waroda) -> A. Its source polyline is approximately 1,186.7 m. Nagrana E -> F is the approximately 70.5 m source footway. The script projects into a local metric plane and rotates the loop so the first leg starts forward from the spawn. It preserves approximate source scale and junction order; no intentional uniform scale compression is applied. Minor bends are simplified, and approximate coordinates are for gameplay inspection rather than surveying. See `layout.json` for reference waypoints and the handling-yard route.

Authoring changes: 14 m Hill carriageway, 10 m St Peter's approach, 8 m inner streets, 2.4 m footway, simplified junction pads, sidewalks/curbs, footway walls/bollards, generic color-block frontage masses, bounded recovery yard and barriers. These dimensions and buildings are gameplay additions, not measured local conditions. Frontages are generic blockout masses; they do not reconstruct named real houses or an accepted landmark. Labels identify reference approaches only. No named residence is assigned a fictional criminal role.

The modern source is an acquired mapping snapshot, not a surveyed current streetscape. Road access, authored widths, building frontages and permissions remain unverified. A present-day setting does not make the generic dressing a reconstruction of actual operating shops or named properties. This is a traversal toy, not a completed district.

Map data from **OpenStreetMap contributors**, under **ODbL 1.0**. Retain the raw extract, transformation details and data-offer obligations if distributing this derived layout. Source package: `../../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/`; read its `ATTRIBUTION.md`, `ODbL-1.0.txt` and `candidate-layout.json`. No external imagery, downloaded game assets or new dependencies are used by this script.

## Handling area

The open asphalt yard is west of the spawn. A seven-meter-wide test ramp along x = -31 rises from z = -28 to -43 by 1.2 m, has an eight-meter deck to z = -51, then descends to ground at z = -66. Approach from `(−31, 0, −20)` toward negative Z. A separate curb and impact wall allow controlled recovery checks; the outer barriers constrain the traversable ground area. The main controller owns recovery actions. Road, junction, footway and yard surfaces are non-colliding visual overlays above one continuous y=0 collision plane; curbs, sidewalks, ramp and barriers retain collisions.

## Present-day authored dressing and vehicle bays

The first eight existing frontage lots have original painted service signs, simple shutters, compact wall equipment and shared color materials. The invented service labels include mobile repair, parcel, groceries, print/copy and everyday services. Three generic digital-payment notices add a current visual cue without using payment-provider logos or copied shop brands. They are design additions, not claims about actual businesses at those OSM coordinates. Additional source geometry, actors and route connections are unchanged by this pass.

Neutral wayfinding identifies Ranwar / Bandra West and the existing route approaches. The older [MMR-HCS heritage inventory, entries 612 and 619](https://mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf) provides prior streetscape context; [St Peter's parish history](https://stpetersbandra.com/about-us/history/) documents the local landmark's background. Both primary pages were rechecked on 22 November 2026. Neither establishes a current storefront inventory or supplies reused artwork, and no external images were imported.

All four vehicles have dedicated paint-only bays with compact identifying labels and forward arrows. Car/auto outlines use amber, the motorcycle uses cyan, and the scooter uses warm white. The auto-rickshaw bay remains centered at `(-3.4, 0, 0)`, width **2.4 m**, length **4.4 m**. Its footprint is x=-4.6..-2.2, z=-2.2..2.2, inside the authored 14 m road. The car bay is 2.8 x 5.4 m at `(0, 0, 0)`.

The motorcycle bay is **1.8 x 3.8 m** at `(-6.2, 0, 1)`; its footprint is x=-7.1..-5.3, z=-0.9..2.9. The scooter bay is **1.7 x 3.4 m** at `(-8.7, 0, 1.5)`; its footprint is x=-9.55..-7.85, z=-0.2..3.2. These two bays sit toward the open handling yard. Lateral center spacing is 2.8 m from auto to motorcycle and 2.5 m from motorcycle to scooter. No bay surface, boundary, arrow or label has a collider, and no pole or street furniture is introduced beside the spawn actors. Final actor-to-actor clearance, mounting, vehicle selection and handling remain integrated checks.

A sparse cyan painted guide at x=-16, z=-8..-21.5 marks a flat practice approach. The nearby quiet test corridor x=-23..-14, z=-8..-28 avoids the ramp, curb-test object and impact wall. It adds no new obstacles or driving-route geometry.

## Focused world check

The 22 November 2026 isolated Godot 4.7.2 headless probe cleared all five actor-sized spawn volumes against world colliders and confirmed the ground beneath the auto bay. It constructed 564 direct world children. The temporary extended probe used the ignored `.toolchain/world_clearance_check.gd` fixture and added motorcycle/scooter box checks; it was removed after the run. This verifies world startup and environmental clearances, not vehicle-to-vehicle interactions or minimum-device performance. The integrated Phase 1 smoke test owns mounting, controls, steering/lean, recovery and route checks. [Playtest and verification commands](../README.md)

## Implementation boundaries

Only local deterministic geometry is generated. Shared materials and simple static box collisions keep the dependency and material footprint small. Static buildings are numerous enough to make camera/readability checks meaningful, but this has not been profiled on minimum hardware or accepted for mobile performance. Runtime input, saves, networking, secrets and cryptography are outside this world script.
