# Aamchi Mumbai Game

This is the game workspace, separate from MotionGraphics. Read README.md, docs/PROJECT_BRIEF.md, docs/PROJECT_RECORD.md and docs/PHASE_PROGRESS.md before changing scope or reporting progress; docs/ROADMAP.md owns schedule and milestone gates. The game targets modest hardware; real Mumbai buildings, landmarks, rickshaws, cars, motorcycles and scooters are required reference categories. Keep original story/characters and record geographic compression.

Current project scope: Windows PC and Android together in the first release; an 8 GB integrated-graphics Windows hardware class; Android 12 OS target; present-day Mumbai only, starting in Ranwar, Bandra West, with original crime fiction; recognizable roads/landmark relationships with compressed distances; all four vehicle families player-drivable. The human has some experience and provisionally ten focused hours/week, to revisit as development progresses. Small boundary and named physical minimum devices remain open; Android 12 alone does not define phone SoC/RAM/GPU. Date current-day sources and validate physical hardware on actual devices. Use the current part-time plan when estimating work. Both export/device/input paths need early gates; keep cast/story/missions original.

Documentation ownership: PROJECT_RECORD owns requirement/decision/risk distinctions; PHASE_PROGRESS owns detailed task status; ASSET_PRODUCTION_PLAN owns production/acceptance steps; MODELING_PIPELINE owns generator architecture; OVERNIGHT_MODELING owns commands/recovery; OVERNIGHT_HANDOFF owns the latest run/defect receipt. Link authoritative records rather than copying tables into several documents. Preserve historic receipts and timestamp current observations. The current Windows Phase 1 slice and remaining acceptance evidence are recorded in docs/PHASE_PROGRESS.md and prototype/README.md.

Latest user delegation, 20 November: target **Windows 10 and Android 12**. Choose the reference pocket, best-suited engine/components, commercially reusable offline map and study-refinement priorities through research; do not reopen these choices as permission questions. Selected direction is Ranwar/Waroda/Chapel Road in Bandra West and Godot 4.7.2 standard with Compatibility/GDScript; the detailed selection reports own exact source evidence. On 22 November the user supplied the GitHub baseline, renamed the game **Aamchi Mumbai Game**, and requested Phase 1 implementation. Use a task branch such as `phase-1/prototype` for development. Record technology/version, runnable exports and actual devices tested. Android installation and physical-device measurements remain separate gates. Hardware performance validation remains open without blocking independent research. The modern OSM extract provides the reference layout for the present-day district. Check current conditions before accepting production art and road access.

## Mandatory Git commit and push workflow

- **Only the Ubuntu VM may push this repository to GitHub.** Publish from `/home/ubuntu/workspace/Aamchi-Mumbai-Game` using the GitHub write credential already stored on that VM. Keep the credential on the VM and out of commands, logs, bundles and commits.
- Windows and epyc24 may edit, test, commit, fetch and transfer reviewed Git commits between the workspaces. Stage the intended files and run the checks relevant to the change before committing.
- Before publishing `main`, sync epyc24 at `/tmp/Aamchi-Mumbai-Game` and Ubuntu to the same reviewed commit. Allow only fast-forward updates and preserve dirty or diverged work for explicit resolution. After the push, verify the full commit ID on GitHub and both remote `main` branches, confirm that both worktrees are clean, and compare their tracked files.
- Follow the [commit, synchronization and publishing procedure](docs/AGENT_WORKFLOW.md#git-commit-synchronization-and-publishing). This applies to code, assets and documentation.

## Phase 1 playtest

Open `prototype/project.godot` with the pinned Godot 4.7.2 standard editor. Keep prototype source in `prototype/`, toolchain material in `.toolchain/`, and Windows exports in `builds/`. Use the Windows desktop preset and smoke script documented in `prototype/README.md`. The user authorized execution servers for rendering or high CPU work when needed. Follow the remote runbook for shared node access.

Use the visible street geometry to govern free-roam traversal. Test ordinary curbs, driveways and grades with all four vehicle families in both directions. Keep walls, high obstacles, blocked clearance and vehicle-width restrictions physically solid. Review the driving camera over changes in road height.

## Current overnight work

The user authorized remote model creation between **22:00 and 08:00 Asia/Kolkata**. Read docs/OVERNIGHT_MODELING.md before operating the queue. jobs/night-queue.json owns the queue; jobs/specs/*.json own individual briefs. jobs/remote.json contains non-secret connection/tool paths. Use existing SSH key authentication; never record passwords/tokens or disable host-key checking.

The remote project is /root/motion/mumbai-gully-heat on epyc24. Respect /root/motion/.jobs/heavy.lock and other users' work. Use tools/remote_night.py for operations. Keep within the project and its generated outputs; do not install packages, change system services or kill unrelated processes as routine queue work.

The Python supervisor executes saved Blender scripts without an active Codex session. It enforces the night window, retries bounded failures and checkpoints results. It is not an unattended reasoning agent. Once all jobs finish it exits; start it again after adding work. A remote reboot requires an explicit restart; the current setup does not install a system boot service.

## Asset acceptance

Use grounded, stylized realism for player-facing art. Match the proportions, contours, materials and scale cues of present-day Mumbai references. Use Minecraft-like, voxel or deliberately block-shaped styling only when the user explicitly requests it for the work. Treat primitive blockouts as layout and collision studies. Review assets in the actual gameplay camera before accepting them as art. [Visual direction and review](docs/ASSET_PRODUCTION_PLAN.md#visual-direction-and-review)

Overnight outputs are original procedural **static blockouts/studies**. They are not approved production characters, authentic nauvari/pheta, surveyed BDD replicas or tested game assets. A report with status:ok means technical export passed. Cultural/architectural review, rigging/weights, animation, collision and populated-scene performance remain separate gates.

Use present-day everyday Mumbai clothing alongside traditional dress where the context supports it. A generic sari is not automatically a nauvari/kashtha drape. Do not label a generic building/shanty kit as a Mumbai chawl. Verify vehicle, landmark and photo references for present-day use in the selected Bandra area. Record candidate provenance and commercial-use terms. Existing study/job IDs, including `contemporary-character-study-v001`, are stable runtime identities and require local reference and art review. Read research/INDIAN_MAHARASHTRIAN_CHARACTERS.md and docs/CHAWL_MODEL_RESEARCH.md before refinement.

Only use third-party assets under their actual per-file license/provenance terms. NoAI/store/noncommercial content must not enter an open-content or generator-input queue by assumption. Record adopted materials in docs/THIRD_PARTY.md.

## Resuming in a new Codex session

1. Read docs/OVERNIGHT_HANDOFF.md, then run python tools/remote_night.py status. Read remote state and failed-job logs before requeuing anything. Snapshot a consequential status update with client/remote timestamps; a saved deployment receipt is historical evidence.
2. Run python tools/remote_night.py collect. Inspect generated PNGs and report.json files. Keep technical completion separate from visual/cultural approval.
3. Fix the smallest relevant generator/specification and run focused checks. Input/script fingerprints requeue affected completed jobs; do not delete state to force reruns.
4. Deploy only reviewed project files, validate remotely, then start/resume the supervisor. Production work remains inside 22:00–08:00 IST.
5. Record the concrete result, remaining defects and next action in docs/OVERNIGHT_HANDOFF.md. Update affected task evidence/status in docs/PHASE_PROGRESS.md and change a roadmap gate only when its acceptance evidence actually passes.

Publish documentation through the same Git workflow. Refresh the modeling runner's separate runbook copy during the next controlled deployment. The modeling queue can keep running during a documentation-only Git update.

Tests: python -m unittest discover -s tools/tests -v. Queue preflight: python tools/night_queue.py --root . --validate. Do not infer that a headless export proves animation quality or low-spec frame pacing.
