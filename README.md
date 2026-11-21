# Mumbai: Gully Heat

A solo-developer indie game workspace for Mumbai: Gully Heat, a stylized open-world driving and mission game based on real Mumbai, India. Buildings, landmarks, streets, and vehicle types use real local references, simplified for modest hardware. The characters, story, missions, and branding are original; geographic compression is documented.

## Start here

The project is in **Phase 0: scope, hardware and reuse decisions**. Research and the remote modeling pipeline have advanced; a playable engine build and target-device measurements remain ahead. The current phase tracker records accepted progress separately from prepared studies.

| Document | Purpose |
|---|---|
| [Project record](docs/PROJECT_RECORD.md) | User requirements, decisions versus proposals, completed evidence, open decisions and risks |
| [Phase progress](docs/PHASE_PROGRESS.md) | Current status, completed evidence, remaining tasks, dependencies and exit gate for all seven phases |
| [Roadmap](docs/ROADMAP.md) | Release envelope, phase durations, effort assumptions and performance targets |
| [Asset production plan](docs/ASSET_PRODUCTION_PLAN.md) | Reuse/adaptation/original routes, asset priorities, provisional budgets and acceptance process |
| [Modeling pipeline](docs/MODELING_PIPELINE.md) | What the generators and remote worker implement, their data flow and remaining capabilities |
| [Overnight runbook](docs/OVERNIGHT_MODELING.md) | Commands, night-window behavior, checkpoints, recovery and morning review |
| [Current handoff](docs/OVERNIGHT_HANDOFF.md) | Timestamped remote status, preflight evidence, known defects and next-session instructions |

## Selected game title

**Mumbai: Gully Heat** is the selected title. Proposed tagline: “Mumbai never slows down.” See `docs/BRAND.md`.

## First target

A compact game for **Windows 10 and Android 12 together**, starting in **Bandra West, 1990–1995**, with a gangster-era crime-fiction direction: on-foot movement, arcade driving, light traffic and pedestrians, and one complete mission as the first playable target. Preserve recognizable road/landmark relationships and compress travel distances. **Cars, rickshaws, motorcycles and scooters must all be player-drivable in the first release**; test their handling and rider requirements in stages. The selected reference pocket is Ranwar/Waroda/Chapel Road; story and cast remain original. The [area/map selection](research/BANDRA_REFERENCE_AREA_AND_MAP.md) owns its boundary and modern-versus-period evidence.

The user selected a weaker PC class with **integrated graphics and 8 GB RAM**, and **Android 12** as the Android OS target. The 720p / 30 FPS PC budget remains provisional; name and benchmark the actual baseline. The available approximately 16 GB development PC is a stronger test device. The **minimum Android phone hardware is pending**; Android 12 does not define its RAM, SoC or GPU. Establish both devices' export, input, memory and performance budgets. The human developer has **some experience** and **provisionally ten focused hours/week**, to be revisited as development progresses.

## Working rules

- Search for reusable open-source components before rebuilding systems.
- Review repository health, engine compatibility, security, performance, code license, and every asset license before adoption.
- Track third-party provenance in `docs/THIRD_PARTY.md`.
- Do not use GTA / Vice City maps, names, characters, missions, logos, audio, or extracted game assets.
- Keep systems modular so districts, missions, vehicles, and platforms can be added later.
- Use agents for independent tasks with explicit outputs; keep one owner for architecture and integration.

## Workspace map

- `docs/BRAND.md` — selected game title and visual direction.
- `docs/PROJECT_BRIEF.md` — product and scope.
- `docs/ROADMAP.md` — milestones.
- [Project record](docs/PROJECT_RECORD.md) — requirements, decisions, evidence and risks.
- [Phase progress](docs/PHASE_PROGRESS.md) — evidence-backed task status and acceptance gates.
- [Asset production plan](docs/ASSET_PRODUCTION_PLAN.md) — local asset workflow and production backlog.
- [Modeling pipeline](docs/MODELING_PIPELINE.md) — implemented generator/worker architecture and limitations.
- `docs/AGENT_WORKFLOW.md` — bounded parallel work, review, and integration.
- `docs/THIRD_PARTY.md` — dependency and asset ledger.
- `research/REPOSITORY_AUDIT.md` — GitHub candidates.
- `research/FEASIBILITY_REVIEW.md` — source-backed findings and planning assumptions, revised 19 November 2026.
- `research/MUMBAI_REAL_WORLD_REFERENCES.md` — actual buildings, landmarks, vehicle models, local traffic geography, and asset-production implications.
- `research/OPEN_MODEL_CATALOGUE.md` — commercially usable open-content catalogues and twelve live metadata-checked model candidates.
- [Indian/Maharashtrian character research](research/INDIAN_MAHARASHTRIAN_CHARACTERS.md) — specific character/clothing candidates, cultural references and remaining garment gaps.
- [Chawl model research](docs/CHAWL_MODEL_RESEARCH.md) — actual housing references, model leads and original-study instructions.
- [Overnight modeling runbook](docs/OVERNIGHT_MODELING.md) — bounded remote Blender queue for 22:00–08:00 IST.
- [Overnight handoff](docs/OVERNIGHT_HANDOFF.md) — deployment/status receipt and instructions for the next session.
- `research/evidence/sketchfab-models-2026-11-19.json` — captured creator/license/download/geometry fields for those candidates.
- `assets/references/REFERENCE_REGISTER.md` — dated photo/OEM/heritage references and per-asset provenance fields.
- `prototype/` — engine project after the foundation is selected and boot-tested.
- `assets/` — original or properly licensed assets.

## Status

Documentation and Phase 0 decisions updated on **20 November 2026**. Phase 0 is in progress. Phases 1–6 have not passed an implementation gate; Phase 2 already has useful reference, catalogue and modeling-tool preparation. The [phase progress tracker](docs/PHASE_PROGRESS.md) owns detailed status; no overall completion percentage is assigned.

The user selected Bandra West in 1990–1995 and all four drivable families. Exact boundary and period-appropriate models remain pending. Existing contemporary catalogues and recent photos need dated corroboration before historical use. The former PC-first, experienced-developer estimate requires rebaselining for these choices, simultaneous Android release and ten human hours/week; it is not a current delivery forecast.

**Godot 4.7.2 standard, Compatibility rendering and typed GDScript** are selected for implementation; the [technology selection](research/TECH_STACK_SELECTION.md) owns versions, component choices and upstream evidence. OpenCity remains a reference rather than the foundation. No engine/game build or target-device benchmark has passed. The user has deferred Git, recovery and repeatable platform-export setup; Phase 0's technical gate remains open.

The first procedural Blender batch **completed all eleven jobs**. All **77 generated files are collected and match accepted checkpoint hashes**, recorded at **20 November 2026, 06:57:50 IST** in the [collection receipt](reports/remote/epyc24/asset-collection-2026-11-20.json). [Preliminary review](reports/ASSET_REVIEW_2026-11-20.md) selects bay/props first; full view/period/cultural/architectural, rig/collision and game acceptance remain open. The [handoff](docs/OVERNIGHT_HANDOFF.md) preserves earlier observations. No new batch was started.

The captured model search contains **21 unique CC BY/download-enabled candidates** across vehicles/environments, Indian characters/clothing and generic building components, plus four character holds. Their catalogue license/download declarations were checked; archives and game readiness remain unverified. No complete open, production-ready nauvari/pheta or Mumbai chawl kit was established. Use the specialist catalogues and [asset plan](docs/ASSET_PRODUCTION_PLAN.md) before acquisition, including the Quaternius license hold.

## Check or collect the night batch

Run from this workspace with the existing VPN/SSH connection available:

```powershell
python tools/remote_night.py status
python tools/remote_night.py collect
```

Generated production artifacts are collected to `assets/generated/<job-id>/`; remote diagnostics go to `reports/remote/epyc24/`. Read the runbook before changing or redeploying jobs. The completed worker has exited; a later prepared batch needs an explicit start. During execution it needs no active laptop/chat session, but the node must remain on and a reboot requires an explicit restart.
