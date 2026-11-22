# Aamchi Mumbai Game — phase progress and acceptance

Updated **22 November 2026** for the GitHub rebaseline, rename, and first Phase 1 Windows playtest. Earlier 20 November snapshots remain dated evidence.
Updated **22 November 2026** with the present-day-only scope change and root-validated Windows car/auto evidence. Dated earlier receipts remain below. This document records evidence, unfinished work and the next acceptance gate. The [roadmap](ROADMAP.md) owns scope, phase definitions, duration estimates and performance targets. The [project record](PROJECT_RECORD.md) owns the consolidated requirements, decisions, risks and evidence index. The [project brief](PROJECT_BRIEF.md) describes the intended game. Preserve the distinct observation times below; generated-output collection and visual/game acceptance remain pending.

## How to read progress

Research, prepared tooling, successful exports and accepted gameplay are different results:

- **Researched:** the cited sources and their limitations have been recorded. A candidate has not thereby been acquired or adopted.
- **Prepared:** a specification, script or queue exists and has the stated checks. The intended output may still be pending.
- **Technically validated:** a specified operation, such as a Blender export, succeeded in the recorded environment. This does not establish visual accuracy or game suitability.
- **Accepted:** the named reviewer has examined the required evidence and recorded that the task's criteria passed, including any relevant game/device checks.
- **Phase complete:** every mandatory exit condition in the roadmap has acceptance evidence. Producing documents or a successful mesh export cannot substitute for an exported playable build.

No progress percentage is assigned: there is no measured total workload or accepted production throughput yet. Roles below describe responsibilities for one developer and bounded agent assistance; they do not assume a staffed team. The human integration owner makes scope, cultural/art, handling and release acceptance decisions. Agents can perform the defined implementation, research and checking work.

## Phase 0 choices and 22 November setting update

The user has selected the following direction. A recorded answer resolves that scope question; it does not prove an export, accepted asset, handling result or performance gate. See the [project record](PROJECT_RECORD.md) for the consolidated decision history.

| Topic | Selected direction | Remaining detail / acceptance |
|---|---|---|
| First-release platforms | **Windows 10 and Android 12 together** | Windows debug export launched on the development PC. Minimum Windows hardware, Android export and physical Android hardware/input budgets remain open. |
| Windows target | **Weaker 8 GB integrated-GPU PC** | Exact CPU/GPU/RAM layout/driver/storage and test access remain open. The available **16 GB Core i5-1145G7 / Iris Xe / Windows 11** machine is a development/test device, not the accepted minimum. |
| First area | **Bandra West** | Exact bounded neighborhood and playable route still to be selected from dated evidence |
| Setting | **Present-day Mumbai only**, selected 22 November 2026 | Supersedes the earlier historical setting. Keep Ranwar/Bandra West, current dated references and original fictional cast/missions; no historical reconstruction gate. |
| Map approach | **Compressed real road and landmark relationships** | Source extract, historical comparison, transformation notes and playable dimensions not yet produced |
| Vehicles | **Cars, rickshaws, motorcycles and scooters all player-drivable in the first release** | All four are integrated in the Windows prototype. Production models, rider art, device input and performance remain open. |
| Human capacity | **Some development experience; provisionally 10 focused hours/week** | User will revisit availability as work proceeds. Include human integration, review and playtesting within this capacity; do not assume the earlier experienced-developer 30–40-hour week. |

The blank additional-answer field added no decision. The **22 November** setting change supersedes the earlier historical choice with **present-day Mumbai only**. Windows 10/Android 12, some experience and provisional **10 focused hours/week** remain. Phone hardware, minimum-PC measurements and final shipped boundary are still open. No new duration is assigned from this scope change or from an hours/agent multiplier.

## Latest delegated selections and acquisition

On 20 November the user specified **Windows 10 and Android 12**, delegated area/stack/map/study choices to research, and deferred Git, recovery and repeatable export setup. The selected reference pocket is **Ranwar/Waroda/Chapel Road**, with a ~0.2016 km2 first greybox envelope inside a larger modern source crop. **Godot 4.7.2 standard, Compatibility, typed GDScript and built-in Jolt** are selected. See the [area/map report](../research/BANDRA_REFERENCE_AREA_AND_MAP.md) and [stack selection](../research/TECH_STACK_SELECTION.md).

The raw OSM reference and route/preview package are acquired with ODbL notices/hashes. **All 77 generated model/render/report files are collected and match accepted checkpoints**; [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) inspected eleven previews/reports and six extra views, selecting the bay and props first. That 20 November pass covered research and collection. The 22 November follow-up below records the prototype and Windows setup. Physical-device evidence and G0 remain pending. Earlier snapshots below remain historical.

## Current snapshot

**Earlier remote observation:** the [20 November status receipt](../reports/remote/epyc24/phase0-status-2026-11-20.json), checked at client time **06:21:08 IST**, records **all 11 jobs technically completed**, each with one launch/attempt, and no pending/failed/exhausted/interrupted jobs. The supervisor is no longer running, with no pause/stop marker. Its saved corrected-time log records `queue_complete` at **19 November 23:24:33 IST**, inside the authorized window. Only status/metadata and the supervisor log were inspected: **no generated model/render outputs were collected or reviewed**. Use the client observation time; post-exit status exposes the uncorrected node clock rather than the earlier supervisor's calibrated scheduling time.

**Historical baseline retained:** the [19 November snapshot](../reports/remote/epyc24/documentation-status-2026-11-19.json) was captured at client UTC **15:44:39**, with corrected remote time **21:14:38 IST**. It recorded the supervisor running, unpaused and not stopped, with **11 production jobs pending, zero attempts and zero completed jobs**, before the first **19 November 22:00–20 November 08:00 Asia/Kolkata** window. That state is superseded but retained as dated deployment evidence. The [overnight handoff](OVERNIGHT_HANDOFF.md) owns collection, review and operational resumption instructions.

| Phase | Status | Evidence available | Gate still missing |
|---|---|---|---|
| 0. Scope, hardware and reuse decisions | **In progress** | Scope/map/reuse decisions, collected studies and Windows prototype/export evidence | Named minimum-device measurements and native Android export/install acceptance remain open |
| 1. Walking and driving toy | **In progress** | Windows walking and driving loop with all four vehicle families | Native Android input, minimum-device performance and fresh-player observations remain open |
| 2. Mumbai neighborhood and performance proof | **Not started; partial preparation available** | Local reference catalogues, exact asset leads and original procedural-study pipeline | Complete reference packets, accepted local assets, playable map/traffic, recognizability review and exported performance proof |
| 3. Complete vertical slice | **Not started** | Requirements and candidate tooling identified | Complete mission, all four drivable families, save/retry/UI/audio and touch/lifecycle acceptance on both platforms |
| 4. First-release content | **Not started** | Recommended content envelope documented | Entire campaign, repeatables and ending in Windows and Android packages |
| 5. Alpha and beta | **Not started** | Proposed QA and performance gates documented | Both-platform new-player/full-campaign/device observations and resolved release blockers |
| 6. Release candidate and launch readiness | **Not started** | Release acceptance requirements documented | Clean install/update, measured per-platform specs, complete notices and reproducible Windows/Android candidates |

The 20 November snapshots predate the playable project. The current Windows playtest includes the full initial vehicle roster on the available development PC. Windows 10 minimum hardware, native Android installation and touch, and device performance still require measurement.

## Evidence already completed

| Evidence ID | Completed work and authoritative record | What it establishes / what remains open |
|---|---|---|
| E-01 | [Brief](PROJECT_BRIEF.md), [brand](BRAND.md), [roadmap](ROADMAP.md), [feasibility review](../research/FEASIBILITY_REVIEW.md) | Selected name and proposed small-game limits. E-09 records later platform/Bandra/present-day/driving/capacity decisions; exact boundary/device hardware and production quantities still need validation. Estimates remain historical planning judgments. |
| E-02 | [Repository audit](../research/REPOSITORY_AUDIT.md) | Primary-source inspection of reusable code, licenses and concrete adaptation issues. No engine/repository import, build or game benchmark was performed. |
| E-03 | [Real-Mumbai references](../research/MUMBAI_REAL_WORLD_REFERENCES.md), [reference register](../assets/references/REFERENCE_REGISTER.md) | Real buildings/landmarks and four vehicle-family reference leads, geographic constraints and remaining packets. No accepted district extract, survey or measured local asset set. |
| E-04 | [Open-model catalogue](../research/OPEN_MODEL_CATALOGUE.md), [vehicle/environment metadata](../research/evidence/sketchfab-models-2026-11-19.json) | Exact commercially reusable candidate metadata and exclusions. Rescreen for present-day: original discovery does not approve current local fit. Archive licenses/components, fidelity, optimization and engine adoption remain uninspected. |
| E-05 | [Indian/Maharashtrian character research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md), [character metadata](../research/evidence/character-models-2026-11-19.json), [chawl research](CHAWL_MODEL_RESEARCH.md), [component metadata](../research/evidence/chawl-components-2026-11-19.json) | Six primary CC BY character/clothing leads and generic building components, contextual cultural/architectural references and an honest catalogue gap. No complete strict-open production-ready nauvari/pheta or Mumbai chawl kit was established in the reviewed sources. No third-party candidate was downloaded or adopted. |
| E-06 | [Runbook](OVERNIGHT_MODELING.md), [queue](../jobs/night-queue.json), [verification receipt](../reports/overnight-verification.json) | Implemented bounded procedural modeling and collection workflow, 11 saved original static-study jobs, retries/checkpoints/window enforcement and tests. It is a saved Blender job runner, not continuous Codex/LLM reasoning or an unattended art-approval service. |
| E-07 | [Chawl-bay preflight report](../reports/preflight/chawl-bay-report.json), [preview](../reports/preflight/chawl-bay-preview.png); [nauvari preflight report](../reports/preflight/nauvari-report.json), [preview](../reports/preflight/nauvari-preview.png), [rear](../reports/preflight/nauvari-rear.png); [watchdog test](../reports/preflight/watchdog-test.json) | Two real Blender preflights exported BLEND/GLB and renders: 300 triangles/25 mesh objects for the bay and 3,240/33 for the outfit study. Watchdog behavior was exercised. These are preflight examples, not completion of the 11 production jobs or accepted architecture/clothing. |
| E-08 | [Deployment manifest](../reports/remote/epyc24/deployment-manifest.json), [start receipt](../reports/remote/epyc24/start-receipt.json), [fresh snapshot](../reports/remote/epyc24/documentation-status-2026-11-19.json), [handoff](OVERNIGHT_HANDOFF.md) | Remote deployment and a running supervisor were observed. At the snapshot all 11 jobs were pending with zero attempts. Deployment is an operational result, not an asset/game acceptance result. |
| E-09 | User's 20 November answers and follow-ups, consolidated in [PROJECT_RECORD](PROJECT_RECORD.md) | Historical decision receipt: platform/device class, Bandra, compression, four drivable families and capacity selected; its former historical setting was superseded on 22 November. These answers alone are not technical acceptance. |
| E-10 | [20 November read-only status receipt](../reports/remote/epyc24/phase0-status-2026-11-20.json), observed at client 06:21:08 IST | Runner records all 11 jobs technically completed once, declared-output hashes/sizes and normal queue termination. Only metadata/logs inspected; collection, four-view/cultural/architectural review, rigs/collision and game/device acceptance remain pending. |
| E-11 | [Area/acquired map](../research/BANDRA_REFERENCE_AREA_AND_MAP.md), [stack selection](../research/TECH_STACK_SELECTION.md), latest user delegation | Windows 10/Android 12, Ranwar pocket, stable engine and reuse direction selected. Actual commercial-use open map acquired with provenance. Git/recovery/export setup explicitly deferred; no engine execution evidence. |
| E-12 | [Collection receipt](../reports/remote/epyc24/asset-collection-2026-11-20.json), [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) | All 77 output hashes match completed checkpoints. Eleven reports/previews and six extra views inspected; bay/props selected first. Remaining views and cultural/functional/runtime acceptance open. |
| E-13 | [Phase 1 playtest and smoke commands](../prototype/README.md), [GitHub source baseline](https://github.com/SutharLabs/Aamchi-Mumbai-Game/commit/85442338c6670b486bad7264eded24e8c9c58479) | Rebaselined on local branch `phase-1/prototype` and renamed Aamchi Mumbai Game. Integrated 30/60 cadence smoke checks pass on Godot 4.7.2, including routing clearance, enter/exit recovery and simulated multi-touch. Windows export built and launched on the available Windows 11 Iris Xe PC. Native Android and measured target-device acceptance remain open. |
| E-14 | 22 November scope/second-vehicle checkpoint; [playtest and smoke guide](../prototype/README.md) | Present-day-only setting recorded. Root validated 32/32 integrated Windows checks at fixed 30/60 cadence including auto handling, entry/exit/reset, shared collision and simulated touch. Windows debug artifact launched on available Iris Xe hardware; native Android, physical minimum devices, fresh-player and motorcycle/scooter gates remain open. |
| E-15 | 22 November four-vehicle Windows checkpoint. [Playtest guide](../prototype/README.md) · [Vehicle notes](../prototype/vehicle/README.md) | 67/67 smoke checks pass at each fixed 30 and 60 frame cadence with simulated touch. Both two-wheelers pass mounting, moving exit refusal, braking, dismounting, recovery, collision and visual lean checks. The rendered run passed 52/52 and captured all four marked bays. The Windows debug export launched on the Iris Xe development PC. Device performance and native Android testing remain open. |
| E-16 | 22 November captured locomotion checkpoint. [Motion data and rebuild](../prototype/character/motion/README.md) · [Third-party ledger](THIRD_PARTY.md) | The original skinned player and two Hill Road pedestrians use adapted 100STYLE captures. 75/75 smoke checks pass at each fixed 30 and 60 cadence with simulated touch. The rendered smoke passed 60/60, and the credited Windows debug package launched on the Iris Xe development PC. Native Android, minimum-device performance, production streetscape and rider animation remain open. |

Recorded queue checks were **37 Windows tests run: 35 passed and two skipped**, and **23 remote Linux runner tests passed**. The Windows skips concerned unavailable test symlink creation. These results validate stated runner behaviors; they provide no gameplay, animation or low-spec frame-time evidence. The [verification receipt](../reports/overnight-verification.json) preserves their scope.

## Phase 0 — scope, hardware and reuse decisions

**Status: in progress.** The 22 November GitHub clone and Windows export resume setup. Area, stack, map and refinement choices are made. G0 still requires the Android build and physical minimum-device checks.

**Newly learned scope and risks.** Present-day Bandra uses dated current local references, not a reconstruction of the former era. The existing 20 November OSM baseline and modern catalogue leads are usable starting points, while locality, current appearance, rights and function still need review. Windows/Android, four player-drivable families and actual minimum-device gates remain. The available 16 GB PC cannot certify the weaker 8 GB target; Android 12 does not identify hardware. The sole founder's provisional ten hours/week includes integration/review/playtesting; no schedule saving is inferred.

| Task ID | Remaining work / status | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P0-01 | **OS/capacity selected:** Windows 10, Android 12, 8 GB iGPU Windows class, some experience, ten hours/week; physical performance pending | Integration owner | Name/test physical devices when setup resumes; no further device question blocks research | E-09; E-11 |
| P0-02 | **Reference pocket selected:** Ranwar/Waroda/Chapel Road, Bandra West, present-day | World/reference owner | Source crop, ~0.2016 km2 first greybox envelope, connected route and uncertainty ledger; final shipped boundary follows traversal tests | E-11; dated per-subject packets still required |
| P0-03 | **Windows toolchain exercised.** Godot 4.7.2 standard with Compatibility, typed GDScript and Jolt. | Technical agent | Verified editor and templates. Windows x64 debug export launched on available Iris Xe development PC. Android tooling and named minimum-device tests remain open. | E-11, E-13 |
| P0-04 | **Reuse strategy selected:** built-in systems/official patterns; optional pinned vehicle comparison | Technical agent | Source/license research recorded; import, handling, touch and performance spikes unperformed | E-02; E-11; P0-03/P0-07 execution |
| P0-05 | **Current-reference preparation in progress;** four drivable families and local housing direction selected | Reference/asset owner | Dated current Ranwar village-house, vehicle/building/wardrobe packets and complete local/cultural/functional acceptance remain open. The hashed historical-change ledger is preserved acquisition history, not the current production workflow. | E-03 to E-05; E-11; E-12 |
| P0-06 | **Offline OSM acquired and topology checked; Windows blockout derived from it.** | World/tools agent | ODbL raw/query/license/attribution/hash retained; source loop 1,186.7 m and footway 70.5 m. Current locality/access and authored gameplay adaptation remain to be accepted; source snapshot unchanged. | E-11; E-13; map report |
| P0-07 | **GitHub baseline and Windows export in use.** Android export setup remains open. | Integration owner | Local clone from `8544233`, branch `phase-1/prototype`, project and Windows preset in `prototype/`. Clean Windows re-export and native Android build/device evidence remain to be expanded. | E-13 |
| P0-08 | **77 outputs collected/hash-verified; preliminary visual triage and refinement choice complete** | Asset/review owner | Eleven reports/previews plus six extra views inspected; bay/props first. Remaining 27 views, knowledgeable cultural/architectural review, rig/collision and engine acceptance open | E-10; E-12; asset plan A0-A5 |
| P0-09 | **Research selections and initial Windows verification documented.** G0 remains open. | Integration owner | Native Android export, named minimum devices and performance measurements. | E-11 to E-13 |

**Remaining G0 evidence.** The pinned template archive includes Android templates. The development machine still needs a Java and Android SDK setup and the project needs an Android debug preset. Package Android, launch both builds on named target devices and record performance.

## Phase 1 — walking and driving toy

**Status: started on 22 November 2026.** The Windows prototype supports walking, entering or mounting any of the four vehicles, driving, safe exit and reset. Android hardware testing, minimum-device measurements and fresh-player observations remain open. [Playtest guide](../prototype/README.md)

**Current implementation.** All four vehicles share the Godot character-body arcade controller. The motorcycle and scooter have distinct handling and seated poses, with visual lean on upright collision bodies. The road graph uses modern OSM with authored lanes and scenery. The Windows smoke tests can simulate separate fingers on the touch overlay. [Vehicle implementation](../prototype/vehicle/README.md)

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P1-01 | **Implemented in the Windows prototype.** Ranwar road loop, curbs, footway and handling yard. | World agent | Existing shape-sweep/ramp evidence is E-13. Manual laps, current streetscape matching and actual-device testing remain open; no historical reconstruction requirement. | E-13 |
| P1-02 | **Implemented movement, camera, keyboard/mouse, touch overlay and captured on-foot animation.** | Gameplay agent | Windows idle/walk/jog, two pedestrian paths, vehicle entry and exit transitions, and simultaneous simulated move/look touch pass. Native Android touch, controller and rebinding remain open. | E-13, E-16 |
| P1-03 | **Arcade car integrated.** Acceleration, steering, reverse, braking and adjustable speed. | Vehicle agent | Forward, reverse, braking and ramp climb pass. Controller comparison, impact/curb trials and physical-device profiling remain open. | E-13 |
| P1-04 | **Integrated entry, safe exit and reset.** | Gameplay agent | Moving exit refused. Two blocked sides keep driver in the car. Clear alternate side, enter and reset pass. Native Android and fresh-player checks remain open. | E-13 |
| P1-05 | **All four vehicle families drivable in the Windows prototype.** | Vehicle/animation agent with integrator acceptance | E-15 covers distinct motorcycle and scooter poses and handling, shared collision, mounting and recovery, plus simulated touch. Native Android, named minimum-device performance, and production vehicle and rider art remain open. | P1-03, P0-05, E-15 |
| P1-06 | Observe fresh players, capture both-device performance and rebaseline scope/schedule | Human integration owner with QA agent | At least three observations with Windows/Android coverage stated; control/camera/touch blockers resolved; per-device route capture and all-four-driving effort recorded against actual weekly capacity | P1-02–P1-05 |

**Next gate G1.** Windows and Android builds support walk → enter → drive → exit → recover/restart on the actual devices with native/touch controls. Record all-four-family feasibility and distinct motorcycle/scooter rider evidence, fresh-player coverage and per-device costs. Rebaseline before expanding content; parked-only substitution does not satisfy selected drivable scope.

## Phase 2 — Mumbai neighborhood and performance proof

**Status: not started. Partial preparation only:** references/catalogues/tooling, collected static studies and the Phase 1 Windows blockout are available inputs. Complete dated current Ranwar packets, remaining cultural/architectural/rig/collision review and populated-scene performance acceptance remain open. These inputs do not complete Phase 2.

**Newly learned scope and risks.** No complete strict-open Maharashtrian clothing or Mumbai chawl kit was established; original modeling/adaptation and knowledgeable review remain necessary. A generic sari is not the selected nauvari/kashtha construction, and generic slum/shanty or Dharavi recycling scans do not establish chawl architecture. Multistorey gallery housing and low-rise baithi courtyard housing are separate studies. Historical BDD dimensions do not supply a surveyed plan, and redevelopment makes the chosen reference year consequential. Estimated bay/stair dimensions must be checked for architecture and gameplay. A low triangle count does not establish acceptable draw calls, materials, collision, rig cost or crowded-street performance.

The selected present-day Bandra area needs dated local examples rather than unrelated researched locations. Contemporary model candidates are eligible for acquisition review without the former historical-era exclusion; locality, exact generation, rights, fidelity and function remain unaccepted until checked. Actual Android touch visibility, sustained heat/memory behavior and quality budgets need separate evidence.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P2-01 | Convert the bounded map into playable roads, sidewalks, gullies and blocks | World/tools agent | Scale/origin and compression record; traversable loop/shortcut and believable boundary | G1; P0-06 |
| P2-02 | Author one shared irregular road/lane graph with left-hand routing | Traffic/tools agent | Road placement, turns, routing and map display use the same data; junction/recovery cases demonstrated | P2-01 |
| P2-03 | Acquire/adapt a present-day Bandra validation set and record provenance | Art/research agent; integrator accepts | Archive/component terms checked; 8–12 current/local building modules, one appropriate landmark/station exterior and four contemporary drivable-family assets meet scale, silhouette, pivot/material/collision and both-device readability requirements | P0-05; P2-01; catalogue leads |
| P2-04 | Refine and validate chawl modules appropriate to the chosen area/year | Environment agent; knowledgeable reviewer | Named dated typology; usable doors, shared galleries, connected stairs and courtyard/service access; estimated versus verified measurements explicit; in-engine collision/camera/material review | P0-08; P0-02; P2-03 |
| P2-05 | Build a contextual present-day Indian/Maharashtrian character/clothing sample | Character/animation agent; knowledgeable reviewer | Contemporary everyday and occasion-specific traditional categories; dated drape/headwear references; common scale/rig/weights; idle/walk/turn, leg separation/clipping and both-device engine checks | P0-08; P0-05; adopted character base |
| P2-06 | Add current district/road permissions and bounded traffic/pedestrians | Traffic/AI agent | Verify dated current local route/vehicle restrictions and map tags; actor caps, spawn/despawn, staggered updates and stuck recovery exercised on both platforms. Do not infer that every road allows every vehicle. | P2-02; accepted vehicle/NPC inputs |
| P2-07 | Compare ten representative assets by total accepted production time | Art/tools agent; integrator records result | Reuse/manual versus image-to-3D time includes input rights, retries, cleanup, UV/materials, collision, import and acceptance; adoption decision per useful category | Agreed engine asset contract; P2-03 |
| P2-08 | Measure resident-map traversal on both devices; add streaming only if justified | Performance/tools agent | Windows/Android busy-junction/long-sightline captures, memory/draw-call/material cost and crossing behavior; sustained phone heat/slowdown run; separate budgets and measured reason for streaming with collision/persistent-actor checks | P2-01–P2-06 |
| P2-09 | Review historical recognizability and accept the both-device neighborhood proof | Human director with Mumbai-familiar reviewers and QA | Bandra streetscape/era recognized from PC and phone game views without title; dated fidelity, touch readability, traffic/recovery and both-device performance gates documented | P2-03–P2-08 |

**Next gate G2.** Accept the Windows/Android loop and shortcut, present-day Bandra identity, readable touch presentation, traffic/recovery and separate low-spec device budgets together, including sustained phone traversal. Static renders alone do not close this phase. Do not grow the district before both-device measurements pass or optional scope is explicitly reduced.

### Prepared overnight studies supporting Phase 2

The following were **all technically completed**, with one launch/attempt each, in the client **20 November 06:21:08 IST** receipt. At the preserved **19 November 21:14 IST** snapshot all had still been pending. Queue IDs/briefs are authoritative in [night-queue.json](../jobs/night-queue.json). The batch uses original procedural geometry without imported external meshes/photos. Output collection and visual/cultural/architectural/rig/game reviews remain pending; these are static studies, not accepted characters/buildings.

| Job ID | Intended study | Acceptance still required after technical export |
|---|---|---|
| `chawl-frontage-bay-v001` | Room/door/window/shared-gallery module | Dated architectural correspondence, openings, dimensions, pivots, collision and material/context review |
| `chawl-stair-v001` | Switchback flights, landings and rails | Gallery/landing connection, player clearance, walkable collision and camera tests |
| `gallery-chawl-study-v001` | Small repeated-gallery G+3 assembly | Typology/locality review; not an exact surveyed 80-room BDD replica; traversal and rendering checks |
| `baithi-chawl-study-v001` | Separate low-rise two-row courtyard assembly | Reference-specific layout and courtyard/service circulation; distinct from gallery housing |
| `chawl-props-v001` | Shared wash/laundry/service objects | Local placement, proportions, readability, materials and collision/performance choices |
| `kurta-dhoti-cap-study-v001` | Original traditional adult outfit silhouette | Garment construction/context, topology, rigging/weights, movement and clipping review |
| `nauvari-kashtha-study-v001` | Divided lower drape, back-tuck and pallu massing | Knowledgeable drape review, cloth/body separation, topology, deformation and engine tests |
| `everyday-sari-study-v001` | Ordinary sari/blouse study | Explicit generic drape/context label, garment construction, rig and clipping tests |
| `contemporary-character-study-v001` | Original generic shirt/trouser street-clothing body | present-day clothing fit/fidelity, character style, body topology, common rig/weights, animation and populated-scene tests |
| `gandhi-cap-study-v001` | Separate folding-cap accessory | Referenced form/fit, attachment and material/game-camera review |
| `pheta-study-v001` | Folded-cloth headwear massing | Specific intended tying style/occasion, cultural review, fit and game-camera test |

Each job declares editable BLEND, GLB, four PNG views and a technical report; the receipt records declared-output paths with hashes/sizes. Actual files/reports must still be collected and inspected. A `status: ok` report means the export checks passed. It does not mean “authentic Maharashtrian dress,” “approved chawl,” “rigged NPC” or “ready to ship.”

The two daytime **preflight** examples in E-07 are separate from this production batch. Their visual review already identified corrections: the nauvari lower mass reads too much like loose trousers, the pallu is flat, shoulder/neck intersections and cloth construction need refinement, and the chawl bay lacks architectural/material context and game collision review. Keep these issues open even if a rerun exports successfully.

**Operational review sequence:** read the [handoff](OVERNIGHT_HANDOFF.md) and [runbook](OVERNIGHT_MODELING.md), query/collect the actual state, inspect all four views and report per completed job, then record technical outcome and separate pass/fix/reject review. Preserve checkpoints/logs. The supervisor is bounded by the night window, shared heavy-work lock and retry/watchdog rules; it can wait or exit before using a whole night. It does not invent new tasks, run continuous LLM agents, or restart itself after a host reboot.

## Phase 3 — complete vertical slice

**Status: not started.** The mission/save/combat acceptance requirements and optional dialogue/AI candidates are researched. No integrated mission or game-save system exists in the recorded evidence.

**Newly learned scope and risks.** A dialogue addon does not own mission persistence. Static clothing exports do not prove rider poses, combat deformation or crowd performance. All four drivable families and contemporary road permissions must work inside the same game. Android touch/combat/UI and background/interruption recovery require acceptance alongside Windows. The slice must measure accepted mission/asset work and cross-platform integration/QA time before replacing planning assumptions.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P3-01 | Implement objective primitives and stable mission/entity IDs | Gameplay/systems agent | Objective transitions, checkpoint/failure/retry, cancel and actor cleanup demonstrated | G2 |
| P3-02 | Author representative 10–15 minute job, travel, encounter, pursuit and escape | Mission agent; human director | Campaign-relevant route and readable complete mission with reward | P3-01; accepted neighborhood/vehicle roles |
| P3-03 | Evaluate limited melee, one firearm and bounded enemy/pursuit behavior | Gameplay/AI agent; human tests | Readable feedback and failure/recovery; combat scope selected before dependent content | P3-01; P3-02 |
| P3-04 | Implement versioned saves, last-good backup and platform state restoration | Systems agent with QA | Missing/corrupt/old saves, settings/bindings and retry/reload pass on both platforms; phone pause/background/resume/interruption does not lose accepted progression or duplicate actors/rewards | P3-01; P3-02 |
| P3-05 | Integrate native/touch UI/audio, finished street/cast and cheap lighting/weather | UI/audio/art agents; integrator | Phone-readable UI/subtitles/actions, usable touch combat/driving, Windows input/settings and audio controls; actual street/character cost reviewed on both devices | P2 asset acceptance; P3-02 |
| P3-06 | Demonstrate player driving for all four families in the present-day mission area | Vehicle/world agent | Car/rickshaw/motorcycle/scooter each drivable on Windows/Android; generation/proportions, permitted routes, mounting/rider state, recovery and touch behavior pass | P1-05; P2-06; P3-02 |
| P3-07 | Observe both-platform complete/retry/save/reload and measure full slice/throughput | Human integrator with QA/performance agent | Unfamiliar-player evidence and budgets per device; phone lifecycle/touch cases; human asset/mission hours, cross-platform integration/QA and rework recorded; remaining game re-estimated and versions/mechanics frozen | P3-02–P3-06 |

**Next gate G3.** New-player coverage on Windows and Android demonstrates complete/fail/retry/save/quit/reload/continue without state duplication/blockers, plus phone touch/background-resume. All four families are player-drivable and the installed/exported slice meets each device's budget. Accept measured throughput and revised schedule before campaign expansion.

## Phase 4 — first-release content

**Status: not started.** Six main missions, two or three repeatables and 60–120 minute first-play target remain recommended limits, not authored or measured content.

**Newly learned scope and risks.** Reference accuracy, animation integration and cleanup can dominate even when agents generate geometry quickly. Every added mission must remain playable with Windows and touch inputs and within separate device budgets. The accepted kit must support varied objectives without a major new mechanic each time. The story needs an ending and reliable state rather than filler to reach a playtime number.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P4-01 | Author remaining main missions using accepted systems on Windows/Android | Mission/content agent; human director | Each mission completes, fails/retries and cleans up with Windows and phone touch inputs under the established contract | G3 |
| P4-02 | Complete selected repeatables, cast, vehicle variants and district dressing | World/character/vehicle agents | Accepted scope/roles and provenance; reused styles/rigs; no unapproved expansion | G3; measured production plan |
| P4-03 | Implement ending and complete both-platform campaign progression | Mission/systems agent | Windows and Android packaged new-game-to-ending paths, rewards/unlocks and post-ending free roam as scoped | P4-01; P4-02 |
| P4-04 | Check abandon/reload/failure state per content addition | QA agent; integrator | Mission fixtures and play evidence show no duplicate rewards, stranded actors or lost progression | Each P4-01–P4-03 increment |
| P4-05 | Track content throughput, per-device benchmark and source/license register | Integrator with QA/art agents | Actual cycle/rework/platform QA time and populated Windows/phone costs recorded; touch/lifecycle regressions checked; explicit optional cuts if needed; current adopted-file notices | Throughout Phase 4 |

**Next gate G4.** Windows and Android packages reach the ending through selected missions/repeatables on their actual devices and inputs, with all four player-drivable families. No missing platform support or core system is deferred as polish; remaining work is quality/release readiness.

## Phase 5 — alpha and beta

**Status: not started.** Current runner tests and preflight reviews are tooling checks; they do not count as game alpha/beta observations.

**Newly learned scope and risks.** Narrow circulation, four driven vehicle types, crowds and shared spaces create combined camera/collision/state/performance cases. The weaker PC and actual phone must both remain reference devices through peak traffic/pursuit, long traversal and shipped presets. Android heat/memory pressure, background/resume and touch readability need observed coverage rather than a successful desktop port alone.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P5-01 | Freeze content and triage crashes/progression/camera/vehicle/state blockers | Integration owner with QA/gameplay agents | Reproducible prioritized defect register; no hidden incomplete core feature | G4 |
| P5-02 | Observe at least five fresh-player sessions and tune Windows/touch readability/input | Human playtest coordinator with QA agent | Both-platform/device coverage stated; observations, accessibility findings, fixes and retests recorded; count is a planning minimum, not a substitute for platform coverage | P5-01 |
| P5-03 | Run at least three full campaigns and both-platform save/recovery/migration cases | QA/systems agents; human observes gameplay | Windows/Android coverage recorded; no known blocker; repeated/corrupt/old saves, settings and reward/actor persistence pass; Android supported update path checked | P5-01; candidate save schema |
| P5-04 | Exercise long play, platform lifecycle and peak traversal/population/pursuit | QA/performance agent | Windows pause/alt-tab/input and Android install/update/background-resume/interruption/touch tests; actual device captures across district/presets including sustained phone heat/memory; issues fixed or optional cost removed | P5-01; P4-05 benchmark |
| P5-05 | Resolve release blockers and accept alpha/beta exit | Human integration owner | No known crash/data-loss/progression blocker; benchmark, save recovery and relevant regressions pass | P5-02–P5-04 |

**Next gate G5.** Meet observation/full-run minima with Windows/Android coverage documented; pass both device/save/input/lifecycle cases and sustained phone measurements with no release blocker. Counts alone do not prove quality on each platform. Cut optional load/presets instead of silently dropping a selected platform or raising its minimum.

## Phase 6 — release candidate and launch readiness

**Status: not started.** No release build, storefront choice, external publication or measured minimum specifications are accepted.

**Newly learned scope and risks.** Terms must match actual shipped files, not only listing metadata. The clean Windows install and Android install/update must run offline without developer tools or the modeling node. Both artifact/toolchain records and Android release-package/signing handling need deliberate preparation. Materials must reflect actual historical content, four-family driving and measured platform support. Candidate preparation and external publication remain separate actions.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P6-01 | Verify Windows clean install and Android install/update/start/save/continue/ending | QA/build agent; human accepts | Both exact candidates run offline on supported devices without developer tools; native/touch inputs, Android resume and supported update/save preservation pass | G5 |
| P6-02 | Finish accurate platform controls/help, screenshots/trailer, measured specs and notices | Human publisher with art/research agent | Windows/Android materials match candidates and tested devices; touch help and geography/data/asset credits/notices complete | P6-01; current adopted-file register |
| P6-03 | Preserve both candidates, source/toolchains and patch/rollback procedures | Build/integration owner | Recoverable Windows/Android artifacts, source revision, export/toolchain/dependency records, save fixtures and Android release-package/signing handling | P6-01; P6-02 |
| P6-04 | Check selected distribution channels and record both-platform readiness | Human publisher with research/QA agent | Current Windows/Android distribution checklists and explicit candidate acceptance; external publishing handled separately | P6-01–P6-03; distribution choice |

**Next gate G6.** Windows and Android candidates install, start, save, resume and reach the ending on supported devices with usable inputs; Android update/background-resume cases pass. Materials/specifications/notices match both reproducible artifacts and patch procedures. One platform's success does not complete simultaneous-release readiness.

## Next work in dependency order

1. Finish the open parts of **P0-01/P0-02/P0-05**: exact weaker PC and Android 12 phone hardware, Bandra boundary and contemporary subject packets. Carry forward **present-day**, compressed real geography, all-four-player-driving and the provisional **10 focused hours/week**; do not reopen these as unanswered choices.
2. Run **P0-03/P0-04**, then **P0-06/P0-07**: prove Windows/Android export/install/native-touch input baselines and a recoverable project before production.
3. Continue **P0-08** by collecting and reviewing the technically completed batch; record separate visual/cultural/architectural fixes. Future generation stays in the authorized night process. Do not promote technical queue completion into accepted Phase 2 content automatically.
4. Continue the Phase 1 Windows playtest while completing the remaining **P0-09/G0** device/export evidence. Use **G1** to capture actual vehicle, input and playtest costs before changing the schedule.
5. Progress through **G2** and **G3** before scaling district/campaign production. Replace schedule assumptions with measured accepted work at the slice.

When updating this file, cite the new build/run/review evidence and its date. Keep older receipts for provenance; do not silently turn a dated running/pending snapshot into a later success claim. Update the [handoff](OVERNIGHT_HANDOFF.md) for operational results, this tracker for task/phase acceptance, and the [roadmap](ROADMAP.md) when accepted evidence changes scope or estimates.
