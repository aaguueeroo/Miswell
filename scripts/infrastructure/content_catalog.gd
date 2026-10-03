class_name ContentCatalog
extends RefCounted

const CLOCK_SETTINGS_PATH: String = "res://data/time/game_clock_settings.tres"
const LOCATION_PATHS: Dictionary = {
	&"home": "res://data/locations/home.tres",
	&"school": "res://data/locations/school.tres",
	&"supermarket": "res://data/locations/supermarket.tres",
	&"gym": "res://data/locations/gym.tres"
}
const ENCOUNTER_PATHS: Dictionary = {
	&"family_good_news": "res://data/encounters/family_good_news.tres"
}
const EVENT_PATHS: Dictionary = {
	&"family_good_news": "res://data/story/events/family_good_news.tres",
	&"family_follow_up": "res://data/story/events/family_follow_up.tres"
}

func get_clock_settings() -> GameClockSettings:
	return load(CLOCK_SETTINGS_PATH) as GameClockSettings

func get_encounter(encounter_id: StringName) -> EncounterDefinition:
	var path: String = str(ENCOUNTER_PATHS.get(encounter_id, ""))
	return load(path) as EncounterDefinition if not path.is_empty() else null

func get_event(event_id: StringName) -> StoryEventDefinition:
	var path: String = str(EVENT_PATHS.get(event_id, ""))
	return load(path) as StoryEventDefinition if not path.is_empty() else null

func get_time_triggered_events() -> Array[StoryEventDefinition]:
	var result: Array[StoryEventDefinition] = []
	for event_id in EVENT_PATHS:
		var event := get_event(event_id)
		if event != null and event.start_policy == StoryEventDefinition.StartPolicy.TIME_TRIGGERED:
			result.append(event)
	return result

func get_location(location_id: StringName) -> LocationDefinition:
	var path: String = str(LOCATION_PATHS.get(location_id, ""))
	if path.is_empty():
		return null
	return load(path) as LocationDefinition
