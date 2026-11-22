extends RefCounted
## Saves the current Ranwar mission checkpoint separately for each local profile.

const Delivery := preload("res://mission/ranwar_delivery.gd")
const VERSION := 1
const MAX_FILE_BYTES := 2048
const MAX_PROFILE_ID := 2147483647
const RECEIPT_SUFFIX := ".receipt"

var _profile_id: String
var _path := ""


func _init(profile_id: String, directory: String = "user://") -> void:
	_profile_id = profile_id
	if not _valid_profile_id(profile_id):
		return
	# Alternate directories keep smoke fixtures away from actual profile saves.
	var folder := directory.get_file()
	if directory != "user://" and (directory != "user://" + folder or not folder.is_valid_filename() or folder.begins_with(".")):
		return
	_path = directory.path_join("mission-progress-%s.json" % profile_id)


func load_snapshot() -> Dictionary:
	if _path.is_empty():
		return {}
	var receipt := _validated_snapshot(_read_document(_path + RECEIPT_SUFFIX))
	if _is_completed(receipt):
		return receipt
	return _select_snapshot(_read_document(_path), _read_document(_path + ".bak"))


func has_incompatible_save() -> bool:
	return not _path.is_empty() and _has_protected_document(
		_read_document(_path), _read_document(_path + ".bak"), _read_document(_path + RECEIPT_SUFFIX))


func save_snapshot(snapshot: Dictionary) -> bool:
	if _path.is_empty() or not Delivery.valid_snapshot(snapshot):
		return false
	var primary := _read_document(_path)
	var backup := _read_document(_path + ".bak")
	var receipt := _read_document(_path + RECEIPT_SUFFIX)
	if _has_protected_document(primary, backup, receipt):
		return false
	var completed_receipt := _is_completed(_validated_snapshot(receipt))
	var completing := _is_completed(snapshot)
	if not completing and (completed_receipt or _is_completed(_select_snapshot(primary, backup))):
		return false
	var directory := ProjectSettings.globalize_path(_path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return false
	var document := {"version": VERSION, "profile_id": _profile_id, "mission": snapshot}
	# Only completion can write the receipt. Checkpoint writers that already
	# passed the earlier read cannot roll back the committed result.
	if completing and not completed_receipt and not _write_atomic(_path + RECEIPT_SUFFIX, document):
		return false
	if _validated_snapshot(primary) != snapshot and not _write_atomic(_path, document):
		if not completing:
			return false
		push_warning("Mission completion was recorded. The primary save could not be refreshed.")
	# Retain the latest good state for recovery, including for older builds.
	if _validated_snapshot(backup) != snapshot and not _write_atomic(_path + ".bak", document):
		push_warning("Mission progress was saved. The backup could not be refreshed.")
	return true


func _has_protected_document(primary: Dictionary, backup: Dictionary, receipt: Dictionary) -> bool:
	return _protected_document(primary) or _protected_document(backup) or _protected_document(receipt)


func _select_snapshot(primary: Dictionary, backup: Dictionary) -> Dictionary:
	var current := _validated_snapshot(primary)
	var fallback := _validated_snapshot(backup)
	if current.is_empty() or _is_completed(fallback):
		return fallback
	return current


func _validated_snapshot(document: Dictionary) -> Dictionary:
	var owner: Variant = document.get("profile_id")
	if document.size() != 3 or not _supported_version(document.get("version")) or not owner is String or owner != _profile_id:
		return {}
	var snapshot: Variant = document.get("mission")
	if snapshot is Dictionary and Delivery.valid_snapshot(snapshot):
		return snapshot
	return {}


func _protected_document(document: Dictionary) -> bool:
	# Preserve data from another profile or a version this build cannot read.
	var owner: Variant = document.get("profile_id")
	return (owner is String and _valid_profile_id(owner) and owner != _profile_id) \
		or (document.has("version") and not _supported_version(document["version"]))


func _is_completed(snapshot: Dictionary) -> bool:
	var state: Variant = snapshot.get("state")
	return state is String and state == String(Delivery.COMPLETED)


func _supported_version(value: Variant) -> bool:
	return (value is int or value is float) and value == VERSION


func _valid_profile_id(value: String) -> bool:
	# Match the canonical positive numeric IDs persisted by Preferences.
	if value.length() > 10 or not value.is_valid_int():
		return false
	var number := value.to_int()
	return number > 0 and number <= MAX_PROFILE_ID and str(number) == value


func _read_document(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var size := file.get_length()
	if size == 0 or size > MAX_FILE_BYTES:
		file.close()
		return {}
	var data := file.get_buffer(size)
	file.close()
	if data.size() != size:
		return {}
	var parser := JSON.new()
	if parser.parse(data.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _write_atomic(path: String, document: Dictionary) -> bool:
	var target := ProjectSettings.globalize_path(path)
	var temporary := "%s.%d.%d.tmp" % [target, OS.get_process_id(), get_instance_id()]
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_string(JSON.stringify(document) + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if stored and error == OK and DirAccess.rename_absolute(temporary, target) == OK:
		return true
	DirAccess.remove_absolute(temporary)
	return false
