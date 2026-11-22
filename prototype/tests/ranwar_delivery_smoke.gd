extends SceneTree

const Delivery := preload("res://mission/ranwar_delivery.gd")

var _checks := 0
var _failures := 0
var _transitions := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var mission := Delivery.new()
	mission.state_changed.connect(_count_transition)
	mission.fail()
	mission.cancel()
	_check(mission.state == Delivery.OFFER and _transitions == 0, "offer ignores failure and cancellation")

	mission.interact()
	_check(mission.state == Delivery.PICKUP and mission.checkpoint == Delivery.PICKUP, "accepting sets pickup checkpoint")
	mission.fail()
	_check(mission.state == Delivery.FAILED and mission.checkpoint == Delivery.PICKUP, "first failure retains pickup checkpoint")
	mission.interact()
	_check(mission.state == Delivery.PICKUP, "first retry returns to pickup")
	mission.interact()
	_check(mission.state == Delivery.DROPOFF and mission.checkpoint == Delivery.DROPOFF, "collection sets dropoff checkpoint")
	mission.fail()
	_check(mission.state == Delivery.FAILED and mission.checkpoint == Delivery.DROPOFF, "second failure keeps the collected parcel")

	var failed_snapshot := mission.snapshot()
	var parsed: Variant = JSON.parse_string(JSON.stringify(failed_snapshot))
	_check(parsed is Dictionary and Delivery.valid_snapshot(parsed), "failed snapshot survives JSON round-trip")
	var loaded := Delivery.new()
	_check(parsed is Dictionary and loaded.restore(parsed), "fresh mission accepts the saved failure")
	loaded.interact()
	_check(loaded.snapshot() == {"mission_id": "ranwar_parcel_run", "state": "dropoff", "checkpoint": "dropoff"}, "loaded retry resumes at dropoff")
	loaded.cancel()
	_check(loaded.state == Delivery.OFFER and loaded.checkpoint == Delivery.OFFER, "cancel clears the active checkpoint")

	mission.interact()
	mission.interact()
	_check(mission.state == Delivery.COMPLETED and _transitions == 7, "handoff completes the mission once")
	var receipt := mission.snapshot()
	mission.interact()
	mission.fail()
	mission.cancel()
	_check(mission.snapshot() == receipt and _transitions == 7, "completed receipt remains stable under gameplay actions")
	_check(loaded.restore(receipt), "completed receipt loads into a fresh session")
	loaded.interact()
	_check(loaded.snapshot() == receipt, "reloaded receipt cannot be earned twice")
	_check(mission.restore(receipt) and _transitions == 7, "loading identical progress does not signal another completion")

	var invalid_snapshots: Array[Dictionary] = [
		{},
		{"mission_id": "second_mission", "state": "offer", "checkpoint": "offer"},
		{"mission_id": "ranwar_parcel_run", "state": "failed", "checkpoint": "completed"},
		{"mission_id": "ranwar_parcel_run", "state": "pickup", "checkpoint": "dropoff"},
		{"mission_id": "ranwar_parcel_run", "state": "unknown", "checkpoint": "unknown"},
		{"mission_id": "ranwar_parcel_run", "state": ["completed"], "checkpoint": "completed"},
		{"mission_id": "ranwar_parcel_run", "state": "completed", "checkpoint": "completed", "reward": 300},
	]
	for index in invalid_snapshots.size():
		var invalid := invalid_snapshots[index]
		_check(not Delivery.valid_snapshot(invalid) and not mission.restore(invalid), "rejects invalid snapshot %d" % index)
	_check(mission.snapshot() == receipt and _transitions == 7, "invalid snapshots leave the receipt unchanged")

	print("Ranwar delivery smoke: %d failures in %d checks" % [_failures, _checks])
	quit(1 if _failures else 0)


func _count_transition() -> void:
	_transitions += 1


func _check(passed: bool, description: String) -> void:
	_checks += 1
	if not passed:
		_failures += 1
		push_error("FAIL: " + description)
