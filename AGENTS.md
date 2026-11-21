# Mumbai: Gully Heat

This is the game workspace, separate from MotionGraphics. Read README.md, docs/PROJECT_BRIEF.md, docs/PROJECT_RECORD.md and docs/PHASE_PROGRESS.md before changing scope or reporting progress; docs/ROADMAP.md owns schedule and milestone gates. The game targets modest hardware; real Mumbai buildings, landmarks, rickshaws, cars, motorcycles and scooters are required reference categories. Keep original story/characters and record geographic compression.

User choices recorded 20 November 2026: Windows PC and Android together in the first release; an 8 GB integrated-graphics Windows hardware class; Android 12 OS target; Bandra West in 1990–1995 with a gangster-era crime-fiction direction; recognizable roads/landmark relationships with compressed distances; all four vehicle families player-drivable. The human has some experience and provisionally ten focused hours/week, to revisit as development progresses. Small boundary and named physical minimum devices remain open; Android 12 alone does not define phone SoC/RAM/GPU. Do not widen the selected year-band, infer physical hardware or reuse the old experienced/full-time PC estimate as the current schedule. Both export/device/input paths need early gates; keep cast/story/missions original.

Documentation ownership: PROJECT_RECORD owns requirement/decision/risk distinctions; PHASE_PROGRESS owns detailed task status; ASSET_PRODUCTION_PLAN owns production/acceptance steps; MODELING_PIPELINE owns generator architecture; OVERNIGHT_MODELING owns commands/recovery; OVERNIGHT_HANDOFF owns the latest run/defect receipt. Link authoritative records rather than copying tables into several documents. Preserve historic receipts and timestamp current observations. This workspace has no accepted engine build or target-device benchmark; a successful static export must not advance a gameplay gate.

Latest user delegation, 20 November: target **Windows 10 and Android 12**. Choose the reference pocket, best-suited engine/components, commercially reusable offline map and study-refinement priorities through research; do not reopen these choices as permission questions. Selected direction is Ranwar/Waroda/Chapel Road in Bandra West and Godot 4.7.2 standard with Compatibility/GDScript; the detailed selection reports own exact source evidence. **Git, recovery and repeatable Windows/Android export setup are deferred at the user's request** (item 5 of the status list). Do not initialize Git, install SDKs or claim exported/device-tested acceptance merely to close Phase 0. Hardware performance validation remains open without blocking independent research. A modern OSM extract is reference data for a separate 1990–1995 reconstruction layer.

## Current overnight work

The user authorized remote model creation between **22:00 and 08:00 Asia/Kolkata**. Read docs/OVERNIGHT_MODELING.md before operating the queue. jobs/night-queue.json owns the queue; jobs/specs/*.json own individual briefs. jobs/remote.json contains non-secret connection/tool paths. Use existing SSH key authentication; never record passwords/tokens or disable host-key checking.

The remote project is /root/motion/mumbai-gully-heat on epyc24. Respect /root/motion/.jobs/heavy.lock and other users' work. Use tools/remote_night.py for operations. Keep within the project and its generated outputs; do not install packages, change system services or kill unrelated processes as routine queue work.

The Python supervisor executes saved Blender scripts without an active Codex session. It enforces the night window, retries bounded failures and checkpoints results. It is not an unattended reasoning agent. Once all jobs finish it exits; start it again after adding work. A remote reboot requires an explicit restart; the current setup does not install a system boot service.

## Asset acceptance

Overnight outputs are original procedural **static blockouts/studies**. They are not approved production characters, authentic nauvari/pheta, surveyed BDD replicas or tested game assets. A report with status:ok means technical export passed. Cultural/architectural review, rigging/weights, animation, collision and populated-scene performance remain separate gates.

Keep period-appropriate everyday Mumbai clothing alongside contextual traditional clothing. A generic sari is not automatically a nauvari/kashtha drape. Do not label a generic building/shanty kit as a Mumbai chawl. Recheck modern vehicle/landmark/photo references against 1990–1995 and the final Bandra boundary; existing metadata remains candidate evidence, not period approval. Existing study/job IDs, including `contemporary-character-study-v001`, are stable runtime identities and do not establish historical fit. Read research/INDIAN_MAHARASHTRIAN_CHARACTERS.md and docs/CHAWL_MODEL_RESEARCH.md before refinement.

Only use third-party assets under their actual per-file license/provenance terms. NoAI/store/noncommercial content must not enter an open-content or generator-input queue by assumption. Record adopted materials in docs/THIRD_PARTY.md.

## Resuming in a new Codex session

1. Read docs/OVERNIGHT_HANDOFF.md, then run python tools/remote_night.py status. Read remote state and failed-job logs before requeuing anything. Snapshot a consequential status update with client/remote timestamps; a saved deployment receipt is historical evidence.
2. Run python tools/remote_night.py collect. Inspect generated PNGs and report.json files. Keep technical completion separate from visual/cultural approval.
3. Fix the smallest relevant generator/specification and run focused checks. Input/script fingerprints requeue affected completed jobs; do not delete state to force reruns.
4. Deploy only reviewed project files, validate remotely, then start/resume the supervisor. Production work remains inside 22:00–08:00 IST.
5. Record the concrete result, remaining defects and next action in docs/OVERNIGHT_HANDOFF.md. Update affected task evidence/status in docs/PHASE_PROGRESS.md and change a roadmap gate only when its acceptance evidence actually passes.

Documentation-only updates do not require stopping the running queue. Keep them local; the deployment allowlist includes a runbook copy, which can be refreshed during the next controlled deployment. Do not redeploy operational files or restart the worker merely to publish prose.

Tests: python -m unittest discover -s tools/tests -v. Queue preflight: python tools/night_queue.py --root . --validate. Do not infer that a headless export proves animation quality or low-spec frame pacing.
