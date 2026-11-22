extends SceneTree

const Delivery := preload("res://mission/ranwar_delivery.gd")
const Progress := preload("res://mission/mission_progress.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var directory := "user://mission-progress-smoke-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var primary := directory.path_join("mission-progress-1.json")
	var backup := primary + ".bak"
	var receipt := primary + Progress.RECEIPT_SUFFIX
	var other_path := directory.path_join("mission-progress-2.json")
	var legacy_path := directory.path_join("mission-progress-3.json")
	var store := Progress.new("1", directory)
	var separate := Progress.new("2", directory)
	var invalid := Progress.new("../1", directory)
	var external_dir := Progress.new("1", "res://")
	var mission := Delivery.new()
	var offer := mission.snapshot()
	_expect(store.load_snapshot().is_empty(), "a new profile has no existing progress")
	_expect(not store.has_incompatible_save(), "a new profile is writable")
	_expect(not invalid.save_snapshot(offer) and invalid.load_snapshot().is_empty(), "invalid profile paths are rejected")
	_expect(not external_dir.save_snapshot(offer), "storage outside user data is rejected")
	_expect(not store.save_snapshot({"state": "completed"}), "invalid mission snapshot is rejected before write")

	mission.interact()
	var pickup := mission.snapshot()
	_expect(store.save_snapshot(pickup), "first checkpoint commits")
	_expect(FileAccess.file_exists(backup), "the first checkpoint creates a backup")
	_expect(not FileAccess.file_exists(receipt), "checkpoint saves leave the receipt path unused")
	_expect(Progress.new("1", directory).load_snapshot() == pickup, "fresh instance resumes first checkpoint")
	_expect(separate.load_snapshot().is_empty(), "a second profile starts without progress")
	_expect(separate.save_snapshot(offer) and store.load_snapshot() == pickup, "a second profile saves independently")

	_write_fixture(primary, "bad data")
	_expect(store.load_snapshot() == pickup, "invalid primary falls back to first checkpoint")
	_write_fixture(primary, "x".repeat(Progress.MAX_FILE_BYTES + 1))
	_expect(store.load_snapshot() == pickup, "oversized primary falls back to backup")

	mission.interact()
	var dropoff := mission.snapshot()
	_expect(store.save_snapshot(dropoff) and store.load_snapshot() == dropoff, "save repairs invalid primary")
	# A directory at the destination forces an ordinary failure before commit.
	var target := ProjectSettings.globalize_path(primary)
	var removed := DirAccess.remove_absolute(target)
	var replaced := DirAccess.make_dir_absolute(target)
	_expect(removed == OK and replaced == OK, "blocked rename fixture prepared")
	_expect(not store.save_snapshot(pickup) and store.load_snapshot() == dropoff, "failed replacement preserves last good state")
	DirAccess.remove_absolute(target)

	mission.interact()
	var completed := mission.snapshot()
	var receipt_target := ProjectSettings.globalize_path(receipt)
	_expect(DirAccess.make_dir_absolute(receipt_target) == OK, "blocked receipt fixture prepared")
	_expect(not store.save_snapshot(completed) and store.load_snapshot() == dropoff, "failed receipt write leaves checkpoint intact")
	DirAccess.remove_absolute(receipt_target)
	_expect(DirAccess.make_dir_absolute(target) == OK, "blocked refresh fixture prepared")
	_expect(store.save_snapshot(completed) and store.load_snapshot() == completed, "receipt preserves completion when primary refresh fails")
	DirAccess.remove_absolute(target)

	_expect(store.save_snapshot(completed) and store.save_snapshot(completed), "completion can be written idempotently")
	_expect(FileAccess.get_file_as_string(receipt) == FileAccess.get_file_as_string(primary), "receipt uses the same versioned document as primary")
	_expect(not store.save_snapshot(dropoff) and store.load_snapshot() == completed, "stale checkpoint cannot replace completion")

	# Reproduce both renames of a writer which read the old state before the receipt committed.
	var stale := JSON.stringify({"version": Progress.VERSION, "profile_id": "1", "mission": dropoff})
	_write_fixture(primary, stale)
	_write_fixture(backup, stale)
	_expect(store.load_snapshot() == completed and not store.has_incompatible_save(), "receipt wins over both supported stale copies")
	_expect(not store.save_snapshot(pickup), "visible receipt blocks later checkpoint writes")

	_write_fixture(primary, "bad data")
	_expect(not store.save_snapshot(offer) and store.load_snapshot() == completed, "corrupt primary preserves completion in the receipt")
	_write_fixture(legacy_path, JSON.stringify({"version": Progress.VERSION, "profile_id": "3", "mission": completed}))
	_expect(Progress.new("3", directory).load_snapshot() == completed, "legacy completion loads without a separate receipt")

	var future := JSON.stringify({"version": 2, "profile_id": "1", "mission": completed})
	_write_fixture(primary, future)
	_expect(store.load_snapshot() == completed, "known receipt can be read alongside a future save")
	_expect(store.has_incompatible_save(), "future-version primary reports incompatible progress")
	_expect(not store.save_snapshot(completed) and FileAccess.get_file_as_string(primary) == future, "future-version primary is preserved")
	var foreign := JSON.stringify({"version": 1, "profile_id": "1", "mission": completed})
	_write_fixture(other_path, foreign)
	_expect(separate.load_snapshot() == offer, "foreign primary cannot load another profile's checkpoint")
	_expect(separate.has_incompatible_save(), "foreign primary reports incompatible progress")
	_expect(not separate.save_snapshot(dropoff) and FileAccess.get_file_as_string(other_path) == foreign, "another profile's file is preserved")
	var malformed := JSON.stringify({"version": 1, "profile_id": 2, "mission": completed})
	_write_fixture(other_path, malformed)
	_expect(separate.load_snapshot() == offer, "wrong profile field type is rejected")
	_write_fixture(other_path, JSON.stringify({"version": 0, "profile_id": "2", "mission": offer}))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(other_path + ".bak"))
	_expect(separate.load_snapshot().is_empty() and not separate.save_snapshot(offer), "unknown old schema without a backup is preserved")
	_expect(separate.has_incompatible_save(), "unknown old schema reports incompatible progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(other_path))
	var other_receipt := other_path + Progress.RECEIPT_SUFFIX
	_write_fixture(other_receipt, foreign)
	_expect(separate.load_snapshot().is_empty() and separate.has_incompatible_save(), "foreign receipt cannot load for this profile and is reported incompatible")
	_expect(not separate.save_snapshot(completed) and FileAccess.get_file_as_string(other_receipt) == foreign, "completion cannot replace foreign receipt")

	for path: String in [primary, backup, receipt, other_receipt, legacy_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var cleanup := DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	_expect(cleanup == OK, "isolated smoke fixtures removed without temporary files left over")
	print("Mission progress smoke: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _write_fixture(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "smoke fixture could be opened")
		return
	file.store_string(value)
	file.close()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
