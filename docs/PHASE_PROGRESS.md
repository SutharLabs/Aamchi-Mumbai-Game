# Mumbai: Gully Heat — phase progress and acceptance

Updated **20 November 2026** with the user's Phase 0 answers and a read-only overnight status receipt. This document records evidence, unfinished work and the next acceptance gate. The [roadmap](ROADMAP.md) owns scope, phase definitions, duration estimates and performance targets. The [project record](PROJECT_RECORD.md) owns the consolidated requirements, decisions, risks and evidence index. The [project brief](PROJECT_BRIEF.md) describes the intended game. Preserve the distinct observation times below; generated-output collection and visual/game acceptance remain pending.

## How to read progress

Research, prepared tooling, successful exports and accepted gameplay are different results:

- **Researched:** the cited sources and their limitations have been recorded. A candidate has not thereby been acquired or adopted.
- **Prepared:** a specification, script or queue exists and has the stated checks. The intended output may still be pending.
- **Technically validated:** a specified operation, such as a Blender export, succeeded in the recorded environment. This does not establish visual accuracy or game suitability.
- **Accepted:** the named reviewer has examined the required evidence and recorded that the task's criteria passed, including any relevant game/device checks.
- **Phase complete:** every mandatory exit condition in the roadmap has acceptance evidence. Producing documents or a successful mesh export cannot substitute for an exported playable build.

No progress percentage is assigned: there is no measured total workload or accepted production throughput yet. Roles below describe responsibilities for one developer and bounded agent assistance; they do not assume a staffed team. The human integration owner makes scope, cultural/art, handling and release acceptance decisions. Agents can perform the defined implementation, research and checking work.

## Phase 0 choices recorded on 20 November

The user has selected the following direction. A recorded answer resolves that scope question; it does not prove an export, accepted asset, handling result or performance gate. See the [project record](PROJECT_RECORD.md) for the consolidated decision history.

| Topic | Selected direction | Remaining detail / acceptance |
|---|---|---|
| First-release platforms | **Windows PC and Android together; Android 12 OS target** | Android 12 names an OS, not hardware. Actual phone/model/RAM/SoC/GPU and separate device budgets remain open; both export/install/input pipelines unproven. |
| Windows target | **Weaker 8 GB integrated-GPU PC** | Exact CPU/GPU/RAM layout/driver/storage and test access remain open. The available **16 GB Core i5-1145G7 / Iris Xe / Windows 11** machine is a development/test device, not the accepted minimum. |
| First area | **Bandra West** | Exact bounded neighborhood and playable route still to be selected from dated evidence |
| Setting | **1990–1995**, with a Mumbai crime-story theme | Narrow band now selected. Keep cast/missions original and fictional; date asset models, building states and landmarks within the band, recording subject-specific year assumptions. |
| Map approach | **Compressed real road and landmark relationships** | Source extract, historical comparison, transformation notes and playable dimensions not yet produced |
| Vehicles | **Cars, rickshaws, motorcycles and scooters all player-drivable in the first release** | Period-correct model choices, body/pose fidelity, handling, mounting, recovery and both-platform input/performance remain unproven |
| Human capacity | **Some development experience; provisionally 10 focused hours/week** | User will revisit availability as work proceeds. Include human integration, review and playtesting within this capacity; do not assume the earlier experienced-developer 30–40-hour week. |

The blank additional-answer field adds no decision. Follow-up answers resolved the period to **1990–1995**, Android OS target to **Android 12** and provisional capacity to **10 hours/week**. Physical phone hardware, exact weaker PC and Bandra boundary remain open. No new duration is assigned or derived by multiplying an hours ratio. The earlier PC-first 15–24 month comparison assumed experienced 30–40-hour availability and is not validated for these choices; human review/integration capacity remains a bottleneck to measure.

## Latest delegated selections and acquisition

The user specified **Windows 10 and Android 12**, delegated area/stack/map/study choices to research, and deferred Git, recovery and repeatable export setup. The selected reference pocket is **Ranwar/Waroda/Chapel Road**, with a ~0.2016 km2 first greybox envelope inside a larger modern source crop. **Godot 4.7.2 standard, Compatibility, typed GDScript and built-in Jolt** are selected. See the [area/map report](../research/BANDRA_REFERENCE_AREA_AND_MAP.md) and [stack selection](../research/TECH_STACK_SELECTION.md).

The raw OSM reference and route/preview package are acquired with ODbL notices/hashes. **All 77 generated model/render/report files are collected and match accepted checkpoints**; [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) inspected eleven previews/reports and six extra views, selecting the bay and props first. No tools were installed, engine project built, source/specification deployed or model batch restarted. Physical-device evidence and G0 remain pending. Earlier snapshots below remain historical.

## Current snapshot

**Earlier remote observation:** the [20 November status receipt](../reports/remote/epyc24/phase0-status-2026-11-20.json), checked at client time **06:21:08 IST**, records **all 11 jobs technically completed**, each with one launch/attempt, and no pending/failed/exhausted/interrupted jobs. The supervisor is no longer running, with no pause/stop marker. Its saved corrected-time log records `queue_complete` at **19 November 23:24:33 IST**, inside the authorized window. Only status/metadata and the supervisor log were inspected: **no generated model/render outputs were collected or reviewed**. Use the client observation time; post-exit status exposes the uncorrected node clock rather than the earlier supervisor's calibrated scheduling time.

**Historical baseline retained:** the [19 November snapshot](../reports/remote/epyc24/documentation-status-2026-11-19.json) was captured at client UTC **15:44:39**, with corrected remote time **21:14:38 IST**. It recorded the supervisor running, unpaused and not stopped, with **11 production jobs pending, zero attempts and zero completed jobs**, before the first **19 November 22:00–20 November 08:00 Asia/Kolkata** window. That state is superseded but retained as dated deployment evidence. The [overnight handoff](OVERNIGHT_HANDOFF.md) owns collection, review and operational resumption instructions.

| Phase | Status | Evidence available | Gate still missing |
|---|---|---|---|
| 0. Scope, hardware and reuse decisions | **In progress** | Research/tooling, 11 technically completed studies, dual-platform/8 GB/Bandra/1990–1995/all-four-driving choices and provisional 10-hour week | Exact device hardware, Bandra boundary, validated dual export/toolchain/recovery; generated-output collection and review |
| 1. Walking and driving toy | **Not started** | Controller/repository source audit only | Windows/Android walk/enter/drive/exit/recover loop, native/touch input, all-four-family feasibility and device measurements |
| 2. Mumbai neighborhood and performance proof | **Not started; partial preparation available** | Local reference catalogues, exact asset leads and original procedural-study pipeline | Complete reference packets, accepted local assets, playable map/traffic, recognizability review and exported performance proof |
| 3. Complete vertical slice | **Not started** | Requirements and candidate tooling identified | Complete mission, all four drivable families, save/retry/UI/audio and touch/lifecycle acceptance on both platforms |
| 4. First-release content | **Not started** | Recommended content envelope documented | Entire campaign, repeatables and ending in Windows and Android packages |
| 5. Alpha and beta | **Not started** | Proposed QA and performance gates documented | Both-platform new-player/full-campaign/device observations and resolved release blockers |
| 6. Release candidate and launch readiness | **Not started** | Release acceptance requirements documented | Clean install/update, measured per-platform specs, complete notices and reproducible Windows/Android candidates |

No engine installation, engine project, gameplay prototype, target-device export or accepted target hardware is established by the current records. No game implementation phase has passed. Research and offline modeling preparation may precede a gameplay phase without starting or completing that phase.

## Evidence already completed

| Evidence ID | Completed work and authoritative record | What it establishes / what remains open |
|---|---|---|
| E-01 | [Brief](PROJECT_BRIEF.md), [brand](BRAND.md), [roadmap](ROADMAP.md), [feasibility review](../research/FEASIBILITY_REVIEW.md) | Selected name and proposed small-game limits. E-09 records later platform/Bandra/1990–1995/driving/capacity decisions; exact boundary/device hardware and production quantities still need validation. Estimates remain historical planning judgments. |
| E-02 | [Repository audit](../research/REPOSITORY_AUDIT.md) | Primary-source inspection of reusable code, licenses and concrete adaptation issues. No engine/repository import, build or game benchmark was performed. |
| E-03 | [Real-Mumbai references](../research/MUMBAI_REAL_WORLD_REFERENCES.md), [reference register](../assets/references/REFERENCE_REGISTER.md) | Real buildings/landmarks and four vehicle-family reference leads, geographic constraints and remaining packets. No accepted district extract, survey or measured local asset set. |
| E-04 | [Open-model catalogue](../research/OPEN_MODEL_CATALOGUE.md), [vehicle/environment metadata](../research/evidence/sketchfab-models-2026-11-19.json) | Exact commercially reusable candidate metadata and exclusions. Rescreen for 1990–1995: original discovery does not approve period fit. Archive licenses/components, fidelity, optimization and engine adoption remain uninspected. |
| E-05 | [Indian/Maharashtrian character research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md), [character metadata](../research/evidence/character-models-2026-11-19.json), [chawl research](CHAWL_MODEL_RESEARCH.md), [component metadata](../research/evidence/chawl-components-2026-11-19.json) | Six primary CC BY character/clothing leads and generic building components, contextual cultural/architectural references and an honest catalogue gap. No complete strict-open production-ready nauvari/pheta or Mumbai chawl kit was established in the reviewed sources. No third-party candidate was downloaded or adopted. |
| E-06 | [Runbook](OVERNIGHT_MODELING.md), [queue](../jobs/night-queue.json), [verification receipt](../reports/overnight-verification.json) | Implemented bounded procedural modeling and collection workflow, 11 saved original static-study jobs, retries/checkpoints/window enforcement and tests. It is a saved Blender job runner, not continuous Codex/LLM reasoning or an unattended art-approval service. |
| E-07 | [Chawl-bay preflight report](../reports/preflight/chawl-bay-report.json), [preview](../reports/preflight/chawl-bay-preview.png); [nauvari preflight report](../reports/preflight/nauvari-report.json), [preview](../reports/preflight/nauvari-preview.png), [rear](../reports/preflight/nauvari-rear.png); [watchdog test](../reports/preflight/watchdog-test.json) | Two real Blender preflights exported BLEND/GLB and renders: 300 triangles/25 mesh objects for the bay and 3,240/33 for the outfit study. Watchdog behavior was exercised. These are preflight examples, not completion of the 11 production jobs or accepted architecture/clothing. |
| E-08 | [Deployment manifest](../reports/remote/epyc24/deployment-manifest.json), [start receipt](../reports/remote/epyc24/start-receipt.json), [fresh snapshot](../reports/remote/epyc24/documentation-status-2026-11-19.json), [handoff](OVERNIGHT_HANDOFF.md) | Remote deployment and a running supervisor were observed. At the snapshot all 11 jobs were pending with zero attempts. Deployment is an operational result, not an asset/game acceptance result. |
| E-09 | User's 20 November Phase 0 answers and follow-ups, consolidated in the [project record](PROJECT_RECORD.md) and choices table above | Windows/Android together, Android 12 OS, weaker 8 GB Windows class, Bandra West, 1990–1995, compressed real geography, four player-drivable families, some experience and provisional 10 hours/week selected. Exact boundary/device hardware remain incomplete. This is decision evidence, not a technical pass. |
| E-10 | [20 November read-only status receipt](../reports/remote/epyc24/phase0-status-2026-11-20.json), observed at client 06:21:08 IST | Runner records all 11 jobs technically completed once, declared-output hashes/sizes and normal queue termination. Only metadata/logs inspected; collection, four-view/cultural/architectural review, rigs/collision and game/device acceptance remain pending. |
| E-11 | [Area/acquired map](../research/BANDRA_REFERENCE_AREA_AND_MAP.md), [stack selection](../research/TECH_STACK_SELECTION.md), latest user delegation | Windows 10/Android 12, Ranwar pocket, stable engine and reuse direction selected. Actual commercial-use open map acquired with provenance. Git/recovery/export setup explicitly deferred; no engine execution evidence. |
| E-12 | [Collection receipt](../reports/remote/epyc24/asset-collection-2026-11-20.json), [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) | All 77 output hashes match completed checkpoints. Eleven reports/previews and six extra views inspected; bay/props selected first. Remaining views and cultural/functional/runtime acceptance open. |

Recorded queue checks were **37 Windows tests run: 35 passed and two skipped**, and **23 remote Linux runner tests passed**. The Windows skips concerned unavailable test symlink creation. These results validate stated runner behaviors; they provide no gameplay, animation or low-spec frame-time evidence. The [verification receipt](../reports/overnight-verification.json) preserves their scope.

## Phase 0 — scope, hardware and reuse decisions

**Status: in progress; technical setup deferred at user request.** Research selections and acquisition/review evidence are recorded through E-12. Area/stack/map/refinement choices are made. Git/recovery/repeatable exports and physical-device validation remain unperformed; G0 has not passed.

**Newly learned scope and risks.** The selected **1990–1995 Bandra** setting requires dated reference packets; present-day catalogue candidates cannot automatically stand in for period vehicles/buildings/landmarks. Windows and Android are first-release commitments, adding touch/display, dual export/install and actual-phone lifecycle gates. All four families must be player-drivable; parked/ambient variants cannot replace that scope. The available 16 GB PC cannot certify the weaker 8 GB minimum; Android 12 alone does not name phone hardware. Some experience and a provisional 10-hour week differ from the earlier experienced 30–40-hour assumption. Rebaseline measured accepted work and human review capacity; no new duration or speedup is implied.

| Task ID | Remaining work / status | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P0-01 | **OS/capacity selected:** Windows 10, Android 12, 8 GB iGPU Windows class, some experience, ten hours/week; physical performance pending | Integration owner | Name/test physical devices when setup resumes; no further device question blocks research | E-09; E-11 |
| P0-02 | **Reference pocket selected:** Ranwar/Waroda/Chapel Road, Bandra West, 1990-1995 | World/reference owner | Source crop, ~0.2016 km2 first greybox envelope, connected route and uncertainty ledger; final shipped boundary follows traversal tests | E-11; dated per-subject packets still required |
| P0-03 | **Stack selected:** Godot 4.7.2 standard, Compatibility, typed GDScript, Jolt; execution pending | Technical agent | Versioned primary sources; no installation, exports or device tests | E-11; setup deferred with P0-07 |
| P0-04 | **Reuse strategy selected:** built-in systems/official patterns; optional pinned vehicle comparison | Technical agent | Source/license research recorded; import, handling, touch and performance spikes unperformed | E-02; E-11; P0-03/P0-07 execution |
| P0-05 | **Period/reference preparation in progress;** four drivable families and local housing direction selected | Reference/asset owner | Ranwar village-house evidence and historical-change ledger; vehicle/building/wardrobe packets and complete local/period acceptance still open | E-03 to E-05; E-11; E-12 |
| P0-06 | **Offline open map acquired and source topology checked;** engine import pending | World/tools agent | ODbL XML/query/license/attribution/hash, 1,186.7 m geometric loop and 70.5 m footway; modern source distinct from period reconstruction | E-11; P0-03/P0-07 for engine demonstration |
| P0-07 | **DEFERRED BY USER:** Git, recovery and repeatable Windows/Android export setup | Human/integration owner | No repository, SDK install or clean-checkout/export claim; resume before technical G0 acceptance | Latest user item 5; DEC-21 |
| P0-08 | **77 outputs collected/hash-verified; preliminary visual triage and refinement choice complete** | Asset/review owner | Eleven reports/previews plus six extra views inspected; bay/props first. Remaining 27 views, knowledgeable cultural/architectural review, rig/collision and engine acceptance open | E-10; E-12; asset plan A0-A5 |
| P0-09 | **Delegated selections recorded; technical G0 pending/deferred** | Integration owner | Area, stack, open map, refinement priorities and Windows 10/Android 12 recorded; setup and actual performance evidence remain open | E-11; E-12; P0-07 deferral |

**Next gate G0 - pending deferred setup.** Resume P0-07 before requiring a recoverable checkout and repeatable Windows 10/Android 12 exports on named physical devices. Record input/display/performance evidence and remaining period gaps. Selections do not substitute for technical acceptance; no further permission round is required for the delegated choices.

## Phase 1 — walking and driving toy

**Status: not started.** E-02 supplies candidate selection and known issues; there is no accepted controller, playable loop or game benchmark.

**Newly learned scope and risks.** OpenCity's inspected renderer, rectangular right-hand grid and fixed vehicle-exit offset require real evaluation/adaptation. Controller CPU cost needs separate PC/phone evidence. Android touch must support simultaneous movement/look and driving/actions without relying on a keyboard. Rickshaws add three-wheel stability; motorcycles and scooters both require accepted mounting, rider pose, balance/lean, camera and recovery. All four families are required drivable content; shared code does not make their models/poses interchangeable.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P1-01 | Greybox loop, curbs, slope, narrow passage, barriers and recovery area | World/technical agent | Exported repeatable test route covers all handling hazards and permits recovery | G0 |
| P1-02 | Character/camera/collision, Windows inputs/rebinding and Android touch | Gameplay agent; human tests feel | Walking/camera obstruction pass on both devices; simultaneous touch movement/look/actions and readable menus work without desktop input | P1-01; adopted baseline |
| P1-03 | Compare/tune arcade car controllers and record physics/input cost | Vehicle agent; human accepts handling | Braking/reverse, curbs, slopes, impacts and rendering-rate cases recorded; Windows controls and phone steering/throttle/brake/camera usable; per-device CPU measurements | P1-01; P0-04 |
| P1-04 | Safe entry/exit, blocked-door fallback, restart and flipped/stuck recovery | Gameplay agent | Clearance/ground checks and moving-vehicle rules work through Windows and touch controls; repeated switching does not strand/duplicate player | P1-02; P1-03 |
| P1-05 | Prove feasibility for required drivable rickshaw, motorcycle and scooter after car | Vehicle/animation agent; integrator accepts | Three-wheel stability and two-wheel lean/balance, distinct rider posture/mounting, camera and recovery evidenced on both platforms; failures remain open requirements with added work recorded | P1-03; P0-05 |
| P1-06 | Observe fresh players, capture both-device performance and rebaseline scope/schedule | Human integration owner with QA agent | At least three observations with Windows/Android coverage stated; control/camera/touch blockers resolved; per-device route capture and all-four-driving effort recorded against actual weekly capacity | P1-02–P1-05 |

**Next gate G1.** Windows and Android builds support walk → enter → drive → exit → recover/restart on the actual devices with native/touch controls. Record all-four-family feasibility and distinct motorcycle/scooter rider evidence, fresh-player coverage and per-device costs. Rebaseline before expanding content; parked-only substitution does not satisfy selected drivable scope.

## Phase 2 — Mumbai neighborhood and performance proof

**Status: not started. Partial preparation only:** E-03–E-08 establish initial references/catalogues/tooling and E-10 records technical completion of 11 static studies. Complete dated 1990–1995 Bandra packets and collection/review remain open. No accepted game district, game-ready asset set, traffic implementation or populated-scene benchmark exists in the record.

**Newly learned scope and risks.** No complete strict-open Maharashtrian clothing or Mumbai chawl kit was established; original modeling/adaptation and knowledgeable review remain necessary. A generic sari is not the selected nauvari/kashtha construction, and generic slum/shanty or Dharavi recycling scans do not establish chawl architecture. Multistorey gallery housing and low-rise baithi courtyard housing are separate studies. Historical BDD dimensions do not supply a surveyed plan, and redevelopment makes the chosen reference year consequential. Estimated bay/stair dimensions must be checked for architecture and gameplay. A low triangle count does not establish acceptable draw calls, materials, collision, rig cost or crowded-street performance.

The selected historical Bandra area requires dated local examples rather than mixing unrelated researched locations. Modern model-catalogue entries are not automatically period matches. The actual Android screen, sustained heat/memory behavior and touch visibility need separate quality gates; PC budgets are not phone benchmarks.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P2-01 | Convert the bounded map into playable roads, sidewalks, gullies and blocks | World/tools agent | Scale/origin and compression record; traversable loop/shortcut and believable boundary | G1; P0-06 |
| P2-02 | Author one shared irregular road/lane graph with left-hand routing | Traffic/tools agent | Road placement, turns, routing and map display use the same data; junction/recovery cases demonstrated | P2-01 |
| P2-03 | Acquire/adapt a historical Bandra validation set and record provenance | Art/research agent; integrator accepts | Archive/component terms checked; 8–12 period/local building modules, one appropriate landmark/station exterior and four period-correct drivable-family assets meet scale, silhouette, pivot/material/collision and both-device readability requirements | P0-05; P2-01; catalogue leads |
| P2-04 | Refine and validate chawl modules appropriate to the chosen area/year | Environment agent; knowledgeable reviewer | Named dated typology; usable doors, shared galleries, connected stairs and courtyard/service access; estimated versus verified measurements explicit; in-engine collision/camera/material review | P0-08; P0-02; P2-03 |
| P2-05 | Build a contextual 1990–1995 Indian/Maharashtrian character/clothing sample | Character/animation agent; knowledgeable reviewer | Period-appropriate everyday and occasion-specific traditional categories; dated drape/headwear references; common scale/rig/weights; idle/walk/turn, leg separation/clipping and both-device engine checks | P0-08; P0-05; adopted character base |
| P2-06 | Add period-appropriate district/road permissions and bounded traffic/pedestrians | Traffic/AI agent | Historical/local routing restrictions evidenced rather than copied from current guidance; actor caps, spawn/despawn, staggered updates and stuck recovery exercised on both platforms | P2-02; accepted vehicle/NPC inputs |
| P2-07 | Compare ten representative assets by total accepted production time | Art/tools agent; integrator records result | Reuse/manual versus image-to-3D time includes input rights, retries, cleanup, UV/materials, collision, import and acceptance; adoption decision per useful category | Agreed engine asset contract; P2-03 |
| P2-08 | Measure resident-map traversal on both devices; add streaming only if justified | Performance/tools agent | Windows/Android busy-junction/long-sightline captures, memory/draw-call/material cost and crossing behavior; sustained phone heat/slowdown run; separate budgets and measured reason for streaming with collision/persistent-actor checks | P2-01–P2-06 |
| P2-09 | Review historical recognizability and accept the both-device neighborhood proof | Human director with Mumbai-familiar reviewers and QA | Bandra streetscape/era recognized from PC and phone game views without title; dated fidelity, touch readability, traffic/recovery and both-device performance gates documented | P2-03–P2-08 |

**Next gate G2.** Accept the Windows/Android loop and shortcut, historical Bandra identity, readable touch presentation, traffic/recovery and separate low-spec device budgets together, including sustained phone traversal. Static renders alone do not close this phase. Do not grow the district before both-device measurements pass or optional scope is explicitly reduced.

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
| `contemporary-character-study-v001` | Original generic shirt/trouser street-clothing body | 1990–1995 clothing fit/fidelity, character style, body topology, common rig/weights, animation and populated-scene tests |
| `gandhi-cap-study-v001` | Separate folding-cap accessory | Referenced form/fit, attachment and material/game-camera review |
| `pheta-study-v001` | Folded-cloth headwear massing | Specific intended tying style/occasion, cultural review, fit and game-camera test |

Each job declares editable BLEND, GLB, four PNG views and a technical report; the receipt records declared-output paths with hashes/sizes. Actual files/reports must still be collected and inspected. A `status: ok` report means the export checks passed. It does not mean “authentic Maharashtrian dress,” “approved chawl,” “rigged NPC” or “ready to ship.”

The two daytime **preflight** examples in E-07 are separate from this production batch. Their visual review already identified corrections: the nauvari lower mass reads too much like loose trousers, the pallu is flat, shoulder/neck intersections and cloth construction need refinement, and the chawl bay lacks architectural/material context and game collision review. Keep these issues open even if a rerun exports successfully.

**Operational review sequence:** read the [handoff](OVERNIGHT_HANDOFF.md) and [runbook](OVERNIGHT_MODELING.md), query/collect the actual state, inspect all four views and report per completed job, then record technical outcome and separate pass/fix/reject review. Preserve checkpoints/logs. The supervisor is bounded by the night window, shared heavy-work lock and retry/watchdog rules; it can wait or exit before using a whole night. It does not invent new tasks, run continuous LLM agents, or restart itself after a host reboot.

## Phase 3 — complete vertical slice

**Status: not started.** The mission/save/combat acceptance requirements and optional dialogue/AI candidates are researched. No integrated mission or game-save system exists in the recorded evidence.

**Newly learned scope and risks.** A dialogue addon does not own mission persistence. Static clothing exports do not prove rider poses, combat deformation or crowd performance. All four drivable families and period-appropriate road permissions must work inside the same game. Android touch/combat/UI and background/interruption recovery require acceptance alongside Windows. The slice must measure accepted mission/asset work and cross-platform integration/QA time before replacing planning assumptions.

| Task ID | Remaining work | Owner role | Acceptance evidence | Dependencies |
|---|---|---|---|---|
| P3-01 | Implement objective primitives and stable mission/entity IDs | Gameplay/systems agent | Objective transitions, checkpoint/failure/retry, cancel and actor cleanup demonstrated | G2 |
| P3-02 | Author representative 10–15 minute job, travel, encounter, pursuit and escape | Mission agent; human director | Campaign-relevant route and readable complete mission with reward | P3-01; accepted neighborhood/vehicle roles |
| P3-03 | Evaluate limited melee, one firearm and bounded enemy/pursuit behavior | Gameplay/AI agent; human tests | Readable feedback and failure/recovery; combat scope selected before dependent content | P3-01; P3-02 |
| P3-04 | Implement versioned saves, last-good backup and platform state restoration | Systems agent with QA | Missing/corrupt/old saves, settings/bindings and retry/reload pass on both platforms; phone pause/background/resume/interruption does not lose accepted progression or duplicate actors/rewards | P3-01; P3-02 |
| P3-05 | Integrate native/touch UI/audio, finished street/cast and cheap lighting/weather | UI/audio/art agents; integrator | Phone-readable UI/subtitles/actions, usable touch combat/driving, Windows input/settings and audio controls; actual street/character cost reviewed on both devices | P2 asset acceptance; P3-02 |
| P3-06 | Demonstrate player driving for all four families in the historical mission area | Vehicle/world agent | Car/rickshaw/motorcycle/scooter each drivable on Windows/Android; period/proportions, permitted routes, mounting/rider state, recovery and touch behavior pass | P1-05; P2-06; P3-02 |
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

1. Finish the open parts of **P0-01/P0-02/P0-05**: exact weaker PC and Android 12 phone hardware, Bandra boundary and period-correct subject packets. Carry forward **1990–1995**, compressed real geography, all-four-player-driving and the provisional **10 focused hours/week**; do not reopen these as unanswered choices.
2. Run **P0-03/P0-04**, then **P0-06/P0-07**: prove Windows/Android export/install/native-touch input baselines and a recoverable project before production.
3. Continue **P0-08** by collecting and reviewing the technically completed batch; record separate visual/cultural/architectural fixes. Future generation stays in the authorized night process. Do not promote technical queue completion into accepted Phase 2 content automatically.
4. Record **P0-09/G0**, then build and accept **G1**. Rebaseline both-platform historical-reference and all-four-driving work against observed costs and actual human availability; retain the old schedule only as comparison until then.
5. Progress through **G2** and **G3** before scaling district/campaign production. Replace schedule assumptions with measured accepted work at the slice.

When updating this file, cite the new build/run/review evidence and its date. Keep older receipts for provenance; do not silently turn a dated running/pending snapshot into a later success claim. Update the [handoff](OVERNIGHT_HANDOFF.md) for operational results, this tracker for task/phase acceptance, and the [roadmap](ROADMAP.md) when accepted evidence changes scope or estimates.
