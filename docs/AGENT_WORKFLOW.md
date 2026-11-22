# Agent workflow - Aamchi Mumbai Game

Updated 19 November 2026. This workflow supports one human developer with a high Codex budget, reusable components and bounded parallel work. The implemented unattended capability is a saved procedural Blender queue during **22:00-08:00 Asia/Kolkata**. A broad continuous reasoning-agent service is not configured. More concurrent agents are useful only when prerequisites, acceptance criteria and human review capacity are ready.

## Start from the owning record

Read [AGENTS.md](../AGENTS.md), [README.md](../README.md), [PROJECT_RECORD.md](PROJECT_RECORD.md), [PROJECT_BRIEF.md](PROJECT_BRIEF.md), [ROADMAP.md](ROADMAP.md) and [PHASE_PROGRESS.md](PHASE_PROGRESS.md) before changing scope. Do not recreate this project in MotionGraphics or assume the older general game-research folder is the implementation workspace.

| Question | Owning document / executable evidence |
|---|---|
| What did the user choose, what is proposed, and what remains open? | [PROJECT_RECORD.md](PROJECT_RECORD.md), [PROJECT_BRIEF.md](PROJECT_BRIEF.md) |
| What comes next and what is actually complete? | [ROADMAP.md](ROADMAP.md), [PHASE_PROGRESS.md](PHASE_PROGRESS.md) |
| Which assets/production gates/backlog should be pursued? | [ASSET_PRODUCTION_PLAN.md](ASSET_PRODUCTION_PLAN.md) |
| What model-generation code exists? | [MODELING_PIPELINE.md](MODELING_PIPELINE.md) and the linked source files |
| How do I safely operate the remote queue? | [OVERNIGHT_MODELING.md](OVERNIGHT_MODELING.md) and `tools/remote_night.py` |
| What was the last observed remote condition? | [OVERNIGHT_HANDOFF.md](OVERNIGHT_HANDOFF.md), its dated receipts, then a new remote `status` |
| What licenses and local identity evidence support a candidate? | Owning research files, [reference register](../assets/references/REFERENCE_REGISTER.md), [THIRD_PARTY.md](THIRD_PARTY.md) |

Do not turn a historical observation into current status. A launch receipt is not a completed model; a technical export is not an accepted asset; an asset is not a playable mission; a runnable scene is not an exported low-spec game.

## Team shape and ownership

The human owns scope, creative direction, driving feel, neighborhood identity, final acceptance and integration. A coordinator can break the next bottleneck into independent bounded tasks and collect evidence. Use two or three worker streams when the environment supports them; increase only after measuring accepted throughput and review load.

| Stream | Suitable bounded deliverables | Dependency before integration |
|---|---|---|
| Engineering | One controller/import experiment, a reproduced defect, focused performance investigation or a reviewed tool patch | Agreed interface, versioned baseline and actual tests |
| World and assets | One reference packet, one inspected archive, one model correction or one authored content file | Selected subject/year/role, rights and a defined production gate |
| QA and research | One regression route, license check, source verification or independent code/art review | Reproducible input/build and explicit expected evidence |

Assign owned files before work begins. Only one owner changes shared architecture, engine/dependency versions, save schemas, road graph formats or active queue sources at a time. Never have two workers write the same model output directory. Use isolated branches/worktrees after project version control is established; it is not yet a verified capability in this workspace. Until then, enforce explicit disjoint file ownership and preserve reviewable patches/backups.

A second agent can review code or a render. Human review remains necessary for handling feel, garment/architectural fidelity and the final combined experience. A knowledgeable Mumbai/Maharashtrian reviewer may be required for a specific unresolved identity question; absence of that review keeps the study unapproved.

## Bounded task contract

Every delegated job should record:

- Objective and the user requirement or backlog item it advances.
- Inputs/baseline, prerequisite decisions, owned files and shared files it must leave alone.
- Chosen reuse candidates and exact source/license constraints; do not introduce a new framework without a reviewed need.
- Time/compute/spend/retry ceiling and stopping condition.
- Acceptance gate, commands or inspection route, evidence destination and expected deliverable.
- Known unknowns, failure behavior and handoff owner.

Prefer one visible, reviewable outcome. A worker returns changed paths, actual validation results, source/provenance notes, remaining defects and next dependency. It does not silently expand its task to unrelated content or make a major scope decision to suit a convenient library/asset.

Before implementing, search the owning research/catalogue and suitable existing code. Inspect the actual repository/archive and license before adoption. Record a reuse-versus-adapt-versus-author decision by total accepted-result cost, including cleanup, integration and rework. Do not count uninspected catalogue entries as installed assets.

## Day and night cycle

1. **Review:** the human plays the latest known-good build when one exists, reviews new art and selects the next bottleneck. Track technical completions separately from A0-A5 asset acceptance.
2. **Prepare:** agents write small ready tasks and durable specs, check provenance, run focused local validation and preserve a rollback point. Clarify only dependencies that actually prevent progress; continue independent work.
3. **Run bounded work:** interactive agents handle reasoning/code/research during their available sessions. The detached supervisor executes reviewed Blender scripts at night with saved limits/checkpoints. It does not invent additional tasks.
4. **Collect and assess:** run remote status/collect, inspect evidence, read failed logs and review the combined output. A busy shared lock is idle time, not a model failure.
5. **Integrate:** accept a bounded number of changes, run relevant import/play/save/performance checks and update the owning progress/asset records. Pause new variants if review backlog grows.

The remote node runs one heavy model job at a time using its shared heavy-work lock. Do not start parallel Blender jobs to bypass that lock. Broader agent concurrency can still cover independent references, code review or task preparation without competing for that machine.

## Starting a new Codex session

A minimal status-and-review prompt is sufficient when the workspace records are intact:

> Open C:\Suresh\Software\MumbaiStreetGame. Read AGENTS.md and docs/OVERNIGHT_HANDOFF.md, then use the runbook to query and collect the remote night queue. Review completed models against their specs and A0-A5 gates. Preserve state and historical receipts. Report concrete defects and update the handoff; do not deploy changes before inspecting the running worker.

The agent should then:

1. Read the required records and check current remote identity/markers/state.
2. Collect before changing local queue paths; collection uses the local queue and can overwrite matching local generated files.
3. Classify each job: pending/idle, running, interrupted, retryable failure, exhausted or technically completed. Read the corresponding attempt log for any failure.
4. For completed assets, confirm report/state hashes, inspect all four views, dimensions and geometry/material/object counts, then record a gate-specific pass/fix/reject.
5. Continue the smallest authorized bounded task. Stop/verify exit before source deployment; use fingerprints to requeue affected jobs, not state deletion.
6. Leave a new timestamped handoff with evidence paths and a concrete next action.

A minimal correction prompt can identify a defect rather than restating the project:

> Continue Aamchi Mumbai Game. Resolve CLOTH-01 and CLOTH-02 from the overnight handoff for the nauvari study. Own only the relevant generator/spec and focused checks. Preserve the current remote batch; prepare a reviewed correction locally, report its visual evidence and use the documented stop/verify/deploy/resume process only when ready for the next run.

For a prepared batch that has exited or a rebooted node:

> Read the latest handoff and remote status. Collect existing results first. If the reviewed queue is already deployed and its sources are correct, use the helper to start/resume it with fresh clock calibration. Preserve the 22:00-08:00 IST production window and existing shared heavy lock. Save a fresh identity/status receipt and update the handoff.

These prompts do not request or configure continuous Codex reasoning. Saved task/spec files and standalone subprocess supervision provide continuity across sessions.

## Morning review and controlled requeue

Use the runbook for exact commands and asynchronous pause/stop semantics. At minimum, review front, side, rear and preview for each completed checkpoint. Chawls need selected-local-reference matching plus usable openings/gallery/stairs/courtyard, not a generic housing label. Clothes need construction, context, fit and front/back route review; retain contemporary clothing alongside contextual traditional variants.

Keep unresolved preflight defects visible: trouser-like nauvari lower drape, flat pallu, shoulder/neck intersections and chawl architectural/context/collision gaps. Do not close them because a report says `ok`. Rigging, weights, idle/walk/turn/vehicle interaction, collision, LOD/material preparation and exported-device performance remain separate work.

For a fix, preserve collected evidence and any manual refinement, stop the old worker, confirm exit, modify the smallest relevant declared input/spec, run focused tests/preflight, deploy and resume. The runner fingerprints the job/script/explicit inputs and requeues affected work. Declare new imported dependencies; fingerprints do not discover every module automatically. Do not edit checkpoints, delete all state or retry an exhausted error without diagnosing it.

Adding jobs after terminal queue exit requires a new start/resume. A node reboot also requires explicit restart: this setup has no boot service. Daytime `running: true` can be normal waiting, including the current terminal-exit timing limitation described in the runbook. Fresh clock calibration applies only when a new supervisor process launches.

## Handoff record template

Add a dated entry or update the current observed section while retaining historical receipts:

```text
Checked UTC / corrected IST:
Source receipt and remote root:
Supervisor identity / running / PAUSE / STOP:
Job counts and completed IDs:
Technical evidence (state, logs, report and hashes):
Visual/cultural/architectural findings and open defect IDs:
A0-A5 outcomes; accepted production assets count:
Local files changed and validation actually run:
Deployed source version/manifest, if deployment occurred:
Clock/shared-lock/storage or recovery concerns:
Next bounded action, owner and prerequisite:
```

Record unavailable information explicitly. Do not replace an observed timestamp with today's date while retaining old counts. Current local docs may be newer than the remotely deployed runbook; record the next deployment separately rather than rewriting the original manifest.

## Throughput, cost and upgrade discipline

Track time to an **accepted** task/asset, ordinary attempts versus interruptions, rework rate, unresolved defects, human review hours and integration time. Record model/tool spend and machine time separately. A high Codex budget enables more experiments; it does not establish an automatic calendar multiplier or remove the human critical path.

Cap work in progress to what can be reviewed in one or two sessions. When backlog grows, assign agents to source inspection, QA or existing defects instead of producing many new variants. Rebaseline phase estimates only from accepted throughput, including rejected attempts and populated-game measurements.

Keep tests focused on actual risks and changed behavior. Headless mesh/export tests cannot establish enjoyable driving or frame pacing. Once an engine is selected, pin dependencies and exported templates; evaluate upgrades in an isolated change with walking/driving, a busy street, mission/save recovery, shaders and exported-build checks. Preserve a known-good build and migration/rollback record. Avoid automatic dependency updates during content production.
