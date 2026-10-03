class_name GameState
extends RefCounted

var day_number: int = 1
var anxiety: float = 22.0
var anxiety_effect_id: StringName = &""
var anxiety_effect_seconds: float = 0.0
var family_trust: int = 0
var family_encounter_seen: bool = false
var family_outcome_chosen: bool = false
var family_opportunity_preserved: bool = true
var last_consequence_text: String = "There is still time to join the family moment."
var visited_activity_ids: Array[StringName] = []
var day_schedule: Array[Dictionary] = []
var previous_day_schedule: Array[Dictionary] = []
var location_result_text: Dictionary = {}

