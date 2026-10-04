class_name ContentPackLoader
extends RefCounted

const BUILTIN_PACKS_ROOT := "res://data/content_packs"
const USER_MODS_ROOT := "user://mods"

func load_json_documents(content_type: String) -> Array[Dictionary]:
	var documents: Array[Dictionary] = []
	_append_from_pack_root(BUILTIN_PACKS_ROOT, content_type, documents)
	_append_from_pack_root(USER_MODS_ROOT, content_type, documents)
	return documents

func _append_from_pack_root(root: String, content_type: String, documents: Array[Dictionary]) -> void:
	var root_directory := DirAccess.open(root)
	if root_directory == null:
		return
	var pack_directories := root_directory.get_directories()
	pack_directories.sort()
	for pack_directory in pack_directories:
		var pack_root := root.path_join(pack_directory)
		var manifest_path := pack_root.path_join("manifest.json")
		var manifest := _read_dictionary(manifest_path)
		var pack_id := str(manifest.get("id", ""))
		if pack_id.is_empty() or pack_id.contains(":"):
			push_warning("Ignoring content pack with an invalid ID: %s" % manifest_path)
			continue
		if int(manifest.get("format_version", 0)) != 1:
			push_warning("Ignoring content pack with an unsupported format version: %s" % manifest_path)
			continue
		var content_directory_path := pack_root.path_join("content").path_join(content_type)
		var content_directory := DirAccess.open(content_directory_path)
		if content_directory == null:
			continue
		var file_names := content_directory.get_files()
		file_names.sort()
		for file_name in file_names:
			if not file_name.to_lower().ends_with(".json"):
				continue
			var source_path := content_directory_path.path_join(file_name)
			var data := _read_dictionary(source_path)
			if data.is_empty():
				continue
			var document_id := str(data.get("id", ""))
			if not document_id.begins_with(pack_id + ":"):
				push_warning("Ignoring %s: its ID must be namespaced by pack '%s'." % [source_path, pack_id])
				continue
			documents.append({
				"id": StringName(document_id),
				"pack_id": StringName(pack_id),
				"source_path": source_path,
				"data": data
			})

func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("Ignoring invalid JSON content file: %s" % path)
		return {}
	return parsed
