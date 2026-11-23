extends RefCounted
## WGS84 longitude/latitude. Provenance and modeled geography are in docs/BANDRA_LANDMARKS.md.

const WARODA_CROSS := Vector2(72.8273489, 19.0541226)
const SEA_LINK_NORTH_SPAN := Vector2(72.81725, 19.03648)
const SITES: Array[Dictionary] = [
	{"id": &"waroda_cross", "label": "Waroda Road Wayside Cross", "kind": "Street landmark", "coordinate": WARODA_CROSS, "playable": true},
	{"id": &"st_peters_church", "label": "St Peter's Church", "kind": "Heritage church", "coordinate": Vector2(72.8295061, 19.0546907), "playable": true},
	{"id": &"meena", "label": "Meena on Hill Road", "kind": "Hill Road building", "coordinate": Vector2(72.8279466, 19.0550586), "playable": true},
	{"id": &"mount_mary", "label": "Mount Mary Basilica", "kind": "Hilltop landmark", "coordinate": Vector2(72.8226511, 19.0465505), "playable": false},
	{"id": &"bandra_fort", "label": "Bandra Fort", "kind": "Coastal fort", "coordinate": Vector2(72.8186080, 19.0420614), "playable": false},
	{"id": &"sea_link", "label": "Bandra–Worli Sea Link", "kind": "Cable-stayed bridge", "coordinate": SEA_LINK_NORTH_SPAN, "playable": false},
]

# Selected nodes of OSM ways 56683663, 289540744 and 289540743, ordered north to south.
const SEA_LINK_ROUTE: Array[Vector2] = [
	Vector2(72.8233789, 19.0426790), Vector2(72.8211450, 19.0417259),
	Vector2(72.8204113, 19.0413635), Vector2(72.8198199, 19.0410153),
	Vector2(72.8191865, 19.0404663), Vector2(72.8187236, 19.0399465),
	Vector2(72.8183317, 19.0394008), Vector2(72.8179812, 19.0386693),
	Vector2(72.8177452, 19.0379010), Vector2(72.8159506, 19.0311530),
	Vector2(72.8142368, 19.0245983), Vector2(72.8125753, 19.0180655),
	Vector2(72.8123322, 19.0171197), Vector2(72.8123356, 19.0165979),
	Vector2(72.8122262, 19.0160877), Vector2(72.8121963, 19.0154413),
	Vector2(72.8122805, 19.0149617), Vector2(72.8124983, 19.0144685),
	Vector2(72.8127786, 19.0139998), Vector2(72.8132312, 19.0137229),
	Vector2(72.8138637, 19.0134559), Vector2(72.8166412, 19.0126931),
]
