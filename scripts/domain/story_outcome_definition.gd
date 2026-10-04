class_name StoryOutcomeDefinition
extends Resource

@export var outcome_id: StringName = &""
@export var title: String = ""
@export_multiline var result_message: String = ""
@export var conditions: Array[Resource] = []
@export var effects: Array[Resource] = []

static func from_document(data: Dictionary) -> StoryOutcomeDefinition:
	var result := StoryOutcomeDefinition.new()
	result.outcome_id = StringName(str(data.get("id", "")))
	result.title = str(data.get("title", ""))
	result.result_message = str(data.get("result_message", ""))
	if result.outcome_id == &"" or result.title.is_empty():
		return null
	var condition_documents: Variant = data.get("conditions", [])
	var effect_documents: Variant = data.get("effects", [])
	if not condition_documents is Array or not effect_documents is Array:
		return null
	for condition_data in condition_documents:
		if not condition_data is Dictionary:
			return null
		var condition := StoryConditionDefinition.from_document(condition_data)
		if condition == null:
			return null
		result.conditions.append(condition)
	for effect_data in effect_documents:
		if not effect_data is Dictionary:
			return null
		var effect := StoryEffectDefinition.from_document(effect_data)
		if effect == null:
			return null
		result.effects.append(effect)
	return result
