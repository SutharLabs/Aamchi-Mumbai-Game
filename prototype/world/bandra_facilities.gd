extends RefCounted
## District site references in WGS84 longitude/latitude. See docs/BANDRA_FACILITIES.md.

# ChaloBEST stop 922. Preserve the stop reference separately from its authored curb geometry.
const ARRIVAL := Vector2(72.8293491518, 19.0549136361)
const SITES: Array[Dictionary] = [
	{"id": &"st_peters_stop", "label": "St Peter's Church", "kind": "Bus stop", "coordinate": ARRIVAL, "playable": true},
	{"id": &"holy_family_hospital", "label": "Holy Family Hospital", "kind": "Hospital", "coordinate": Vector2(72.82715, 19.05562), "playable": false},
	{"id": &"bandra_police", "label": "Bandra Police Station", "kind": "Police", "coordinate": Vector2(72.83574, 19.05591), "playable": false},
	{"id": &"bandra_fire", "label": "Bandra Fire Brigade", "kind": "Fire station", "coordinate": Vector2(72.83756, 19.05044), "playable": false},
	{"id": &"bandra_bus_west", "label": "Bandra Bus Station (W)", "kind": "Bus station", "coordinate": Vector2(72.83973, 19.05402), "playable": false},
	{"id": &"bandra_suburban", "label": "Bandra Railway Station", "kind": "Suburban rail", "coordinate": Vector2(72.84022, 19.05498), "playable": false},
	{"id": &"bandra_terminus", "label": "Bandra Terminus", "kind": "Intercity rail", "coordinate": Vector2(72.84130, 19.06270), "playable": false},
	{"id": &"bandra_colony_metro", "label": "Bandra Colony Metro", "kind": "Metro", "coordinate": Vector2(72.84936, 19.06996), "playable": false},
]
