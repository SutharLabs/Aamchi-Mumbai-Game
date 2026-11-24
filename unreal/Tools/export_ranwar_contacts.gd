extends SceneTree
## Export both original contacts with their quiet idle and handover motion.

const Visual := preload("res://character/locomotion_visual.gd")
const ContactMotion := preload("res://character/parcel_contact_motion.gd")
const CONTACTS := {
	"Ravi": Color("786859"),
	"Kavita": Color("567c75"),
}


func _initialize() -> void:
	_export.call_deferred()


func _export() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or not arguments[0].is_absolute_path():
		printerr("Pass one absolute contact output directory after --.")
		quit(ERR_INVALID_PARAMETER)
		return
	var target := arguments[0]
	var result := DirAccess.make_dir_recursive_absolute(target)
	for name: String in CONTACTS:
		if result != OK:
			break
		result = _write_contact(target, name)
	if result != OK:
		printerr("Ranwar contacts exchange failed: ", error_string(result))
	quit(result)


func _write_contact(target: String, name: String) -> Error:
	var actor := Visual.new()
	var receiving := name == "Kavita"
	actor.name = name
	actor.face_variant = name
	actor.shirt_color = CONTACTS[name]
	actor.wears_overshirt = not receiving
	actor.wears_kurta_with_dupatta = receiving
	actor.kurta_hair_style = 1 if receiving else 0
	root.add_child(actor)
	var library := ContactMotion.create_library(actor, receiving)
	var player := actor.animation_player
	player.stop()
	player.remove_animation_library(&"")
	player.remove_animation_library(&"impacts")
	player.add_animation_library(&"", library)
	for bone in actor.skeleton.get_bone_count():
		actor.skeleton.reset_bone_pose(bone)

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_scene(actor, state)
	if result == OK:
		var path := target.path_join(name + ".glb")
		result = document.write_to_filesystem(state, path)
		if result == OK:
			print("Exported ", name, " with skinned breath and gesture clips to ", path)
	actor.free()
	return result
