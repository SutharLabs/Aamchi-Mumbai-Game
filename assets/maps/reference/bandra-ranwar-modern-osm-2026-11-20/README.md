# Ranwar / Bandra West offline OSM reference

Acquired 20 November 2026. **Modern reference data, not a 1990–1995 historical map or an accepted playable scene.** The source selection box is about 0.46 km²; the proposed first greybox core is about 0.20 km². Whole OSM objects/dependencies extend beyond the selection box. No coordinate compression has been applied.

Read the [area/map research](../../../../research/BANDRA_REFERENCE_AREA_AND_MAP.md) for the selection, route, sources and historical limitations. The source's database timestamp and acquisition times are in [manifest.json](manifest.json).

| File | Purpose |
|---|---|
| [bandra-ranwar-modern.osm](bandra-ranwar-modern.osm) | Unmodified actual Overpass OSM XML response; 572,456 bytes |
| [source-query.overpassql](source-query.overpassql) | Exact successful bounded query |
| [manifest.json](manifest.json) | Endpoint, access times, query, response details, counts, validation, limitations and file hashes |
| [ODbL-1.0.txt](ODbL-1.0.txt) | Official complete license text downloaded from Open Data Commons |
| [ATTRIBUTION.md](ATTRIBUTION.md) | Attribution, commercial/database-use conditions and source links |
| [roads-modern.geojson](roads-modern.geojson) | 221 highway ways with original IDs/tags and full, unclipped coordinates |
| [candidate-layout.json](candidate-layout.json) | Source crop versus proposed core, actual connected loop/footway, WGS84 anchors and design assumptions |
| [reference-preview.svg](reference-preview.svg) | Offline vector preview of modern buildings/roads, proposed core, geometric loop and footway |
| [historical-change-ledger.csv](historical-change-ledger.csv) | Initial 1990–1995 evidence/uncertainty ledger; no historical geometry asserted |
| [checksums.sha256](checksums.sha256) | SHA-256 for every other file in this directory |

The approximately **1,186.7 m loop** is an undirected connectivity result. Traffic direction, period access, road widths and driving clearance remain unverified. The approximately **70.5 m Nagrana Lane** is currently tagged footway and is an on-foot candidate. See [candidate-layout.json](candidate-layout.json) before using either.

Map data from **OpenStreetMap contributors**, under **ODbL 1.0**. See [OSM copyright](https://www.openstreetmap.org/copyright), [local license text](ODbL-1.0.txt) and [attribution conditions](ATTRIBUTION.md). Keep them with raw/derived data. This package contains no aerial/street-view imagery and provides no blanket image-reuse rights.

The query selects current highways, buildings and relevant place/land-use/amenity/context features, then includes dependencies. Raw IDs and geometry are preserved. GeoJSON, layout and preview were generated locally from that response. No Google data, fabricated streets, remote-model assets, live tile service or engine project is involved.
