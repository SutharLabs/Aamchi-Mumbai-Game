extends Node3D

const Delivery := preload("res://mission/ranwar_delivery.gd")
const Progress := preload("res://mission/mission_progress.gd")
const BOARD := Vector3(-9.0, 0.0, 5.0)
const ON_FOOT_RANGE := 1.8
const MARKER_COLOR := Color("f4a261")
const SAVE_ERROR := "Job progress could not be saved. Try again."
const INCOMPATIBLE_SAVE := "Job save belongs to another version or profile."

var flow := Delivery.new()
var _progress: Progress
var _save_incompatible := false
var _pickup := Vector3.ZERO
var _dropoff := Vector3.ZERO
var _marker := MeshInstance3D.new()
var _beacon := MeshInstance3D.new()


func setup(progress: Progress, footway: PackedVector3Array) -> void:
	_progress = progress
	_pickup = footway[-1].move_toward(footway[-2], 13.0)
	_dropoff = footway[0].move_toward(footway[1], 10.0)
	flow.restore(_progress.load_snapshot())
	_save_incompatible = _progress.has_incompatible_save()
	_build_marker()
	_refresh_marker()


func target() -> Vector3:
	if _save_incompatible:
		return Vector3.INF
	match flow.state:
		Delivery.PICKUP: return _pickup
		Delivery.DROPOFF: return _dropoff
		Delivery.COMPLETED: return Vector3.INF
		_: return BOARD


func can_abandon() -> bool:
	return not _save_incompatible and flow.state in [Delivery.PICKUP, Delivery.DROPOFF, Delivery.FAILED]


func prompt_for(position: Vector3) -> String:
	var destination := target()
	if not destination.is_finite() or position.distance_squared_to(destination) > ON_FOOT_RANGE ** 2:
		return ""
	var reach := PhysicsRayQueryParameters3D.create(position + Vector3.UP, destination + Vector3.UP, 1)
	if not get_world_3d().direct_space_state.intersect_ray(reach).is_empty():
		return ""
	match flow.state:
		Delivery.PICKUP: return "Pick up the parcel"
		Delivery.DROPOFF: return "Leave the parcel"
		Delivery.FAILED: return "Retry parcel run"
		_: return "Start Ranwar Parcel Run"


func objective(position: Vector3) -> String:
	if _save_incompatible:
		return INCOMPATIBLE_SAVE
	var destination := target()
	if not destination.is_finite():
		return ""
	var distance := Vector2(position.x - destination.x, position.z - destination.z).length()
	var instruction: String
	match flow.state:
		Delivery.PICKUP: instruction = "Pick up parcel · Hill Road"
		Delivery.DROPOFF: instruction = "Drop off parcel · Waroda Road"
		Delivery.FAILED: instruction = "Retry at the job board"
		_:
			if distance > 22.0:
				return ""
			instruction = "Job board by the vehicle bays"
	return "%s  ·  %d m" % [instruction, roundi(distance)]


func interact() -> String:
	var before := flow.snapshot()
	flow.interact()
	if not _persist_change(before):
		return _save_error()
	match flow.state:
		Delivery.PICKUP: return "Job active. Pick up at the Hill Road end of Nagrana Lane."
		Delivery.DROPOFF: return "Parcel collected. Follow Nagrana Lane to Waroda Road."
		Delivery.COMPLETED: return "Parcel delivered. Receipt saved to your profile."
		_: return ""


func on_recovery() -> String:
	if _save_incompatible or (flow.state != Delivery.PICKUP and flow.state != Delivery.DROPOFF):
		return ""
	var before := flow.snapshot()
	flow.fail()
	return "Job interrupted. Retry at the job board." if _persist_change(before) else _save_error()


func abandon() -> String:
	if not can_abandon():
		return ""
	var before := flow.snapshot()
	flow.cancel()
	return "Job abandoned. You can start it again at the job board." if _persist_change(before) else _save_error()


func _persist_change(before: Dictionary) -> bool:
	var saved := _progress.save_snapshot(flow.snapshot())
	if not saved:
		flow.restore(before)
		_save_incompatible = _progress.has_incompatible_save()
	_refresh_marker()
	return saved


func _save_error() -> String:
	return INCOMPATIBLE_SAVE if _save_incompatible else SAVE_ERROR


func _build_marker() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = MARKER_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := TorusMesh.new()
	ring.inner_radius = 0.56
	ring.outer_radius = 0.76
	ring.rings = 24
	ring.ring_segments = 8
	_marker.name = "JobMarker"
	_marker.mesh = ring
	_marker.material_override = material
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_marker)
	var diamond := BoxMesh.new()
	diamond.size = Vector3(0.32, 0.32, 0.32)
	_beacon.mesh = diamond
	_beacon.material_override = material
	_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beacon.position.y = 1.05
	_beacon.rotation_degrees = Vector3(25.0, 25.0, 45.0)
	_marker.add_child(_beacon)


func _refresh_marker() -> void:
	var destination := target()
	_marker.visible = destination.is_finite()
	if _marker.visible:
		_marker.position = destination + Vector3.UP * 0.12
