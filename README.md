# Aamchi Mumbai Game

Aamchi Mumbai Game is a solo-developed, stylized open-world driving and mission game set in present-day Mumbai, India. Its original characters and vehicles draw on local references, with a compact Ranwar, Bandra West playtest built for modest hardware.

## Download the 0.0.1 development playtest

- **Windows x64.** Download the Windows ZIP, extract it and launch `Aamchi Mumbai Game 0.0.1.exe`. [Windows ZIP](https://github.com/SutharLabs/Aamchi-Mumbai-Game/releases/download/v0.0.1/Aamchi-Mumbai-Game-0.0.1-Windows-x64.zip)
- **Android ARM64.** Download the signed APK to install on your phone. The Android ZIP includes the same APK and the notices. [Android APK](https://github.com/SutharLabs/Aamchi-Mumbai-Game/releases/download/v0.0.1/Aamchi-Mumbai-Game-0.0.1-Android-arm64.apk) · [Android ZIP](https://github.com/SutharLabs/Aamchi-Mumbai-Game/releases/download/v0.0.1/Aamchi-Mumbai-Game-0.0.1-Android-arm64.zip)

The playtest includes walking, pedestrian conversations, driving four vehicle types and the Ranwar route. The Windows build was tested on the development PC. Native Android playtesting on the selected Redmi Note 9 Pro Max (India) is pending. [Release notes](https://github.com/SutharLabs/Aamchi-Mumbai-Game/releases/tag/v0.0.1) · [Phase progress](docs/PHASE_PROGRESS.md)

## License

The original project is source-available. You may inspect the public code and run the official builds for personal, noncommercial playtesting. Commercial redistribution requires prior written permission from SutharLabs. Third-party materials keep their own licenses. [Project license](LICENSE) · [Third-party notices](docs/THIRD_PARTY.md)

## Start here

Open `prototype/project.godot` in Godot **4.7.2** and press **F5** to launch the title menu from source. The playtest guide covers controls and export commands. [Godot project](prototype/project.godot) · [Playtest guide](prototype/README.md)

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

**Aamchi Mumbai Game** is the selected title. Proposed tagline: “Mumbai never slows down.” See `docs/BRAND.md`.

## First target

A compact game for **Windows 10 and Android 12 together**, starting in **present-day Bandra West**, with an original crime-fiction story: on-foot movement, arcade driving, light traffic and pedestrians, and one complete mission as the first playable target. Preserve recognizable road/landmark relationships and compress travel distances. **Cars, rickshaws, motorcycles and scooters must all be player-drivable in the first release**; test their handling and rider requirements in stages. The selected reference pocket is Ranwar/Waroda/Chapel Road; story and cast remain original. The [area/map selection](research/BANDRA_REFERENCE_AREA_AND_MAP.md) owns its boundary and current reference evidence.

The user selected a weaker PC class with **integrated graphics and 8 GB RAM**, and **Android 12** as the Android OS target. The 720p / 30 FPS PC budget remains provisional. The available 16 GB development PC is a stronger test device. The **Redmi Note 9 Pro Max (India)** is the selected Android test phone. Its installed Android/MIUI, RAM variant and performance are pending. The human developer has **some experience** and **provisionally ten focused hours/week**, to be revisited as development progresses. [Phase progress](docs/PHASE_PROGRESS.md)

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
- `prototype/` — runnable Godot Phase 1 practice route, walking/controller code and Windows export preset.
- `assets/` — original or properly licensed assets.

## Status

Rebaselined on **22 November 2026** from [GitHub main at `8544233`](https://github.com/SutharLabs/Aamchi-Mumbai-Game/commit/85442338c6670b486bad7264eded24e8c9c58479) in `C:/Suresh/Software/Aamchi-Mumbai-Game`. Active local branch: `phase-1/prototype`. The 0.0.1 development playtest has Windows x64 and Android ARM64 builds. Minimum-device acceptance remains open on both platforms.

The game is set entirely in present-day Mumbai, starting in Ranwar, Bandra West. Use current photos, street data and vehicle references with recorded dates and provenance. The Windows playtest opens with a Marathi-branded title menu, local profiles, settings and credits. It has four drivable vehicles and uses captured locomotion for the player and two pedestrians. The release schedule will be re-estimated after both-platform testing with the provisional ten human hours per week. [Playtest guide](prototype/README.md)

**Godot 4.7.2 standard, Compatibility rendering and typed GDScript** are selected for implementation. The first development release **0.0.1** has Windows x64 and signed Android ARM64 builds. Installation and performance checks on the 8 GB Windows 10 baseline and the Android test handset remain open. [Technology selection](research/TECH_STACK_SELECTION.md) · [Playtest guide](prototype/README.md)

The first procedural Blender batch **completed all eleven jobs**. All **77 generated files are collected and match accepted checkpoint hashes**, recorded at **20 November 2026, 06:57:50 IST** in the [collection receipt](reports/remote/epyc24/asset-collection-2026-11-20.json). [Preliminary review](reports/ASSET_REVIEW_2026-11-20.md) selects bay/props first; local architectural, cultural, rig, collision and game checks remain open. The [handoff](docs/OVERNIGHT_HANDOFF.md) preserves earlier observations. No new batch was started.

The captured model search contains **21 unique CC BY/download-enabled candidates** across vehicles/environments, Indian characters/clothing and generic building components, plus four character holds. Their catalogue license/download declarations were checked; archives and game readiness remain unverified. No complete open, production-ready nauvari/pheta or Mumbai chawl kit was established. Use the specialist catalogues and [asset plan](docs/ASSET_PRODUCTION_PLAN.md) before acquisition, including the Quaternius license hold.

## Check or collect the night batch

Run from this workspace with the existing VPN/SSH connection available:

```powershell
python tools/remote_night.py status
python tools/remote_night.py collect
```

Generated production artifacts are collected to `assets/generated/<job-id>/`; remote diagnostics go to `reports/remote/epyc24/`. Read the runbook before changing or redeploying jobs. The completed worker has exited; a later prepared batch needs an explicit start. During execution it needs no active laptop/chat session, but the node must remain on and a reboot requires an explicit restart.
