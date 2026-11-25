extends RefCounted

const DEFAULT := {"gender": "man", "hair": "crop", "outfit": "traditional"}
const HAIR := [
	{"id": "crop", "label": "Textured crop"},
	{"id": "side_part", "label": "Classic side part"},
	{"id": "swept", "label": "Side-swept waves"},
	{"id": "bun", "label": "Low bun"},
	{"id": "braid", "label": "Low braid"},
	{"id": "bob", "label": "Layered bob"},
]
const MAN_OUTFITS := [
	{"id": "traditional", "label": "Sadara & dhotar"},
	{"id": "casual", "label": "Shirt & chinos"},
	{"id": "kurta", "label": "Kurta & trousers"},
]
const WOMAN_OUTFITS := [
	{"id": "traditional", "label": "Kurta & dupatta"},
	{"id": "casual", "label": "Everyday top & trousers"},
	{"id": "kurta", "label": "Kurta & straight trousers"},
]


static func hair_choices(_gender: String) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	choices.assign(HAIR.duplicate(true))
	return choices


static func outfit_choices(gender: String) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	choices.assign((WOMAN_OUTFITS if gender == "woman" else MAN_OUTFITS).duplicate(true))
	return choices


static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return DEFAULT.duplicate()
	var gender := "woman" if value.get("gender") == "woman" else "man"
	return {
		"gender": gender,
		"hair": _known_id(value.get("hair"), HAIR, "crop"),
		"outfit": _known_id(value.get("outfit"), WOMAN_OUTFITS if gender == "woman" else MAN_OUTFITS, "traditional"),
	}


static func is_valid(value: Variant) -> bool:
	return value is Dictionary and value == normalize(value)


static func character_name(options: Dictionary) -> String:
	return "Ira Shirodkar" if options.get("gender") == "woman" else "Omkar Shirodkar"


static func _known_id(value: Variant, choices: Array, fallback: String) -> String:
	if value is String:
		for choice: Dictionary in choices:
			if value == choice["id"]:
				return value
	return fallback
