extends Node3D
## Bounded residency for the procedural background frontage meshes.

const CHUNK_SIZE := 96.0
const LOAD_DISTANCE := 160.0
const UNLOAD_DISTANCE := 224.0
const REFRESH_INTERVAL := 0.20


class ChunkVisual:
	var label: String
	var pose: Transform3D
	var size: Vector3
	var material: Material
	var mesh: Mesh


class Chunk:
	var bounds: Rect2
	var visuals: Array[ChunkVisual] = []
	var node: Node3D


var _chunks: Dictionary[Vector2i, Chunk] = {}
var _streaming := false
var _total_meshes := 0
var _active_chunks := 0
var _active_meshes := 0
var _peak_active_meshes := 0
var _loads := 0
var _unloads := 0
var _last_focus := Vector2.ZERO
var _time_until_refresh := REFRESH_INTERVAL


func register_box(anchor: Vector3, label: String, at: Vector3, size: Vector3, yaw: float, material: Material) -> void:
	var visual := ChunkVisual.new()
	visual.label = label
	visual.pose = Transform3D(Basis(Vector3.UP, yaw), at)
	visual.size = size
	visual.material = material
	_register_visual(anchor, visual)


func register_mesh(anchor: Vector3, label: String, pose: Transform3D, mesh: Mesh) -> void:
	var visual := ChunkVisual.new()
	visual.label = label
	visual.pose = pose
	visual.mesh = mesh
	_register_visual(anchor, visual)


func _register_visual(anchor: Vector3, visual: ChunkVisual) -> void:
	var cell := Vector2i(floori(anchor.x / CHUNK_SIZE), floori(anchor.z / CHUNK_SIZE))
	if not _chunks.has(cell):
		var chunk := Chunk.new()
		chunk.bounds = Rect2(Vector2(cell) * CHUNK_SIZE, Vector2.ONE * CHUNK_SIZE)
		_chunks[cell] = chunk
	_chunks[cell].visuals.append(visual)
	_total_meshes += 1


func start(streaming: bool, initial_focus: Vector3) -> void:
	_streaming = streaming
	set_process(streaming)
	if streaming:
		_refresh(Vector2(initial_focus.x, initial_focus.z), true)
	else:
		for cell: Vector2i in _chunks:
			_load_chunk(cell)


func stats() -> Dictionary:
	return {
		"mode": "streamed" if _streaming else "resident",
		"total_chunks": _chunks.size(),
		"active_chunks": _active_chunks,
		"total_meshes": _total_meshes,
		"active_meshes": _active_meshes,
		"peak_active_meshes": _peak_active_meshes,
		"loads": _loads,
		"unloads": _unloads,
	}


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var local_focus := to_local(camera.global_position)
	var focus := Vector2(local_focus.x, local_focus.z)
	# A reset or camera cut needs its nearby assets on the next render frame.
	var camera_cut := focus.distance_squared_to(_last_focus) >= CHUNK_SIZE * CHUNK_SIZE * 0.25
	_time_until_refresh -= delta
	if camera_cut or _time_until_refresh <= 0.0:
		_refresh(focus, camera_cut)
		_time_until_refresh = REFRESH_INTERVAL


func _refresh(focus: Vector2, immediate: bool) -> void:
	_last_focus = focus
	var nearest: Chunk
	var nearest_cell := Vector2i.ZERO
	var nearest_distance := LOAD_DISTANCE * LOAD_DISTANCE
	for cell: Vector2i in _chunks:
		var chunk := _chunks[cell]
		var closest := focus.clamp(chunk.bounds.position, chunk.bounds.end)
		var distance := focus.distance_squared_to(closest)
		if chunk.node != null:
			if distance > UNLOAD_DISTANCE * UNLOAD_DISTANCE:
				_unload_chunk(chunk)
		elif distance <= LOAD_DISTANCE * LOAD_DISTANCE:
			if immediate:
				_load_chunk(cell)
			elif nearest == null or distance < nearest_distance:
				nearest = chunk
				nearest_cell = cell
				nearest_distance = distance
	if nearest != null:
		_load_chunk(nearest_cell)


func _load_chunk(cell: Vector2i) -> void:
	var chunk := _chunks[cell]
	var group := Node3D.new()
	group.name = "VisualChunk_%d_%d" % [cell.x, cell.y]
	for visual: ChunkVisual in chunk.visuals:
		var instance := MeshInstance3D.new()
		instance.name = visual.label
		instance.transform = visual.pose
		if visual.mesh != null:
			instance.mesh = visual.mesh
		else:
			var mesh := BoxMesh.new()
			mesh.size = visual.size
			instance.mesh = mesh
			instance.material_override = visual.material
		group.add_child(instance)
	add_child(group)
	chunk.node = group
	_loads += 1
	_active_chunks += 1
	_active_meshes += chunk.visuals.size()
	_peak_active_meshes = maxi(_peak_active_meshes, _active_meshes)


func _unload_chunk(chunk: Chunk) -> void:
	remove_child(chunk.node)
	chunk.node.queue_free()
	chunk.node = null
	_unloads += 1
	_active_chunks -= 1
	_active_meshes -= chunk.visuals.size()
