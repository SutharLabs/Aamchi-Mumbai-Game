# Bandra West reference area and acquired offline map

Selected and acquired **20 November 2026**; active scope updated **22 November 2026** to **present-day Mumbai only**. Retain Ranwar/Bandra West, compressed real roads/landmarks, Windows 10/Android 12 and original fictional cast/missions. The acquired contemporary OSM snapshot is now the spatial baseline; the former historical reconstruction requirement is superseded.

**Selection:** the **Ranwar–Waroda Road–Chapel Road pocket**, with Hill Road as the busier northern edge and St Peter's Church as the first nearby landmark anchor. This is a small, defensible reference area rather than a plan to model all of Bandra. An actual modern OSM extract is now saved under [assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md). No engine import, player navigation, historical mesh or device-performance gate is claimed.

## Why this pocket

MMR-HCS's Bandra precinct study separates Ranwar, Waroda Road development and Chapel Road development. Its commercial-road/narrow-residential-lane contrast supports the compact loop and on-foot shortcut. This later conservation study documents identity and morphology, not a fresh current survey. Its large Volume I exceeded direct browser fetch limits; indexed primary text was accessible. [MMR-HCS Bandra study, printed p.4](https://mmrhcs.org.in/images/documents/projects/precinct-studies/Study_of_Bandra_Precinct/Bandra%20vol%20I.pdf)

The MMR-HCS heritage list documents the Hill/Waroda/Chapel precinct, pitched roofs, porches/verandahs, squares and lane footprints. Entry 619 describes nineteenth-century village-house features; this does not establish a local BDD gallery chawl. Entry 621 records a villa replacement in the 1990s, illustrating why older descriptions must be checked against the actual current parcel rather than treated as present appearance. [Entries 612, 619, 621, printed pp.69-71](https://www.mmrhcs.org.in/images/documents/projects/heritage-listning/01-Heritage-List.pdf#page=69)

For the first landmark, St Peter's official site continues to identify the existing church and its history; checked again on 22 November 2026. The 1938 foundation/1964 consecration are historical identity facts, not a requirement to recreate its old appearance. Use dated current exterior/surrounding views with suitable rights before final modeling. [Official parish history](https://stpetersbandra.com/about-us/history/)

St Andrew's and Mount Carmel remain contextual anchors outside the first core. Do not enlarge the map solely to include them. St Andrew's official history, checked 22 November, records its 2024-2025 restoration; current modeling should account for that restored state rather than requiring a pre-restoration facade. The site labels images representational, so they are not a survey or blanket image license. [Official parish history](https://www.standrewchurch.in/history)

## Three different boundaries

All coordinates below are WGS84 latitude/longitude. Dimensions are approximate ground-plane distances calculated from the coordinate bounds, not surveyed land areas.

| Boundary | South / west / north / east | Approximate size | Purpose |
|---|---|---|---|
| Acquired source selection box | **19.050500, 72.824300, 19.055500, 72.832200** | **830.3 × 556.0 m; 0.4616 km²** | Modern road/building/reference context and nearby landmark relationships |
| Proposed first greybox source footprint | **19.051900, 72.826000, 19.055350, 72.831000** | **525.5 × 383.6 m; 0.2016 km²** | Small initial loop, narrow-lane contrast and local landmark; a production recommendation selected from the acquired data |
| Shipped playable boundary | **Not fixed by this acquisition** | To follow traversal/device tests | Final authored boundary, backing scenery, blocked routes and compression must be recorded after gameplay evaluation |

The source query returns **whole selected objects and dependencies**, so some nodes lie outside its selection box. The actual returned node bounds are south **19.0462389**, west **72.8196829**, north **19.0596604**, east **72.8342653**. These extended ways are context, not an instruction to build that larger area. The saved raw file is unmodified; any later clipping is a traceable derived operation.

The first core is roughly bounded by Hill Road to the north, the St Peter's Road junction area to the east, the Ranwar/Chapel interior to the south, and the western Waroda Road approach. Its rectangular crop is a working authoring envelope, not a cadastral, municipal heritage or exact historical boundary.

## Concrete routes from the downloaded geometry

The local topology was checked using shared OSM node IDs. Source lengths follow the downloaded polyline geometry. These undirected checks do not establish current one-way/access legality, widths or driveability; verify current routing rules and author the left-hand arcade lane graph separately.

| Anchor | Modern source junction | OSM node | Latitude, longitude |
|---|---|---:|---|
| A | Hill Road / Waroda Road | 346633397 | 19.0546940, 72.8260536 |
| B | Hill Road / St Peter's Road | 9681688973 | 19.0552115, 72.8308263 |
| C | Waroda / Chapel / St Peter's Road junction | 346620827 | 19.0537922, 72.8307258 |
| D | Waroda Road / Veronica Road | 346621512 | 19.0541089, 72.8284513 |
| E | Nagrana Lane / Waroda Road | 347181270 | 19.0541387, 72.8275960 |
| F | Nagrana Lane / Hill Road | 10242737039 | 19.0547279, 72.8278068 |

**Initial road circuit:** A -> Hill Road -> B -> St Peter's Road -> C -> Waroda Road -> D -> western Waroda Road -> A. Source geometry is about **1,186.7 m**, using ways **1053511374, 31152959, 31152970 and 431825049**. Ordered IDs/coordinates remain in [candidate-layout.json](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/candidate-layout.json). Use the dated contemporary geometry as the baseline; current traffic direction, clearances and authored gameplay adaptation still need acceptance.

**On-foot gully candidate:** E -> Nagrana Lane -> F, about **70.5 m**, way **31217220**, tagged footway in the acquired snapshot. Keep it an on-foot shortcut candidate. Verify current width, steps/access, changes since capture and camera/collision behavior; a polyline is not evidence of vehicle access.

**First mission-route recommendation:** accept a fictional repair/delivery job near A; drive the loop past the St Peter's anchor to a fictional curbside stop near D; dismount and walk along Waroda to E, then use Nagrana Lane to reach F. Put the fictional handoff at an authored non-residential frontage rather than assigning criminal activity to a named real household. This proves travel, mounting, delivery and route choice without expanding the district or requiring a church interior.

Start the greybox at approximate source scale. If travel needs shortening, trial gentle reductions of selected block gaps, initially up to about **15%**, preserving landmark order, junction connections and distinct outer-road/inner-lane character. This is a design experiment, not an applied transformation or surveyed target. Keep vehicle clearances and lane widths separately authored; do not uniformly shrink collision geometry to compress the city.

## Actual acquired data and inspection

The accepted download is a **572,456-byte raw OSM XML** response from `https://overpass-api.de/api/interpreter`, using the saved [query](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/source-query.overpassql). The source reports database time **2026-11-20T01:19:21Z**. Acquisition/access times and response details are preserved in the [manifest](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/manifest.json). This is a **modern database snapshot**, a dated contemporary reference.

| Recorded count | Result |
|---|---:|
| Nodes | 4,392 |
| Ways | 816 |
| Relations | 2 |
| Highway-tagged ways | 221 |
| Named highway ways | 63 |
| Building-tagged ways | 539 |

Counts are OSM object counts, not necessarily unique physical roads/buildings or a complete inventory. Relations can group multiple ways; one street can have several segments. All referenced way nodes and relation members resolve within the downloaded file. XML parsing, actual-loop closure and gully endpoints were checked locally. No heights, building ages, road widths, walkability or cultural accuracy were inferred from absent tags.

The first full request returned HTTP 502 and a bounded alternate-mirror attempt timed out; neither was accepted as data. A subsequent primary-endpoint request succeeded. Those attempts are in the manifest. No fabrication, Google extraction, imagery download, live tile dependency or change to OSM was involved. Overpass is a read-oriented query route documented by its operator. [Overpass API manual](https://dev.overpass-api.de/overpass-doc/en/)

Convenience files include [modern road GeoJSON](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/roads-modern.geojson), [SVG preview](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/reference-preview.svg) and the original [historical uncertainty ledger](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/historical-change-ledger.csv). The last file and historical-setting strings inside the hashed package are preserved acquisition history, not the active production workflow. Keep package bytes/checksums unchanged; record present-day checks and gameplay edits outside that immutable source package.

## Licensing and commercial use

OSM database reuse, including commercial use, is allowed under **ODbL 1.0**, with attribution and applicable database-sharing obligations. The official license text is saved as [ODbL-1.0.txt](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/ODbL-1.0.txt). Keep the copyright/license notices and the accompanying [attribution note](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/ATTRIBUTION.md) with the extract. [OSM copyright page](https://www.openstreetmap.org/copyright), [ODbL legal code](https://opendatacommons.org/licenses/odbl/1-0/)

Treat a publicly distributed modified OSM road/footprint database as an ODbL Derivative Database unless the actual processing justifies a different classification. ODbL sections 4.4 and 4.6 address share-alike and access to a derivative database or alteration file, including when a Produced Work from it is publicly used. Game art/code are not automatically the same object as that geographic database; a rendered/game presentation does not erase the underlying data obligations. Keep source, transformations and release data offer traceable. Separating an authored historical layer is useful provenance, not a way to remove obligations from OSM-derived edits. [ODbL, sections 4.4–4.6](https://opendatacommons.org/licenses/odbl/1-0/), [OSMF Produced Work guideline](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline)

Use **“Map data from OpenStreetMap contributors”** with the copyright/license link in this reference package. For a shipped game, plan legible attribution in a suitable startup/game/menu/credits location plus accessible detailed data licensing. The exact display and data offer must match the released use. This data license does not grant reuse rights for Google, street-view, parish or heritage-report images. [OSMF game attribution guidance](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Computer_games_and_simulations)

## Present-day reference adoption and remaining gates

Keep four distinct records: immutable 20 November modern source; traceable OSM-derived gameplay data; dated current locality/appearance/access checks; original art/gameplay additions. The earlier 1990-1995 reconstruction plan is superseded by the 22 November present-day-only instruction. Historical facts and the unchanged package ledger remain provenance, not active-era requirements.

1. **Current anchors:** retain St Peter's and the Ranwar village-house streetscape. Older conservation records explain identity and architecture; compare current facade, roof, services, context and access before production matching.
2. **Current corroboration needed:** verify road widths/alignment, one-way/vehicle permissions, signage, paving/drainage, occupants, redevelopment and shoreline/reclamation context where actually visible. The OSM database timestamp is **2026-11-20T01:19:21Z**; it is a dated current baseline, not proof every mapped tag was freshly surveyed. OSM absence is not evidence of physical absence.
3. **Building-state uncertainty:** older references, including a villa replaced in the 1990s, explain changes rather than require historical reconstruction. Check the actual current parcel/form and source rights. St Andrew's restoration is part of contemporary reference matching if that contextual landmark is used.
4. **Local module choice:** prioritize current Ranwar examples with raised plinths, tiled roofs, verandahs/balconies and narrow exterior stairs where documented. Keep BDD/gallery and baithi/courtyard assemblies as typology studies until an actual current local match is established; present-day scope does not relocate Worli or Chembur into Ranwar.
5. **Implementation still ahead:** convert a bounded subset into a playable road graph/blockout, author lane/sidewalk/vehicle clearances, demonstrate collision/navigation and test the loop/shortcut on actual Windows/Android devices. Acquisition and layout research alone do not finish the Phase 0 technical gate or start the accepted neighborhood phase.

The later GitHub/Windows prototype path is recorded in the phase tracker and playtest guide. This acquisition report does not itself establish engine, traffic, historical or real-device acceptance. The source data, query, license and checksums remain unchanged by the 22 November scope update.
