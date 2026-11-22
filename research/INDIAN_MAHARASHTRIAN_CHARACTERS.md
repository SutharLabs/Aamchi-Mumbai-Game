# Indian and Maharashtrian characters and clothing

Latest delegated choices: **Windows 10/Android 12**, the [selected Ranwar/Waroda/Chapel reference pocket and acquired open map](BANDRA_REFERENCE_AREA_AND_MAP.md), and the [selected Godot 4.7.2 stack](TECH_STACK_SELECTION.md). The [collected-study triage](../reports/ASSET_REVIEW_2026-11-20.md) selects bay/props first and holds generic chawl assemblies from local placement. Final shipped boundary, dated per-subject fit and technical/device acceptance remain open; earlier catalogue metadata below is preserved.

Research date: 19 November 2026. Project: Aamchi Mumbai Game. User requirement: Indian characters and clothing, with specific attention to Maharashtrian dress, suitable for a commercial stylized game.

**Production direction updated 22 November 2026:** **present-day Ranwar/Bandra West only**. The wardrobe combines ordinary contemporary street clothing with contextual Maharashtrian/traditional outfits. Modern-style candidates and the stable contemporary-character study are eligible inputs; current local silhouette, fit, rights, rig/deformation and performance remain to be accepted. Historical costume sources support construction/context rather than present-day prevalence. Windows 10/Android 12 and all four drivable families require driver/rider poses and both-platform acceptance; physical minimum-device details remain open.

Production follow-up: the suggested studies below now have implemented original Blender generators and saved overnight job briefs. The [asset production plan](../docs/ASSET_PRODUCTION_PLAN.md) owns their production route; the [handoff](../docs/OVERNIGHT_HANDOFF.md) owns actual execution and review status; [phase progress](../docs/PHASE_PROGRESS.md) records remaining acceptance work. The catalogue findings remain candidate research, without model-archive or rig inspection.

## Evidence and acceptance status

The catalogue below distinguishes an openly licensed candidate from a finished game character. Sketchfab's public model API was checked live for six CC BY 4.0 candidates and four exclusions/holds. Captured fields are in [character-models-2026-11-19.json](evidence/character-models-2026-11-19.json), including creator, license URL, download flag, geometry and animation counts.

No model archives, textures or source meshes were downloaded; no rig, clothing weight, separate body part, topology or engine behavior was inspected. A zero animation count does not prove that an asset lacks a skeleton. A creator's rigging description is a claim awaiting inspection; an animation count does not establish retargeting compatibility.

CC BY 4.0 permits commercial reuse/adaptation under its attribution and other conditions. Preserve creator/source/license/change records and inspect actual archive notices and third-party components at acquisition. [Creative Commons terms](https://creativecommons.org/licenses/by/4.0/)

## 1. Open-content character and garment candidates

All six rows returned **download enabled** and the **CC BY 4.0 license URL** in live public metadata. Face counts are reported by the catalogue, not locally measured. These are Indian-category references; none is authenticated as a complete specifically Maharashtrian outfit.

Current locality and wardrobe context are separate acceptance checks for every candidate. Inspect dated current Bandra/Mumbai clothing references, garment cut/material, footwear, hair and occasion. CHAR-005/006 and traditional garments are not excluded by the superseded historical-era setting; model title or license still does not authenticate local use or construction.

| ID | Model and creator | API faces / animations | Proposed use and remaining work |
|---|---|---:|---|
| CHAR-001 | [Indian Man In Dhoti](https://sketchfab.com/3d-models/indian-man-in-dhoti-54b9e050d0d6424b848a04bec02a85d0) — anandmohan662 | 21,604 / 0 | First traditional male candidate to inspect. Creator describes it as rigged, but weights/rig were not verified. Compare the garment's actual drape, body proportions, materials and scale against the chosen reference packet. |
| CHAR-002 | [Indian women in saree](https://sketchfab.com/3d-models/indian-women-in-saree-c1a3a0e75fcf4a5d95668030dc7deb6c) — anandmohan662 | 35,900 / 0 | Generic sari character; creator identifies GLB. Do not count it as a verified nauvari/kashtha garment. Inspect separation, folds, legs and deformation. |
| CHAR-003 | [Mom dress (saree and blouse)](https://sketchfab.com/3d-models/mom-dress-saree-and-blouse-e5eeac0236714098a27fdbe13aedcb09) — Habib Siddick | 27,774 / 0 | Garment-focused adaptation lead. Creator describes a garment made for a Bengali animation using Maya/Marvelous/Substance. It is not Maharashtra-specific; archive notices, textures and fit still need review. |
| CHAR-004 | [Indian woman in traditional saree outfit](https://sketchfab.com/3d-models/indian-woman-in-traditional-saree-outfit-895a6682c82245058f408da36a80cb75) — abhiaimer / Abhijeet Bhagat | 170,946 / 0 | Creator identifies Blender and GLTF/GLB. Higher-cost reconstruction/adaptation candidate; substantial reduction likely before repeated NPC use. |
| CHAR-005 | [Indian Man In Tshirt](https://sketchfab.com/3d-models/indian-man-in-tshirt-091381a4eeb14e3b9814e3aaf075ac59) — Nodeaxis Interactive | 50,007 / 1 | Everyday contemporary-clothing lead. Check animation contents, weights, hidden geometry, materials and scale. |
| CHAR-006 | [Indian Office Woman](https://sketchfab.com/3d-models/indian-office-woman-e6c60cafd33c4d54b0b840c4146ed244) — Nodeaxis Interactive | 105,608 / 1 | Contemporary city/office clothing reference. A listed animation does not establish that the asset is ready for our NPC controller. Geometry/material optimization needs assessment. |

For any ID above the live metadata URL has the form `https://api.sketchfab.com/v3/models/<32-character-model-id>`. The evidence file preserves each complete URL. The original-format source archive and authenticated download workflow were not exercised; do not promise editable `.blend` files from metadata alone.

## 2. Important holds and exclusions

| Listing | Verified reason / handling |
|---|---|
| [A Maharashtrian bride](https://sketchfab.com/3d-models/a-maharashtrian-bride-217e4ef0d70f49628e0637c379db2172) | Live API: download disabled, license empty, 213,576 faces. AI/Meshy indicators appear in its source metadata. It is not an available open asset. |
| [Maharastrian groom](https://sketchfab.com/3d-models/maharastrian-groom-352c27f811a743c1b5524d4452f03909) | Live API: download disabled, license empty, 171,926 faces. Description discloses Meshy generation. Do not count it as an acquired source. |
| [Nodeaxis Indian Woman in Saree](https://sketchfab.com/3d-models/indian-woman-in-saree-b5965a93b03440dea65160f7cbac1fc7) and [Indian Man In Kurta](https://sketchfab.com/3d-models/indian-man-in-kurta-a7fcb7ce36984b1b860ac7e476033bb1) | Live metadata identifies Free Standard rather than CC BY; listing pages show NoAI. Keep outside this strict-open shortlist and outside generator-input jobs. The creator's collection is not uniformly licensed. |
| [Indian Farmer — Hariom Singh](https://sketchfab.com/3d-models/indian-farmer-b9398d519ea7499ca844d81e2877206b) | Listing is NonCommercial; excluded from commercial asset acquisition. |
| [Mohini](https://sketchfab.com/3d-models/mohini-indian-horror-female-5bb02361bc5347259a515c1e5c75bff6) | Film-inspired horror styling does not supply an ordinary Mumbai pedestrian merely because it includes a sari. Keep outside the default NPC set. |
| Celebrity-likeness models | Do not use them as generic residents or assume a model uploader's license settles likeness/source rights. Choose original, non-celebrity characters. |

An additional [traditional sari model](https://sketchfab.com/3d-models/traditional-indian-saree-model-528f28ebdf214c7d9278b7bdd16292ca) by sam-30 was API-screened as CC BY 4.0/download enabled, 226,377 faces, no animations. It is lower priority than lighter candidates and not an authenticated nauvari. An [AI-generated dhoti character](https://sketchfab.com/3d-models/dhoti-clad-man-in-traditional-indian-attire-052dff295ffa40a69628d9960c0580c9) is another CC BY candidate, but generation quality, cultural fidelity and input provenance remain unknown.

## 3. Maharashtrian dress needs its own reference packet

No openly licensed complete production-ready nauvari/kashtha, pheta or Gandhi-cap clothing kit was established in this review. This is a gap in the reviewed sources, not proof that no such asset exists anywhere.

Use garment construction and contextual references, not an assumed facial appearance, to establish clothing identity. Keep contemporary everyday, traditional/heritage and festival/ceremonial categories distinct. A Maharashtrian model title is not accuracy evidence; present-day street references and knowledgeable review must support form and context.

| Reference | What it supports | Limits |
|---|---|---|
| [Maharashtra Gazetteer: Poona, Dress](https://gazetteers.maharashtra.gov.in/cultural.maharashtra.gov.in/english/gazetteer/Poona/PART%20III/Chap%20%283%29/Dress.htm) | Historical descriptions of eight/nine-yard sari forms, between-leg/back-tucked sakaccha treatment versus round skirt-like draping, shoulder/padar route, and folding-cap/headgear forms | Historical source. Use construction terminology; do not adopt its obsolete demographic, caste or clothing-frequency generalizations as present-day Mumbai data. |
| [Dr. Bhau Daji Lad Mumbai City Museum: Textiles and Attires](https://artsandculture.google.com/story/QAWx8kNCYEA_JQ) | Curated Bombay Presidency costume and textile examples, including different community/period forms | Historical objects and illustrations are not a current street-clothing survey. Image reuse rights need item-level checking. |
| [CSMVS: Pune pagadi](https://artsandculture.google.com/asset/pagadi-pune-brahmin-community-turban/JQE0TXAk0fLguw) and [headgear exhibition](https://artsandculture.google.com/story/humsafar-the-companion-chhatrapati-shivaji-maharaj-vastu-sangrahalaya/GwURySZA8BXdIw) | Specific historical headgear forms and variation by place/context | A historical pagadi is not automatically interchangeable with a contemporary festival pheta. Museum publication does not grant blanket texture/generator-input rights. |
| [Maharashtra Tourism: Jaakhdi](https://maharashtratourism.gov.in/culture/jaakhdi/) | Nauvari appears in a performance/festival context | Supports a contextual traditional outfit; it does not justify dressing every contemporary Mumbai NPC for a festival. |

A generic cylindrical sari cannot pass as the selected divided/back-tucked nauvari variant. A generic turban cone cannot pass as a referenced pheta. A dhoti, pajama and lungi should retain their different construction/silhouette where those distinctions matter to the selected character.

For present-day Bandra West, collect dated, appropriately reusable current street references before deciding clothing frequencies. Historical costume descriptions and museums do not establish today's prevalence. Do not invent percentages; preserve regional, generational, occupational and occasion variation.

## 4. Reusable base-body route

MakeHuman's official [commercial-use FAQ](https://static.makehumancommunity.org/oldsite/faq/can_i_sell_models_created_with_makehuman.html) states that exported models are CC0 and can be used commercially. It is a potential original/non-celebrity base-body route if the toolchain is deliberately evaluated. Separately acquired clothing, hair, textures and community assets still need their own provenance/license records. This research did not install MakeHuman or validate a headless export pipeline.

## 5. Proposed overnight model studies

The remote node available to the main workflow is CPU-only Blender. The first batch should produce **original procedural drafts**, saved for later human review, rather than claim to generate accepted cultural/game assets unattended. These are suggested job priorities, not a claim that any job has run:

1. **Ordinary-clothing technical study:** the existing contemporary-named brief provides shirt/trouser/body proportions; its cuts, footwear and details still need selected-current reference evidence. Keep the saved job ID intact as execution history; no celebrity likeness or third-party generator input.
2. **Cotton sari study:** original simplified blouse/sari draft with an explicit generic drape label. Keep it distinct from the nauvari study.
3. **Nauvari/kashtha drape study:** preserve the selected lower-leg separation, front-pleat/back-tuck concept and shoulder/pallu route. Document approximation and missing references. Human cultural review is required before labeling the result authentic.
4. **Kurta/dhoti study:** original kurta/sadara and dhoti/dhotar silhouette, with clear legs and garment/body separation in the source scene.
5. **Headwear studies:** separate folding-cap and referenced pheta/pagadi experiments. Label the exact intended type and occasion rather than using one generic turban for every character.

Outputs should be source `.blend`, exported `.glb`, a few useful orthographic/three-quarter previews, and a small manifest with job/version/seed, asset dimensions, counts, reference URLs, simplifications, and review status. If these studies are **static and unrigged**, their manifest and filenames should say so. Do not present static drafts as animated NPCs or pass rig/skin acceptance without a rig test.

No live cloth simulation is needed for these initial drafts. Later character acceptance needs idle/walk/turn tests, clipping and leg-separation checks, shoulder/sleeve deformation, scale/rig consistency, and driver/rider grip, seat, foot and mounting tests for all four required drivable families. Verify touch controls and camera readability alongside keyboard/controller behavior. Measure the populated exported game on both the actual 8 GB integrated-GPU Windows PC and the Android test phone; exact device models and performance remain pending. Geometry budgets remain proposed until measured in both builds.

## 6. Acceptance sequence

Current place/context/input-rights references complete -> silhouette/cultural review -> mesh/material review -> rig/animation and driver/rider review -> engine import -> populated Windows/Android performance -> production adoption.

Any overnight output stops at the stage it actually demonstrates. Archive and human review statuses should survive worker/session restarts; rerunning a completed study should create a new version rather than silently overwrite an accepted asset.
