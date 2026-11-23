# Bandra district services

Omkar starts by the St Peter's Church BEST stop on Hill Road in Ranwar, Bandra West. The shelter, bench and lettering use original game geometry and materials. The stop's geographic pin comes from the ChaloBEST stop inventory, and the shelter sits near that pin on the church side of the road. The pavement and shelter placement follow the game's Hill Road geometry. [ChaloBEST stop 922](https://github.com/chalobest/ChaloBEST/blob/master/chaloBEST/gtfs/gtfs_mumbai_bus/stops.txt#L3426), [BEST A-214 stop sequence](https://www.accountable.social/mumbai/bus/routes/a-214), [St Peter's parish address](https://stpetersbandra.com/contact-us/)

The north-up district map uses projected site coordinates and shows the playable Ranwar street loop for orientation. The church stop is accessible in the current world. The other seven pins show surrounding facilities for orientation and future district expansion. Numbered callouts can shift to keep them readable. The dots mark the site coordinates.

| Facility | Site reference | Basis for the name and location |
| --- | --- | --- |
| St Peter's Church BEST stop | 19.05491° N, 72.82935° E | [ChaloBEST stop 922](https://github.com/chalobest/ChaloBEST/blob/master/chaloBEST/gtfs/gtfs_mumbai_bus/stops.txt#L3426), checked against the [current A-214 route listing](https://www.accountable.social/mumbai/bus/routes/a-214) |
| Holy Family Hospital | 19.05562° N, 72.82715° E | Approximate [OSM campus centre](https://www.openstreetmap.org/way/31213763) from the saved extract and [hospital address](https://holyfamilyhospital.in/) on St Andrews Road |
| Bandra Police Station | 19.05591° N, 72.83574° E | [Mumbai Suburban district police directory](https://mumbaisuburban.gov.in/en/police/) and [OSM building](https://www.openstreetmap.org/way/1334676842) |
| Bandra Fire Brigade | 19.05044° N, 72.83756° E | [Municipal fire brigade directory](https://portal.mcgm.gov.in/irj/go/km/docs/documents/HomePage%20Data/FAQ/SANKALAN%20FAQ%20-ENGLISH%20COPY-%20MCGM%20MUMBAI.pdf) and [OSM site](https://www.openstreetmap.org/way/434887905) |
| Bandra Bus Station (W) | 19.05402° N, 72.83973° E | BEST terminal on the [A-214 route](https://www.accountable.social/mumbai/bus/routes/a-214) and [OSM terminal site](https://www.openstreetmap.org/way/434887902) |
| Bandra Railway Station | 19.05498° N, 72.84022° E | Western Railway's Bandra suburban station, code BA, and [OSM station point](https://www.openstreetmap.org/node/2630075000). [Western Railway station list](https://wr.indianrailways.gov.in/wr/notice/1747138972095_EOI%20consulatancy%20signed%2013-05-25%20%28all%20pages%20signed%29.pdf) |
| Bandra Terminus | 19.06270° N, 72.84130° E | Western Railway's intercity terminus, code BDTS, and [OSM railway site](https://www.openstreetmap.org/way/107303404). [Western Railway station list](https://wr.indianrailways.gov.in/wr/notice/1747138972095_EOI%20consulatancy%20signed%2013-05-25%20%28all%20pages%20signed%29.pdf) |
| Bandra Colony Metro | 19.06996° N, 72.84936° E | Mumbai Metro Line 3's [Gazette corridor map](https://corporate-old.mmrcl.com/sites/default/files/20240919%20Gazette%20of%20India%20%28Published%29_1.pdf) and [OSM station point](https://www.openstreetmap.org/node/12074909129) |

The production coordinate list is available in [`bandra_facilities.gd`](../prototype/world/bandra_facilities.gd). Points indicate approximate geographic sites and may use a campus centre. The ground mesh, walking routes and driving loop cover Ranwar only. Transit timetables, services inside the mapped facilities and the streets connecting them require later development.

Map data © OpenStreetMap contributors. The OSM-derived coordinates and the route data are available under the [Open Database License 1.0](https://opendatacommons.org/licenses/odbl/1-0/). [OSM attribution](https://www.openstreetmap.org/copyright), [Ranwar route extract and processing](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/README.md)
