# Phase 1 traversal world

`phase1_world.gd` extends `Node3D` and builds local mesh/collision geometry in `_ready()`. Attach it below the game's main scene. The main project supplies lighting, camera, player, vehicles and UI.

Player start: `(0, 0.5, 5)`. Vehicle start: `(0, 0.55, 0)`, pointing along negative Z. The first road leaves the origin approximately along negative Z; follow its bends rather than driving indefinitely straight.

## Route and provenance

The blockout uses selected bend points from the downloaded modern OpenStreetMap reference loop: A (Hill/Waroda) -> B (Hill/St Peter's) -> C (Chapel/Waroda) -> D (Veronica/Waroda) -> A. Its source polyline is approximately 1,186.7 m. Nagrana E -> F is the approximately 70.5 m source footway. The script projects into a local metric plane and rotates the loop so the first leg starts forward from the spawn. It preserves approximate source scale and junction order; no intentional uniform scale compression is applied. Minor bends are simplified, and approximate coordinates are for gameplay inspection rather than surveying. See `layout.json` for reference waypoints and the handling-yard route.

Authoring changes: 14 m Hill carriageway, 10 m St Peter's approach, 8 m inner streets, 2.4 m footway, simplified junction pads, sidewalks/curbs, footway walls/bollards, generic color-block frontage masses, bounded recovery yard and barriers. These dimensions and buildings are gameplay additions, not measured local conditions. Frontages are generic blockout masses; they do not reconstruct named real houses or an accepted landmark. Labels identify reference approaches only. No named residence is assigned a fictional criminal role.

The modern source is not a historical map. Exact 1990-1995 roads, access, widths, surface, buildings and permissions remain unverified. Historical world acceptance, routing and period-correct art remain separate work. This is a traversal toy, not a completed district.

Map data from **OpenStreetMap contributors**, under **ODbL 1.0**. Retain the raw extract, transformation details and data-offer obligations if distributing this derived layout. Source package: `../../../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/`; read its `ATTRIBUTION.md`, `ODbL-1.0.txt` and `candidate-layout.json`. No external imagery, downloaded game assets or new dependencies are used by this script.

## Handling area

The open asphalt yard is west of the spawn. A seven-meter-wide test ramp along x = -31 rises from z = -28 to -43 by 1.2 m, has an eight-meter deck to z = -51, then descends to ground at z = -66. Approach from `(−31, 0, −20)` toward negative Z. A separate curb and impact wall allow controlled recovery checks; the world boundary prevents leaving the ground plane. The main controller owns recovery actions.

## Implementation boundaries

Only local deterministic geometry is generated. Shared materials and simple static box collisions keep the dependency and material footprint small. Static buildings are numerous enough to make camera/readability checks meaningful, but this has not been profiled on minimum hardware or accepted for mobile performance. Runtime input, saves, networking, secrets and cryptography are outside this world script.
