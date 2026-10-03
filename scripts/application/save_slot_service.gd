class_name SaveSlotService
extends RefCounted

const DEFAULT_SLOT_COUNT := 3

var _repository: SaveRepository
var _migrator: SaveMigrator
var _codec: GameSaveCodec
var _slot_ids: Array[StringName] = []

func _init(repository: SaveRepository = null, configured_slot_count: int = DEFAULT_SLOT_COUNT) -> void:
	_repository = repository if repository != null else FileSaveRepository.new()
	_migrator = SaveMigrator.new()
	_codec = GameSaveCodec.new()
	for index in range(maxi(configured_slot_count, 1)):
		_slot_ids.append(StringName("slot_%02d" % (index + 1)))

func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for index in range(_slot_ids.size()):
		var slot_id := _slot_ids[index]
		var read_result := _repository.read_slot(slot_id)
		var summary := {
			"slot_id": slot_id,
			"display_name": "Slot %d" % (index + 1),
			"occupied": bool(read_result.get("exists", false)),
			"valid": false,
			"day_number": 0,
			"minute_of_day": 0,
			"last_saved_at": "",
			"error": str(read_result.get("error", ""))
		}
		if not read_result.get("ok", false):
			slots.append(summary)
			continue
		if not read_result.get("exists", false):
			summary["valid"] = true
			slots.append(summary)
			continue
		var migration := _migrator.migrate_record(read_result.get("data", {}))
		if not migration.get("ok", false):
			summary["error"] = str(migration.get("error", "This save cannot be loaded."))
			slots.append(summary)
			continue
		var record: Dictionary = migration.data
		var snapshot: Variant = record.get("session_snapshot", null)
		var world_context: Variant = record.get("world_context", null)
		if not snapshot is Dictionary or not world_context is Dictionary:
			summary["error"] = "This save is incomplete."
			slots.append(summary)
			continue
		var metadata: Variant = record.get("metadata", {})
		if not metadata is Dictionary:
			summary["error"] = "This save has invalid metadata."
			slots.append(summary)
			continue
		var state_data: Variant = snapshot.get("state", null)
		if not state_data is Dictionary:
			summary["error"] = "This save has no playthrough state."
			slots.append(summary)
			continue
		summary["valid"] = true
		summary["day_number"] = int(state_data.get("day_number", 0))
		summary["minute_of_day"] = int(state_data.get("minute_of_day", 0))
		summary["last_saved_at"] = str(metadata.get("last_saved_at", ""))
		slots.append(summary)
	return slots

func save_slot(slot_id: StringName, session: GameSession, world_context: Dictionary, confirm_overwrite: bool = false) -> Dictionary:
	if not _slot_ids.has(slot_id) or session == null:
		return {"ok": false, "error": "That save slot is unavailable."}
	var existing := _repository.read_slot(slot_id)
	if not existing.get("ok", false) and not existing.get("exists", false):
		return {"ok": false, "error": str(existing.get("error", "Could not access this slot."))}
	if existing.get("exists", false) and not confirm_overwrite:
		return {"ok": false, "requires_overwrite_confirmation": true}
	var player_position: Variant = world_context.get("player_position", null)
	if not player_position is Vector2 or not is_finite(player_position.x) or not is_finite(player_position.y):
		return {"ok": false, "error": "The current world position cannot be saved."}
	var now := Time.get_datetime_string_from_system(true, true)
	var previous_metadata: Dictionary = {}
	if existing.get("ok", false) and existing.get("exists", false):
		var old_record: Variant = existing.get("data", {})
		if old_record is Dictionary:
			var old_metadata: Variant = old_record.get("metadata", {})
			if old_metadata is Dictionary:
				previous_metadata = old_metadata
	var metadata := {
		"slot_id": String(slot_id),
		"display_name": "Slot %d" % (_slot_ids.find(slot_id) + 1),
		"created_at": str(previous_metadata.get("created_at", now)),
		"last_saved_at": now
	}
	var record := {
		"schema_version": SaveMigrator.CURRENT_SCHEMA_VERSION,
		"metadata": metadata,
		"session_snapshot": _codec.encode_session(session),
		"world_context": {
			"scene_id": str(world_context.get("scene_id", "village")),
			"player_position": [player_position.x, player_position.y]
		}
	}
	var write_result := _repository.write_slot(slot_id, record)
	if not write_result.get("ok", false):
		return write_result
	return {"ok": true, "slot_id": slot_id, "metadata": metadata}

func load_slot(slot_id: StringName) -> Dictionary:
	if not _slot_ids.has(slot_id):
		return {"ok": false, "error": "That save slot is unavailable."}
	var read_result := _repository.read_slot(slot_id)
	if not read_result.get("ok", false):
		return {"ok": false, "error": str(read_result.get("error", "Could not read this save."))}
	if not read_result.get("exists", false):
		return {"ok": false, "error": "This slot is empty."}
	var migration := _migrator.migrate_record(read_result.get("data", {}))
	if not migration.get("ok", false):
		return {"ok": false, "error": str(migration.get("error", "This save cannot be loaded."))}
	var record: Dictionary = migration.data
	var snapshot: Variant = record.get("session_snapshot", null)
	var world_context: Variant = record.get("world_context", null)
	if not snapshot is Dictionary or not world_context is Dictionary:
		return {"ok": false, "error": "This save is incomplete."}
	var restored_session := _codec.decode_session(snapshot)
	if restored_session == null:
		return {"ok": false, "error": "This save contains invalid playthrough data."}
	var position_data: Variant = world_context.get("player_position", null)
	if not position_data is Array or position_data.size() != 2:
		return {"ok": false, "error": "This save has no valid player position."}
	var restored_position := Vector2(float(position_data[0]), float(position_data[1]))
	if not is_finite(restored_position.x) or not is_finite(restored_position.y):
		return {"ok": false, "error": "This save has no valid player position."}
	return {
		"ok": true,
		"session": restored_session,
		"scene_id": StringName(str(world_context.get("scene_id", "village"))),
		"player_position": restored_position
	}
