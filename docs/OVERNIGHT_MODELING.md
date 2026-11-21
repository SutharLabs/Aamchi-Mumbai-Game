# Overnight modeling operations

Updated 19 November 2026 for **Mumbai: Gully Heat**. This is the operating runbook for the saved Blender queue. Read [the current handoff](OVERNIGHT_HANDOFF.md) for the latest observed remote state and [the modeling pipeline](MODELING_PIPELINE.md) for geometry, budgets and acceptance gates.

## What runs after Codex closes

A detached Python supervisor on the remote node executes reviewed Blender Python scripts sequentially. It can wait for the next allowed window and checkpoint completed jobs without a chat, laptop or SSH session remaining open. It does not call Codex, interpret a natural-language brief, browse references, pay an image-to-3D service or approve its own art. The current eleven jobs produce original procedural **static blockouts and studies**.

The production window is **22:00 inclusive to 08:00 exclusive, Asia/Kolkata**. A job at 01:00 belongs to the window that began the previous evening. No new job starts outside the window; an unfinished job at the morning cutoff is interrupted and remains retryable. The scheduler uses corrected UTC and a monotonic clock, rather than the remote machine's displayed local time.

## Sources of truth

| File or location | Owns |
|---|---|
| [jobs/remote.json](../jobs/remote.json) | Non-secret node, SSH user/port, remote root, existing Blender path, shared lock and thread count |
| [jobs/night-queue.json](../jobs/night-queue.json) | Ordered production jobs, enabled flags, scripts, arguments, declared inputs/outputs, timeout, retry and minimum-window limits |
| [jobs/specs/](../jobs/specs/) | Individual model kind, estimated parameters, triangle cap, source references, assumptions and human review instructions |
| [tools/remote_night.py](../tools/remote_night.py) | Allowlisted SSH deployment, clock calibration, process identity checks, control markers and collection |
| [tools/night_queue.py](../tools/night_queue.py) | Actual scheduling, locks, fingerprints, checkpoint reconciliation, subprocess supervision and technical output acceptance |
| [tools/build_queued_model.py](../tools/build_queued_model.py), [tools/modeling/](../tools/modeling/) | Actual geometry/export/render behavior; descriptive JSON instructions do not add features that these scripts lack |
| Remote `.night-queue/state.json` | Current per-job runtime checkpoints and accepted output hashes |
| Remote `.night-queue/logs/` and `supervisor.log` | Attempt diagnostics and scheduler/control events |
| [reports/remote/epyc24/](../reports/remote/epyc24/) | Collected diagnostic copies and dated deployment/status receipts; these are observations, not live state |
| [OVERNIGHT_HANDOFF.md](OVERNIGHT_HANDOFF.md) | Timestamped operational handoff and unresolved defects |

Do not edit a collected `reports/remote/epyc24/state.json` to control the node. It is deliberately kept away from any local `.night-queue/` operational state. Query the node again when its current condition matters.

## Target and prerequisites

The configured node is **epyc24**, `root@10.64.100.159`, port 22. The isolated project is `/root/motion/mumbai-gully-heat`. Its existing Blender is `/root/motion/.tools/blender-5.3.0/blender`; production uses eight threads and nice priority 10. Python 3.10.12 and Blender 5.3.0 were verified during preparation. The other node was busy and is not part of this queue.

The existing machine-wide heavy-work lock is `/root/motion/.jobs/heavy.lock`. The queue waits when that lock is held. It does not preempt video work or start another node automatically. The VPN/node, existing SSH key authentication, known host key, Python, Blender, GNU `timeout` and `nice` must remain available. There is no automatic local heavy-work fallback.

No password or API token belongs in `jobs/remote.json`, a command, a receipt or an asset. The helper uses batch SSH with strict host-key checking. Connection failure is a reason to restore the existing connection, not to disable host verification or install packages.

## Routine commands from Windows

Run these from `C:\Suresh\Software\MumbaiStreetGame`, using the existing Python command:

```powershell
python tools/remote_night.py status
python tools/remote_night.py collect
```

Use `status` before changing an active queue. `collect` is safe to repeat, but read its snapshot limitations below.

| Command | Exact effect and follow-up |
|---|---|
| `python tools/remote_night.py deploy` | Transfers reviewed allowlisted local files. Refuses while this project's identity-checked supervisor is running. Preserves remote state/results and does not delete old extra files. |
| `python tools/remote_night.py start` | Calibrates the clock, validates the remote queue, then launches a detached supervisor if none is running. A STOP marker requires `resume`; a PAUSE marker makes a newly started worker idle. A launch receipt is not evidence of completed modeling. |
| `python tools/remote_night.py status` | Reads identity, clock estimate, markers and remote state. Does not start, reconcile or repair jobs. |
| `python tools/remote_night.py collect` | Copies available expected asset files plus state, supervisor log/PID and attempt logs. Verifies transferred bytes and writes local files atomically. Does not delete remote files or sync source code back. |
| `python tools/remote_night.py pause` | Writes this project's PAUSE marker. The supervisor interrupts its active job and stays alive waiting. The command returns before that acknowledgement is guaranteed. |
| `python tools/remote_night.py resume` | Calibrates, removes PAUSE and STOP, then starts a supervisor if needed. If one is already running, it keeps its original clock anchor. |
| `python tools/remote_night.py stop` | Writes this project's STOP marker. The supervisor interrupts its job and exits after observing it. Verify `running: false` before deployment. It does not kill other projects. |

During an active job the supervisor checks control markers approximately once a second. While idle it polls every 30 seconds; process shutdown can also require its termination grace period. Do not treat a successful pause/stop command as proof that Blender has already stopped. Read status and the next log/checkpoint update.

### Reviewed source update

Collect before changing the local queue, especially before removing or renaming job IDs. Preserve any generated file that has been manually refined outside its generated destination.

```powershell
python tools/remote_night.py status
python tools/remote_night.py collect
python tools/remote_night.py stop
python tools/remote_night.py status
```

Continue only after status shows the old supervisor has exited. Read failed/interrupted logs, make the smallest relevant local changes, then run:

```powershell
python tools/night_queue.py --root . --validate
python -m unittest discover -s tools/tests -v
python tools/remote_night.py deploy
python tools/remote_night.py resume
python tools/remote_night.py status
```

Validation here checks the local queue and paths without running Blender. The remote helper performs its own remote queue validation before launch. Record actual command results, a fresh identity/status receipt and the changed job IDs in the handoff. Do not deploy changed sources under a live worker.

The helper only prints its JSON result; it does not automatically create the dated receipt filenames used in the handoff. Save a new receipt deliberately if required and keep historical deployment/start receipts unchanged.

### What deploy and collect permit

Deploy permits these exact files: `tools/night_queue.py`, `tools/build_queued_model.py`, `jobs/night-queue.json`, `docs/OVERNIGHT_MODELING.md`, plus direct `.py` children of `tools/modeling/` and `.json` children of `jobs/specs/`. It does not send SSH keys, `jobs/remote.json`, arbitrary project files, model archives, research photos, tests or all documentation. Each file is hash-checked and atomically replaced; the deployment is not a single all-files transaction. On transfer failure, fix and redeploy the complete allowlist before starting.

Collect derives its requested asset paths from the **current local** `jobs/night-queue.json`. An old remote job removed from the local queue may no longer be requested. The supported asset destination is `assets/generated/<job-id>/` with the seven standard filenames below. Diagnostics go to `reports/remote/epyc24/`, not local worker state.

Collection verifies each transfer's byte count and SHA-256. It does not guarantee that all files were read at the same instant or compare them automatically with the accepted hashes in state. Files left by an interrupted attempt or an earlier generation can exist even when a job is not completed. Prefer completed jobs or collect after pausing and confirming the active attempt has settled. Require a completed checkpoint, matching report/output hashes and human review before adopting results. Collection overwrites corresponding local generated files; keep manual refinements separately.

Current limits are 2 MiB per deployed file, 16 MiB total deployment, 128 MiB per collected file and 1 GiB per collection. Collection has no chunked large-file transfer. An over-limit file requires a reviewed extension to the helper or a separate authorized transfer, not an arbitrary remote path workaround.

## Scheduling, clocks and cutoff

Before `start` or `resume`, the client samples its own UTC before and after a remote UTC request. The midpoint minus remote UTC becomes `--clock-offset-seconds`. Calibration refuses an offset beyond +/-1,800 seconds, a round trip above ten seconds, or a client wall-clock jump above one second relative to elapsed monotonic time. The client clock must itself be trustworthy; midpoint uncertainty is approximately half the measured round trip.

A newly launched supervisor anchors corrected UTC once and advances it with `time.monotonic()`. Later remote wall-clock/NTP jumps cannot lengthen that worker's allowed window. No system clock is modified. Output freshness is checked separately against native OS `time.time()` and filesystem timestamps; comparing mtimes to corrected UTC would reject legitimate files on a skewed host.

Two distinctions matter during recovery:

- `resume` on an already running supervisor clears markers but does not replace its clock anchor with the fresh calibration. To apply a new calibration, stop, verify exit, then resume/start.
- The remote helper's status display computes native remote UTC plus the saved offset. The running supervisor uses its monotonic anchor. After a later host wall-clock jump these displays may diverge; preserve worker logs/state and restart deliberately if a new calibration is needed.

Each Linux Blender launch is wrapped in GNU `timeout --signal=KILL` with the smaller of its 20-minute job limit and the remaining night window. A 0.25-second allowance makes the independent deadline slightly early. This timeout continues if the Python supervisor is killed. The supervisor also monitors its own child and normally requests termination, then forces termination after up to five seconds. The independent hard deadline remains the final bound. Linux execution fails closed if the expected GNU timeout executable is unavailable.

At the cutoff, timeout return codes -9, 124 or 137 within one second of a window-limited deadline are treated as retryable interruption. An ordinary job timeout consumes a failure attempt. Do not interpret every exit 137 as an out-of-memory failure without checking deadline and logs.

## Queue and checkpoint lifecycle

The supervisor holds `.night-queue/supervisor.lock` for its lifetime. The helper serializes mutations with `.night-queue/control.lock`. Each modeling attempt acquires the shared heavy-work lock nonblocking; if busy, the queue reports `shared_worker_busy` without starting Blender. The Linux timeout/Blender descendants inherit the shared lock so it remains held until orphan work ends even if Python dies.

Every scheduling tick loads the queue, reconciles fingerprints/checkpoints and writes state atomically using a temporary file, flush/fsync and replacement. It then checks prior live workers, STOP, PAUSE, the allowed window and ready jobs in queue order. Only one model runs at a time. There is no dependency graph, dynamic task planning or automatic queue expansion.

| State or result | Meaning | Normal next action |
|---|---|---|
| `pending` | New job, changed declared source/spec, or accepted output missing/changed | Wait for its turn in the allowed window |
| `running` | An attempt was launched; state includes PID/start token/log | Wait, or pause/stop through the helper |
| `completed` | Process exited zero and all declared outputs passed freshness/nonempty/report checks; hashes saved | Collect and perform visual/cultural/game checks |
| `failed` | A real attempt failed but failure budget remains | Read log; supervisor can retry in order |
| `exhausted` | Ordinary failures reached the job's maximum | Fix the cause and change the relevant declared input/spec; restart |
| `interrupted` | Cutoff, operator control, supervisor interruption or unreconciled dead prior worker | Retry later without spending an ordinary failure attempt |
| `outside_window` / `insufficient_window` | Daytime, or less than the job's 90-second minimum remains | Wait; no new attempt starts |
| `shared_worker_busy` | Another heavy job owns the shared lock | Wait; do not remove or bypass its lock |
| `waiting_for_prior_worker` | Saved prior worker PID/start token is still alive | Let its independent deadline finish; do not duplicate or kill unrelated work |
| `paused` / `stopped` | Control marker observed | Resume deliberately; stopped supervisor exits |
| `queue_complete` / `queue_exhausted` | All enabled jobs are terminal, with no / some exhausted jobs | Supervisor exits; start again after adding/fixing work |

`attempts` is the charged attempt count toward `max_attempts`; it includes a successful attempt. A completed job with `attempts: 1` need not have failed at all. `launches` counts actual starts, including retryable interruptions. Both increase at launch; retryable interruptions refund the charged attempt. Each production job allows at most two charged attempts, each capped at 1,200 seconds including Blender startup, modeling, rendering and export. Eleven jobs therefore allow 22 full charged attempts, equivalent to 440 minutes at those caps. This is not an absolute elapsed-time or total-compute bound: refunded window/operator interruptions can repeat, and idle/shared-lock waits add elapsed time. It is not a delivery estimate or a promise that all eleven finish tonight. Work can carry into later windows.

A completed job is skipped while its fingerprint and accepted outputs still match. The fingerprint covers canonical job JSON, the generator script bytes, and the explicitly declared input paths/bytes. Editing a brief or a shared declared module resets only affected jobs to pending with a fresh failure budget. It does not inspect every imported module, URL or source directory automatically. Missing/altered accepted output size or SHA-256 also requeues that job. Do not delete all state or mark output complete manually to hide a failure.

If the supervisor dies, restart reads the saved running PID and Linux process-start token. A live prior worker causes waiting; a dead worker becomes interrupted and retryable. A PID alone is not sufficient identity because it may be reused.

### Daytime and terminal exit behavior

An incomplete queue started during the day remains running and reports `outside_window` until the next night. It can continue across nights while work remains. It does not keep regenerating accepted models to fill ten hours.

Terminal queue detection currently occurs **after** the outside-window guard. Normally the supervisor exits after all enabled jobs are completed/exhausted during the allowed window. If the final attempt finishes just before 08:00 and the next 30-second poll occurs after 08:00, it can remain idle until the next 22:00 poll before recording terminal queue exit. A daytime `running: true` alone therefore does not mean models are being created. Use state counts and log results. It is safe to stop an idle completed queue through the helper.

## Outputs and acceptance

Each job declares these exact files under `assets/generated/<job-id>/`:

| File | Content |
|---|---|
| `model.blend` | Editable model plus the review camera, lighting and presentation ground |
| `model.glb` | Selected model geometry; presentation scene excluded; no exported animation |
| `preview.png`, `front.png`, `rear.png`, `side.png` | Four 640 x 640 review renders |
| `report.json` | Technical result, measured geometry/bounds, assumptions, reference URLs, file hashes and pending-review flags |

The generator stages files in a private `.attempt-*` directory, then promotes each file with atomic replacement and writes the report last. Promotion is per file, so interruption can leave mixed prior/new files. The supervisor accepts only a zero exit plus all declared regular, nonempty, newly written outputs and an `ok`/passed validation report. Its state records hashes for all seven files. The generator's report separately hashes the six BLEND/GLB/PNG outputs. Mere file existence is not completion.

A report with `status: ok` means **technical export passed**. Cultural/architectural fidelity, a usable garment, rig/weights, animation, collision, LOD/material budgets and populated-game performance remain separate gates. See [MODELING_PIPELINE.md](MODELING_PIPELINE.md) and the preflight defects in [OVERNIGHT_HANDOFF.md](OVERNIGHT_HANDOFF.md).

## Recovery and troubleshooting

| Symptom | Check and safe response |
|---|---|
| Laptop/chat/SSH closes | Detached work continues while the node stays up. Reconnect, status, collect. |
| VPN or SSH fails | Restore the existing VPN/key/known-host route; no local heavy fallback starts automatically. |
| Shared node busy | Wait for `heavy.lock`; skipped preflights/idle ticks do not prove export failure. |
| Deploy refused | Stop this project's supervisor, verify exit, then deploy. Do not overwrite live code. |
| Clock calibration refused | Check client time/connectivity and measured RTT/offset; do not change remote host time as routine queue work. |
| Failed/exhausted model | Read its attempt log and report, repair the relevant declared source/spec, validate, deploy and resume. |
| Supervisor crash | Let independent timeout release inherited lock; restart reconciles the old worker. |
| Node reboot | No boot service/cron/timer is installed. After reconnecting, status then explicitly start/resume. Accepted checkpoints survive if storage survives. |
| Files exist but state is not completed | Treat them as partial/stale. Read state/log; retry through the scheduler. |
| Collected local file unexpectedly changed | Collection replaces generated destinations. Restore reviewed manual work from its separate working location/backup. |
| Collection fails on size | Check current 128 MiB/file and 1 GiB/batch limits; preserve remote artifacts. |

Each attempt log is capped at 64 MiB; exceeding it fails that attempt. `supervisor.log` is append-only and has no automatic rotation. Failed `.attempt-*` working directories are retained. Watch disk usage during review and plan deliberate, scoped archival/cleanup after evidence is preserved; this runbook authorizes no blanket deletion.

For focused local inspection, `python tools/night_queue.py --root . --status` is read-only **local** status, and `--once` performs one local scheduling tick (it can execute one job inside the window). They do not query the remote node. The low-level `--resume` only clears local markers and does not launch a supervisor; routine remote operations should use `tools/remote_night.py`.

Low-level runner exit codes: 0 for normal terminal/one-tick idle success, 1 for a failed/exhausted one-tick result or exhausted queue, 2 for configuration/I/O errors, 3 for a supervisor lock already held, and 130 for interrupted supervisor. The remote helper's exit 0 only means its requested RPC/control/transfer succeeded; inspect returned state to judge the modeling batch.

## Morning handoff

1. Read [AGENTS.md](../AGENTS.md), the current handoff and relevant character/chawl reference research.
2. Run remote status and collect before changing the local queue. Preserve a dated status snapshot and state/log evidence.
3. For each completed job, check its report, accepted hashes, all four PNG views, dimensions and triangle/material/object counts. Record **technical / visual / cultural or architectural / game integration** outcomes separately.
4. Test door clearances, gallery/stair connections and courtyard routes; inspect nauvari/dhotar/pallu/headwear from front, side and back with appropriate local knowledge. Existing defects do not disappear when a later export succeeds.
5. Choose the smallest next correction. Preserve reviewed outputs, fix a declared source/spec, run focused checks, then follow the stop/verify/deploy/resume sequence.
6. Update [OVERNIGHT_HANDOFF.md](OVERNIGHT_HANDOFF.md) with timestamps, counters, actual commands/results, defect IDs, changed sources, acceptance state and the next bounded action. See [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) for reusable session prompts.
