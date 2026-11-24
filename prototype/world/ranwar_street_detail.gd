extends RefCounted
## Original visual-only road repairs and utility covers for the Ranwar road graph.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const TILE_METRES := 128.0
# The road mesh tops out at 0.015 m and the nearby junction pad at 0.012 m.
const ROAD_DETAIL_Y := 0.023
const JUNCTION_CLEARANCE := 12.0
const PATCH_OUTLINE: Array[Vector2] = [
	Vector2(-0.50, -0.34), Vector2(0.26, -0.50), Vector2(0.52, -0.25),
	Vector2(0.49, 0.34), Vector2(0.15, 0.50), Vector2(-0.43, 0.42), Vector2(-0.56, 0.04)
]


class StreetTile:
	var origin: Vector3
	var repairs := SurfaceTool.new()
	var hardware := SurfaceTool.new()
	var has_repairs := false
	var has_hardware := false

	func _init(center: Vector3) -> void:
		origin = center
		for batch: SurfaceTool in [repairs, hardware]:
			batch.begin(Mesh.PRIMITIVE_TRIANGLES)
			batch.set_smooth_group(-1)


static func add_to(world: Node3D, roads: Array[PackedVector3Array], widths: Array[float],
		asphalt: StandardMaterial3D, hardware_material: Material) -> void:
	var tiles: Dictionary[Vector2i, StreetTile] = {}
	var repair_material := asphalt.duplicate() as StandardMaterial3D
	repair_material.vertex_color_use_as_albedo = true
	repair_material.vertex_color_is_srgb = true
	var variation := RandomNumberGenerator.new()
	variation.seed = 20642
	for road_index in roads.size():
		var road := roads[road_index]
		var half_width := widths[road_index] * 0.5
		for segment in range(road.size() - 1):
			var start := road[segment]
			var end := road[segment + 1]
			var length := start.distance_to(end)
			if length <= JUNCTION_CLEARANCE * 2.0:
				continue
			var along := (end - start) / length
			var across := Vector3(-along.z, 0.0, along.x)
			var frame := Basis(along, Vector3.UP, across)
			var side := -1.0 if segment % 2 == 0 else 1.0
			var distance := JUNCTION_CLEARANCE + variation.randf_range(0.0, 5.0)
			while distance < length - JUNCTION_CLEARANCE:
				var roadside := start + along * distance + across * side * (half_width - 0.36)
				var gutter_tile := _tile_at(tiles, roadside)
				_add_grate(gutter_tile.hardware, roadside - gutter_tile.origin, frame)
				gutter_tile.has_hardware = true
				var patch := start + along * (distance + 1.7) + across * side * (half_width - 1.12)
				var road_tile := _tile_at(tiles, patch)
				_add_repair(road_tile.repairs, patch - road_tile.origin, frame,
					Vector2(variation.randf_range(1.5, 3.8), variation.randf_range(0.65, 1.5)),
					variation.randf_range(0.62, 0.82))
				road_tile.has_repairs = true
				distance += variation.randf_range(15.0, 25.0)
				side *= -1.0
			var cover := start.lerp(end, variation.randf_range(0.39, 0.60)) - across * side * half_width * 0.43
			var cover_tile := _tile_at(tiles, cover)
			_add_cover(cover_tile.hardware, cover - cover_tile.origin, frame)
			cover_tile.has_hardware = true
	for key: Vector2i in tiles:
		var tile := tiles[key]
		var holder := Node3D.new()
		holder.name = "RanwarStreetDetail_%d_%d" % [key.x, key.y]
		holder.position = tile.origin
		world.add_child(holder)
		if tile.has_repairs:
			_commit(holder, "AsphaltRepairs", tile.repairs, repair_material)
		if tile.has_hardware:
			_commit(holder, "UtilityHardware", tile.hardware, hardware_material)


static func _tile_at(tiles: Dictionary[Vector2i, StreetTile], point: Vector3) -> StreetTile:
	var key := Vector2i(floori(-point.z / TILE_METRES), floori(-point.x / TILE_METRES))
	if not tiles.has(key):
		var origin := Vector3(-key.y - 0.5, 0.0, -key.x - 0.5) * TILE_METRES
		tiles[key] = StreetTile.new(origin)
	return tiles[key]


static func _add_repair(batch: SurfaceTool, center: Vector3, frame: Basis, size: Vector2,
		tint: float) -> void:
	center.y = ROAD_DETAIL_Y
	var color := Color(tint, tint * 0.99, tint * 0.96)
	for index in PATCH_OUTLINE.size():
		var a := PATCH_OUTLINE[index] * size
		var b := PATCH_OUTLINE[(index + 1) % PATCH_OUTLINE.size()] * size
		Surfaces.add_triangle(batch, center, center + frame * Vector3(a.x, 0.0, a.y),
			center + frame * Vector3(b.x, 0.0, b.y), color, Surfaces.PLAIN)


static func _add_grate(batch: SurfaceTool, center: Vector3, frame: Basis) -> void:
	center.y = ROAD_DETAIL_Y
	Surfaces.add_box(batch, center, Vector3(0.61, 0.012, 0.33), Color("313332"), Surfaces.PLAIN, frame)
	# A concrete surround and dull iron bars make the drain readable from the chase camera.
	for side: float in [-1.0, 1.0]:
		Surfaces.add_box(batch, center + frame * Vector3(0.0, 0.006, side * 0.15),
			Vector3(0.64, 0.008, 0.046), Color("73736a"), Surfaces.CONCRETE, frame)
	for bar in range(-5, 6):
		Surfaces.add_box(batch, center + frame * Vector3(bar * 0.051, 0.007, 0.0),
			Vector3(0.019, 0.004, 0.26), Color("64635c"), Surfaces.PLAIN, frame)


static func _add_cover(batch: SurfaceTool, center: Vector3, frame: Basis) -> void:
	center.y = ROAD_DETAIL_Y
	for ring: Vector2 in [Vector2(0.37, 0.0), Vector2(0.30, 0.005)]:
		var top := center + Vector3.UP * ring.y
		var color := Color("353633") if ring.y == 0.0 else Color("615a50")
		for index in 16:
			var a := TAU * index / 16.0
			var b := TAU * (index + 1) / 16.0
			Surfaces.add_triangle(batch, top, top + frame * Vector3(cos(a), 0.0, sin(a)) * ring.x,
				top + frame * Vector3(cos(b), 0.0, sin(b)) * ring.x, color, Surfaces.PLAIN)
	for rib in range(-2, 3):
		Surfaces.add_box(batch, center + frame * Vector3(0.0, 0.008, rib * 0.077),
			Vector3(0.39, 0.002, 0.014), Color("777064"), Surfaces.PLAIN, frame)


static func _commit(holder: Node3D, label: String, batch: SurfaceTool, material: Material) -> void:
	batch.generate_normals()
	batch.index()
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = batch.commit()
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(visual)
