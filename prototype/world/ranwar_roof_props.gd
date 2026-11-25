extends RefCounted

const Footprints := preload("res://world/ranwar_building_footprints.gd")
const Tank := preload("res://world/props/rooftop_water_tank.glb")
const Condensers := preload("res://world/props/rooftop_condenser_pair.glb")
const PLACEMENTS := {
	360291657: [Tank, Vector2(4.6, 4.0), 1.57],
	360291662: [Condensers, Vector2(-1.8, -2.7), 0.34],
	360291667: [Tank, Vector2(5.0, 3.2), 0.0],
	545621116: [Tank, Vector2(2.5, 4.1), -0.44],
	545621118: [Condensers, Vector2(-1.4, 1.5), 0.0],
	357472313: [Condensers, Vector2(-0.9, 1.6), 0.76],
}


static func add_to(world: Node3D) -> void:
	for site: Array in Footprints.SITES:
		if not PLACEMENTS.has(site[0]):
			continue
		var placement: Array = PLACEMENTS[site[0]]
		var polygon := PackedVector2Array(site[3])
		var center := Vector2.ZERO
		for point: Vector2 in polygon:
			center += point
		center = center / float(polygon.size()) + (placement[1] as Vector2)
		# Leave an inset around the model, including room for its authored rotation.
		var inset := 1.65 if placement[0] == Condensers else 1.25
		if not _fits(polygon, center, inset):
			continue
		center += Footprints.SETBACKS.get(site[0], Vector2.ZERO) as Vector2
		var scene := placement[0] as PackedScene
		var prop := scene.instantiate() as Node3D
		prop.name = "RanwarRoofProp_%d" % site[0]
		prop.position = Vector3(center.x, site[1], center.y)
		prop.rotation.y = placement[2]
		world.add_child(prop)


static func _fits(polygon: PackedVector2Array, center: Vector2, margin: float) -> bool:
	for corner: Vector2 in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		if not Geometry2D.is_point_in_polygon(center + corner * margin, polygon):
			return false
	return true
