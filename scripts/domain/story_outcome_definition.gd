class_name StoryOutcomeDefinition
extends Resource

@export var outcome_id: StringName = &""
@export var title: String = ""
@export_multiline var result_message: String = ""
@export var conditions: Array[Resource] = []
@export var effects: Array[Resource] = []
