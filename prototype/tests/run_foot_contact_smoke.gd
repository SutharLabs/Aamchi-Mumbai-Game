extends SceneTree

const Visual := preload("res://character/locomotion_visual.gd")
const CONTACTS := { "Right": Vector2(5.0, 11.0) / 30.0, "Left": Vector2(16.0, 21.0) / 30.0 }
const TOE_SOLE := Vector3(0.0, -0.035, -0.019)

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var runner := Visual.new()
	runner.wears_dhotar = true
	root.add_child(runner)
	var skeleton := runner.skeleton
	var label := ["LeftFoot", "RightFoot", "LeftToes", "RightToes"]
	var joints := {}
	for name: String in label:
		joints[name] = skeleton.find_bone(name)

	var body := runner.get_node("ClothedBody") as MeshInstance3D
	var mesh := body.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = mesh[Mesh.ARRAY_VERTEX]
	var skin_bones: PackedInt32Array = mesh[Mesh.ARRAY_BONES]
	var skin_weights: PackedFloat32Array = mesh[Mesh.ARRAY_WEIGHTS]
	var sole_indices := PackedInt32Array()
	for index in vertices.size():
		if vertices[index].y < 0.026 and skin_bones[index * 4] in joints.values():
			sole_indices.append(index)

	var player := runner.animation_player
	player.play(&"run")
	player.pause()
	var duration := player.get_animation(&"run").length
	var ankle_separation := INF
	var lowest_point := INF
	var air_clearance := 0.0
	var support_error := 0.0
	var plant_travel := 0.0
	var plant_anchors := {}
	for tick in range(93):
		var seconds := minf(float(tick) / 120.0, duration)
		player.seek(seconds, true)
		var left := skeleton.get_bone_global_pose(joints["LeftFoot"])
		var right := skeleton.get_bone_global_pose(joints["RightFoot"])
		ankle_separation = minf(ankle_separation, right.origin.x - left.origin.x)
		var sole_height := INF
		for index in sole_indices:
			var skinned := Vector3.ZERO
			for slot in range(index * 4, index * 4 + 4):
				if skin_weights[slot] <= 0.0:
					continue
				var bone := skin_bones[slot]
				var pose := skeleton.get_bone_global_pose(bone) * skeleton.get_bone_global_rest(bone).affine_inverse()
				skinned += (pose * vertices[index]) * skin_weights[slot]
			sole_height = minf(sole_height, skinned.y)
		lowest_point = minf(lowest_point, sole_height)
		air_clearance = maxf(air_clearance, sole_height)

		for side: String in CONTACTS:
			var interval: Vector2 = CONTACTS[side]
			if seconds < interval.x - 0.0001 or seconds > interval.y + 0.0001:
				continue
			support_error = maxf(support_error, absf(sole_height))
			var toes := skeleton.get_bone_global_pose(joints[side + "Toes"])
			var world_forefoot := toes * TOE_SOLE + Vector3.FORWARD * seconds * Visual.RUN_REFERENCE_SPEED
			var point := Vector2(world_forefoot.x, world_forefoot.z)
			if not plant_anchors.has(side):
				plant_anchors[side] = point
			plant_travel = maxf(plant_travel, point.distance_to(plant_anchors[side]))

	_expect(ankle_separation > 0.055, "ankles stay on anatomically separate tracks")
	_expect(sole_indices.size() > 35 and lowest_point >= -0.020 and support_error < 0.020,
		"the skinned chappal soles remain within two centimetres of the floor during support")
	_expect(air_clearance > 0.048, "the captured run still has an airborne phase")
	_expect(plant_anchors.size() == 2 and plant_travel < 0.020,
		"both planted forefeet move less than two centimetres at the run's reference speed")
	runner.set_ground_speed(1.46)
	var expected_rate := 1.46 / Visual.RUN_REFERENCE_SPEED
	_expect(runner.animation_player.current_animation == &"run"
		and is_equal_approx(runner.animation_player.speed_scale, expected_rate),
		"the run cadence follows movement through a slow transition")

	print("Run feet: ankle spacing %.3f m, lowest sole %.3f m, support error %.3f m, airborne %.3f m, forefoot drift %.3f m." %
		[ankle_separation, lowest_point, support_error, air_clearance, plant_travel])
	print("run foot contact: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
