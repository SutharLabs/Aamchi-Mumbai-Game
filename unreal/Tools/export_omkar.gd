extends SceneTree

const Locomotion := preload("res://character/locomotion_visual.gd")
const CLIPS := [&"idle", &"walk", &"run"]


func _initialize() -> void:
	_export.call_deferred()


func _export() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or not arguments[0].is_absolute_path() or arguments[0].get_extension().to_lower() != "glb":
		printerr("Pass one absolute .glb output path after --.")
		quit(ERR_INVALID_PARAMETER)
		return

	var output := arguments[0]
	var result := DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	if result != OK:
		_fail(result)
		return

	var actor := Locomotion.new()
	actor.name = "Omkar"
	actor.wears_dhotar = true
	root.add_child(actor)
	var animation_player := actor.animation_player
	var locomotion := AnimationLibrary.new()
	for clip: StringName in CLIPS:
		if not animation_player.has_animation(clip):
			printerr("Omkar export is missing the ", clip, " clip.")
			quit(ERR_DOES_NOT_EXIST)
			return
		locomotion.add_animation(clip, animation_player.get_animation(clip))
	animation_player.stop()
	animation_player.remove_animation_library(&"")
	animation_player.remove_animation_library(&"impacts")
	animation_player.add_animation_library(&"", locomotion)
	for index in actor.skeleton.get_bone_count():
		actor.skeleton.reset_bone_pose(index)

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	result = document.append_from_scene(actor, state)
	if result == OK:
		result = document.write_to_filesystem(state, output)
	if result != OK:
		_fail(result)
		return
	print("Exported Omkar, including the current idle, walk, and run clips, to ", output)
	quit(OK)


func _fail(result: Error) -> void:
	printerr("Omkar export failed: ", error_string(result))
	quit(result)
