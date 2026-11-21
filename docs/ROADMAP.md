# Mumbai: Gully Heat — phased roadmap

Revised 20 November 2026 with the user's Phase 0 answers: Windows PC and Android together for the first release, a weaker 8 GB integrated-GPU Windows target, Android 12 as the selected Android OS target, Bandra West in **1990–1995**, compressed real geography and all four vehicle families player-drivable. The user reports some experience and provisionally **10 focused hours/week**. Exact device hardware and the Bandra boundary remain open. This roadmap owns scope, schedule assumptions and phase exits. The [phase progress tracker](PHASE_PROGRESS.md) owns completed evidence, remaining task IDs, owners, dependencies and acceptance status; the [project record](PROJECT_RECORD.md) consolidates requirements, decisions and risks. Supporting documents: [real-world reference research](../research/MUMBAI_REAL_WORLD_REFERENCES.md), [reference register](../assets/references/REFERENCE_REGISTER.md), [feasibility findings](../research/FEASIBILITY_REVIEW.md), [repository audit](../research/REPOSITORY_AUDIT.md), and [agent workflow](AGENT_WORKFLOW.md).

## Planning basis

Build a compact, finished, stylized Mumbai open-world action/driving game. One human directs and integrates the work, with substantial Codex use and reusable components. A standalone bounded Blender queue is implemented; the [20 November read-only status receipt](../reports/remote/epyc24/phase0-status-2026-11-20.json) records all eleven original static-study jobs technically completed, with collection and asset review still pending. The [overnight handoff](OVERNIGHT_HANDOFF.md) and [runbook](OVERNIGHT_MODELING.md) own operations and the 22:00–08:00 IST process. This is reviewed procedural job execution; a broad continuous LLM-agent service has not been configured. Accepted progress still depends on human review and playtesting.

The earlier estimates assumed an experienced developer contributing **30–40 focused hours per week**, including integration, art direction, review and playtesting. The user reports **some development experience and provisionally 10 focused hours/week**, to revisit as work proceeds. Human integration, art review and playtesting capacity will constrain accepted throughput. Parallel agent work was already included; do not divide calendar estimates by agent count or directly multiply them by an hours ratio. The earlier PC-first estimates are **not validated for simultaneous Windows/Android delivery, historical-reference work, all four drivable families or this provisional capacity**. No revised duration is invented here. Rebaseline after device/toolchain and handling experiments, then again after the slice using measured accepted work and review time.

**Current milestone status:** Phase 0 is in progress; Phases 1–6 have not started. Phase 2 has partial research/tooling preparation, with reference packets and acceptance still pending. No engine/game implementation gate has passed. The [tracker's dated snapshots](PHASE_PROGRESS.md#current-snapshot) preserve the earlier pending state and the 20 November observation of eleven technically completed jobs with the supervisor exited. Outputs have not been collected or visually/culturally reviewed; technical completion is separate from architectural, rigging and in-game acceptance.

## Recommended first-release envelope

- **Bandra West is selected as the first area**, with compressed real road and landmark relationships. The exact boundary remains open; **0.25–0.5 km² of playable area** plus background scenery remains a recommended size to validate. The selected period is **1990–1995**, with a Mumbai crime-story theme and original fictional cast/missions. Buildings, clothes, vehicles and landmarks must fit dated evidence within that band; record any subject-specific year assumptions. The earlier South Mumbai option is not the selected first area.
- One protagonist, third-person movement, safe vehicle enter/exit, arcade driving, interaction, a lightweight pursuit/escape loop, and limited combat. Evaluate melee plus one firearm in the slice; add a second only if content needs justify it.
- **Cars, rickshaws, motorcycles and scooters are all required to be player-drivable in the first release**. Four to six body variants remains a provisional roster limit. Start the driving prototype with a car/taxi, then prove three-wheel stability and two-wheel/rider behavior; motorcycle and scooter bodies/poses need separate acceptance. Ambient/parked variants may also exist. Choose period-correct models after the year is narrowed. Aircraft and boats remain later work.
- Indian characters and clothing, with reference-backed Maharashtrian garments in their appropriate context alongside everyday street clothing appropriate to **1990–1995**. Chawls must match the selected local typology/year; gallery and baithi courtyard housing are distinct. The reviewed sources did not establish a complete strict-open nauvari/pheta or Mumbai chawl kit, so adaptation/original modeling and knowledgeable review remain part of the asset workload. See [character/clothing research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md) and [chawl research](CHAWL_MODEL_RESEARCH.md).
- Six main missions and two or three small repeatable activities. Target **60–120 minutes for a first story playthrough**, followed by free roam. This is a content target, not a playtime claim.
- One safehouse/menu hub, very few interiors, text-led dialogue with limited voice work, original audio, and a complete ending.
- **Offline Windows PC and Android together in the first release**, with **Android 12** selected as the Android OS target. Windows needs keyboard/mouse and controller; Android needs usable touch movement, camera, driving, actions and menus. The chosen Windows class is a weaker **8 GB integrated-GPU PC**; the available **16 GB Core i5-1145G7 / Iris Xe / Windows 11** machine is a development/test device, not the accepted minimum. Exact weaker PC hardware and the Android phone/model/RAM/SoC/GPU remain to be named and tested; an OS version alone does not identify a performance target.

Quantities and production limits remain recommendations to validate in Phases 0–3. The user's platforms, Bandra West, 1990–1995 period, real-geography compression and four drivable-family choices are selected requirements; they do not establish technical feasibility or complete a phase gate.

## Phase overview

The durations below preserve the earlier **PC-first, experienced-developer, small-roster comparison baseline**. Parallel research/tool/content jobs were included. They are **not revalidated for simultaneous Windows/Android delivery, 1990–1995 Bandra references, all four fully playable vehicle families, some experience or a provisional 10-hour week**. Phase 0 must make the selected scope concrete and prove both export/device baselines; Phase 1 must test handling/input and rebaseline effort. This table is not a current delivery commitment.

| Phase | Base duration | Usable result | Prerequisite |
|---|---:|---|---|
| 0. Scope, hardware, and reuse decisions | 2–3 weeks | Recorded choices and an exported baseline scene | None |
| 1. Walking and driving toy | 4–6 weeks | One character, one car, road loop, safe enter/exit | Phase 0 |
| 2. Mumbai neighborhood and performance proof | 6–10 weeks | Recognizable streets, left-hand traffic, measured traversal | Phase 1 |
| 3. Complete vertical slice | 6–10 weeks | One mission with pursuit/combat, saves, UI, and audio | Phase 2 |
| 4. First-release content | 16–28 weeks | Entire small campaign and district playable | Phase 3 |
| 5. Alpha and beta | 8–14 weeks | Observed new-player runs, performance and save fixes | Phase 4 |
| 6. Release candidate and launch readiness | 3–5 weeks | Installable candidate, credits, release materials, rollback plan | Phase 5 |

**Earlier baseline total: 45–76 weeks.** With **25–35% contingency**, approximately **56–103 weeks** supported a **15–24 month planning window** for the earlier PC-first small roster and experienced 30–40-hour week. Those values are retained for comparison, not validated estimates for the selected dual-platform historical game with four drivable families and a provisional 10-hour week. The earlier **24–36+ months** learning/part-time caveat is also historical; it is not a new personalized forecast for the user's some-experience/10-hour plan.

The earlier first-playable and slice comparisons were about **6–9 base weeks** and **18–29 base weeks**, excluding contingency. They have not been revalidated for the new requirements. No calendar deadline is committed before baseline testing.

## Phase 0 — scope, hardware, and reuse decisions

**Latest delegated selections:** Windows 10 and Android 12; Ranwar–Waroda Road–Chapel Road reference pocket in Bandra West; Godot 4.7.2 standard, Compatibility, typed GDScript and built-in Jolt. The [area/map report](../research/BANDRA_REFERENCE_AREA_AND_MAP.md) records the acquired ODbL sample and smaller playable route; the [stack report](../research/TECH_STACK_SELECTION.md) records exact upstream evidence and optional components. These selections replace the earlier open area/engine/source questions. Physical-device and engine tests remain unperformed. The user explicitly deferred Git, recovery and repeatable platform-export setup; that deferral keeps G0's technical conditions open while research and asset review continue.

**Work**

1. Name the actual weaker 8 GB Windows baseline: CPU, integrated GPU, RAM configuration, OS/driver and storage. Keep the available 16 GB i5-1145G7/Iris Xe Windows 11 machine separate from the minimum. Name the Android 12 phone/model, chipset/GPU, RAM, screen/orientation and test access. Plan ready work around the provisional 10 focused human hours/week and revisit actual review/integration capacity. Both target classes must remain testable even if builds use stronger remote machines.
2. Research selection complete: Godot 4.7.2 standard with exactly matching templates, typed GDScript, Compatibility and built-in Jolt. When setup resumes, acquire/hash the tools and validate actual Windows 10/Android 12 exports and device performance. The stack report separates OS/ABI support from an unmeasured performance promise.
3. Reuse built-in movement/input/animation/UI systems and narrowly reviewed official example patterns. Keep OpenCity outside the foundation and the pinned higher-frequency vehicle controller as an optional comparison; test actual vehicle handling/cost before adoption. Exact references and separate code/content license boundaries are in the stack report.
4. Acquired a small offline Ranwar OSM XML reference with exact query, license, attribution, source timestamp and checksum. Use the documented loop/gully/mission-route proposal; keep the modern reference separate from period reconstruction and actual engine import.
5. **Deferred by the user:** Git, large-file handling, recovery/project-worker setup and repeatable Windows/Android export/install commands. No completion or acceptance evidence is inferred from the deferral. Resume this work before advancing through G0 into the walking/driving implementation gate.
6. Define the Bandra West boundary within the selected **1990–1995** period. Preserve compressed real roads/landmarks; date each real-subject record and note narrower subject-specific years when needed, dimensions/model generation and rights/provenance. Keep the crime-story cast/missions original. Record all four player-drivable families with model choices, milestones and reference gaps; rescreen contemporary catalogue entries against 1990–1995 rather than adopting them unchanged.

**Exit G0 — technical acceptance pending:** a clean checkout imports and exports Windows 10 and Android 12 artifacts; the baseline installs/launches on named physical devices. The hardware/toolchain/dependency record, input/display plan and map feasibility notes exist. The selected Ranwar boundary, 1990–1995 reference assumptions, provisional human capacity and all-four-player-drivable ledger have gaps identified. Research selections and the user's setup deferral do not pass this gate. Resume deferred setup and resolve any baseline failures before production; do not request another permission round merely to record the delegated selections.

## Phase 1 — walking and driving toy

**Work**

- Greybox a road loop with turns, narrow passages, curbs, a slope, barriers, and recovery space.
- Reuse a character/camera starting point. Add responsive movement, camera obstruction handling, collision, Windows keyboard/mouse/controller input and rebinding. Prove Android simultaneous touch movement/look, actions, steering/throttle/brake and readable touch menus on the actual phone.
- Compare a simple arcade controller with the shortlisted raycast vehicle. Exercise braking/reverse, curb strikes, repeated impacts, and 30/60 rendering-rate scenarios. Measure physics tick cost.
- Add enter/exit clearance and ground checks, blocked-door fallback, moving-vehicle rules, restart, and flipped/stuck recovery.
- Put vehicle tuning in data, so variants share controller logic.
- After the car benchmark, assess a period-appropriate rickshaw and two-wheeler handling, then verify both motorcycle and scooter bodies/poses: stability, lean/balance assistance, rider posture, mounting, camera and recovery. All four families remain required player-drivable content. Test the control scheme and CPU cost on both platforms; record additional work and revise the schedule before expanding art.

**Exit:** Windows and Android builds support walk → enter → drive → exit → recover/restart with their intended inputs on the named devices. Observe at least three fresh-player sessions with coverage recorded for both platforms, fix control/camera/touch blockers, and capture route performance per device. All four required drivable families have feasibility evidence, including motorcycle/scooter rider distinctions, and the schedule is rebaselined for their work. This feedback count is a planning minimum, not a statistical study. If handling fails, simplify physics and resolve the requirement before expanding art; do not silently substitute parked-only vehicles.

## Phase 2 — Mumbai neighborhood and performance proof

**Work**

- Convert a bounded map extract into a blockout, then author playable widths, sidewalks, junctions, and gully connections. Document where geography was compressed.
- Use one shared road graph for road placement, lanes, traffic routing, and map display. Implement left-hand lane rules and turns on irregular streets.
- Build a small modular kit: residential/shop frontages, corner, roof, shutter, awning, and props. Reuse vetted background assets; local identity needs intentional art.
- Accept a coherent historical Bandra West validation set: 8–12 modules based on actual neighborhood buildings, one period-appropriate local landmark/station exterior, and recognizable period-correct rickshaw/car/motorcycle/scooter assets. Keep dated reference packets and test recognition from game cameras on Windows and the Android screen.
- Use the [chawl model research](CHAWL_MODEL_RESEARCH.md) and [Indian/Maharashtrian character research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md) for local housing and clothing. The prepared overnight studies are draft inputs to this validation set; technical export alone does not establish cultural accuracy, rigging or runtime readiness.
- Store district and road-class permissions for ambient/player routing. Confirm rickshaw boundary roads and bridge/highway restrictions against the **1990–1995** setting before connecting routes; present-day guidance is a research lead rather than assumed historical evidence. Do not treat every Mumbai road as open to every vehicle.
- Add bounded traffic/pedestrians with spawn/despawn, stuck recovery, staggered updates, and lightweight distant simulation. Start with simple states.
- Start with a small resident map and separable block scenes. Add streaming only if measured memory/loading requires it; then test high-speed crossings, collision availability, and persistent mission actors.
- Run the 10-asset AI-versus-reuse/manual experiment in the research review. Judge total accepted-asset time, including cleanup and engine integration.
- Measure materials, texture memory, draw calls, crowd/vehicle cost and readable touch layout separately on the weaker PC and Android phone; include a sustained phone traversal run to expose heat-related slowdown and memory pressure. Derive Android budgets from that device rather than copying PC limits.

**Exit:** the driveable loop and on-foot shortcut work on both devices; Mumbai-familiar reviewers recognize the intended historical Bandra streetscape without relying on the title. Demonstrate lane rules and recovery. Benchmark a busy junction, long sightline and sustained phone traversal in installed/exported builds before growing the district. If it fails, reduce active area/population, draw calls or material/transparency cost while preserving selected platform and drivable-family scope.

## Phase 3 — complete vertical slice

**Work**

- Author one representative 10–15 minute mission: job acceptance, travel, delivery/encounter, bounded pursuit, escape, and reward. Use campaign-relevant mechanics.
- Build small objective primitives with stable mission/entity IDs, checkpoints, failure/retry, cancel, and cleanup. Reuse dialogue tooling if useful; mission state stays game-owned.
- Evaluate melee and one firearm with readable feedback and a small enemy behavior set. Lock combat scope before authoring dependent missions.
- Implement versioned saves, a last-good backup, graceful corrupt/old-save handling, persistent bindings/settings, UI scaling, subtitles and audio controls on both platforms. Prove pause/background/resume, interruption recovery and touch/UI readability on the Android phone alongside Windows behavior.
- Finish one representative street and a small cast. Add basic sound and one cheap lighting/weather treatment; test its rendering cost.
- Demonstrate player driving for all four vehicle families in the historical reference area on both platforms, with ambient/parked roles as additional variants. Verify model period/proportions, rider behavior and neighborhood fit alongside visual style, input and performance.

**Exit:** unfamiliar-player observations cover completing, failing/retrying, saving/quitting/reloading and continuing on Windows and Android without duplicate rewards or orphaned actors. Phone background/resume and touch play pass. The full slice meets separately measured device budgets. Record human hours per mission/accepted asset, platform integration/QA and defect/rework time, then re-estimate the remaining game. Freeze major mechanics and engine versions for production. Redesign or explicitly revisit scope if evidence fails.

## Phase 4 — first-release content

**Work**

- Author the remaining campaign using the proven kit/systems, with varied routes and objectives rather than a new major mechanic per mission.
- Add the remaining vehicle variants, supporting cast, selected repeatable activities, and ending within the scope envelope.
- Exercise failure/retry, abandonment, save/reload, and world-state cleanup while each mission is authored.
- Keep Windows and Android packages playable as content is added, with fixed per-device release-build benchmark routes and current source/license records. Each new mission must remain usable with touch as well as Windows inputs.
- Track actual mission cycle time; cut optional content if throughput misses the plan. Do not create filler solely to reach a playtime number.

**Exit:** a new game reaches the ending through all planned missions in Windows and Android packages on the named devices, using their intended inputs; no missing platform or core system remains hidden as future polish.

## Phase 5 — alpha and beta

**Work**

- Alpha: freeze content; fix crashes, progression failures, camera/vehicle blockers, and state leaks.
- Beta: observe new players; tune difficulty/readability, settings, inputs, and accessibility basics.
- Exercise save migration/recovery, repeated loading, pause/alt-tab, long sessions, and extreme plausible traversal.
- Run Android install/update, background/resume/interruption, screen/input readability, sustained heat/memory and touch-driving cases on the actual supported phone; keep Windows-specific input/windowing cases too.
- Profile the entire district with peak population, combat/pursuit, and every shipped lighting/weather preset. Cut unsupported presets rather than silently raising minimum hardware.

**Exit:** at least five fresh-player sessions and three full campaign runs leave no known progression blocker, with device/input coverage explicitly recorded for both platforms. Benchmark, save-recovery and platform lifecycle/input cases pass on the intended Windows and Android release builds. No known crash/data-loss/progression blocker is accepted for release. Session counts are planning minima, not proof of zero defects or a substitute for coverage on each platform.

## Phase 6 — release candidate and launch readiness

**Work**

- Verify Windows installation/export on a clean user account or machine and Android install/update on the supported phone, without development tools or network-dependent gameplay services. Confirm settings/saves survive the supported update path.
- Prepare accurate screenshots/trailer, controls help, measured minimum specifications, credits, and third-party notices.
- Preserve both platform artifacts, build/source revision, toolchains, export settings, save fixtures and dependency record; prepare platform-appropriate patch/rollback procedures and Android release-package/signing handling.
- Perform current storefront checks when distribution is selected. Preparing a candidate and externally publishing it are separate tasks.

**Exit:** both candidates install, start, save, resume and reach the ending on their supported hardware with usable native inputs; Android update/background-resume behavior passes. Provenance/notices are complete; release materials and measured specifications describe Windows and Android support accurately.

## Provisional performance targets

These are proposed **Windows** acceptance targets, not measured results or universal device claims. The selected weaker 8 GB class still needs an exact CPU/GPU/driver. The available 16 GB i5-1145G7/Iris Xe Windows 11 device is not accepted minimum hardware. Android needs its own actual phone and measured resolution/frame-time/memory/population/heat budgets in Phase 0; do not apply the Windows table to an unnamed phone.

| Measure | Starting target / rule |
|---|---|
| Baseline | Named Windows x64 integrated-GPU device with 8 GB shared system memory; exact CPU/GPU/driver recorded in Phase 0 |
| Resolution / preset | 1280×720, low preset, 30 FPS target; scalable render resolution where appropriate |
| Frame time | Uncapped exported-build capture after warm-up: 95th percentile ≤33.3 ms; log worst stalls separately |
| Traversal | Investigate recurring frames over 100 ms; cross boundaries at maximum allowed vehicle speed |
| Memory | Initial process working-set guardrail ≤2 GB after warm-up; also measure system commit/shared GPU memory; calibrate in Phase 0 |
| Simulation | Start experiments with 8 nearby ambient vehicles / 12 pedestrians; final caps follow measurements |
| Stability | Repeated laps show no continuing memory growth; save/reload does not multiply persistent actors |

Keep build, route, population seed, resolution, preset, and capture procedure consistent. Low polygon count alone does not control cost: LOD, materials, transparency, instancing, and navigation all matter. [Godot 3D optimization](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html), [navigation performance](https://docs.godotengine.org/en/4.4/tutorials/navigation/navigation_optimizing_performance.html)

## Upgrade path and scope cuts

Use stable content IDs, versioned saves, data-defined vehicles/missions, and separate district scenes from the beginning. Share gameplay/content while keeping platform input, export and device-quality settings explicit. Add a district with those conventions first; expand vehicle variants, interiors, combat, weather or additional platforms individually with benchmarks and save checks. Windows and Android are already first-release requirements. Evaluate engine/addon upgrades on isolated branches with known-good builds for both and a migration record.

If the slice misses its budget, cut optional weather/lighting complexity, interiors/duplicate vehicle variants, side activities/campaign length, district size, then combat/pursuit complexity. Preserve Windows/Android delivery, all four player-drivable families, responsive native inputs, recognizable historical Bandra geography, readable objectives, reliable saves and an ending. Re-estimate after a substantial cut. A change to the selected platforms or drivable families is a scope decision, not an automatic optimization.

## Immediate implementation queue

The [progress tracker's next-work sequence](PHASE_PROGRESS.md#next-work-in-dependency-order) and Phase 0 task IDs own detailed acceptance and dependencies for this queue. Prepared overnight studies are a parallel research/art input; their output does not replace the engine, target-device and handling gates.

1. Name the weaker target PC and Android 12 phone hardware, and define the Bandra boundary; use the selected 1990–1995 period and provisional 10 focused hours/week. The available 16 GB PC is a separate test device.
2. Perform isolated repository import/export/handling evaluations on both platforms; pin selected versions and prove touch input early.
3. Inspect a small Bandra West map-data extract and dated historical references, then select the compressed block-scale boundary/loop.
4. Establish a recoverable project and repeatable Windows/Android exports and installs.
5. Complete period-correct real-building/landmark and four-family vehicle packets; keep all four player-drivable milestones and record their measured effect on the baseline estimate.
6. Use the [model acquisition shortlist](../research/OPEN_MODEL_CATALOGUE.md) for acquisition evaluation, rescreening each candidate against **1990–1995**. Activa, Pulsar and WagonR entries are not approved period matches merely because they were shortlisted earlier. Record archive licenses, provenance, fidelity/adaptation cost and both-device results before adoption; metadata qualification alone does not pass the asset gate.

Research and bounded asset-generation tooling are implemented. No engine/game implementation gate above has passed yet; the prepared study queue does not satisfy those gates by itself. Read the overnight handoff before resuming generation or reviewing outputs.
