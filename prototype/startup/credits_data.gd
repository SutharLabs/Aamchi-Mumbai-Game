extends RefCounted

const SECTIONS: Array[Dictionary] = [
	{
		"title": "Aamchi Mumbai Game",
		"body": "A SutharLabs playtest set in a stylized, present-day Ranwar, Bandra West, Mumbai.",
		"links": [
			{"label": "Project repository", "url": "https://github.com/SutharLabs/Aamchi-Mumbai-Game"},
		],
	},
	{
		"title": "Map data",
		"body": "© OpenStreetMap contributors. OpenStreetMap data and the adapted Ranwar route data are available under the Open Database License 1.0. Download the source map extract and derived route data below.",
		"links": [
			{"label": "OpenStreetMap copyright", "url": "https://www.openstreetmap.org/copyright"},
			{"label": "ODbL 1.0", "url": "https://opendatacommons.org/licenses/odbl/1-0/"},
			{"label": "Source extract and preprocessing", "url": "https://github.com/SutharLabs/Aamchi-Mumbai-Game/tree/main/assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20"},
			{"label": "Derived route layout", "url": "https://github.com/SutharLabs/Aamchi-Mumbai-Game/blob/main/prototype/world/layout.json"},
			{"label": "Bandra district facility sources", "url": "https://github.com/SutharLabs/Aamchi-Mumbai-Game/blob/main/docs/BANDRA_FACILITIES.md"},
		],
	},
	{
		"title": "Chapel Road photo reference",
		"body": "Bandra old house.jpg by Chandan Nandrajog, 28 October 2006, CC BY 2.0. Aamchi Mumbai Game adapted the gallery and stair forms into a simplified 3D streetscape study.",
		"links": [
			{"label": "Chapel Road photograph", "url": "https://commons.wikimedia.org/wiki/File:Bandra_old_house.jpg"},
			{"label": "CC BY 2.0", "url": "https://creativecommons.org/licenses/by/2.0/"},
		],
	},
	{
		"title": "Motion capture",
		"body": "The 100STYLE Dataset by Ian Mason, Sebastian Starke and Taku Komura (2022), licensed under CC BY 4.0. Aamchi Mumbai Game trimmed, normalized, resampled and retargeted clips for idle, walking, jogging and jumping.",
		"links": [
			{"label": "100STYLE dataset", "url": "https://www.ianxmason.com/100style/"},
			{"label": "Dataset archive", "url": "https://doi.org/10.5281/zenodo.8127870"},
			{"label": "CC BY 4.0", "url": "https://creativecommons.org/licenses/by/4.0/"},
		],
	},
	{
		"title": "Motion capture · impact falls",
		"body": "The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217. Aamchi Mumbai Game cropped and retargeted Subject 90 trials 16 and 17. The publisher permits commercial product use and restricts direct data resale.",
		"links": [
			{"label": "CMU Motion Capture Database and terms", "url": "https://mocap.cs.cmu.edu/"},
			{"label": "Subject 90 recordings", "url": "https://mocap.cs.cmu.edu/search.php?subjectnumber=90"},
		],
	},
	{
		"title": "Street kiosk",
		"body": "Indian street shop by nayan pachori, CC BY 4.0. Aamchi Mumbai Game adapted its scale, placement and collision for a fictional Ranwar kiosk.",
		"links": [
			{"label": "Original Sketchfab model", "url": "https://sketchfab.com/3d-models/indian-street-shop-a7476a895cb841709ccbd5d9d8b96f36"},
			{"label": "CC BY 4.0", "url": "https://creativecommons.org/licenses/by/4.0/"},
		],
	},
	{
		"title": "Game engine",
		"body": "Godot Engine, licensed under MIT. The Windows package includes Godot-NOTICES.txt with the engine license and bundled third-party notices.",
		"links": [
			{"label": "Godot Engine license", "url": "https://godotengine.org/license/"},
		],
	},
	{
		"title": "Devanagari type",
		"body": "Noto Sans Devanagari. Copyright 2022 The Noto Project Authors. Licensed under the SIL Open Font License 1.1.",
		"links": [
			{"label": "Noto Devanagari project", "url": "https://github.com/notofonts/devanagari"},
			{"label": "SIL Open Font License 1.1", "url": "https://github.com/notofonts/devanagari/blob/main/OFL.txt"},
		],
	},
]
