# Open model catalogue — Aamchi Mumbai Game

Latest delegated choices: **Windows 10/Android 12**, the [selected Ranwar/Waroda/Chapel reference pocket and acquired open map](BANDRA_REFERENCE_AREA_AND_MAP.md), and the [selected Godot 4.7.2 stack](TECH_STACK_SELECTION.md). The [collected-study triage](../reports/ASSET_REVIEW_2026-11-20.md) selects bay/props first and holds generic chawl assemblies from local placement. Final shipped boundary, dated per-subject fit and technical/device acceptance remain open; earlier catalogue metadata below is preserved.

Research date: 19 November 2026. Purpose: find existing 3D assets with licenses permitting commercial game use, prioritizing real Mumbai subjects and practical low-spec production.

**Current production direction, updated 22 November 2026:** **present-day Ranwar/Bandra West only**, compressed geography, Windows 10/Android 12 and all four vehicle families player-drivable. The former historical-era exclusion is removed. Modern vehicle/skyline/scene candidates are eligible for evaluation, with current local fit, exact generation, archive rights, fidelity, function and device cost still unaccepted. The 19 November metadata/license observations and source counts below remain dated research, not new acquisition or production approval.

## What was verified

### Authenticated intake on 23 November 2026

Sketchfab’s authenticated Download API returned six GLBs. All six live listings declared CC BY 4.0 and downloads enabled. The receipt records creators, model URLs, signed-download results, ordinary archive sizes and hashes. The files were opened and reviewed locally. Only the 266-triangle paan kiosk entered the game at this checkpoint. Local originals and intake previews live under `.toolchain/sketchfab-intake/`. [Acquisition receipt](evidence/sketchfab-acquisitions-2026-11-23.json) · [Sketchfab Download API](https://sketchfab.com/developers/download-api) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

| Downloaded model | GLB review and disposition |
| --- | --- |
| [Indian street shop](https://sketchfab.com/3d-models/indian-street-shop-a7476a895cb841709ccbd5d9d8b96f36) by nayan pachori | **Adopted.** 266 triangles, one material and three 1024² maps. A generic paan kiosk at a fictional shop lot, with authored scale, placement and collision. |
| [Indian Shop](https://sketchfab.com/3d-models/indian-shop-dad04bbb505443129a86cebd89d77610) by anandmohan662 | **Held.** A lightweight grocery façade with a baked Kirana King storefront photograph and recognizable third-party product labels. The photo and branding rights need separate resolution. |
| [Low Poly Autorickshaw aka TukTuk](https://sketchfab.com/3d-models/low-poly-autorickshaw-aka-tuktuk-c7c87455ad014b3f9fc8c9fb2d164a61) by Nirmal.Justin | **Held for conversion.** 4,798 indexed triangles, 21 surfaces and one 1024² atlas. All three tire and rim assemblies share geometry that needs separation and usable pivots. The atlas includes registration plates and a blue badge. |
| [Activa scooty 3d model fts](https://sketchfab.com/3d-models/activa-scooty-3d-model-fts-de84863d474d4276ae52ff9ab72337bb) by Sunny khude 3d model | **Held for conversion.** 15,000 triangles, one fused surface and a 512² atlas. Driving needs separate steering and wheel parts, corrected origin/orientation, and product-design review. |
| [Thela street food stall](https://sketchfab.com/3d-models/thela-street-food-stall-9407e18db7404bd5855707dd12ecd149) by anandmohan662 | **Held.** 72,900 triangles, 41 surfaces and 17 maps. Repeated bicycle groups account for 45,408 triangles. The baked Masala Darbar sign and food photographs need clearance or replacement. |
| [Indian street food cart and vendor](https://sketchfab.com/3d-models/indian-street-food-cart-and-vendor-c2106d6c043f486c8f17275c315326d8) by Mrinal Kukreti | **Held.** 62,386 triangles, 192 surfaces and fourteen 1024² maps. The static vendor needs rigging, and the scene needs scale normalization, texture batching and review of the menu photography. |

### Original metadata review on 19 November 2026

Creator/catalogue pages were checked for license terms, files and downloads. For twelve specific Sketchfab models, the public model API was queried live and confirmed **CC BY 4.0**, **download enabled**, creator and geometry counts. The captured fields are saved in [catalogue metadata evidence](evidence/sketchfab-models-2026-11-19.json), with each API/source URL.

No model archive was downloaded, no login/download transaction was exercised, and no mesh, material, rig, moving part, source-file format, or engine performance was inspected. Several viewer pages returned 403 while their public metadata remained accessible. The API confirms the publisher's current catalogue declaration, not ownership of every component or final production suitability.

Follow-up research: [Indian/Maharashtrian characters and clothing](INDIAN_MAHARASHTRIAN_CHARACTERS.md) records the exact character candidates and distinguishes generic sari/dhoti assets from specifically Maharashtrian dress. A complete verified open nauvari/pheta outfit or Mumbai chawl kit has not been established. See [chawl model research](../docs/CHAWL_MODEL_RESEARCH.md) for the housing leads and remaining gaps.

A [bounded overnight modeling queue](../docs/OVERNIGHT_MODELING.md) is implemented with eleven original static-study jobs prepared to explore some of those gaps. These procedural drafts require cultural/architectural and game-readiness review; current deployment/activation evidence belongs in [the overnight handoff](../docs/OVERNIGHT_HANDOFF.md). The queue does not run continuous LLM agents.

The [asset production plan](../docs/ASSET_PRODUCTION_PLAN.md) connects these catalogues to acquisition order, reference packets, per-family methods, provisional budgets and acceptance gates. The [phase tracker](../docs/PHASE_PROGRESS.md) owns production task status; listing a model here does not complete that task.

## License selection

For this asset search, prioritize openly licensed content:

- **CC0:** commercial copying, modification and redistribution permitted without copyright-attribution requirements. Other rights are not automatically waived. [Creative Commons CC0](https://creativecommons.org/publicdomain/zero/1.0/)
- **CC BY:** commercial use/adaptation permitted under its conditions, including appropriate credit, license linkage and change notices. Capture the exact version and creator for every selected file. [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **CC BY-SA:** commercial use is possible but adds share-alike obligations; not a default acquisition target here.
- **NC:** fails this commercial-use requirement. **ND:** unsuitable for the planned adaptation pipeline.
- **Royalty-free/commercial-use permission** can support a paid game without being an open-content license. Keep those candidates visibly separate.

Editable source availability is also separate: CC0/CC BY does not guarantee an artist's original `.blend` file is supplied.

## 1. Recommended catalogues and reusable kits

| Catalogue / specific pack | License evidence | Useful files / availability | Fit for this project |
|---|---|---|---|
| [Kenney Car Kit](https://kenney-assets.itch.io/car-kit) | Creator page explicitly CC0 1.0 and commercial use | ZIP; OBJ, FBX, glTF; over 40 models | Good lightweight placeholders/base components. Generic cars are not accepted as exact Mumbai vehicle models without adaptation. |
| [Kenney City Kit — Roads](https://kenney-assets.itch.io/city-kit-roads) | Creator page explicitly CC0 1.0 | ZIP; OBJ, FBX, DAE, STL, glTF; over 65 models | Road pieces, barriers, lightposts and construction fences. Rework lane markings, road proportions and details from Mumbai references. |
| [Kenney Building Kit](https://opengameart.org/content/building-kit) / [City Kit Commercial](https://kenney.nl/assets/city-kit-commercial) | Kenney-authored/indexed pack pages state CC0; [publisher support](https://kenney.nl/support) confirms its asset-page policy | Modular building components; exact archive contents need acquisition review | Useful base geometry/background. Distinctive Mumbai frontages still need real-reference modeling. Some direct pages were robots-blocked; creator/indexed evidence was used. |
| [KayKit City Builder Bits](https://github.com/KayKit-Game-Assets/KayKit-City-Builder-Bits-1.0) | Creator GitHub README/license identifies CC0 1.0 | Free OBJ/FBX/glTF, 32+ low-poly models; `.blend` source is a separately paid tier on [creator itch page](https://kaylousberg.itch.io/city-builder-bits) | A genuine GitHub-hosted asset pack for blockout/background experiments. Toy/city-builder proportions need adaptation for a third-person Mumbai street. |
| [Poly Pizza](https://poly.pizza/) | Per-model CC0 or CC BY; inspect the entry and credit record | Examples: [CC0 hatchback](https://poly.pizza/m/BG0KAhmGDt), [generic scooter](https://poly.pizza/m/eHdEFPwUfCt); listed FBX/GLTF or OBJ/GLTF varies by item | Useful low-poly props, roofs, street furniture, and adaptation bases. A collection can contain several licenses; [City Pack credits](https://poly.pizza/l/kJqRAIGsw0/credits) demonstrate that mix. |
| [Poly Haven models](https://polyhaven.com/models) | Its [asset license](https://polyhaven.com/license) explicitly makes downloadable assets CC0 | Per-model source/download options; publisher describes downloads without an account/paywall | Good props, vegetation, surfaces and light references. Many assets need simplification/downscaled textures for this style. The license on assets does not make every website preview/logo reusable. |
| [ambientCG](https://ambientcg.com/) | [Official license documentation](https://docs.ambientcg.com/license/) states CC0 for its assets | Materials, some models and other resources; formats checked per asset | Especially useful for paving, concrete, walls and asphalt. It is not a complete Mumbai building/vehicle library. |
| [Sketchfab downloadable models](https://sketchfab.com/) | Asset-specific; twelve live CC BY 4.0 examples below | Public metadata confirms download flags; browser/API acquisition and original formats need separate checks | Strongest concrete real-Mumbai/Indian-vehicle leads in this search. Never infer an entire catalogue is commercially reusable. |

Additional discovery sources: [OpenGameArt](https://opengameart.org/) and [BlendSwap](https://blendswap.com/). Both require per-upload license/provenance review. Do not treat a free-download filter as a commercial-license filter. No specific Mumbai BlendSwap model was accepted in this review.

## 2. Vehicle metadata candidates - current-reference shipping gate pending

All six entries below returned **CC BY 4.0** and **Downloadable = true** through the public API. Counts are API-reported faces, not local mesh measurements. Animation count was zero for these entries; this does not establish whether an unanimated skeleton or separate moving parts exist.

Before selecting any body, identify its generation and current Mumbai use. VEH-001/002/003 rickshaws, VEH-004 Activa, VEH-005 WagonR and VEH-006 Pulsar are eligible acquisition leads; none is rejected merely for being modern. A title/license still cannot establish local fit, topology or function. Every family needs player handling, driver/rider, entry/mount, recovery and save tests on Windows/Android, including touch.

| ID | Model / credited creator | API faces | Evaluation recommendation |
|---|---|---:|---|
| VEH-001 | [Low Poly Autorickshaw aka TukTuk](https://sketchfab.com/3d-models/low-poly-autorickshaw-aka-tuktuk-c7c87455ad014b3f9fc8c9fb2d164a61) — Nirmal.Justin | 4,800 | First rickshaw candidate to inspect. Compare silhouette/scale/canopy against the Mumbai packet; do not assume a specific Bajaj generation. |
| VEH-002 | [Autorikshaw — Indian Tuk Tuk](https://sketchfab.com/3d-models/autorikshaw-indian-tuk-tuk-5775d012693741008acff9dad410e92d) — bhagathartworks | 8,128 | Indian scene-filler alternative. Check body proportions, material count, wheels and Mumbai livery fit. |
| VEH-003 | [Auto Rickshaw](https://sketchfab.com/3d-models/auto-rickshaw-44776bcb34e04c1a8b9c18a70376304e) — rSquare | 12,604 | Creator describes a practice model. Compare adaptation cost with the two lighter candidates before choosing. |
| VEH-004 | [Activa scooty 3d model fts](https://sketchfab.com/3d-models/activa-scooty-3d-model-fts-de84863d474d4276ae52ff9ab72337bb) — Sunny khude 3d model | 15,000 | Relevant named scooter. Check generation, wheel/handlebar separation, hidden geometry, materials and rider pose. |
| VEH-005 | [Wagon R](https://sketchfab.com/3d-models/wagon-r-6700812ecaa840199bdc31fc3b921385) — tkanimationsd742 | 72,873 | Relevant car-body candidate, but needs a reduction/LOD and material-cost assessment before traffic use. Confirm generation and component provenance. |
| VEH-006 | [Pulsar 135 Ls 2](https://sketchfab.com/3d-models/pulsar-135-ls-2-accbf2048c9344718791588b70d2ebf8) — e-restrepo1114 / EmanuelRestrepoVelez | 24,260 | Specific motorcycle alternative if it fits the selected present-day/neighborhood. It is not a Splendor; inspect rider pose, parts, scale and optimization work. |

These are meshes to evaluate, not working vehicle controllers. Mounting, steering, wheel rotation, balance, collisions and save behavior remain implementation work.

The official [Sketchfab download API](https://sketchfab.com/developers/download-api) describes glTF/GLB/USDZ delivery through an authenticated workflow. Original FBX/OBJ/`.blend` availability was not checked for these individual models. Do not promise those original formats from a preview or API license response.

### Contemporary Ranwar fleet reference and reuse decisions | 23 November 2026

The in-game fleet uses eleven unbranded models authored from shaped profiles and simple materials. Manufacturer pages supplied reference proportions and silhouette cues. The game assets use project-authored geometry, lighting, detailing and surfaces. Vehicle names and tuning identify fictional gameplay variants. The manufacturer list is a reference sample and has no district-level registration or fleet-share data.

| Fleet type | Present-day Indian-market reference and visible cues |
| --- | --- |
| `hatch` | Tall urban hatch with a compact footprint, large cabin and short ends. [Maruti Suzuki WagonR](https://www.marutisuzuki.com/arena/wagon-r) |
| `sedan` | Compact three-box car with a raked rear screen and visible rear deck. [Maruti Suzuki Dzire](https://www.marutisuzuki.com/arena/dzire) |
| `suv` | Compact crossover with taller cabin, rail accents and dark lower cladding. [Tata Nexon brochure](https://cars.tatamotors.com/content/dam/tml/pv/products/nexon/year-2024/ice/promoting-vc/brochures/oct-2024/nexon-brochure.pdf) |
| `mpv` | Family MPV with a longer roof over the rear seats and separated rear quarter glazing. [Maruti Suzuki Ertiga](https://www.marutisuzuki.com/arena/ertiga) |
| `rickshaw` | Passenger three-wheeler with open side entrances, a rear bench and a black-and-yellow Mumbai treatment. [Bajaj RE](https://www.bajajauto.com/three-wheelers/re) |
| `commuter` | Upright, narrow motorcycle with an air-cooled engine and practical passenger saddle. [Hero Splendor+](https://www.heromotocorp.com/en-in/motorcycles/splendor-plus.html) |
| `classic` | Rounded headlamp, deeper tank, full painted fenders and satin metal pipework. [Royal Enfield Classic 350](https://www.royalenfield.com/in/en/app/motorcycles/classic-350/) |
| `roadster` | Low modern-classic motorcycle with a tapered tank, compact circular lamp and dark engine hardware. [Jawa 42 model range](https://www.jawayezdimotorcycles.com/collections/all-motorcycles) |
| `scrambler` | Wider bar, taller front mudguard, a narrower rear saddle and rising exhaust. [Yezdi Scrambler model range](https://www.jawayezdimotorcycles.com/collections/all-motorcycles) |
| `scooter` | Everyday petrol step-through with a lamp in the handlebar cowl, low floorboard and enclosed drive. [Honda Activa scooter range](https://www.honda2wheelersindia.com/scooter) |
| `electric_scooter` | Sharper step-through with an apron lamp, floor battery tray and a compact motor/swingarm. [Ather 450](https://www.atherenergy.com/450/specifications) |

The vehicle controller, wheel pivots and occupant rigs are reused across the models. The car variants retain the current damage meshes and right-hand-drive cabin. They share one collision footprint. The shapes prioritize silhouettes and moving parts for repeated use in the district. [Vehicle implementation](../prototype/vehicle/README.md)

| Reuse candidate | Decision |
| --- | --- |
| Kenney Car Kit and KayKit City Builder Bits | Confirmed CC0 from the publishers. Suitable for distant/filler vehicles when the project needs them. Their compact toy or city-builder shapes do not match this third-person street treatment. [Kenney](https://kenney.nl/assets/car-kit?part=e68f4c97-d968-4f08-a3da-e1f770a3d0bb), [KayKit GitHub license](https://github.com/KayKit-Game-Assets/KayKit-City-Builder-Bits-1.0/blob/main/LICENSE.txt) |
| Acquired Sketchfab Activa scooter and Indian auto-rickshaw | Original archive and declared CC BY 4.0 intake are documented above. The fused Activa mesh requires separated moving parts. The auto requires wheel/pivot conversion and texture review. |
| Royal Enfield Classic 350 by Mansoor | Listing declares CC Attribution and offers a download. Its 733,100 listed triangles place it well beyond the existing vehicle budgets. Archive, derivative branding and source provenance remain unverified. [Creator listing](https://sketchfab.com/3d-models/royal-enfield-classic-350-f6495bfbffe443e89c499a2ba8766c88) |
| Custom Jawa by kreems | Listing declares CC Attribution and offers a download. The 42,600-triangle custom motorcycle has a distinct custom design. It needs geometry, archive provenance and texture review if used for an optional hero vehicle. [Creator listing](https://sketchfab.com/3d-models/motorcycle-custom-bike-jawa-low-poly-13771fe558604aedae09b5157029e790) |
| Exact Yezdi, Hero, Ather and current sedan, crossover or MPV production assets | Still pending suitable sources with verified redistribution terms and provenance. The third-party simulator extraction remains excluded. |

Exact branded models remain a separate acquisition task. Capture license and provenance for the mesh, materials and visible source elements, separate steering and wheels, verify driver fit/collision, and measure the populated scene on the Android and Windows targets before adopting any replacement. [Creative Commons Attribution 4.0 deed](https://creativecommons.org/licenses/by/4.0/)

## 3. Mumbai building/landmark metadata - current locality and asset gates pending

All six entries below also returned **CC BY 4.0** and **Downloadable = true**. Place them according to the actual map, not merely wherever the first district needs decoration.

Modern bridge/tower/scene entries are eligible reference or acquisition leads. Verify current capture state, geographic location/viewpoint, dimensions, archive components, fidelity and optimization before placement. A 2020 scan is dated evidence rather than a current survey. This applies to backdrops and walkable geometry; the former historical-era exclusion no longer applies.

| ID | Model / credited creator | API faces | Evaluation recommendation |
|---|---|---:|---|
| ENV-001 | [Mumbai Sealink bridge](https://sketchfab.com/3d-models/mumbai-sealink-bridge-401a9687558c47349faaa287b9523878) — AsteroidCap4040 | 2,584 | A **main-pillar component**, not a verified complete bridge. Creator says no textures and reports a cable-preview issue. Technical skyline comparator; current-reference hold pending dated evidence. |
| ENV-002 | [Kohinoor Square Dadar, Mumbai](https://sketchfab.com/3d-models/kohinoor-square-dadar-mumbai-b8fb7a17c54342c8b3b58b574a04d63c) — alokhirekhan | 7,871 | Named real Mumbai tower, potentially economical geometry. Check scale/materials/UVs/fidelity; belongs to Dadar's catalogue rather than automatically moving into Bandra. |
| ENV-003 | [Dharavi, India](https://sketchfab.com/3d-models/dharavi-india-4e8a19be98ba4dd0870672580ce981b7) — demondawson | 191,720 | Creator describes a January 2020 recycling-space scan from an artist residency. Useful specific-place reconstruction/reference candidate, not a general Dharavi kit. Needs substantial scene-cost review. |
| ENV-004 | [mumbai city](https://sketchfab.com/3d-models/mumbai-city-10a9b5635fa2413884bb2089d34fc043) — suvee10 | 800,942 | Heavy scene with little descriptive provenance. Hold until geographic accuracy, modularity, materials and source components are understood. Not a validated Mumbai map. |
| ENV-005 | [Gateway of india Model](https://sketchfab.com/3d-models/gateway-of-india-model-bee1163781e7474486007915a3f430ed) — anant20042003 | 1,117,070 | Creator discloses Meshy generation. Open-license metadata exists, but direct low-spec use is unsuitable without major evaluation/rebuilding; accuracy/input provenance remain unknown. |
| ENV-006 | [Marin_ Drive_01](https://sketchfab.com/3d-models/marin--drive-01-855b64c5847440e783670f8e50145058) — Vineet_Vishwakarma | 629,444 | Lead only: description does not establish accurate Mumbai coverage or capture method. Inspect location/fidelity before counting it as a real-Mumbai asset. |

No vetted complete open model was established for Bandra station, Mount Mary, Bandra Fort, complete CSMT, Ranwar frontages, or a reliable Mumbai Art Deco/chawl kit. This is a gap in the reviewed sources, not evidence that no such asset exists anywhere. Plan selected reference-based modeling/adaptation for those gaps.

## 4. Commercial-use sources outside the strict-open shortlist

**Quaternius:** the current [QAL v1.0](https://quaternius.com/license.html), updated 28 August 2026, permits commercial games/modification but restricts standalone asset redistribution. Legacy [Ultimate Buildings](https://quaternius.com/packs/ultimatetexturedbuildings.html) and [Modular Streets](https://quaternius.com/packs/modularstreets.html) pages still explicitly display CC0. Record this mismatch and inspect the exact archive/license before treating a pack as openly redistributable. Do not label the entire current catalogue CC0. No Quaternius archive has been acquired here.

**Indian Street Low Poly free sampler:** the [creator's listing](https://raerae-007.itch.io/indian-street-low-poly-free-sampler) offers a rickshaw, chai stall and props, including FBX/GLB/OBJ/`.blend`. It permits personal/commercial projects but says not to redistribute the files. This is an optional commercial-use source, not a strict open-content pack. Its listed green/yellow auto treatment also needs Mumbai reference adaptation.

## 5. Excluded or held despite attractive search results

| Listing | Reason |
|---|---|
| [Bus Simulator India — Traffic Cars](https://sketchfab.com/3d-models/bus-simulator-india-traffic-cars-a0c72a6277bf4301bb3e5db4ccb194b6) | Identifies a commercial game's traffic set. A CC label does not resolve source ownership/relicensing; hold. |
| [2024 Eeco by BHP3D](https://sketchfab.com/3d-models/2024-maruti-suzuki-eeco-6d1931e262534c96a096b2d18bbc54b9) | Description says exported from the OEM virtual showroom; uploader's CC selection does not establish permission to relicense those files. |
| [Suzuki Eeco by MidaZ_3D](https://sketchfab.com/3d-models/suzuki-eeco-3d-model-pbr-real-time-7953dfda303d40aebdbafb8487fc48d2) | NonCommercial license; outside this shortlist. |
| [CyArk Gateway scan](https://sketchfab.com/3d-models/gateway-of-india-mumbai-38a652e9f3bf49039026ef65ef61ac92) | Public API reports download disabled and no license; viewable research material, not an available open game model. |
| [CSMT Gargoyle](https://sketchfab.com/3d-models/gargoyle-aa8ee49d5d8e480798ced087573fd90b) | NonCommercial; excluded. |
| [Hero Super Splendor store model](https://sketchfab.com/3d-models/hero-super-splendor-d77c9013ed194606ab5545ab8dc1105c) | Relevant subject, but reviewed as a store/royalty-free listing rather than a verified open asset. |

## 6. Recommended acquisition/evaluation order

1. Evaluate Kenney Roads/Car Kit and free KayKit components as placeholders, retaining actual archive licenses. Adapt visible road details and vehicle bodies to current Ranwar references rather than labeling generic geometry authentic.
2. Verify current local model/generation packets, then inspect the existing rickshaw/Activa/Pulsar/WagonR acquisition leads and actual archive rights/components. The former historical-era hold is lifted; keep accept/hold decisions grounded in present-day locality, fidelity, function and cost.
3. Evaluate ENV-001 bridge pillar and ENV-002 tower only where current location, bearing/sightline and asset quality fit the intended scene. Their presence in contemporary Mumbai does not place them inside the small Ranwar map; no full bridge is supplied by a pillar model.
4. Review the denser scans/scenes only if their accuracy and reusable components justify optimization time. Keep key Bandra/heritage modeling gaps visible.
5. Record exact archive/hash, author, license/version, required credit, modifications, source-model provenance, current reference evidence, geometry/material/texture counts, scale, moving parts and import outcome in the asset ledger. Test exported populated streets on the named Windows integrated-GPU device and Android phone, with the four drivable families, drivers/riders and platform input active. Neither device has a measured accepted budget yet.

The original catalogue remains an acquisition shortlist. The later authenticated intake and the contemporary fleet section record current decisions and integration status. Exact branded vehicle sourcing and target-device acceptance remain open.
