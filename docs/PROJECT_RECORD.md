# Aamchi Mumbai Game project record

Updated 22 November 2026. This record brings together the agreed direction, working proposals, evidence, unresolved decisions and reasons for the current production sequence. The [project brief](PROJECT_BRIEF.md) defines the product; the [roadmap](ROADMAP.md) owns scope and schedule; [phase progress](PHASE_PROGRESS.md) records completed work and remaining acceptance gates.

## Current position

The first GitHub version, `85442338c6670b486bad7264eded24e8c9c58479`, is the source baseline for the new `Aamchi-Mumbai-Game` checkout. The game is now **Aamchi Mumbai Game** and Phase 1 has started with a Godot walking and driving prototype and a local Windows export. See the [playtest guide](../prototype/README.md). Actual minimum-device performance and the Android export remain open.

Subsequent research selected Ranwar/Waroda/Chapel Road, acquired the actual ODbL map and selected Godot 4.7.2/Compatibility/GDScript for Windows 10/Android 12. The [06:57:50 IST collection receipt](../reports/remote/epyc24/asset-collection-2026-11-20.json) verifies all **77 generated outputs** against accepted checkpoint hashes. The [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) selects bay/props first after eleven previews/reports and six extra views. Full art/current-reference/runtime gates remain open. At the time, the user deferred Git, recovery and repeatable exports.

At **20 November 2026, 06:21:08 IST (client clock)**, a read-only remote check found all **eleven jobs technically completed**, one charged attempt and one launch each, with no pending, running, failed, exhausted or interrupted jobs. The supervisor had exited normally. The saved worker log records `queue_complete` at **19 November 23:24:33 IST**. No model artifacts were collected during this check; visual, cultural/architectural, rig/collision and game acceptance remain pending. The helper's displayed remote time after supervisor exit is the uncalibrated host clock; use the client observation time here. [Current status snapshot](../reports/remote/epyc24/phase0-status-2026-11-20.json)

The earlier documentation snapshot at **19 November 2026, approximately 21:14 IST**, recorded the remote supervisor running on **epyc24**, unpaused and not stopped, with **11 pending jobs and zero production attempts** ahead of the **19 November 22:00 to 20 November 08:00 Asia/Kolkata** window. Preserve that receipt as historical evidence, superseded by the observation above. [Earlier status snapshot](../reports/remote/epyc24/documentation-status-2026-11-19.json)

Two separate smoke studies have already exported and rendered successfully in remote Blender: a chawl frontage bay and a nauvari drape/body study. They are technical demonstrations with known visual defects, distinct from the eleven production-queue entries. Their evidence and current defects are in the [overnight handoff](OVERNIGHT_HANDOFF.md).

## Workspace boundaries

| Location | Purpose and boundary |
|---|---|
| `C:\Suresh\Software\Aamchi-Mumbai-Game` | Active GitHub-based worktree (`phase-1/prototype`), product, research, modeling tools, and playable prototype. |
| `C:\Suresh\Software\MumbaiStreetGame` | Source for the archived 20 November Phase 0 snapshot and former title. |
| `C:\Suresh\Software\GameDevelopmentResearch` | Earlier independent research workspace for GTA/comparable open-world development processes. Its [README](../../GameDevelopmentResearch/README.md) describes case-study questions and planned deliverables; that is not evidence those studies or a game have been completed. |
| `C:\Suresh\Software\MotionGraphics` | Separate video workspace. The game queue uses an existing remote Blender installation and heavy-work lock; the video project's scripts and services were not modified for this work. |
| `/root/motion/mumbai-gully-heat` on epyc24 | Isolated deployed game-modeling scripts, remote state, logs and generated artifacts. The [runbook](OVERNIGHT_MODELING.md) owns operations. |

Keep new game work in the game workspace. A shared machine or tool installation does not merge the video, general-research and game-production projects.

## User requirements

| ID | Requirement | Consequence for production |
|---|---|---|
| REQ-01 | Use the selected name **Aamchi Mumbai Game** | Preserve this title in the workspace and game-facing proposals. The tagline, palette and logo direction are separate proposals. |
| REQ-02 | Begin with a less realistic, classic Vice City-style open-world city game | Aim for readable stylized geometry and arcade play, with original characters, story, missions, branding and assets. |
| REQ-03 | Base the setting on Mumbai, India | Use real district, road, building, landmark and vehicle references; document geographic compression. |
| REQ-04 | Run on less capable devices; target an 8 GB integrated-graphics Windows PC | Establish a named baseline machine and measure exported builds before expanding visual or simulation cost. The available approximately 16 GB development PC is a stronger test device, not proof of the 8 GB minimum. |
| REQ-05 | Deliver a playable indie game | Prioritize an enjoyable, complete small game and a finished mission loop before expanding the city. |
| REQ-06 | Keep it upgradable as development progresses | Use separable district/content structures, stable IDs, versioned saves and data-defined vehicles/missions. |
| REQ-07 | Plan around one human developer with some experience, provisionally ten hours/week, and a high Codex budget | Assign agents bounded work; include integration, art direction and playtesting within the human's weekly allowance. The user will revisit availability as development progresses. |
| REQ-08 | Search prebuilt open-source components before implementing equivalents | Compare reuse and adaptation against a small custom implementation; inspect code and bundled content separately. |
| REQ-09 | Consider agents working around the clock | Prepare durable tasks and evidence. The currently implemented unattended process executes saved Blender scripts during the requested night window; a continuous reasoning-agent service remains future work. |
| REQ-10 | Buildings, vehicles and landmarks should reflect real Mumbai; all four vehicle families must be player-drivable in the first release | Record subject, year/generation, place, proportions and reference rights. Include cars, rickshaws, motorcycles and scooters; test three-wheel stability and two-wheel riders separately. |
| REQ-11 | Research Indian characters and clothing, especially Maharashtrian, plus Mumbai chawls | Include contemporary everyday clothing and contextual traditional garments; distinguish nauvari from generic sari and actual chawl forms from generic housing. |
| REQ-12 | Queue remote model creation from 10 PM to 8 AM with detailed instructions across Codex sessions | Use the detached, checkpointed night worker, saved JSON briefs, morning review procedure and recovery commands. |
| REQ-13 | Find commercially usable open model sources | Preserve per-item licenses and provenance. A catalogue declaration qualifies a candidate for inspection; it does not inspect an archive, rig, texture or local accuracy. |
| REQ-14 | Ship Windows PC and Android together in the first release; Android 12 is the selected OS target | Require real exports, input/UI and device checks on both platforms from the early prototype. Android 12 does not specify a minimum phone's SoC, RAM or GPU; physical hardware remains open. |
| REQ-15 | Present-day Mumbai only, starting in the selected Ranwar/Bandra West pocket | User change on 22 November supersedes the former historical setting. Preserve recognizable roads/landmarks with compressed distances; use dated current subject references and original fictional cast/missions. |

### Phase 0 answers recorded on 20 November 2026

| Answer | Meaning recorded | What remains open |
|---|---|---|
| 1. B | Windows PC and Android together for the first release | Android minimum device, export and touch-input evidence |
| 2. A | Weaker Windows PC target: 8 GB RAM and integrated graphics | Exact baseline CPU/GPU/driver and a measured exported build |
| 3. A | Bandra West first | Exact small playable boundary |
| 4. C, followed by 1990–1995 (superseded) | Historical 20 November answer only; superseded by present-day Mumbai on 22 November | Retained for decision history. Current production uses present-day references, with no historical reconstruction requirement. |
| 5. A | Preserve recognizable road/landmark relationships; compress distances | Source-backed boundary and compression plan |
| 6. A | Cars, rickshaws, motorcycles and scooters all player-drivable in the first release | Model selection and separate handling/rider feasibility results |
| 7. Some experience; follow-up ten hours/week | Human developer has some experience and provisionally ten focused hours/week | Revisit capacity as work progresses; measure integration/review throughput |
| Android follow-up: Android 12 | Android 12 selected as the OS target | Physical minimum phone, SoC, RAM and GPU remain unspecified |

The blank numbered item 8 adds no decision. On **22 November 2026** the user replaced the earlier setting with **present-day Mumbai only**. Ranwar, Windows 10/Android 12, four first-release drivable families, compressed geography and the sole founder's provisional ten hours/week remain. Current catalogues and OSM now support the active reference direction; each still needs locality, source-rights, fidelity and functional checks. Existing metadata, model identities and dated receipts remain unchanged.

### Subsequent six-item delegation

In the 20 November discussion, the user specified **Windows 10 and Android 12**, delegated the reference-area, engine/components, open-map acquisition and study-refinement choices to research, and said **“I will plan this later”** for the prior list's item 5: Git, recovery and repeatable platform exports. This defers that setup; it does not pass its technical tests. Independent research proceeds without another phone-model/area/engine approval round. See the [selected reference area and acquired map](../research/BANDRA_REFERENCE_AREA_AND_MAP.md) and [selected stack](../research/TECH_STACK_SELECTION.md). Physical device performance remains unverified.

## Decisions and proposals

The status column distinguishes a user choice, an implemented operation and an unresolved production proposal. A recommendation becomes a locked production choice only when its stated evaluation is recorded.

| ID | Subject | Current position | Status / next evidence |
|---|---|---|---|
| DEC-01 | Name | Aamchi Mumbai Game | User renamed the game on 22 November 2026. The Phase 0 archive and model-run receipts document the former title. [Brand guide](BRAND.md) |
| DEC-02 | Art and setting | Stylized present-day real Mumbai with original fictional game content | User selected present-day-only on 22 November. Ranwar/Bandra West remains the first pocket; current local reference and gameplay acceptance remain open. |
| DEC-03 | First player platforms | Windows 10 and Android 12 together | User specified both operating systems. Plan Windows x64/Android ARM64 evaluation; offline play remains proposed. Physical performance and actual exports remain unverified; setup deferred under DEC-21. |
| DEC-04 | Minimum device | Integrated graphics and 8 GB RAM for the weaker Windows target | User selected hardware class. 720p / 30 FPS remains a proposed budget; exact CPU/GPU/driver/storage and measured baseline are open. Android minimum is separately open. |
| DEC-05 | Initial map | One compressed 0.25–0.5 km² playable district with background scenery | Proposed envelope, not a selected or measured boundary. |
| DEC-06 | District | Ranwar–Waroda Road–Chapel Road pocket, Bandra West; preserve relationships and compress distances | Research selection under user delegation. The area/map report owns exact reference crop, smaller playable subset, route and current-reference gaps. South Mumbai remains separate research. |
| DEC-07 | Setting | Present-day Mumbai only | User change on 22 November 2026 supersedes the 20 November 1990–1995 choice. Keep current observation dates/generations and document changes since capture; no period-reconstruction gate remains. |
| DEC-08 | Engine | Godot 4.7.2 standard, Compatibility rendering, typed GDScript | Researched selection with matching templates; installation/export/device validation pending. [Stack selection](../research/TECH_STACK_SELECTION.md) |
| DEC-09 | Gameplay reuse | Built-in engine systems, official demo references and narrowly evaluated vehicle components | Research-selected approach; avoid a wholesale OpenCity fork. Exact selected sources and any downloaded evaluation material belong to the stack report and third-party ledger; no shipping adoption implied. |
| DEC-10 | Campaign envelope | Six main missions, two or three repeatable activities, provisional 60–120 minute first story playthrough | Working production limits; validate fun, throughput and playtime at the slice. |
| DEC-11 | Vehicle roster | Cars, rickshaws, motorcycles and scooters all player-drivable at first release | Four to six body variants remain a proposal. Choose generations visible in contemporary Mumbai, then verify rights, proportions, handling and rider fit; older bodies can appear if current evidence supports them. |
| DEC-12 | Handling order | Prove a car first, then test rickshaw stability and motorcycle/scooter riding, mounting and dismounting | Proposed implementation sequence supporting the selected four-family release. Staging prototypes does not defer a selected family out of release scope. |
| DEC-13 | Geography source | Acquired 20 November 2026 offline OSM snapshot plus authored gameplay adaptation | Retain raw/query/license/attribution/checksums. The dated snapshot is the current spatial baseline, with local access, geometry and changes since capture checked before adoption. Immutable historical-ledger wording is acquisition history, not active scope. [Map report](../research/BANDRA_REFERENCE_AREA_AND_MAP.md) |
| DEC-14 | Asset method | Reuse suitable open assets; author/adapt local identity; measure image-to-3D against alternatives | Production approach. No automated reconstruction tool or quality improvement has been demonstrated here. |
| DEC-15 | First remote batch | Eleven original procedural static studies using existing CPU Blender | All 77 generated files collected/checkpoint-hash verified; preliminary review selects bay/props first. Complete views, art/current-reference, rig/collision and runtime acceptance remain open. |
| DEC-16 | Remote schedule | Sequential work during 22:00–08:00 Asia/Kolkata, shared heavy lock, checkpoint/retry limits | Implemented. [Operational runbook](OVERNIGHT_MODELING.md) |
| DEC-17 | Automatic restart | Detached process survives chat/laptop closure; operator restart after server reboot or terminal queue completion | Current implementation. No boot service is installed. |
| DEC-18 | Effort estimate | Preserve the earlier small-roster comparison baseline and re-estimate after vehicle/reference tests and the slice | No new deadline or AI speedup multiplier is justified by the current evidence. The roadmap owns the ranges. |
| DEC-19 | Asset acceptance | Reference and license acquisition → visual/cultural review → technical preparation → functional import → whole-scene performance | Required production sequence. `status: ok` in an overnight report means technical export only. |
| DEC-20 | Human planning capacity | One developer with some experience; provisionally ten focused hours/week | User supplied capacity and will revisit it as work progresses. Rebaseline using this allowance rather than assuming an experienced full-time developer. |
| DEC-21 | Setup status | GitHub baseline and export setup resumed on 22 November | GitHub source rebaselined. The portable Godot editor and both debug presets are exercised. Device acceptance remains open. |
| DEC-22 | First development release and Android test phone | **0.0.1** on Windows and Android. The user will install and test on a **Redmi Note 9 Pro Max (India)**. | Xiaomi lists Snapdragon 720G, Adreno 618 and 6/8 GB RAM variants. The handset's installed Android/MIUI and RAM variant need to be recorded during the test. [Xiaomi India specifications](https://www.mi.com/in/redmi-note-9-pro-max/specs) |

## Evidence inventory

### Reusable models

The three captured model-metadata files contain **25 records with 25 unique model IDs**. Of those, **21 declare CC BY 4.0 and download enabled**: twelve environment/vehicle candidates, six character/clothing candidates and three generic Indian building components. Four additional character records are holds or exclusions. These counts describe captured metadata, not inspected or adopted model archives.

| Group | Evidence | What remains before adoption |
|---|---|---|
| Vehicles and Mumbai environment | [Open model catalogue](../research/OPEN_MODEL_CATALOGUE.md); [12 metadata records](../research/evidence/sketchfab-models-2026-11-19.json) | Acquire source archives, preserve notices/hashes, inspect materials and scale, confirm subject/generation, optimize and test. |
| Indian characters and garments | [Character research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md); [10 records including holds](../research/evidence/character-models-2026-11-19.json) | Inspect the six open candidates' actual archives, topology, skeletons, weights, animation and suitability. No complete approved Maharashtrian outfit kit was established. |
| Generic building components | [Chawl research](CHAWL_MODEL_RESEARCH.md); [three component records](../research/evidence/chawl-components-2026-11-19.json) | Confirm whether any component fits the selected local reference. A generic Indian house is not a verified Mumbai chawl. |

The actual BDD model leads use bespoke/store terms and remain outside the strict-open shortlist. Quaternius packs with conflicting license statements remain on hold pending exact archive review. The [third-party ledger](THIRD_PARTY.md) owns actual adoption and notices; candidate discovery does not populate the game with shipping assets.

### Real-world identity

The [Mumbai reference research](../research/MUMBAI_REAL_WORLD_REFERENCES.md) covers candidate districts, ordinary buildings, landmarks, transport geography and model-specific vehicles. The [reference register](../assets/references/REFERENCE_REGISTER.md) records source dates and separates subject evidence, photo rights, geographic data and geometry rights.

The follow-up character research adds historical garment-construction and museum references. Those sources help distinguish a divided/back-tucked drape or headwear form; they do not establish clothing frequencies in the selected present-day Bandra setting. The chawl research distinguishes multistorey galleries, low-rise courtyard arrangements and redevelopment-era changes. Production still needs an actual selected building/parcel and date. Modern OEM/photo/landmark references and current transport guidance require dated corroboration before historical use; no exact introduction, demolition or policy dates are inferred here.

### Working modeling tools

| Implemented component | Role | Evidence / remaining boundary |
|---|---|---|
| `tools/modeling/core.py` | Original geometry primitives and material palette | Used by the two successful smoke studies; no imported model/photo inputs. |
| `tools/modeling/chawl.py` | Bay, stair, gallery assembly, low-rise courtyard assembly and service props | Draft design dimensions and simplified construction; architectural/collision acceptance pending. |
| `tools/modeling/characters.py` | Original static body, clothing and headwear massing | No rig/skin weights or accepted garment construction. |
| `tools/build_queued_model.py` | Headless export, four renders, geometry statistics and report | Technical success does not approve art or engine cost. |
| `tools/night_queue.py` | Night-window scheduling, job state, retries, locks and independent deadline | Bounded job executor; no autonomous design reasoning. |
| `tools/remote_night.py` | Allowlisted deployment, calibrated start/control/status and checked collection | Existing SSH credentials remain outside project files. |
| `jobs/night-queue.json` and `jobs/specs/` | Eleven exact production jobs plus two separate smoke specifications | Queue declarations and executable scripts own actual behavior; prose does not instruct a new AI model at runtime. |

The [modeling pipeline](MODELING_PIPELINE.md) explains implementation and limitations. The [asset production plan](ASSET_PRODUCTION_PLAN.md) defines the route from candidates/studies to accepted content.

### Verification already completed

The saved verification ran **37 Windows checks: 35 passes and two symlink-privilege skips**. On the remote Linux system, **all 23 worker tests passed**, including the symlink check. Real Blender smoke exports produced a 300-triangle chawl bay and a 3,240-triangle clothing/body study. An independent watchdog experiment killed its harmless supervisor and confirmed that the child's own timeout terminated it and released its inherited test lock.

The deployment verification also matched 21 deployed source/spec/doc hashes and all eleven job fingerprints, validated 18 JSON files and checked documentation links at that time. These are historical receipts; later documentation edits do not change their recorded timestamp. [Original verification](../reports/overnight-verification.json)

## Open decisions

These decisions are not permission requests for the current documentation work. Record them when their production gate is reached; continue independent research and small evaluations in the meantime.

| ID | Decision required | Why it matters | Phase / accountable role |
|---|---|---|---|
| OPEN-01 | Name the actual 8 GB integrated-graphics Windows baseline device | Hardware class is selected; exact CPU/GPU/driver and exports set usable budgets | Phase 0 / human integrator |
| OPEN-02 | Assemble dated current coverage for the selected Ranwar/Waroda/Chapel pocket | The reference area is selected; current building/vehicle/wardrobe fidelity and authored gameplay changes still need evidence | Phase 0 preparation and Phase 2 / creative/reference owner |
| OPEN-03 | Define and test all four selected drivable implementations | The role choice is resolved; rider, camera, handling, animation and exact model work remain | Phase 0 planning, tested in Phase 1 / human gameplay owner |
| OPEN-04 | Validate the selected engine/components when setup resumes | Godot 4.7.2/Compatibility/GDScript selected; export behavior and integration cost require execution | Phase 0 technical gate, setup deferred / integration owner |
| OPEN-05 | Select one common character body/rig route | Avoids separate incompatible bodies and deformation workflows for every garment | Phase 1 preparation, accepted in Phase 2 / character workflow owner |
| OPEN-06 | Acquire dated, reusable multiview inputs for chosen hero subjects | Enables local fidelity and a lawful reconstruction/adaptation experiment | Phases 0–2 / reference and asset owners |
| OPEN-07 | Select one appropriate landmark and actual chawl reference for the chosen area | Avoids expanding the map to include unrelated researched examples | Phases 0–2 / creative owner |
| OPEN-08 | Evaluate an image-to-3D tool/model and available compute | Current CPU Blender setup proves procedural generation only | Phase 2 experiment / asset workflow owner |
| OPEN-09 | Lock actual campaign/combat scope from the slice | Prevents content production around unproven mechanics | Phase 3 / human creative and gameplay owner |
| OPEN-10 | Rebaseline effort from observed handling, accepted-asset and mission time | Research and raw generation counts cannot predict accepted production throughput | After Phase 1 experiments and Phase 3 / human integrator |
| OPEN-11 | Test the selected Redmi Note 9 Pro Max (India) and record the Android 12 baseline | DEC-22 records the model. Installed OS, actual RAM variant, native input, thermal behavior and measured performance still need verification. | Phase 0 / human integrator |
| OPEN-12 | Reassess the provisional ten human hours/week using actual development/review/playtest work | Initial availability and some experience are recorded; revise the plan when the user's capacity changes | Phase 1 onward / human integrator |

## Risk register

| ID | Material risk | Current response and trigger | Owner / next gate |
|---|---|---|---|
| RISK-01 | No named minimum device or exported performance result | Hold broad art/population expansion until an exported route is measured | Human integrator / Phase 0 baseline |
| RISK-02 | Authenticity work grows beyond a small district | Lock area/year, preserve reference packets and reject unrelated landmarks from the first map | Creative/reference owners / Phase 0 boundary |
| RISK-03 | Open catalogue metadata hides archive or third-party issues | Acquire and inspect per-file notices, textures and provenance before adoption | Asset acquisition owner / per-asset intake |
| RISK-04 | Specifically Maharashtrian garments or chawls need substantial original work | Treat current generators as studies; review silhouettes and construction before rigging or mass production | Character/environment owners / Phase 2 art gate |
| RISK-05 | Static character studies are counted as functional NPCs | Require a shared rig, weights, idle/walk/turn tests, clothing clipping and actual controller integration | Character/gameplay owners / Phase 2–3 |
| RISK-06 | All four selected drivable families exceed the earlier car-focused schedule | Run separate three-wheel/two-wheel handling and rider experiments; re-estimate the selected scope using results | Gameplay owner / Phase 1 |
| RISK-07 | Low triangles conceal high material/object/draw-call cost | Consolidate appropriately and measure populated streets under the actual renderer | Environment/integration owners / Phase 2 benchmark |
| RISK-08 | Unattended generation outruns human review | Bound batches; keep technical, visual, cultural and runtime statuses separate; prioritize accepted work | Human integrator / daily review |
| RISK-09 | Shared remote node is busy, restarts or has clock drift | Shared heavy lock, corrected monotonic scheduling, independent timeouts, checkpoint recovery and explicit restart procedure | Queue operator / runbook |
| RISK-10 | Current workspace lacks a recoverable game repository and repeatable export | Establish version control, recovery and exact component versions before the gameplay prototype grows | Human/integration owners / Phase 0 |
| RISK-11 | Dated or unrelated assets are assumed to represent current Ranwar | Check current locality, generation, facade/redevelopment state, clothing context and viewpoint. Preserve historical sources as background evidence rather than an active historical-era filter. | Reference/environment owners / Phase 0–2 |
| RISK-12 | Image-to-3D assumptions create apparent savings that vanish during cleanup | Run the paired ten-asset experiment and count rejected attempts plus human cleanup/integration | Asset workflow owner / Phase 2 |
| RISK-13 | Simultaneous Android/Windows release is treated as a late export task | Make real-device export, touch controls/UI, save/resume and performance gates part of early development on both platforms | Integration/gameplay owners / Phase 0–1 and each release gate |

## Effort and progress rules

The [roadmap](ROADMAP.md) owns the phase duration table. Its earlier 15–24 month comparison window already assumed substantial agent assistance and an experienced human working 30–40 focused hours per week on the earlier PC-first scope. It is not a delivery estimate for simultaneous Windows/Android, present-day Bandra reconstruction, four drivable families and the user's **some experience at provisionally ten human hours/week**. Human review, integration and playtesting share that allowance even when agents run continuously. Rebaseline after naming both physical device baselines and measuring handling/export and accepted-asset throughput. Do not directly multiply the earlier calendar range by an hours ratio, divide it by agent count or infer a known schedule saving from eleven overnight studies.

Track progress with evidence: researched, source inspected, acquired, technically exported, visually accepted, culturally/architecturally accepted, functional in engine, and accepted on the target device. A later stage requires its own result. Do not assign an overall completion percentage without a defined work breakdown and measured effort.

## Record maintenance

| Information | Owning document or file |
|---|---|
| Product scope and user requirements in brief | [Project brief](PROJECT_BRIEF.md) |
| Milestones, duration assumptions and performance gates | [Roadmap](ROADMAP.md) |
| Phase task status, dependencies and next gate | [Phase progress](PHASE_PROGRESS.md) |
| Research, source claims and model shortlist evidence | [Feasibility](../research/FEASIBILITY_REVIEW.md), [reuse audit](../research/REPOSITORY_AUDIT.md), [model catalogue](../research/OPEN_MODEL_CATALOGUE.md), specialist reference reports |
| Per-asset method, budgets and acceptance workflow | [Asset production plan](ASSET_PRODUCTION_PLAN.md) |
| Reference dates, dimensions and image/data/model provenance | [Reference register](../assets/references/REFERENCE_REGISTER.md) |
| Actual adopted third-party content and notices | [Third-party ledger](THIRD_PARTY.md) |
| Generator/worker architecture and limitations | [Modeling pipeline](MODELING_PIPELINE.md) |
| Remote commands, controls, recovery and morning procedure | [Overnight runbook](OVERNIGHT_MODELING.md) |
| Most recent run receipt, defects and next-session handoff | [Overnight handoff](OVERNIGHT_HANDOFF.md) |
| Exact job inputs, outputs and execution limits | [Queue](../jobs/night-queue.json) and `jobs/specs/*.json` |
| Integration ownership and agent handoffs | [Agent workflow](AGENT_WORKFLOW.md) |

When evidence changes, update its owning record first and then the affected phase tasks. Preserve original receipts, report timestamps, failed logs and superseded artifact identities. Local documentation changes are not deployed over an active worker merely to refresh prose; use the next controlled deployment for its allowlisted runbook copy.
