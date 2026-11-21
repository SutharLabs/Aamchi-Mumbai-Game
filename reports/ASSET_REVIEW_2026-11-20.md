# First batch: collected evidence and refinement selection

Reviewed 20 November 2026 for Mumbai: Gully Heat. The user delegated selection of the most useful studies. This is agent visual triage and a refinement decision; no production character, authentic local building, collision, rig or device-performance gate is accepted here.

## Collection and review scope

The [collection receipt](remote/epyc24/asset-collection-2026-11-20.json) records 77 generated files plus three queue diagnostics collected through the existing allowlisted helper. All **77 generated output sizes and SHA-256 values match the completed checkpoints**, in addition to transfer checks. Earlier diagnostic copies were preserved under `remote/epyc24/archive-before-collection-2026-11-20/`. The supervisor had exited; collection did not deploy, regenerate, start/stop a worker or change the clock.

The original serial copy was replaced with six concurrent read-only fetches through the same helper and validation functions to reduce connection overhead. Ten attempt logs had already been copied during the serial pass; they are diagnostics rather than generated model outputs. The 77-file count is not a claim about total diagnostic files.

Inspected all eleven `report.json` files and all eleven `preview.png` images. Also inspected the bay's front/rear/side, the ordinary character's rear/side, and the nauvari's rear: **17 images total**. All 44 review images are collected; the other 27 orthographic views still need review. No interactive BLEND/GLB inspection, animation test or knowledgeable cultural/architectural sign-off occurred.

Every report declares original procedural blockout geometry, no rig and zero animations. Measured figures below are export statistics, not engine draw-call or frame-time results.

## Selected refinement order

1. **Frontage bay and small props first.** Keep the reusable opening/pivot/material concepts and original ownership. Adapt the bay into a dated Ranwar village-house frontage kit: raised plinth, locally supported opening proportions, porch/verandah and tiled roof modules. Use the [selected area's heritage evidence](../research/BANDRA_REFERENCE_AREA_AND_MAP.md); the existing rectangular gallery bay is not already an authentic Ranwar house. Keep props separate and optional so paths remain clear.
2. **Establish a shared, connected character body/rig before polishing outfits.** The current ordinary character is a scale/input placeholder, not the production topology. Reuse an inspected commercial-safe body/rig route when available, then fit period everyday clothing and test idle/walk/rider/mounting. Do not spend the next batch decorating disconnected primitive body parts.
3. **Refine ordinary sari/dhoti construction on that body, then the specific nauvari and headwear variants.** Preserve garment identity through construction and reference review, not just color. Do not make traditional clothing the whole pedestrian roster or infer prevalence from these studies.
4. **Hold assembled gallery/baithi chawls as typology studies.** Selected Ranwar sources support village-house features. Use a chawl assembly in this pocket only when a dated local subject packet justifies it. Retain the stair as a reusable technical study; first prove connection, clearances and collision before repeating it.

No source/specification or queue change is part of this selection. The next modeling batch should be a small, explicitly reviewed refinement brief, rather than automatically rerunning all eleven studies.

## Per-study triage

| Study | Triangles / mesh objects / materials | Observed result and decision |
|---|---|---|
| [Frontage bay](../assets/generated/chawl-frontage-bay-v001/preview.png) | 300 / 25 / 5 | **REFINE FIRST.** Clear modular frontage, window and door-leaf concepts. Rendered black structural patches and bare walls need material/construction review; dated local facade/roof/plinth changes needed. Door clearance/collision and hinge behavior untested. |
| [Service props](../assets/generated/chawl-props-v001/preview.png) | 176 / 14 / 7 | **REFINE FIRST.** Readable bench, containers, washing/tap form and hanging cloth. Cloth is flat and tap/basin simplified; confirm subject/date, reduce material fragmentation and place without blocking movement. |
| [Stair](../assets/generated/chawl-stair-v001/preview.png) | 1,656 / 140 / 2 | **RETAIN FOR TECHNICAL REFINEMENT.** Flights/landings/rails read in the preview. Verify floor connections, head clearance, rail ends and traversable collision; consolidate repeated objects where appropriate. No actual stair traversal is proven. |
| [Gallery assembly](../assets/generated/gallery-chawl-study-v001/preview.png) | 6,060 / 507 / 6 | **HOLD LOCAL PLACEMENT.** Repeated dwellings and external galleries are readable, but 507 mesh objects are a repeated-scene concern despite low triangle count. No actual Ranwar building match, tested circulation or accepted module seams. |
| [Baithi assembly](../assets/generated/baithi-chawl-study-v001/preview.png) | 1,968 / 164 / 10 | **HOLD LOCAL PLACEMENT.** Two low-rise rows, roofs and courtyard are distinguishable from the gallery study. Still generic, with blank backs and simple roof/plinth detail; do not relabel as a surveyed local housing group. |
| [Ordinary character](../assets/generated/contemporary-character-study-v001/preview.png) | 2,840 / 27 / 7 | **REBUILD BODY BEFORE PRODUCTION.** Visible shirt/body gaps, black neckline and exposed rectangular waist/body mass; separate primitive joints. Useful only as a rough scale placeholder. Stable job name does not establish 1990s wardrobe fit. |
| [Everyday sari](../assets/generated/everyday-sari-study-v001/preview.png) | 3,152 / 35 / 8 | **REBUILD/FIT GARMENT.** Skirt-like wrapped silhouette reads more distinctly than the divided drape, but pallu/trim remain flat strips and neckline/shoulder fit unresolved. Generic sari label retained; not a verified nauvari. |
| [Kurta/dhoti/cap](../assets/generated/kurta-dhoti-cap-study-v001/preview.png) | 3,140 / 32 / 9 | **REBUILD/FIT GARMENT.** Current short upper form and bulbous divided lower masses do not establish the intended kurta/dhoti construction. Same body/neck issues; cap fit and garment terminology require review. |
| [Nauvari/kashtha](../assets/generated/nauvari-kashtha-study-v001/preview.png) | 3,240 / 33 / 8 | **REBUILD DRAPE.** Preview/rear read as loose divided trousers, with flat front/rear strips and unresolved pallu/tuck construction. Preserve CLOTH-01/02/03; no authentic-garment approval. |
| [Gandhi cap](../assets/generated/gandhi-cap-study-v001/preview.png) | 40 / 2 / 2 | **RETAIN ACCESSORY STUDY.** Small faceted folded-cap silhouette is a useful low-cost starting shape. Opening, fit, fold contour and head attachment remain unverified; color alone does not establish form. |
| [Pheta](../assets/generated/pheta-study-v001/preview.png) | 312 / 10 / 1 | **REBUILD WRAP DETAILS.** Preview uses stacked ring-like masses, rectangular crest and tail. Needs a chosen tying style, believable wrap/folds, scale and attachment; no ceremonial/cultural approval. |

## Acceptance boundary and next evidence

Existing defect IDs remain open: CLOTH-01 lower-drape silhouette, CLOTH-02 flat pallu, CLOTH-03 intersections, CHAWL-01 unmatched local component, CHAWL-02 traversal and CHAR-01 rig/fit. Add **CHAR-02** for disconnected/visible body-outfit gaps and **ENV-01** for excessive mesh-object fragmentation in repeated modules. These are observed or measured triage concerns; actual runtime cost is unmeasured.

The [Maharashtra Gazetteer's historical dress description](https://gazetteers.maharashtra.gov.in/cultural.maharashtra.gov.in/english/gazetteer/Poona/PART%20III/Chap%20%283%29/Dress.htm) distinguishes back-tucked and skirt-like sari construction. It is a construction reference, not evidence of 1990s Bandra clothing frequency. Direct fetch returned 404 during this check while indexed official text remained available; obtain the relevant complete source/reference views before detailed garment matching. Existing [character research](../research/INDIAN_MAHARASHTRIAN_CHARACTERS.md) records additional cultural sources and limits. The Worli MHADA reference is geographically separate and does not authenticate the selected Ranwar buildings.

Next acceptance needs full remaining views, source-led local/period checks, edited topology/materials, common rig or collision as appropriate, real engine import and populated Windows 10/Android 12 scene measurements. The [asset plan](../docs/ASSET_PRODUCTION_PLAN.md) owns A0–A5; this review makes the refinement choice without bypassing those gates.
