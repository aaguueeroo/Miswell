class_name EncounterDefinition
extends Resource

@export var encounter_id: StringName = &""
@export var title: String = ""
@export_multiline var prompt: String = ""
@export var player_name: String = "You"
@export var opponent_name: String = ""
@export var choices: Array[Resource] = []

static func from_document(data: Dictionary) -> EncounterDefinition:
	var result := EncounterDefinition.new()
	result.encounter_id = StringName(str(data.get("id", "")))
	result.title = str(data.get("title", ""))
	result.prompt = str(data.get("prompt", ""))
	result.player_name = str(data.get("player_name", "You"))
	result.opponent_name = str(data.get("opponent_name", ""))
	if result.encounter_id == &"" or result.title.is_empty() or result.prompt.is_empty():
		return null
	var choice_documents: Variant = data.get("choices", [])
	if not choice_documents is Array or choice_documents.is_empty():
		return null
	for choice_data in choice_documents:
		if not choice_data is Dictionary:
			return null
		var choice := EncounterChoiceDefinition.from_document(choice_data)
		if choice == null:
			return null
		result.choices.append(choice)
	return result
