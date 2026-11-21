# Mumbai: Gully Heat — feasibility review

Research date: 19 November 2026. Scope: a solo developer, substantial agent assistance, reusable open-source pieces, stylized classic open-world gameplay, a Mumbai map, modest Windows hardware, and later expansion.

**Decision update, 20 November 2026:** the user selected **Windows PC and Android together**, **8 GB/integrated graphics** as the weaker Windows class, **Android 12** as the OS target, **Bandra West in 1990–1995**, recognizable roads/landmark relationships with compressed distances, and **cars/rickshaws/motorcycles/scooters all player-drivable**. The human reports **some experience and a provisional ten hours/week**. Phone hardware and exact small map boundary remain open. These choices supersede the earlier PC-first/district/era/drivable-role proposals below. Contemporary reference catalogues require dated period checks; no new historical introduction, policy or demolition dates have been inferred. The earlier experienced-developer schedule is a comparison, not a current forecast; rebaseline using both exports and measured handling/review/integration throughput at ten human hours/week.

A read-only check at **20 November 06:21:08 IST (client clock)** found all eleven night jobs technically completed and the supervisor exited normally. Model artifacts were not collected or accepted by that check. The [current handoff](../docs/OVERNIGHT_HANDOFF.md) and [dated receipt](../reports/remote/epyc24/phase0-status-2026-11-20.json) supersede the earlier pending observation below.

Follow-up: the user explicitly requires real-Mumbai buildings, landmarks, rickshaws, cars, motorcycles, and scooters. The [real-world reference research](MUMBAI_REAL_WORLD_REFERENCES.md) now refines the area/asset recommendations below. The former small-roster schedule is a comparison baseline, pending real-asset workload and drivable-role evaluation.

Further work on 19 November added [Indian/Maharashtrian character research](INDIAN_MAHARASHTRIAN_CHARACTERS.md), [chawl research](../docs/CHAWL_MODEL_RESEARCH.md), 21 unique CC BY/download-enabled metadata candidates across the three evidence files, original Blender study generators and a detached night queue. At the approximately 21:14 IST status check, all eleven production jobs were still pending before the 22:00 start; two separate technical smoke studies had succeeded. These results establish a working study/export workflow, not accepted production assets or playable progress. The [project record](../docs/PROJECT_RECORD.md), [phase tracker](../docs/PHASE_PROGRESS.md) and [asset plan](../docs/ASSET_PRODUCTION_PLAN.md) own the updated implementation and acceptance sequence.

## Evidence and limits

This review used official engine documentation, upstream GitHub source/license files, map-provider guidance, and asset publishers. Three parallel research streams examined technical reuse, Mumbai/world production, and scheduling. Recommendations and estimates below are planning judgments; vendor feature descriptions are attributed evidence, not benchmarks.

The source-audit stage did not install a game engine, clone a candidate repository, acquire a third-party model archive, import a local map or benchmark a game. Those game-adoption gates remain open. Subsequent original Blender smoke exports are recorded separately above. Source inspection does not establish build compatibility or production quality. GitHub API metadata requests returned HTTP 403; accessible repository/source pages were used instead. Selected commits, exact engine/toolchain versions, and file-level asset provenance still need recording during adoption.

## 1. Narrow the initial product, then validate it

Recommend one compressed, recognizable district rather than a full Mumbai map. Begin with 0.25–0.5 km² of playable space, six main missions, two or three repeatable activities, four to six vehicle variants, limited combat/pursuit, and a complete ending. Evaluate a 60–120 minute first-play story target at the slice. These quantities are proposed scope controls; neither map size nor mission count has been measured yet.

Bandra West is now the selected first district; its exact small boundary needs dated 1990–1995 references. Girgaon–Marine Drive remains separate architectural research: tourism documents its coastal character. Contemporary airport guidance describes routine metered rickshaws as suburban, but that source does not establish 1990–1995 rules. Keep these regional and period catalogues separate. [Tourism reference](https://maharashtratourism.gov.in/districts/mumbai-city/), [airport transport geography](https://csmia-mumbai.adaniairports.com/Airport-Facilities/Transport)

## 2. Choose the rendering baseline before expensive art

Recommend evaluating a stable Godot release and the Compatibility renderer first. Godot describes that renderer as suited to older desktops and a broad range of hardware. This is a starting hypothesis requiring measurements. At implementation time, check the official release archive and record the exact stable build and matching templates that actually pass validation; this research does not pin an untested engine version. [Renderer guidance](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [release archive](https://godotengine.org/download/archive/)

Use a small material palette, restrained lights/shadows, simple collision, distance-based detail, and explicit population budgets. The engine's optimization guide notes that automatic instancing is renderer-dependent and transparency can be costly; do not assume repeated objects batch automatically under Compatibility. [3D performance guidance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)

The roadmapped 720p/30 FPS target and memory/actor caps are proposed targets. A fast remote development GPU cannot validate the minimum player device. Record actual CPU, GPU, RAM, driver, storage, frame-time distribution, and memory behavior in exported builds.

## 3. OpenCity is a reuse experiment, with concrete adaptation work

The actual OpenCity configuration selects Godot 4.7 / Forward Plus and MSAA. Its traffic source assumes a right-hand rectangular grid and duplicates world constants. Those choices do not match our intended rendering baseline or left-hand, irregular Mumbai streets. [Project configuration](https://raw.githubusercontent.com/webgl-games/opencity/main/project.godot), [traffic implementation](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/traffic.gd)

Its pedestrian manager follows rectangular block loops; vehicle switching uses a fixed exit offset without a visible clearance query. Useful adaptation experiments include the camera, vehicle switching, and basic movement, but safe exits, input mapping, actor persistence, and a shared road graph remain production work. [Pedestrian implementation](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/peds.gd), [vehicle switching](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/game.gd)

OpenCity's inspected code license is MIT. Its credits identify a Quaternius mannequin as CC0; verify the originating pack and bundled notice before copying it. Retain required notices for any selected code. [Code license](https://raw.githubusercontent.com/webgl-games/opencity/main/LICENSE), [asset credits](https://raw.githubusercontent.com/webgl-games/opencity/main/CREDITS.md)

Decision: keep an isolated candidate evaluation. A full fork becomes an option only if import/export, handling, renderer adaptation, and architecture costs beat a focused component approach. Repository popularity is not an adoption test.

## 4. Vehicle feel and CPU cost are an early gate

Godot's VehicleBody3D documentation acknowledges known issues and limits for realism. That does not rule it out for this arcade game; compare it on curbs, barriers, slopes, and repeated collisions before committing. [VehicleBody3D reference](https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html)

Godot Easy Vehicle Physics provides arcade assists and examples, but its README recommends at least 120 physics ticks and says behavior changes with tick rate. This is a reason to measure its CPU/handling tradeoff against a simpler controller, especially with traffic active. Reuse is valuable only if the complete integration remains affordable. [GEVP README](https://raw.githubusercontent.com/DAShoe1/Godot-Easy-Vehicle-Physics/master/README.md)

Ambient traffic should primarily follow a lightweight lane model; reserve expensive nearby interaction for where it affects play. Use left-hand routing from a shared graph, intersection conflict rules, actor caps, and stuck recovery. Those are project design recommendations.

## 5. Build Mumbai from geographic reference plus authored play space

Use a small offline OpenStreetMap vector extract as a candidate starting point. OSM is ODbL-licensed; attribution and applicable derivative-database obligations need recording. Do not assume that a code license covers imported geographic data. OSMF has specific game-attribution guidance. [OSM copyright/license](https://www.openstreetmap.org/copyright), [game attribution guidance](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Computer_games_and_simulations)

BlenderGIS can import OSM XML and query roads/buildings. It is an editor-tool candidate with a GPLv3 license; verify a working Blender/addon pair. Imported roads/footprints still need scale checks, playable geometry, collision, simplified materials, and local art. The tool's license and the source data's terms must be tracked independently. [BlenderGIS](https://github.com/domlysz/BlenderGIS), [license](https://github.com/domlysz/BlenderGIS/blob/master/LICENSE)

Preserve coast/arterial relationships, compress travel distances, widen only where needed, and replace prominent generic frontages with authored modules. Keep source extracts, transformation notes, and game-road data traceable. Use original or separately licensed imagery. Google Maps Platform's terms restrict extraction and certain derivative-content uses; it is not the planned source of game geometry. [Google Maps Platform terms, section 3.2.3](https://cloud.google.com/maps-platform/terms)

Run import tools during development and ship an offline game. Do not make public OSM tile servers the game's live backend; that service has separate capacity/usage rules. [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/)

## 6. Reuse art selectively; measure image-to-3D end to end

Kenney City Kit (Commercial) remains a candidate background kit with a publisher CC0 statement. Quaternius Ultimate Buildings and Modular Streets remain **on hold** because the [current model catalogue](OPEN_MODEL_CATALOGUE.md) records conflicting legacy and current license statements. Preserve the acquired pack's actual notices and inspect materials, dimensions, collision, and import behavior before any adoption. Mumbai-specific frontages, signs, street layout, and props still need consistent art direction. [Kenney kit](https://kenney.nl/assets/city-kit-commercial), [Quaternius buildings](https://quaternius.com/packs/ultimatetexturedbuildings.html), [Quaternius streets](https://quaternius.com/packs/modularstreets.html)

Meshy's documentation supports image inputs, multi-view reconstruction, and topology/poly-count options; additional views reduce unseen-side guessing. Those features justify a trial, not an assumed whole-city pipeline. [Image-to-3D documentation](https://docs.meshy.ai/en/webapp/image-to-3d)

Proposed experiment: ten small representative props, such as a cart, bench, awning, shutter, container, bollard, crate stack, planter, water tank, and decorative object. Compare generated results with adapting reusable models or simple manual modeling. Measure time per **accepted** asset: input preparation, generation attempts, cleanup, scale/pivots, UV/material work, collision, import, and performance. Record source rights and the tool/model/terms used. Adopt the method only in categories where the full cycle improves.

## 7. Keep NPC, mission, and save systems bounded

Start NPCs with simple walk/idle/flee/chase states. Godot's navigation guidance warns against per-frame path resets and simultaneous path requests; stagger work and keep navigation meshes simple. [Navigation performance guidance](https://docs.godotengine.org/en/4.4/tutorials/navigation/navigation_optimizing_performance.html)

Dialogue Manager is a candidate for authored dialogue, with MIT licensing and version-specific Godot support. It is stateless: objective progression and persistence still belong to the game. Beehave is optional if simple AI needs more structure; its authors caution that behavior trees can be excessive for simple cases. [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager), [Beehave](https://github.com/bitbrain/beehave)

Use stable IDs and a save version early. Godot's save tutorial explicitly leaves game-state reconstruction to the developer, so copying a tutorial does not finish save/reload behavior across mission changes. Budget for backups, corrupt/missing saves, checkpoint cleanup, and version migration. [Saving games](https://docs.godotengine.org/en/latest/tutorials/io/saving_games.html)

Start with a resident small map and block-compatible content. If streaming becomes necessary, background resource loading is available, but retrieving a resource before its background load finishes can block; threaded loading alone does not eliminate scene-integration stalls. [Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html)

## 8. Estimate accepted progress, including human integration

The earlier small-roster roadmap budgeted 45–76 base weeks plus 25–35% contingency, with a 15–24 month planning window at 30–40 focused human hours/week; learning/part-time work could extend that to 24–36+ months. These remain comparison estimates pending real-reference work and drivable three-/two-wheeler scope. They are planning judgments, not measured productivity or an agent speedup guarantee.

Use two or three bounded worker streams initially, isolated by file ownership and branch. A single integration owner controls shared APIs, saves, engine upgrades, and accepted builds. If agents propose eight changes/day but the human can accept two, backlog grows by six/day; running more jobs does not improve shipping throughput. Stop downstream work when a prerequisite is unresolved. See [agent workflow](../docs/AGENT_WORKFLOW.md).

Upgradeability should come from stable content formats, saves, and module boundaries. Add districts and systems after the first-release loop is proved. A general engine/framework, huge city, multiplayer, and photorealism are outside the current production envelope.

## Decisions this research enables

Proceed to a short Godot/Compatibility technical evaluation, a controller comparison, a bounded geographic import, and an exported low-spec driving loop. Hold full-map production until hardware/handling/map identity pass. Hold campaign expansion until one representative mission proves the complete pipeline and reveals actual production time.
