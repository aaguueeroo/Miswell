class_name EncounterChoiceDefinition
extends Resource

@export var choice_id: StringName = &""
@export var label: String = ""
@export_multiline var description: String = ""
@export_multiline var result_message: String = ""
@export var required_effect_id: StringName = &""
@export var conditions: Array[Resource] = []
@export var outcome_id: StringName = &""

static func from_document(data: Dictionary) -> EncounterChoiceDefinition:
	var result := EncounterChoiceDefinition.new()
	result.choice_id = StringName(str(data.get("id", "")))
	result.label = str(data.get("label", ""))
	result.description = str(data.get("description", ""))
	result.result_message = str(data.get("result_message", ""))
	result.required_effect_id = StringName(str(data.get("required_effect_id", "")))
	result.outcome_id = StringName(str(data.get("outcome_id", "")))
	if result.choice_id == &"" or result.label.is_empty() or result.outcome_id == &"":
		return null
	var condition_documents: Variant = data.get("conditions", [])
	if not condition_documents is Array:
		return null
	for condition_data in condition_documents:
		if not condition_data is Dictionary:
			return null
		var condition := StoryConditionDefinition.from_document(condition_data)
		if condition == null:
			return null
		result.conditions.append(condition)
	return result
