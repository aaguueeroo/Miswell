class_name ContentCatalog
extends RefCounted

const FAMILY_ENCOUNTER_PATH: String = "res://data/dialogue/family_encounter.tres"
const LOCATION_PATHS: Dictionary = {
	&"home": "res://data/locations/home.tres",
	&"school": "res://data/locations/school.tres",
	&"supermarket": "res://data/locations/supermarket.tres",
	&"gym": "res://data/locations/gym.tres"
}

func get_family_encounter() -> DialogueDefinition:
	return load(FAMILY_ENCOUNTER_PATH) as DialogueDefinition

func get_location(location_id: StringName) -> LocationDefinition:
	var path: String = str(LOCATION_PATHS.get(location_id, ""))
	if path.is_empty():
		return null
	return load(path) as LocationDefinition
