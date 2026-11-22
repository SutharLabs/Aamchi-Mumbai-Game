# Third-party code and asset ledger

Record every dependency and shipped asset. Code and content may have different licenses, including files in one repository. Inspect license files, notices, submodules, and asset credits before adoption. Keep required license texts and attribution with the project.

Updated 22 November 2026. The Ranwar prototype uses retargeted 100STYLE motion capture on an original procedural humanoid. The separate model, material and reference-image catalogues remain research inputs. [Asset production plan](ASSET_PRODUCTION_PLAN.md)

## Candidate registers - not acquired or adopted

| Candidate group | Owning catalogue / evidence | Current limit |
|---|---|---|
| Road/building packs, vehicles and Mumbai landmarks | [Open model catalogue](../research/OPEN_MODEL_CATALOGUE.md), [model evidence](../research/evidence/sketchfab-models-2026-11-19.json) | Twelve specific models have live CC BY 4.0/download declarations; packs have publisher/license leads. No archive contents, local geometry, rig or game import inspected |
| Indian character/clothing models | [Character research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md), [model evidence](../research/evidence/character-models-2026-11-19.json) | Six CC BY 4.0/download declarations plus four captured holds. No inspected rig/weights/animations; no accepted specifically Maharashtrian outfit |
| Chawl subject leads and generic components | [Chawl research](CHAWL_MODEL_RESEARCH.md), [component evidence](../research/evidence/chawl-components-2026-11-19.json) | Three generic Indian-building CC BY 4.0/download declarations. Specific BDD/paid leads use separate terms; no complete strict-open chawl kit established |
| Engine/addon/code reuse candidates | [Repository audit](../research/REPOSITORY_AUDIT.md), [feasibility review](../research/FEASIBILITY_REVIEW.md) | Source-reviewed candidates; exact adopted commits, dependencies and bundled asset notices still need acquisition/build review. Engine acceptance and target-device benchmarks remain pending |

The three model metadata files contain **25 distinct UIDs, 21 of which declare CC BY 4.0 and download enabled**. The other four are captured holds, not usable acquisitions. A metadata declaration records the publisher's claim; it does not prove underlying ownership, inspect constituent textures/meshes or capture the license shipped inside an archive. Recheck live terms when acquiring and preserve the actual archive/notices/hash. Do not promote candidate rows to the adopted table merely because they appear in a scene viewer.

CC BY content needs its actual creator/source/license/change record; see [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Custom commercial-use, royalty-free, QAL, Free Standard and NoAI terms are distinct from the strict-open shortlist. NC content, ripped-game/OEM extracts and unresolved provenance stay on hold or excluded as documented. Quaternius's current QAL versus legacy CC0 pack-page mismatch requires exact archive reconciliation. Map-data obligations, photo/input rights and geometry licenses are separate records.

## Adopted third-party code and shipping assets

The Ranwar playtest includes the map-based blockout and the 100STYLE animation excerpts below. [Engine and component selections](../research/TECH_STACK_SELECTION.md)

| Item / file | Source URL | Version / commit | Code license | Asset license | Obligations | Changes | Adopted? |
|---|---|---|---|---|---|---|---|
| Ranwar modern OSM reference | [OSM license](https://www.openstreetmap.org/copyright); [local package/manifest](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md) | Database 20 Nov 2026, 01:19:21 UTC; raw hash/checksums retained | Map data, not runtime code | ODbL 1.0; no imagery rights | Attribution/license and applicable derivative-database/Produced Work data offer; local ATTRIBUTION.md records details | Raw XML unchanged; GeoJSON/layout/preview separately traceable | Acquired reference/evaluation; no engine/shipping acceptance |
| 100STYLE `Neutral_ID.bvh`, `Neutral_FW.bvh`, `Neutral_FR.bvh` | [Ian Mason's 100STYLE dataset](https://www.ianxmason.com/100style/) and [Zenodo archive](https://doi.org/10.5281/zenodo.8127870) | Publisher's neutral XSens recordings at 60 fps | Motion data | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | Give creator credit, link source and license, and identify adaptations. [Packaged notice](../prototype/character/motion/100STYLE-ATTRIBUTION.txt) | Extracted, trimmed, looped, made in-place and retargeted at 30 Hz to the original humanoid | `phase1_motions.tres` plays idle, walk and jog in the Windows prototype |

## Original procedural geometry - separate provenance record

These records explain what the overnight tools actually produced or prepared. They do not reclassify original geometry as a downloaded asset and do not grant an open-source/content license. The generator sources are project-origin code under the project's control; no workspace-level `LICENSE`/`COPYING` file was found during this documentation check. Preserve project ownership/provenance records and choose a distribution/license policy deliberately rather than assuming a blanket grant over code, images or output geometry.

| Project study | Source / version evidence | Inputs and present acceptance |
|---|---|---|
| `smoke-chawl-bay` | `tools/build_queued_model.py`, `tools/modeling/core.py`, `tools/modeling/chawl.py`, [spec](../jobs/specs/smoke-chawl-bay.json), [report and output hashes](../reports/preflight/chawl-bay-report.json) | Original procedural primitives/material palette; documentary references recorded, no external meshes/textures imported. Technical BLEND/GLB/four-view export completed; static/unrigged, architectural, collision and engine review pending |
| `smoke-nauvari-study` | `tools/build_queued_model.py`, `tools/modeling/core.py`, `tools/modeling/characters.py`, [spec](../jobs/specs/smoke-nauvari-study.json), [report and output hashes](../reports/preflight/nauvari-report.json) | Original procedural body/garment massing, no external mesh/texture inputs; technical export completed. Static/unrigged, cloth/cultural/deformation review pending; not an accepted authentic nauvari outfit |
| Eleven `*-v001` overnight study jobs | [Queue](../jobs/night-queue.json), [inventory](ASSET_PRODUCTION_PLAN.md#eleven-job-study-inventory) | Original procedural route. All 77 outputs [collected/checkpoint-hash verified](../reports/remote/epyc24/asset-collection-2026-11-20.json); [preliminary review](../reports/ASSET_REVIEW_2026-11-20.md) selects bay/props. No third-party model imported or full cultural/functional/game acceptance. Earlier receipts remain historical. |

Blender and Python are existing production tools on the remote node, not evidence that third-party model content was adopted. Tool licenses do not replace a source model's notices, and using a reference URL does not copy or license the site's photographs. The [reference register](../assets/references/REFERENCE_REGISTER.md) records subject evidence and acquisition gaps. The [handoff](OVERNIGHT_HANDOFF.md) owns runtime receipts and the specific preflight defects still needing review.
