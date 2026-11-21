# Mumbai: Gully Heat — real-world environment and vehicle research

Latest delegated choices: **Windows 10/Android 12**, the [selected Ranwar/Waroda/Chapel reference pocket and acquired open map](BANDRA_REFERENCE_AREA_AND_MAP.md), and the [selected Godot 4.7.2 stack](TECH_STACK_SELECTION.md). The [collected-study triage](../reports/ASSET_REVIEW_2026-11-20.md) selects bay/props first and holds generic chawl assemblies from local placement. Final shipped boundary, dated per-subject fit and technical/device acceptance remain open; earlier catalogue metadata below is preserved.

Research date: 19 November 2026. This document implements the user's requirement that buildings, vehicles, landmarks, and streets be based on real Mumbai. It refines the earlier feasibility review and takes precedence over its generic-city or car-focused assumptions.

**Direction update, 20 November 2026:** the user selected **Bandra West**, the **1990-1995 year-band** and documented geographic compression. First release must support **Windows and Android together**, with **Android 12 as the OS target** and **cars, rickshaws, motorcycles and scooters all player-drivable**. The Windows minimum class is 8 GB RAM with integrated graphics; exact PC details and Android phone model/SoC/RAM/GPU remain unknown. Android 12 is not a hardware specification. The developer has some experience and provisionally 10 human hours/week. Existing modern-reference research below is retained as comparison material, not a period-approved shipping roster. No historical model replacements are selected in this update. The user's "gangster era" description is an original-fiction tone direction, not a historical assertion made by this research.

## Direction and evidence

Use real places and specified vehicle models as the reference for proportions, silhouettes, materials, street relationships, and local details. Simplify geometry and rendering for modest hardware. Keep the game's characters, story, missions, and branding original. Geographic compression must be recorded rather than disguising unrelated landmarks as neighbors.

The research uses municipal/heritage authorities, landmark operators, transport authorities/operators, manufacturers, and individual photo records. Manufacturer dimensions establish a specified model's proportions; they do not prove period availability or frequency in Mumbai. Tourism/heritage references establish identity and location; their images are not automatically reusable textures. Sources have different dates, and the selected historical condition needs dated corroboration.

The 1990-1995 setting year-band is settled. The compressed Bandra West boundary and dated evidence for individual subjects remain open. Contemporary OEM pages, map geometry, photographs, landmark views and redevelopment records can inform technical comparisons or changes over time, but do not establish what belonged in the selected period. Require dated primary-source evidence of the chosen vehicle generation, building state, road relationship and street details before period shipping approval. License metadata and recognizable Mumbai identity do not satisfy this separate era gate.

## 1. Selected district and retained regional comparisons

| Region / current role | Grounded identity | Production implication |
|---|---|---|
| **Bandra West - selected first pocket** | Village/residential lanes, coastal streets, Mount Mary, Bandra Fort/Lands End; individual places are reference candidates, not all within one small playable footprint | Define the compressed boundary and dated period evidence, then verify which buildings, roads and four-family vehicle models belong together |
| **Girgaon/Khotachiwadi–Marine Drive** | Low-rise heritage lanes, Art Deco residential frontage, seafront road and promenade | Strong architectural alternative; routine suburban rickshaw traffic does not fit the researched contemporary transport geography |
| **Fort/Churchgate/Colaba** | Gothic civic and station buildings, Art Deco cinema/apartments, Gateway waterfront | Build selected coherent subareas later; Gateway, CSMT, and Marine Drive should not all be squeezed around one block |
| **Central Mumbai / BKC** | Chawl/redevelopment districts versus planned commercial-office blocks | Separate visual/road grammars; verify current parcels rather than mixing historical chawls and present-day towers arbitrarily |

Bandra West is the selected first area; the precise boundary and compressed playable layout are still pending. This does not imply that all of Bandra fits 0.25–0.5 km². Other regions remain comparison or later-expansion research. Municipal sources identify Bandra's old settlements; tourism describes its coastal and religious landmarks, without independently establishing their selected-period condition. [BMC H/West ward reference](https://www.mcgm.gov.in/irj/go/km/docs/documents/Ward%20Information/HW_WARD_Gardens.pdf), [Maharashtra Tourism: Mumbai Suburban](https://maharashtratourism.gov.in/districts/mumbai-suburban/)

### Transport geography

The official airport operator describes metered rickshaws as operating in the suburbs, with the western range reaching Bandra and the central range reaching Sion. This is contemporary regional guidance; historical permissions and precise boundary roads need period-specific evidence before implementation. Do not infer period traffic rules from a current visitor page. [CSMIA transport guidance](https://csmia-mumbai.adaniairports.com/Airport-Facilities/Transport)

MSRDC's Sea Link project description specifies four-wheelers-and-above access. Retain this as a modern road-permission comparator, not an approved historical route or skyline element. Sea Link geometry stays on period-shipping hold until dated evidence is checked against the exact setting; current access rules cannot establish period access. [MSRDC Sea Link project](https://msrdc.in/Site/Common/ProjectListDetails.aspx?ID=66&MainId=18)

## 2. Buildings and landmarks: real reference catalogue

The modeling column is a preserved subject/reference catalogue, not a period-approved asset list. Verify the selected-year facade, surrounding roads, access and viewpoints before acceptance. Modern skyline entries, current station photographs, BKC and redevelopment views are comparators or holds until their exact-period form is evidenced; no construction/existence dates are asserted here without that research.

| Real reference | Area and factual basis | Recognition cues to preserve in a simplified model |
|---|---|---|
| **Marine Drive Art Deco apartments** | Marine Drive/Churchgate; part of the documented Art Deco ensemble | Actual frontage proportions, rounded balcony/corner forms, horizontal rhythms, and consistent roofline rather than generic glass towers. [UNESCO evaluation](https://whc.unesco.org/document/168687) |
| **Eros Cinema** | Churchgate; named within the ensemble documentation | Distinct cinema mass, stepped profile and entrance treatment; obtain dated exterior views. [UNESCO evaluation](https://whc.unesco.org/document/168687) |
| **Rajabai Clock Tower** | University/Oval Maidan area | Landmark-specific tall silhouette and its relationship to lower surrounding buildings. [UNESCO ensemble](https://whc.unesco.org/en/list/1480/) |
| **Bombay High Court / civic frontage** | East of Oval Maidan, facing the Art Deco side across the open ground | Gothic roof/tower silhouettes and repeated pointed-arch bays; texture small ornament. [UNESCO ensemble](https://whc.unesco.org/en/list/1480/) |
| **Chhatrapati Shivaji Maharaj Terminus** | Fort station district | Dome, turrets, pointed arches, principal frontage rhythm; create a dedicated landmark asset. [UNESCO station entry](https://whc.unesco.org/en/list/945/) |
| **Gateway of India** | Apollo Bunder/Colaba waterfront | Central arch, side masses, proportions, approach, and sea setting. [Mumbai City district administration](https://mumbaicity.gov.in/en/tourist-place/gateway-of-india/) |
| **Taj Mahal Palace** | Colaba, overlooking Gateway/Arabian Sea | Distinct roof/dome silhouette and main frontage; interiors are separate scope. [Official hotel page](https://www.tajhotels.com/en-in/hotels/taj-mahal-palace-mumbai) |
| **Khotachiwadi houses** | Girgaon/Charni Road; municipal legacy article documents the precinct | Low-rise house proportions, porches/verandas, balustrades, roof forms, and winding lane relationships. [BMC precinct article](https://www.mcgm.gov.in/irj/go/km/docs/documents/D%20Ward/Heritage-Sites/64_Legacy%20of%20D%20Ward_Article_Khotachi%20Wadi.pdf) |
| **Ranwar/Bandra village houses and shop edges** | Bandra West, with precinct references around Hill/Waroda/Chapel roads | Base frontage modules on dated examples from the chosen block; preserve actual setbacks and lane character. [Municipal heritage list](https://portal.mcgm.gov.in/irj/go/km/docs/documents/MCGM%20Department%20List/Chief%20Engineer%20%28Development%20Plan%29/Docs/HERITAGE/Heritage%20List%20%26%20Govt.%20Notifications/Heritage%20List.pdf) |
| **Bandra railway station exterior** | Bandra; a file-level photo record supplies a 2024 façade view | Match principal roofline, openings, frontage proportions, and station approach from multiple references. [2024 photo record](https://commons.wikimedia.org/wiki/File:Bandra_Station%CB%90_View_of_the_fa%C3%A7ade.jpg) |
| **Mount Mary Basilica** | Bandra West; operator publishes architecture/access information | Twin spires, major façade arches, and hill/approach relationship. [Official architecture guide](https://www.mountmarybasilicabandra.in/Architecture.html) |
| **Bandra Fort / Lands End** | Bandra West; municipal document identifies the site | Fort walls, stepped/terraced massing, rocky coastal edge and sea views; selected-period condition and surroundings need dated verification. [BMC H/West reference](https://www.mcgm.gov.in/irj/go/km/docs/documents/Ward%20Information/HW_WARD_Gardens.pdf) |
| **Chimbai / Khar Danda working waterfront** | Separate western-suburban settlement references; tourism identifies Khar Danda's fishing-village role | Survey the selected settlement's actual house edges, work/storage spaces and waterfront. Fishing props belong where locally supported. [Tourism reference](https://maharashtratourism.gov.in/districts/mumbai-suburban/) |
| **BDD chawls and replacement blocks** | Worli, Naigaon, N.M. Joshi Marg/Lower Parel project areas | Separate historical and redeveloped reference sets. Choose an actual parcel/date before drawing its form. [MHADA project hub](https://www.mhada.gov.in/en/content/bdd-chawl-redevelopment-project) |
| **BKC office/institutional blocks** | Bandra East/Kurla; MMRDA describes the planned commercial district | Different road widths, building setbacks, façade grids, and large masses from village lanes. [MMRDA overview](https://www.mmrda.maharashtra.gov.in/en/planning/badra-kurla-complex/overview) |
| **Bandra–Worli Sea Link** | Bandra–Worli coastal connection | Modern comparison/period-shipping hold. Do not add even a background silhouette until period compatibility is verified. [MSRDC project](https://msrdc.in/Site/Common/ProjectListDetails.aspx?ID=66&MainId=18) |

The ordinary city needs as much care as the landmarks. Capture a small real block containing everyday apartments, shops, compounds/gates, utilities, pavements, and parked vehicles. Build 8–12 reusable frontage/building modules from those observations. A tower kit alone or a city made entirely of distressed houses would misrepresent the range being researched.

## 3. Contemporary vehicle comparators - 1990-1995 model qualification pending

All four requested families—**rickshaw, car, motorcycle, scooter**—must be **player-drivable in the first Windows and Android release**. Parked/ambient completion is an intermediate implementation milestone. The sources below document modern model details, not a selected 1990-1995 roster or local market share. Hold named modern vehicles and their dimensions as comparators until a dated primary-source packet verifies the exact generation, year and Mumbai fit; select period replacements only after that work. No model's period eligibility is inferred from its family name.

| Category / retained comparator | Published or visible basis | Technical comparison and pending period acceptance |
|---|---|---|
| **Rickshaw: Bajaj RE CNG** | Indexed OEM specification reference: 2,635 × 1,300 × 1,700 mm; 2,000 mm wheelbase. [Current model page](https://www.bajajauto.com/three-wheelers/re), [specification reference](https://www.bajajauto.com/three-wheelers/re/specifications) | Three-wheel silhouette, canopy/open sides and narrow nose. Reconfirm dimensions against the selected generation's brochure; corroborate Mumbai canopy, meter, trim and paint with local photos. Test rollover, turns and curbs separately from a car. |
| **Tall hatchback/taxi: Maruti WagonR / Tour H3** | OEM Tour H3 reference: 3,655 × 1,620 × 1,675 mm; 2,435 mm wheelbase. [Tour H3](https://www.marutisuzuki.com/tour/wagonr) | Distinct tall-roof shell; private and taxi treatments only after actual Mumbai livery/roof equipment checks. |
| **Sedan/cab: Maruti Dzire Tour S** | Indexed OEM specification reference: 3,995 × 1,735 × 1,525 mm; 2,450 mm wheelbase. [Tour S](https://www.marutisuzuki.com/tour/dzire) | Compact sedan proportions. Reconfirm the chosen generation's brochure; do not combine a different-generation grille/body with these dimensions unnoticed. |
| **Van: Maruti Eeco / Tour V** | OEM page: 3,675 × 1,475 × 1,825 mm; 2,350 mm wheelbase. [Tour V](https://www.marutisuzuki.com/tour/eeco) | Narrow boxy utility/passenger body; optional later variant once the four core families are represented. |
| **Scooter: Honda Activa** | Honda's official 2025 release supplies a dated petrol-model reference. [Honda release](https://www.honda2wheelersindia.com/news/honda-motorcycle-and-scooter-india-launches-new-2025-activa-scooter-bole-toh-activa) | Step-through body, floorboard, enclosed engine area, scooter rider pose. Obtain the chosen generation's brochure; do not confuse it with Activa e:. |
| **Scooter alternative: Suzuki Access 125** | OEM page provides variant-dependent dimensions and visual references. [Access 125](https://www.suzukimotorcycle.co.in/product-details/all-new-access-125-bluetooth-enabled/features) | Optional second scooter silhouette after one working scooter pipeline; choose a single documented variant. |
| **Commuter motorcycle: Hero Splendor+** | Indian OEM page: 2,000 × 720 × 1,052 mm; 1,236 mm wheelbase. [Splendor+](https://www.heromotocorp.com/en-in/motorcycles/splendor-plus.html) | Tank/seat/exposed-engine silhouette, narrow wheels, motorcycle rider posture. Different body/pose from a scooter even if they share some arcade handling code. |
| **BEST bus: a specified Tata electric bus or Switch EiV22** | Tata confirms supplying 9 m/12 m electric buses to BEST; PIB records the Mumbai EiV22 launch. [Tata delivery announcement](https://smartcitymobility.tatamotors.com/news/tata-motors-delivers-state-of-the-art-electric-buses), [PIB launch](https://www.pib.gov.in/PressReleasePage.aspx?PRID=1852875&lang=2&reg=48) | Ambient landmark/traffic asset first. Confirm body, paint, route/date and dimensions before adding it; a launch is not proof of service on every street. |

Source availability note: Bajaj's specification subpage remained indexed but returned 404 on repeat direct access; the model landing page worked. Some OEM specification tables also appeared in indexed text but were absent from a later dynamic page rendering. Preserve a generation-specific brochure before accepting exact model scale; the numbers above are reference leads rather than measured production assets.

The transport department maintains separate auto, black/yellow taxi, and Cool Cab tariff categories. That supports different service identities; it does not establish which model dominates today's traffic. No fleet percentages or model-frequency weights were verified in this research. [Official tariff index](https://transport.maharashtra.gov.in/Site/Common/ViewPdfList.aspx?Doctype=1d1f28f9-a4e5-4b09-ab8b-1d4576adca18)

Build the shipping traffic roster from dated references for the selected 1990-1995 year-band, including livery, equipment and route context. The earlier Premier Padmini mention is a research lead, not a selected replacement or an authenticated period fleet claim. Exact badges, advertisements and operator graphics need their own source/reuse records; accurate proportions and local paint layout are separate art decisions from copying a logo image.

## 4. Parked, ambient, and player-drivable are separate statuses

Every vehicle gets three explicit implementation flags:

1. **Parked/static:** accepted real-world silhouette, dimensions, materials and collision.
2. **Ambient:** road/zone permissions, lane following, braking/stopping, spawn/despawn and recovery; a rider is required where visible.
3. **Player-drivable:** handling, camera, input, mounting/entry, rider/driver animation, crash/recovery and save behavior.

Start the driving prototype with a car, then prove rickshaw stability and both motorcycle and scooter interaction/handling. All four families are required player-drivable; the sequence stages implementation rather than deferring a required family. Bikes and scooters can share selected systems but need distinct poses/tuning and visual proportions. Validate driver/rider animation, mount/entry, steering, recovery and saves using Windows input and Android touch controls. A three-wheeler or rider-controlled bike is not covered by a car reskin. Export the populated route to both named test devices and measure performance; 8 GB/integrated graphics alone and an unspecified phone cannot establish accepted minimum specifications.

## 5. Reference acquisition and modeling process

- Record the real subject, neighborhood/road anchor, reference year, source URLs, dimensions and their confidence, image creator/license, geometry source/license, and intended role. See the [reference register](../assets/references/REFERENCE_REGISTER.md).
- Use official heritage/OEM material to identify shape and specifications. Use original or individually licensed photos for reusable image inputs. UNESCO's gallery credits individual photographers; official publication does not make all images a freely reusable texture library. [UNESCO gallery](https://whc.unesco.org/en/list/1480/gallery/)
- Obtain several useful views of each hero subject. Mark unseen sides and estimated dimensions; do not present an AI reconstruction as an accurate survey.
- Build the major silhouette and scale first, then test recognition from the actual driving/on-foot camera. Add façade/window/roof or wheel/body detail only where it helps identity.
- Adapt reusable modules when their proportions fit the reference. Preserve local rooflines, façade rhythms, wheelbase/body proportions, and street relationships rather than importing a generic pack unchanged.
- Keep collision simple, use a small material/atlas family, and author distance simplifications. Accept performance in exported complete-street builds on both the actual Windows integrated-GPU PC and the Android test phone, including touch controls, drivers/riders and all four drivable families; an isolated turntable is insufficient.

No vetted ready-to-ship low-poly Mumbai city pack was established in the sources reviewed. A downloadable Gateway model on Sketchfab is labeled AI-generated and reports 1.1 million triangles; it is a screened example requiring substantial evaluation, not an adopted shortcut. [Model listing](https://sketchfab.com/3d-models/gateway-of-india-model-bee1163781e7474486007915a3f430ed)

Follow-up catalogue search: [twelve specific open-license model candidates](OPEN_MODEL_CATALOGUE.md) now have live license/download metadata, including vehicles and Mumbai building/landmark components. They remain candidates awaiting archive, fidelity, geometry and engine review; this does not establish a ready-made Mumbai city kit.

## 6. First validation set and roadmap changes

Proposed geographically coherent validation set, after defining the selected Bandra West pocket's boundary and dated 1990-1995 subject packets:

- One real landmark or station exterior that belongs in that subarea; one or two additional silhouettes only where geographically appropriate.
- Eight to twelve frontage/building modules based on actual local examples, including an ordinary apartment/shop corner.
- One period-verified real-model rickshaw, car, scooter and motorcycle, each with a complete generation/year packet and player-drivable Windows/Android acceptance. The modern Bajaj RE/WagonR/Tour H3/Activa/Splendor references above remain comparators or holds; this update does not choose untested replacements. A second car/van is optional within the small roster.
- Street props, signs, parking patterns, bus-stop details and road markings corroborated from the same neighborhood/date band.

Phase 0 now defines the selected Bandra West boundary, collects dated packets for the settled 1990-1995 year-band, records actual Windows/Android 12 test hardware, and rejects unverified modern carryovers. Phase 1 proves the car and the required rickshaw/motorcycle/scooter handling and riders, including touch input. Phase 2 accepts the period-Mumbai set, geographic compression and populated-scene performance on both platforms. Phase 3 demonstrates it in a complete mission. The previous 15–24 month estimate remains an earlier comparison baseline; simultaneous platforms and all four drivable families need a measured schedule rebaseline using the provisional 10 human hours/week and some developer experience, without assuming the old full-time/experienced baseline.

Status: research and source records only. No local survey, downloaded reference-image library, map extraction, production mesh, asset import, or handling test was completed in this update.
