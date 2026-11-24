extends RefCounted
## Saves the current Ranwar mission checkpoint separately for each local profile.

const Delivery := preload("res://mission/ranwar_delivery.gd")
const VERSION := 1
const MAX_FILE_BYTES := 2048
const MAX_PROFILE_ID := 2147483647
const RECEIPT_SUFFIX := ".receipt"
const LEDGER_ID := "hill_road_ledger"
const LEDGER_COLLECT := &"collect"
const LEDGER_HANDOFF := &"handoff"
const LEDGER_COMPLETED := &"completed"

var _profile_id: String
var _path := ""
var _career_path := ""
var _arrival_path := ""
var _ledger_path := ""


func _init(profile_id: String, directory: String = "user://", generation: int = 0) -> void:
	_profile_id = profile_id
	if not _valid_profile_id(profile_id) or generation < 0 or generation > MAX_PROFILE_ID:
		return
	# Alternate directories keep smoke fixtures away from actual profile saves.
	var folder := directory.get_file()
	if directory != "user://" and (directory != "user://" + folder or not folder.is_valid_filename() or folder.begins_with(".")):
		return
	var slot := profile_id if generation == 0 else "%s-%d" % [profile_id, generation]
	_path = directory.path_join("mission-progress-%s.json" % slot)
	_career_path = directory.path_join("career-progress-%s.json" % slot)
	_arrival_path = directory.path_join("arrival-%s.json" % slot)
	_ledger_path = directory.path_join("ledger-progress-%s.json" % slot)


func has_progress() -> bool:
	return arrival_seen() or not load_snapshot().is_empty() or not load_career().is_empty() or has_incompatible_save() \
		or load_ledger_checkpoint() != LEDGER_COLLECT or has_incompatible_ledger()


func save_files_exist() -> bool:
	if _path.is_empty():
		return false
	for path: String in [_path, _path + ".bak", _path + RECEIPT_SUFFIX, _career_path, _career_path + ".bak", _arrival_path,
			_ledger_path, _ledger_path + ".bak", _ledger_path + RECEIPT_SUFFIX]:
		if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
			return true
	return false


func load_snapshot() -> Dictionary:
	return _load_checkpoint(_path, _validated_snapshot)


func load_ledger_checkpoint() -> StringName:
	var saved := _load_checkpoint(_ledger_path, _validated_ledger_snapshot)
	return StringName(saved.get("state", LEDGER_COLLECT))


func _load_checkpoint(path: String, validate: Callable) -> Dictionary:
	if path.is_empty():
		return {}
	var receipt: Dictionary = validate.call(_read_document(path + RECEIPT_SUFFIX))
	if _is_completed(receipt):
		return receipt
	return _select_snapshot(_read_document(path), _read_document(path + ".bak"), validate)


func has_incompatible_save() -> bool:
	return not _path.is_empty() and _has_protected_document(
		_read_document(_path), _read_document(_path + ".bak"), _read_document(_path + RECEIPT_SUFFIX))


func has_incompatible_ledger() -> bool:
	if _ledger_path.is_empty():
		return false
	for path: String in [_ledger_path, _ledger_path + ".bak", _ledger_path + RECEIPT_SUFFIX]:
		var document := _read_document(path)
		if _protected_document(document):
			return true
		var mission: Variant = document.get("mission")
		if mission is Dictionary and mission.has("mission_id") and mission["mission_id"] != LEDGER_ID:
			return true
	return false


func arrival_seen() -> bool:
	if _arrival_path.is_empty():
		return false
	var record := _read_document(_arrival_path)
	return record.size() == 3 and record.get("profile_id") == _profile_id \
		and _supported_version(record.get("version")) and record.get("arrived") == true


func save_arrival() -> bool:
	if _arrival_path.is_empty() or _protected_document(_read_document(_arrival_path)):
		return false
	if arrival_seen():
		return true
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_arrival_path.get_base_dir())) != OK:
		return false
	return _write_atomic(_arrival_path, {"version": VERSION, "profile_id": _profile_id, "arrived": true})


func load_career() -> Dictionary:
	if _career_path.is_empty():
		return {}
	var current := _validated_career(_read_document(_career_path))
	return current if not current.is_empty() else _validated_career(_read_document(_career_path + ".bak"))


func save_career(spent: int, lead_seen: bool) -> bool:
	if _career_path.is_empty():
		return false
	var path_backup := _career_path + ".bak"
	var current_doc := _read_document(_career_path)
	var backup_doc := _read_document(path_backup)
	if _protected_document(current_doc) or _protected_document(backup_doc):
		return false
	var current := _validated_career(current_doc)
	if current.is_empty():
		current = _validated_career(backup_doc)
	if spent < int(current.get("spent", 0)) or (current.get("lead_seen", false) and not lead_seen):
		return false
	var document := {"version": VERSION, "profile_id": _profile_id, "career": {"spent": spent, "lead_seen": lead_seen}}
	if _validated_career(document).is_empty() or DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(_career_path.get_base_dir())) != OK:
		return false
	if not _write_atomic(_career_path, document):
		return false
	if not _write_atomic(path_backup, document):
		push_warning("Career progress was saved. The backup could not be refreshed.")
	return true


func _validated_career(document: Dictionary) -> Dictionary:
	if document.size() != 3 or document.get("profile_id") != _profile_id or not _supported_version(document.get("version")):
		return {}
	var career: Variant = document.get("career")
	if not career is Dictionary or career.size() != 2 or not career.get("lead_seen") is bool:
		return {}
	var spent: Variant = career.get("spent")
	if not (spent is int or spent is float) or not is_finite(float(spent)) or spent < 0 or spent > 1000000 or spent != floorf(float(spent)):
		return {}
	return {"spent": int(spent), "lead_seen": career["lead_seen"]}


func save_snapshot(snapshot: Dictionary) -> bool:
	if not Delivery.valid_snapshot(snapshot):
		return false
	return _save_checkpoint(_path, snapshot, _validated_snapshot)


func save_ledger_checkpoint(state: StringName) -> bool:
	if state not in [LEDGER_COLLECT, LEDGER_HANDOFF, LEDGER_COMPLETED] or has_incompatible_ledger():
		return false
	var current := load_ledger_checkpoint()
	if state == LEDGER_COLLECT and current != LEDGER_HANDOFF:
		return false
	if state == LEDGER_COMPLETED and current == LEDGER_COLLECT:
		return false
	return _save_checkpoint(_ledger_path, {"mission_id": LEDGER_ID, "state": String(state)}, _validated_ledger_snapshot)


func _save_checkpoint(path: String, snapshot: Dictionary, validate: Callable) -> bool:
	if path.is_empty():
		return false
	var primary := _read_document(path)
	var backup := _read_document(path + ".bak")
	var receipt := _read_document(path + RECEIPT_SUFFIX)
	if _has_protected_document(primary, backup, receipt):
		return false
	var completed_receipt := _is_completed(validate.call(receipt))
	var completing := _is_completed(snapshot)
	if not completing and (completed_receipt or _is_completed(_select_snapshot(primary, backup, validate))):
		return false
	var directory := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return false
	var document := {"version": VERSION, "profile_id": _profile_id, "mission": snapshot}
	# Only completion can write the receipt. Checkpoint writers that already
	# passed the earlier read cannot roll back the committed result.
	if completing and not completed_receipt and not _write_atomic(path + RECEIPT_SUFFIX, document):
		return false
	if validate.call(primary) != snapshot and not _write_atomic(path, document):
		if not completing:
			return false
		push_warning("Mission completion was recorded. The primary save could not be refreshed.")
	# Retain the latest good state for recovery, including for older builds.
	if validate.call(backup) != snapshot and not _write_atomic(path + ".bak", document):
		push_warning("Mission progress was saved. The backup could not be refreshed.")
	return true


func _has_protected_document(primary: Dictionary, backup: Dictionary, receipt: Dictionary) -> bool:
	return _protected_document(primary) or _protected_document(backup) or _protected_document(receipt)


func _select_snapshot(primary: Dictionary, backup: Dictionary, validate: Callable) -> Dictionary:
	var current: Dictionary = validate.call(primary)
	var fallback: Dictionary = validate.call(backup)
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


func _validated_ledger_snapshot(document: Dictionary) -> Dictionary:
	if document.size() != 3 or not _supported_version(document.get("version")) or document.get("profile_id") != _profile_id:
		return {}
	var mission: Variant = document.get("mission")
	if mission is Dictionary and mission.size() == 2 and mission.get("mission_id") == LEDGER_ID:
		var state: Variant = mission.get("state")
		if state is String and state in [String(LEDGER_COLLECT), String(LEDGER_HANDOFF), String(LEDGER_COMPLETED)]:
			return mission
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
