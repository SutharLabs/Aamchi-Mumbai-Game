extends RefCounted
## Original contemporary Indian-market vehicle families, sharing the existing drivable rigs.

const Vehicle := preload("res://vehicle/phase1_vehicle.gd")
const Car := preload("res://vehicle/phase1_car.gd")
const Rickshaw := preload("res://vehicle/phase1_rickshaw.gd")
const Motorcycle := preload("res://vehicle/phase1_motorcycle.gd")
const Scooter := preload("res://vehicle/phase1_scooter.gd")


static func create(kind: StringName) -> Vehicle:
	match kind:
		&"hatch":
			return Car.new()
		&"sedan":
			return Car.new(false, Car.BodyStyle.SEDAN)
		&"suv":
			return Car.new(false, Car.BodyStyle.SUV)
		&"mpv":
			return Car.new(false, Car.BodyStyle.MPV)
		&"rickshaw":
			return Rickshaw.new()
		&"commuter":
			return Motorcycle.new()
		&"classic":
			return Motorcycle.new(Motorcycle.BodyStyle.CLASSIC)
		&"roadster":
			return Motorcycle.new(Motorcycle.BodyStyle.ROADSTER)
		&"scrambler":
			return Motorcycle.new(Motorcycle.BodyStyle.SCRAMBLER)
		&"scooter":
			return Scooter.new()
		&"electric_scooter":
			return Scooter.new(true)
	push_error("Unknown Ranwar vehicle: %s" % kind)
	return null
