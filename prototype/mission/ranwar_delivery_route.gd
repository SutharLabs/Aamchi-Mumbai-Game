extends Node3D

const Delivery := preload("res://mission/ranwar_delivery.gd")
const Progress := preload("res://mission/mission_progress.gd")
const Career := preload("res://mission/ranwar_career.gd")
const Pedestrian := preload("res://character/practice_pedestrian.gd")
const PICKUP_CUE := preload("res://shared/audio/parcel-pickup.wav")
const PICKUP_VOICE := "ranwar-parcel-pickup"
const HANDOFF_VOICE := "ranwar-parcel-handoff"
const BOARD := Vector3(-9.0, 0.0, 5.0)
const ON_FOOT_RANGE := 1.8
const CONTACT_OFFSET := 0.90
const MARKER_COLOR := Color("f4a261")
const SAVE_ERROR := "Job progress could not be saved. Try again."
const INCOMPATIBLE_SAVE := "Job save belongs to another version or profile."

var flow := Delivery.new()
var _progress: Progress
var _save_incompatible := false
var _pickup := Vector3.ZERO
var _dropoff := Vector3.ZERO
var _marker: MeshInstance3D
var _ravi: Pedestrian
var _kavita: Pedestrian
var _ravi_parcel: BoneAttachment3D
var _carried_parcel: BoneAttachment3D
var _kavita_parcel: BoneAttachment3D
var _received_in_session := false


func setup(progress: Progress, footway: PackedVector3Array, carrier: Skeleton3D) -> void:
	_progress = progress
	_pickup = footway[-1].move_toward(footway[-2], 13.0)
	_dropoff = footway[0].move_toward(footway[1], 10.0)
	var hill_inward := (footway[-2] - footway[-1]).normalized()
	var waroda_inward := (footway[1] - footway[0]).normalized()
	_ravi = _add_contact("Ravi", _pickup, Vector3.UP.cross(hill_inward), Color("786859"), false)
	_kavita = _add_contact("Kavita", _dropoff, Vector3.UP.cross(-waroda_inward), Color("567c75"), true)
	_ravi_parcel = _attach_parcel(_ravi.visual.skeleton)
	_carried_parcel = _attach_parcel(carrier)
	_kavita_parcel = _attach_parcel(_kavita.visual.skeleton)
	_add_job_board()
	flow.restore(_progress.load_snapshot())
	_save_incompatible = _progress.has_incompatible_save()
	_marker = make_marker("JobMarker", false)
	add_child(_marker)
	_refresh_marker()
	_refresh_parcels()


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


func contact_for(stage: StringName) -> Pedestrian:
	match stage:
		Delivery.PICKUP: return _ravi
		Delivery.DROPOFF: return _kavita
		_: return null


func prompt_for(position: Vector3) -> String:
	var destination := target()
	var contact := contact_for(flow.state)
	if destination.is_finite() and is_instance_valid(contact):
		if contact.is_reacting():
			return ""
		destination = contact.global_position
	if not destination.is_finite() or position.distance_squared_to(destination) > ON_FOOT_RANGE ** 2:
		return ""
	var reach := PhysicsRayQueryParameters3D.create(position + Vector3.UP, destination + Vector3.UP, 1)
	if not get_world_3d().direct_space_state.intersect_ray(reach).is_empty():
		return ""
	match flow.state:
		Delivery.PICKUP: return "Collect the parcel from Ravi"
		Delivery.DROPOFF: return "Give the parcel to Kavita"
		Delivery.FAILED: return "Retry parcel run"
		_: return "Start Ranwar Parcel Run · ₹%d" % Career.PARCEL_PAY


func objective(position: Vector3) -> String:
	if _save_incompatible:
		return INCOMPATIBLE_SAVE
	var destination := target()
	if not destination.is_finite():
		return ""
	var distance := Vector2(position.x - destination.x, position.z - destination.z).length()
	var instruction: String
	match flow.state:
		Delivery.PICKUP: instruction = "Pick up parcel from Ravi · Hill Road"
		Delivery.DROPOFF: instruction = "Hand off parcel to Kavita · Waroda Road"
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
	if before["state"] == String(Delivery.PICKUP) and flow.state == Delivery.DROPOFF:
		_play_pickup_cue()
	if before["state"] == String(Delivery.DROPOFF) and flow.state == Delivery.COMPLETED:
		_received_in_session = true
		_refresh_parcels()
	match flow.state:
		Delivery.PICKUP: return "Job active. Find Ravi at the Hill Road end of Nagrana Lane."
		Delivery.DROPOFF: return "Parcel collected"
		Delivery.COMPLETED: return "Parcel delivered · +₹%d. New lead from Mira." % Career.PARCEL_PAY
		_: return ""


func _play_pickup_cue() -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "ParcelPickupCue"
	player.stream = PICKUP_CUE
	player.volume_db = -3.0
	player.unit_size = 3.0
	player.max_distance = 16.0
	add_child(player)
	player.global_position = _pickup + Vector3.UP * 0.8
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	player.play()


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
	_refresh_parcels()
	return saved


func _save_error() -> String:
	return INCOMPATIBLE_SAVE if _save_incompatible else SAVE_ERROR


static func make_marker(marker_name: String, raised := true) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = MARKER_COLOR if raised else Color(0.78, 0.58, 0.32, 0.58)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not raised:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ring := TorusMesh.new()
	ring.inner_radius = 0.56 if raised else 0.43
	ring.outer_radius = 0.76 if raised else 0.49
	ring.rings = 24
	ring.ring_segments = 8
	var marker := MeshInstance3D.new()
	marker.name = marker_name
	marker.mesh = ring
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not raised:
		marker.scale.y = 0.033
		return marker
	var diamond := BoxMesh.new()
	diamond.size = Vector3(0.32, 0.32, 0.32)
	var beacon := MeshInstance3D.new()
	beacon.mesh = diamond
	beacon.material_override = material
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.position.y = 1.05
	beacon.rotation_degrees = Vector3(25.0, 25.0, 45.0)
	marker.add_child(beacon)
	return marker


func _refresh_marker() -> void:
	var destination := target()
	_marker.visible = destination.is_finite()
	if _marker.visible:
		var height := 0.056 if is_instance_valid(contact_for(flow.state)) else 0.019
		_marker.position = destination + Vector3.UP * height


func _add_contact(display_name: String, anchor: Vector3, sidewalk_side: Vector3, shirt: Color, wears_kurta: bool) -> Pedestrian:
	var contact := Pedestrian.new()
	contact.name = display_name
	contact.display_name = display_name
	contact.shirt_color = shirt
	contact.wears_overshirt = not wears_kurta
	contact.visual.wears_kurta_with_dupatta = wears_kurta
	contact.visual.kurta_hair_style = 1
	contact.visual.face_variant = display_name
	contact.path_start = anchor + sidewalk_side * CONTACT_OFFSET + Vector3.UP * 0.06
	contact.path_end = contact.path_start
	add_child(contact)
	var toward_lane := anchor - contact.position
	contact.rotation.y = atan2(-toward_lane.x, -toward_lane.z)
	return contact


func _attach_parcel(skeleton: Skeleton3D) -> BoneAttachment3D:
	var holder := BoneAttachment3D.new()
	holder.name = "ParcelGrip"
	holder.bone_name = "RightHand"
	skeleton.add_child(holder)
	var body := _box(holder, "BrownPaperParcel", Vector3(0.078, -0.041, 0.010), Vector3(0.155, 0.055, 0.185), Color("ac8051"))
	_box(body, "PaperTape", Vector3(0, -0.029, 0), Vector3(0.038, 0.004, 0.185), Color("ceb68a"))
	return holder


func _refresh_parcels() -> void:
	_ravi_parcel.visible = not _save_incompatible and (flow.state == Delivery.OFFER or flow.state == Delivery.PICKUP)
	_carried_parcel.visible = not _save_incompatible and flow.state == Delivery.DROPOFF
	_kavita_parcel.visible = _received_in_session and flow.state == Delivery.COMPLETED


func _add_job_board() -> void:
	var board := Node3D.new()
	board.name = "DeliveryNoticeBoard"
	board.position = BOARD + Vector3(-0.95, 0, 0)
	board.rotation.y = PI * 0.5
	add_child(board)
	var frame := Color("3e544d")
	for side in [-0.41, 0.41]:
		_box(board, "BoardPost", Vector3(side, 0.59, 0), Vector3(0.046, 1.18, 0.051), frame)
	_box(board, "BoardFrame", Vector3(0, 0.97, 0), Vector3(0.93, 0.53, 0.043), frame)
	_box(board, "PrintedNotice", Vector3(0, 0.97, 0.022), Vector3(0.82, 0.42, 0.008), Color("e2d6b9"))
	var sign := Label3D.new()
	sign.text = "RANWAR\nDELIVERIES"
	sign.font_size = 35
	sign.pixel_size = 0.0031
	sign.outline_size = 0
	sign.modulate = Color("344a3d")
	sign.position = Vector3(0, 0.97, 0.028)
	board.add_child(sign)


func _box(parent: Node3D, part_name: String, center: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	part.mesh = shape
	part.material_override = material
	part.position = center
	parent.add_child(part)
	return part
