class_name FileSaveRepository
extends SaveRepository

const SAVE_DIRECTORY := "user://saves"

func read_slot(slot_id: StringName) -> Dictionary:
	var path := _path_for(slot_id)
	if path.is_empty():
		return {"ok": false, "exists": false, "error": "Invalid save slot ID."}
	var backup_path := path + ".bak"
	if not FileAccess.file_exists(path) and FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))
	if not FileAccess.file_exists(path):
		return {"ok": true, "exists": false, "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "exists": true, "error": "Could not read the save file."}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return {"ok": false, "exists": true, "error": "This save file is damaged."}
	return {"ok": true, "exists": true, "data": parser.data}

func write_slot(slot_id: StringName, data: Dictionary) -> Dictionary:
	var target_path := _path_for(slot_id)
	if target_path.is_empty():
		return {"ok": false, "error": "Invalid save slot ID."}
	var absolute_directory := ProjectSettings.globalize_path(SAVE_DIRECTORY)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		return {"ok": false, "error": "Could not create the save directory."}
	var temporary_path := target_path + ".tmp"
	var backup_path := target_path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not write the save file."}
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	# Validate the temporary JSON before it can replace an existing slot.
	if FileAccess.file_exists(temporary_path):
		var validation_file := FileAccess.open(temporary_path, FileAccess.READ)
		if validation_file == null:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
			return {"ok": false, "error": "The new save could not be validated."}
		var parser := JSON.new()
		var parse_error := parser.parse(validation_file.get_as_text())
		validation_file.close()
		if parse_error != OK or not parser.data is Dictionary:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
			return {"ok": false, "error": "The new save could not be validated."}
	else:
		return {"ok": false, "error": "The new save file is missing."}
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	var had_previous_save := FileAccess.file_exists(target_path)
	if had_previous_save:
		var backup_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(target_path),
			ProjectSettings.globalize_path(backup_path)
		)
		if backup_error != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
			return {"ok": false, "error": "The existing save could not be protected."}
	var commit_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(target_path)
	)
	if commit_error != OK:
		if had_previous_save:
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(target_path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
		return {"ok": false, "error": "The save could not be committed."}
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	return {"ok": true}

func _path_for(slot_id: StringName) -> String:
	var value := String(slot_id)
	if not value.begins_with("slot_") or value.length() <= 5 or value.contains("/") or value.contains("\\"):
		return ""
	return SAVE_DIRECTORY + "/" + value + ".json"
