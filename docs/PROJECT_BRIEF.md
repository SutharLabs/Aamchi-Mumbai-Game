# Aamchi Mumbai Game — project brief

## Selected game title

**Aamchi Mumbai Game** is the selected title. Proposed tagline: “Mumbai never slows down.” See `BRAND.md` for the visual direction.

## Concept

An original, stylized open-world driving and mission game based on **present-day Mumbai only**. The user changed the setting on **22 November 2026**, superseding the earlier historical setting. Start in Ranwar/Waroda/Chapel Road, Bandra West, with recognizable real streets, buildings, landmarks and vehicle families. Record geographic compression and use dated current references. Cast, story, missions and branding remain original and fictional.

The selected operating systems remain **Windows 10 and Android 12**. Ranwar is the researched reference pocket; Godot 4.7.2 standard, Compatibility rendering and typed GDScript are the implementation direction. The GitHub baseline and initial Windows prototype/export are now in use; native Android, named minimum devices and measured budgets remain open in the [phase tracker](PHASE_PROGRESS.md). The sole founder directs and integrates bounded agent work.

## Recommended first-release scope

Updated 22 November 2026. Current requirements are present-day Bandra West, simultaneous Windows 10/Android 12 delivery, an 8 GB integrated-graphics Windows target, compressed real geography and all four vehicle families player-drivable. Indian/Maharashtrian clothing, real buildings/landmarks and Mumbai chawls remain reference subjects. Quantities, exact models and production limits below are recommendations to validate; the [project record](PROJECT_RECORD.md) separates current choices from dated history.

- One geographically grounded, compressed Bandra West district. The initial 0.25–0.5 km² playable envelope with background scenery remains a proposal; select the actual small boundary. Preserve recognizable roads, landmark relationships and coastline while shortening travel distances. South Mumbai research remains a separate reference group.
- Third-person movement, arcade driving, safe vehicle entry/exit, light traffic/pedestrians, and a bounded pursuit/escape loop.
- One protagonist; cars, rickshaws, motorcycles and scooters all player-drivable in the first release, with provisionally four to six contemporary body variants. Track ambient/parked use as well. Test three-wheel stability and two-wheel handling, rider animation and mounting separately. Evaluate simple melee and one firearm in the slice before locking combat scope.
- Indian pedestrians and clothing, including contemporary everyday dress alongside contextual Maharashtrian/traditional or ceremonial outfits. Use current local references; historical costume collections support construction/context rather than present-day prevalence. Reuse one evaluated body/rig workflow; static outfit studies have not passed character acceptance.
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

The earlier PC-first, small-roster comparison assumed an experienced developer at 30–40 focused hours/week: 45–76 base weeks plus contingency and a 15–24 month planning window, with a longer learning/part-time comparison. Those figures are not a current delivery estimate for simultaneous Android/Windows, present-day Bandra, all four drivable families and some experience at ten hours/week. Rebaseline using the selected scope/capacity, actual physical devices and early handling/export results; revise again after the slice using measured throughput. Remote generation counts do not establish human review throughput or a new delivery date; the earlier calendar range should not be mechanically scaled by an hours ratio.

The [phased roadmap](ROADMAP.md) owns the milestone schedule and performance gates; [phase progress](PHASE_PROGRESS.md) records completed work and the remaining task sequence; the [agent workflow](AGENT_WORKFLOW.md) owns execution and handoffs.

## Vertical slice success

A new player can start, explore a recognizable local neighborhood on foot/in a vehicle, complete and retry one representative mission, save/quit/reload, and continue without duplicate state or blockers. Exports meet their measured Windows and Android budgets with the intended population/effects; Android touch controls and suspend/resume also pass on a named phone. Separate handling tests cover every selected drivable family before the slice scope is accepted. No implementation or performance gate has passed yet.
