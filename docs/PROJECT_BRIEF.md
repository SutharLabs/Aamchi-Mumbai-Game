# Mumbai: Gully Heat — project brief

## Selected game title

**Mumbai: Gully Heat** is the selected title. Proposed tagline: “Mumbai never slows down.” See `BRAND.md` for the visual direction.

## Concept

An original, stylized open-world driving and mission game based on real Mumbai. Actual buildings, landmarks, road relationships, and vehicle models establish the setting; simplify their rendering and document map compression. The user selected **Bandra West in 1990–1995**, with a gangster-era crime-fiction direction. Characters, story, missions and branding remain original; the selected Ranwar reference pocket still needs dated per-subject production references and traversal-led final boundaries.

The user's latest delegation settles the operating systems as **Windows 10 and Android 12**, authorizes research-led area/stack/map/study choices and defers Git, recovery and repeatable export setup. The selected reference pocket is **Ranwar–Waroda Road–Chapel Road**, with its small playable subset and modern reference crop documented in the [area/map report](../research/BANDRA_REFERENCE_AREA_AND_MAP.md). Use **Godot 4.7.2 standard, Compatibility and typed GDScript** as the researched implementation choice; see the [stack selection](../research/TECH_STACK_SELECTION.md). Selection does not establish an installed toolchain, build or benchmark.

## Recommended first-release scope

Updated 20 November 2026. The user selected a simultaneous Windows PC/Android first release, an 8 GB integrated-graphics Windows target, Android 12 as the OS target, Bandra West in 1990–1995, recognizable geography with compressed distances, and all four vehicle families player-drivable. Indian/Maharashtrian clothing, real buildings/landmarks and Mumbai chawls remain required research subjects. Quantities, exact model choices and production limits below remain recommendations to validate. The [project record](PROJECT_RECORD.md) records the questionnaire answers and separates user choices from proposals and unresolved decisions.

- One geographically grounded, compressed Bandra West district. The initial 0.25–0.5 km² playable envelope with background scenery remains a proposal; select the actual small boundary. Preserve recognizable roads, landmark relationships and coastline while shortening travel distances. South Mumbai research remains a separate reference group.
- Third-person movement, arcade driving, safe vehicle entry/exit, light traffic/pedestrians, and a bounded pursuit/escape loop.
- One protagonist; cars, rickshaws, motorcycles and scooters all player-drivable in the first release, with provisionally four to six period-appropriate body variants. Track ambient/parked use as well. Test three-wheel stability and two-wheel handling, rider animation and mounting separately. Evaluate simple melee and one firearm in the slice before locking combat scope.
- Indian pedestrians and clothing with room for specifically Maharashtrian garments and headwear in appropriate contexts. Include period-appropriate everyday dress alongside traditional/ceremonial variants; historical references must establish the chosen time/place. Reuse a suitable common body/rig workflow after evaluation; the present static outfit studies have not passed character acceptance.
- Research chawl housing through actual dated local examples. Keep multistorey gallery and low-rise courtyard forms distinct, and select a reference that belongs to the chosen district/year before production. The current studies do not establish an exact BDD replica or a first-map location.
- Six authored main missions, two or three small repeatable activities, a complete ending, and a provisional 60–120 minute first-play story target.
- One safehouse/menu hub, very few interiors, original dialogue/audio, and limited voice work.
- Versioned saves, recovery from missing/corrupt saves, pause/settings, keyboard/mouse/controller input, rebinding and basic accessibility, plus Android touch controls/UI and suspend/resume checks.
- Windows PC and Android together in the first release; offline play is the proposed mode. The user selected an integrated-GPU, 8 GB Windows class and Android 12 as the OS target; 720p / 30 FPS remains a provisional PC budget. Android 12 alone does not specify phone RAM/SoC/GPU. Name and measure both physical device baselines, then establish per-platform render/memory budgets through real exports. The available approximately 16 GB development PC is a stronger test device.

## Defer

Full geographic Mumbai recreation, multiplayer, aircraft/boats, complex interiors, realistic crowds, advanced police simulation, large voice cast, extensive cutscenes, photorealism and major district expansion. Prototype vehicle families in stages while retaining all four as player-drivable first-release requirements. Android is part of that release and needs early export, touch-input and device checks.

## Technology approach

Use the selected Godot 4.7.2 standard build with matching templates, Compatibility and typed GDScript when implementation resumes. Retain actual Windows 10/Android 12 export and device tests as acceptance gates. Compare focused reusable components before writing equivalents; the stack report records selection versus experiment status. OpenCity's renderer/road-graph adaptation costs keep it outside the foundation. Start with a small resident district; keep scenes separable and add streaming only when measurements require it. Retain stable content IDs, data-driven vehicles/missions, and versioned saves for controlled upgrades.

Use existing modular art where it fits real references. Evaluate image-to-3D against asset adaptation/manual work by total accepted-asset time, including reference accuracy, cleanup, collision, and in-engine performance. See [real-Mumbai research](../research/MUMBAI_REAL_WORLD_REFERENCES.md), [reference register](../assets/references/REFERENCE_REGISTER.md), [feasibility review](../research/FEASIBILITY_REVIEW.md), and [repository audit](../research/REPOSITORY_AUDIT.md).

The [asset production plan](ASSET_PRODUCTION_PLAN.md) defines the acquisition and acceptance route. Live metadata has identified reusable candidates, but no third-party model archive has been adopted. Exact nauvari/pheta and chawl gaps currently use original procedural static studies for review. The existing CPU Blender node supports that workflow; image-to-3D reconstruction and a common character rig remain evaluations, not installed capabilities. The [modeling pipeline](MODELING_PIPELINE.md) records the implemented boundary.

## Team and planning assumptions

One human with **some experience** owns integration and creative decisions, with **provisionally ten focused hours/week**, to be revisited as development progresses. Development, review and playtesting all draw on that allowance. Parallel agents get bounded tasks, file ownership, acceptance criteria and review before integration. The detached remote Blender worker completed the eleven prepared jobs during its first requested 22:00–08:00 IST window, with checkpoints and bounded retries. Collection and asset review remain pending. A broad continuous reasoning-agent service has not been configured. The workspace still needs game-project version control and repeatable exports for both player platforms. See the [overnight handoff](OVERNIGHT_HANDOFF.md) for timestamped queue evidence.

The earlier PC-first, small-roster comparison assumed an experienced developer at 30–40 focused hours/week: 45–76 base weeks plus contingency and a 15–24 month planning window, with a longer learning/part-time comparison. Those figures are not a current delivery estimate for simultaneous Android/Windows, 1990–1995 Bandra, all four drivable families and some experience at ten hours/week. Rebaseline using the selected scope/capacity, actual physical devices and early handling/export results; revise again after the slice using measured throughput. Remote generation counts do not establish human review throughput or a new delivery date; the earlier calendar range should not be mechanically scaled by an hours ratio.

The [phased roadmap](ROADMAP.md) owns the milestone schedule and performance gates; [phase progress](PHASE_PROGRESS.md) records completed work and the remaining task sequence; the [agent workflow](AGENT_WORKFLOW.md) owns execution and handoffs.

## Vertical slice success

A new player can start, explore a recognizable local neighborhood on foot/in a vehicle, complete and retry one representative mission, save/quit/reload, and continue without duplicate state or blockers. Exports meet their measured Windows and Android budgets with the intended population/effects; Android touch controls and suspend/resume also pass on a named phone. Separate handling tests cover every selected drivable family before the slice scope is accepted. No implementation or performance gate has passed yet.
