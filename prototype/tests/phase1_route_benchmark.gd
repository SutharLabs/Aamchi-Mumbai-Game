extends SceneTree
## Measures one rendered car lap using the current checkout and gameplay scene.

const Scenario := preload("res://phase1.tscn")
const WARMUP_TICKS := 90
const MAX_ROUTE_TICKS := 18000

var _frame_times_ms := PackedFloat64Array()
var _physics_times_ms := PackedFloat64Array()
var _draw_call_samples := PackedFloat64Array()
var _last_frame_us := 0
var _stalls_over_100_ms := 0
var _peak_nodes := 0
var _peak_render_objects := 0
var _peak_steady_allocated_bytes := 0
var _worst_frame_ms := 0.0
var _worst_frame_position := Vector3.ZERO
var _worst_frame_waypoint := 0
var _waypoint_index := 0
var _car: CharacterBody3D
var _world: Node3D
var _min_active_visual_meshes := -1
var _scene_setup_ms := 0.0


func _initialize() -> void:
	_run_lap.call_deferred()


func _run_lap() -> void:
	if DisplayServer.get_name() == "headless" or "--fixed-fps" in OS.get_cmdline_args():
		printerr("Run the route benchmark with normal rendered frames and a wall clock.")
		quit(2)
		return

	var scene_start_us := Time.get_ticks_usec()
	var game := Scenario.instantiate()
	# The automated car follows the centerlines, including the rehearsal direction.
	# Exclude ambient vehicles from both streaming comparison modes.
	game.ambient_traffic_enabled = false
	root.add_child(game)
	_scene_setup_ms = float(Time.get_ticks_usec() - scene_start_us) / 1000.0
	_world = game.world
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.set_process_unhandled_input(false)
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		InputMap.action_set_deadzone(action, 0.0)
	_car = game.car
	game.player.set_on_foot(false)
	game.active_vehicle = _car
	_car.set_driver_active(true)

	var waypoints := PackedVector3Array()
	for road: PackedVector3Array in game.world._roads:
		for index in range(1, road.size()):
			waypoints.append(road[index])
	if waypoints.is_empty():
		printerr("Ranwar has no driving waypoints.")
		quit(2)
		return

	for tick in range(WARMUP_TICKS):
		await physics_frame
	_sample_scene()
	var start_us := Time.get_ticks_usec()
	var next_physics_sample_us := start_us + 1000000
	process_frame.connect(_sample_frame)
	for tick in range(MAX_ROUTE_TICKS):
		await physics_frame
		if Time.get_ticks_usec() >= next_physics_sample_us:
			_physics_times_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
			_sample_scene()
			next_physics_sample_us += 1000000
		var offset := waypoints[_waypoint_index] - _car.global_position
		offset.y = 0.0
		if offset.length_squared() < 9.0:
			_waypoint_index += 1
			if _waypoint_index == waypoints.size():
				_finish(start_us, _waypoint_index)
				return
			offset = waypoints[_waypoint_index] - _car.global_position
			offset.y = 0.0
		_steer_to(_car, offset)

	printerr("Ranwar benchmark failed at waypoint %d/%d near %s." % [
		_waypoint_index + 1, waypoints.size(), str(_car.global_position),
	])
	quit(1)


func _steer_to(car: CharacterBody3D, offset: Vector3) -> void:
	var heading := atan2(-offset.x, -offset.z)
	var yaw_error := angle_difference(car.rotation.y, heading)
	var target_speed := 3.6 if offset.length() < 9.0 or absf(yaw_error) > 0.48 else 10.0
	var steer := -clampf(yaw_error / 0.39, -1.0, 1.0)
	_set_action(&"move_forward", target_speed / car.max_forward_speed)
	_set_action(&"move_left", maxf(0.0, -steer))
	_set_action(&"move_right", maxf(0.0, steer))
	_set_action(&"brake", 1.0 if car.get_speed_mps() > target_speed + 0.45 else 0.0)


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _sample_frame() -> void:
	var now_us := Time.get_ticks_usec()
	if _last_frame_us > 0:
		var frame_ms := float(now_us - _last_frame_us) / 1000.0
		_frame_times_ms.append(frame_ms)
		if frame_ms > _worst_frame_ms:
			_worst_frame_ms = frame_ms
			_worst_frame_position = _car.global_position
			_worst_frame_waypoint = _waypoint_index + 1
		if frame_ms > 100.0:
			_stalls_over_100_ms += 1
	_last_frame_us = now_us


func _sample_scene() -> void:
	_peak_nodes = maxi(_peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	_peak_render_objects = maxi(_peak_render_objects, int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	_peak_steady_allocated_bytes = maxi(_peak_steady_allocated_bytes, OS.get_static_memory_usage())
	_draw_call_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var stats: Dictionary = _world.visual_residency_stats()
	var active: int = stats["active_meshes"]
	_min_active_visual_meshes = active if _min_active_visual_meshes < 0 else mini(_min_active_visual_meshes, active)


func _percentile(samples: PackedFloat64Array, fraction: float) -> float:
	return samples[floori((samples.size() - 1) * fraction)]


func _finish(start_us: int, waypoints: int) -> void:
	process_frame.disconnect(_sample_frame)
	if _frame_times_ms.is_empty():
		printerr("Ranwar finished without measuring rendered frame intervals.")
		quit(1)
		return
	_frame_times_ms.sort()
	_physics_times_ms.sort()
	_draw_call_samples.sort()
	var elapsed_s := float(Time.get_ticks_usec() - start_us) / 1000000.0
	print("RANWAR_ROUTE_BENCHMARK ", JSON.stringify({
		"waypoints": waypoints,
		"elapsed_s": elapsed_s,
		"viewport_width": int(root.size.x),
		"viewport_height": int(root.size.y),
		"fps_cap": Engine.max_fps,
		"physics_hz": Engine.physics_ticks_per_second,
		"simulation_time_scale": Engine.time_scale,
		"scene_setup_ms": _scene_setup_ms,
		"ambient_vehicles": 0,
		"stream_visual_chunks": "--stream-visual-chunks" in OS.get_cmdline_user_args(),
		"min_sampled_active_visual_meshes": _min_active_visual_meshes,
		"visual_residency": _world.visual_residency_stats(),
		"frames": _frame_times_ms.size(),
		"mean_fps": float(_frame_times_ms.size()) / elapsed_s,
		"frame_ms_p50": _percentile(_frame_times_ms, 0.50),
		"frame_ms_p95": _percentile(_frame_times_ms, 0.95),
		"frame_ms_p99": _percentile(_frame_times_ms, 0.99),
		"frame_ms_max": _worst_frame_ms,
		"worst_frame_waypoint": _worst_frame_waypoint,
		"worst_frame_position_m": [_worst_frame_position.x, _worst_frame_position.y, _worst_frame_position.z],
		"frames_over_100_ms": _stalls_over_100_ms,
		"engine_physics_windows": _physics_times_ms.size(),
		"engine_physics_1s_peak_ms_p95": _percentile(_physics_times_ms, 0.95) if not _physics_times_ms.is_empty() else null,
		"engine_peak_allocated_mib": OS.get_static_memory_peak_usage() / 1048576.0,
		"sampled_engine_allocated_mib_max": _peak_steady_allocated_bytes / 1048576.0,
		"sampled_live_nodes_max": _peak_nodes,
		"sampled_render_objects_max": _peak_render_objects,
		"sampled_draw_calls_p95": _percentile(_draw_call_samples, 0.95) if not _draw_call_samples.is_empty() else null,
	}))
	quit()
