# Overnight modeling handoff

**Latest collection: 20 November 2026, 06:57:50 IST (client clock).** All **77 generated files** are now local; sizes/SHA-256 match the completed checkpoints. The [collection receipt](../reports/remote/epyc24/asset-collection-2026-11-20.json) covers these plus three diagnostics. Earlier diagnostic copies were archived; ten attempt logs were also copied during the initial serial pass. No remote queue control, deployment, clock change or regeneration occurred.

The [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) inspected eleven reports/previews plus six extra views and selects **bay/props first**, adapted toward Ranwar village-house references. Gallery/baithi assemblies remain unplaced typology studies; characters need connected bodies and garment rebuilding/fitting. All 44 PNGs are local; 27 remaining views and full knowledgeable cultural/architectural, rig/collision and game acceptance remain open. Preserve prior defect IDs; add CHAR-02 body/outfit gaps and ENV-01 mesh-object fragmentation.

The user specified Windows 10/Android 12 and deferred Git/recovery/repeatable-export setup. No generator/specification was changed for this selection. The old next-session collection instructions below now apply to a changed future batch; preserve any manual refinements before recollection.

**Historical remote status check: 20 November 2026, 06:21:08 IST (client clock).** All **11 production jobs technically completed**, with one charged attempt and one launch each, and zero pending/running/failed/exhausted/interrupted jobs. The supervisor had exited normally. Model artifacts were not collected or visually reviewed during this read-only check. This is a timestamped observation, not live status or production-asset acceptance.

Run `python tools/remote_night.py status` before making an operational decision. The detailed procedure is [OVERNIGHT_MODELING.md](OVERNIGHT_MODELING.md); geometry/acceptance boundaries are [MODELING_PIPELINE.md](MODELING_PIPELINE.md). The selected title is **Aamchi Mumbai Game**.

## Latest status evidence

Source: [phase0-status-2026-11-20.json](../reports/remote/epyc24/phase0-status-2026-11-20.json). The snapshot contains remote state/hashes, diagnostic metadata and the last twelve verified scheduler log lines. The final `pheta-study-v001` completed at **19 November 23:24:03 IST** and the worker logged `queue_complete` at **23:24:33 IST** before exiting.

| Item | Observed value |
|---|---|
| Node / remote project | `epyc24` / `/root/motion/mumbai-gully-heat` |
| Supervisor | Not running; identity `null` |
| Control markers | `paused: false`, `stopped: false` |
| Queue counts | 11 technically completed; zero pending/running/failed/exhausted/interrupted |
| Charged attempts / launches | 11 / 11; one per job |
| Completion reason | `All declared outputs freshly written` for every job |
| Collection / acceptance | Production artifacts not collected by this check; all human/engine acceptance pending |

No deploy, control, clock calibration or model-artifact transfer occurred. After supervisor exit the helper reports offset zero/no live calibration, so its displayed remote current time follows the skewed host clock. Use the client timestamp for this observation and saved corrected worker log times for run events. No host clock was changed.

**Scope update, 22 November 2026:** the active setting is **present-day Ranwar/Bandra West only**, superseding the former historical setting. Windows 10/Android 12 and all four first-release drivable families remain. Studies require current locality, art/cultural, rig/collision and runtime checks; a stable job name is not acceptance. Dated execution receipts, output hashes and saved specifications remain unchanged.

## Historical pre-window status

Source: [documentation-status-2026-11-19.json](../reports/remote/epyc24/documentation-status-2026-11-19.json), `remote_status` field. Client checked UTC: `2026-11-19T15:44:39.641515+00:00`; helper's corrected IST: `2026-11-19T21:14:38.743677+05:30`.

| Item | Observed value |
|---|---|
| Node / remote project | `epyc24` / `/root/motion/mumbai-gully-heat` |
| Supervisor | Running, PID `2061718`, Linux process-start token `425304148` |
| Control markers | `paused: false`, `stopped: false` |
| Queue counts | 11 pending, zero attempts/launches, zero production completed |
| Saved clock mode | `corrected_utc_monotonic_anchor` |
| Saved offset | `+146.42144751548767` seconds |
| State update UTC | `2026-11-19T15:44:21.284731+00:00` |
| Next authorized window | 19 November 22:00 through 20 November 08:00 IST |

The helper checks PID **and** Linux start token/expected command/root. Do not trust a bare PID or kill it based on this old document. A daytime running supervisor may simply be waiting; inspect state and `outside_window` log results.

## Historical deployment and activation receipt

The recorded deployment/start was verified at approximately **20:45 IST on 19 November 2026**, corrected time `2026-11-19T20:45:16.666134+05:30`. At that point the same supervisor was running and all eleven production jobs were pending. Preserve this history separately from later status/collection snapshots.

- Target: `root@10.64.100.159`, port 22; isolated project `/root/motion/mumbai-gully-heat`.
- Existing runtime: Python **3.10.12**, Blender **5.3.0**, CPU only, eight Blender threads, nice priority 10.
- Deployment receipt: **21 allowlisted files, 103,383 bytes**. This count/hash manifest describes that deployment, not all later local edits.
- No model archive/photo input, credentials, package installation, system service or MotionGraphics source was transferred/modified as part of that game-worker deployment.
- Existing shared heavy-work lock: `/root/motion/.jobs/heavy.lock`. Other heavy work can delay this batch; no competing work was stopped.
- Clock calibration: client midpoint `2026-11-19T15:15:12.624331+00:00`; remote clock was approximately **146.421 seconds slow**. Round trip **1.882627 seconds**, midpoint uncertainty approximately **0.941314 seconds**. The remote host clock was not changed.
- The supervisor log recorded `outside_window` while waiting. A start receipt proves a detached launch/identity observation, not completed modeling.

Receipts: [deployment result](../reports/remote/epyc24/deployment-receipt.json), [deployment manifest](../reports/remote/epyc24/deployment-manifest.json), [start result](../reports/remote/epyc24/start-receipt.json), [armed status](../reports/remote/epyc24/armed-status.json). Collected diagnostic copies include [state](../reports/remote/epyc24/state.json), [supervisor log](../reports/remote/epyc24/supervisor.log) and [PID record](../reports/remote/epyc24/supervisor.pid). Recollection may refresh diagnostic copies; preserve dated receipts when making comparisons.

The documentation expansion was performed **locally after activation**. It did not stop/restart the worker or deploy changed documentation. The remote copy of the runbook remains the version in the historical deployment until the next controlled stop/verify/deploy cycle. No assertion is made that the active deployment's hashes match every current local source/document.

## Batch and limits

The queue is [jobs/night-queue.json](../jobs/night-queue.json). It executes sequentially, with a 1,200-second attempt cap, at most two ordinary failure attempts per job and a 90-second minimum remaining window before launch. Cutoff/operator interruptions remain retryable and refund the ordinary failure attempt. It does not regenerate completed jobs to occupy the whole night.

| Sequence | Job | Latest recorded state |
|---|---|---|
| 1 | `chawl-frontage-bay-v001` | Technically completed; human acceptance pending |
| 2 | `chawl-stair-v001` | Technically completed; human acceptance pending |
| 3 | `gallery-chawl-study-v001` | Technically completed; human acceptance pending |
| 4 | `baithi-chawl-study-v001` | Technically completed; human acceptance pending |
| 5 | `chawl-props-v001` | Technically completed; human acceptance pending |
| 6 | `kurta-dhoti-cap-study-v001` | Technically completed; human acceptance pending |
| 7 | `nauvari-kashtha-study-v001` | Technically completed; human acceptance pending |
| 8 | `everyday-sari-study-v001` | Technically completed; human acceptance pending |
| 9 | `contemporary-character-study-v001` | Technically completed; human acceptance pending |
| 10 | `gandhi-cap-study-v001` | Technically completed; human acceptance pending |
| 11 | `pheta-study-v001` | Technically completed; human acceptance pending |

Independent GNU timeouts bound Blender after supervisor failure. The shared lock is inherited by its descendants so orphaned Blender does not immediately free the machine for competing heavy work. On restart, PID/start-token reconciliation waits for a live prior worker instead of duplicating it. A remote reboot needs explicit start/resume; no boot service, cron or system timer has been installed.

The terminal-queue check currently follows the daytime-window check. If the final job finishes before 08:00 but the next poll lands after it, the worker may remain idle until 22:00 before recording `queue_complete`/`queue_exhausted` and exiting. A completed idle queue can be stopped through the helper. See the runbook for exact lifecycle semantics.

## Verification performed before activation

These are recorded preparation results, not claims that tests were rerun after every documentation edit:

| Check | Recorded result | Evidence / scope |
|---|---|---|
| Windows automated suite | **37 run, 35 passed, 2 skipped** | Symlink tests skipped because this Windows account cannot create test symlinks |
| Actual remote Linux runner suite | **23 tests passed** | Window/cutoff, clock offset, native output freshness, retries/checkpoints, path/symlink rejection and locks |
| Real Blender chawl-bay smoke | Export/render passed; **300 triangles, 25 meshes, 5 materials** | [Report](../reports/preflight/chawl-bay-report.json), [preview](../reports/preflight/chawl-bay-preview.png) |
| Real Blender nauvari smoke | Export/render passed; **3,240 triangles, 33 meshes, 8 materials** | [Report](../reports/preflight/nauvari-report.json), [preview](../reports/preflight/nauvari-preview.png), [rear](../reports/preflight/nauvari-rear.png) |
| Orphan watchdog integration | Passed | [Receipt](../reports/preflight/watchdog-test.json): harmless test supervisor killed; inherited test lock held, independent two-second deadline killed child, lock released |
| Remote collection | Diagnostics copied successfully | State/log/PID available; production outputs correctly absent before the night window |

The smoke specifications use separate IDs and are not any of the eleven production queue jobs. Additional preflight launches that could not obtain the shared lock skipped Blender; they are neither successful model checks nor export failures. Other workloads were left running.

## Current asset acceptance and visible defects

Every prepared output is an original procedural **static blockout/study**. `status: ok` means technical export passed. No output has been approved as an authentic garment, exact Mumbai building, rigged character, collision-tested world module or low-spec game asset.

| Finding | Evidence / implication | Required next gate |
|---|---|---|
| `CLOTH-01`: nauvari lower drape reads like loose trousers | Smoke front/side silhouette is insufficient for authentic kashtha construction | Reference-led cloth/fold/back-tuck correction and knowledgeable review |
| `CLOTH-02`: pallu is a flat surface | Cloth volume, route, folds and back/front relationship are unresolved | Rebuild garment construction; inspect all views |
| `CLOTH-03`: shoulder/neck intersections and weak cloth fit | Primitive body/outfit pieces overlap | Topology/fit correction before rigging and deformation tests |
| `CHAWL-01`: bay is a simplified isolated component | Material/context and a selected real architectural match remain absent | Select district/year/example; compare dimensions and gallery rhythm |
| `CHAWL-02`: gameplay traversal untested | Rendered stairs, door gaps and galleries are not collision/navigation evidence | Add appropriate collision, then walk door/gallery/stair/courtyard routes in engine |
| `CHAR-01`: character bodies are unrigged; accessories lack validated attachment/fit | Report declares `rigged: false`, `animations: 0` | Common rig/weights and idle/walk/turn/vehicle-entry/clipping tests for characters; fit and attachment tests for static accessories |

The source research is [Indian/Maharashtrian characters](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md) and [Mumbai chawls](CHAWL_MODEL_RESEARCH.md). Six character/clothing candidates had live CC BY/download metadata in the research pass; exact archives/dependencies/rigs remain uninspected. No third-party catalogue candidate was adopted or imported in this batch, and no complete strict-open nauvari/pheta/chawl kit was established. Original geometry references are design evidence, not a surveyed replica or permission to ship reference images.

No image-to-3D backend, MakeHuman integration, photogrammetry, common rig, automatic retopology, LOD, atlas or engine import/performance gate is configured by this worker. No broad unattended reasoning-agent service is running.

## Known implementation follow-ups

These are future bounded engineering tasks. The first batch has exited normally; review these before the next controlled code/specification deployment.

1. **Terminal daytime exit:** consider moving/adding terminal-queue detection before the outside-window idle result, with a regression for a final completion whose next poll crosses 08:00.
2. **Clock display and resume:** expose the worker's actual anchored scheduling time consistently in remote status. Either make `resume` clearly report that a live worker keeps its original anchor or deliberately restart only after a verified stop. A new measured offset is currently applied only to a new process.
3. **Declared dependency coverage:** `build_queued_model.py` eagerly imports `characters.py`, while chawl jobs do not list that imported module in `inputs`. Make dispatch/imports or declared inputs consistent before extending cross-module behavior.
4. **Collection consistency:** consider collecting a completed job against its accepted state hashes, or a versioned job bundle, so concurrent file promotion cannot present a mixed snapshot. Current per-transfer hashes verify transport, not one accepted generation.
5. **Storage lifecycle:** define scoped archival/retention for `.attempt-*`, append-only supervisor logs and collected versions after diagnostic evidence is retained. No automatic cleanup exists now.

## Next session: morning review and correction

From the Windows game workspace:

```powershell
python tools/remote_night.py status
python tools/remote_night.py collect
```

Keep the local queue unchanged until collection; it determines which remote asset paths the helper requests. Results land at `assets/generated/<job-id>/`; diagnostics land at `reports/remote/epyc24/`. Do not overwrite manually improved local generated files without first preserving them elsewhere.

For each completed checkpoint, verify the report and hashes, inspect all four PNG views, record triangle/material/object counts and dimensions, and make a separate visual/cultural/architectural decision. Open BLEND/GLB only as needed for a concrete check. Retain the defect IDs above until a reviewer actually resolves them. Record pass/fix/reject with a reason, not just a file count.

For failures, read the exact attempt log first. Stop and verify supervisor exit before deploying changed sources. Change the smallest relevant declared module/spec, run focused checks, deploy and resume. Fingerprints requeue affected jobs; do not clear all state or manually set completion. If the node rebooted or the batch already exited, explicitly start/resume after inspection.

Update this handoff with: checked UTC/IST, receipt path, running identity/markers, counts by state, completed IDs, actual visual findings, failed logs/reasons, files changed, checks run, remaining acceptance gates and the next bounded task. Keep original deployment/start receipts as history.
