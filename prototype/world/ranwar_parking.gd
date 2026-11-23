extends RefCounted

# Bays are on the paved handling yard and the Hill Road setback. The three
# stop bays are west of the shelter and leave the bus approach clear.
const YARD_SLOTS := [
	Vector2(-48, -15), Vector2(-40, -15), Vector2(-32, -15),
	Vector2(-24, -15), Vector2(-16, -15), Vector2(-8, -15),
	Vector2(-48, -24), Vector2(-40, -24), Vector2(-24, -24),
	Vector2(-16, -24), Vector2(-8, -24), Vector2(-47, -33),
	Vector2(-40, -33), Vector2(-20, -33)
]
const FIRST_YARD_COUNT := 9


static func plan(arrival: Vector3, yaw: float, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var lot_indices := _indices(YARD_SLOTS.size(), rng)
	var result: Array[Transform3D] = []
	for index in FIRST_YARD_COUNT:
		var lot: Vector2 = YARD_SLOTS[lot_indices[index]]
		var heading := 0.0 if rng.randi_range(0, 1) == 0 else PI
		result.append(Transform3D(Basis(Vector3.UP, heading), Vector3(lot.x, 0.55, lot.y)))
	var west := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	var church_side := Vector3(west.z, 0.0, -west.x)
	for bay_index in _indices(3, rng):
		var spot := arrival + west * (13.0 + 7.0 * bay_index) + church_side * 2.85
		spot.y = 0.55
		result.append(Transform3D(Basis(Vector3.UP, yaw), spot))
	return result


static func _indices(count: int, rng: RandomNumberGenerator) -> Array[int]:
	var order: Array[int] = []
	for index in count:
		order.append(index)
	for index in range(count - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var previous := order[index]
		order[index] = order[other]
		order[other] = previous
	return order
