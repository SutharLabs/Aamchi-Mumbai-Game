extends Control
## Profile appearance editor with a lightweight, isolated 3D preview.

signal applied(options: Dictionary)
signal closed

const AvatarStyle := preload("res://startup/avatar_style.gd")
const Actor := preload("res://character/locomotion_visual.gd")
const BACKDROP := preload("res://startup/art/mumbai-dusk.webp")
const NAVY := Color("0c1725")
const PANEL := Color("182638")
const BORDER := Color("405268")
const CREAM := Color("f9f1e3")
const MUTED := Color("bfc9d4")
const GOLD := Color("f3c684")
const ERROR := Color("f4a88f")

var _selection := AvatarStyle.DEFAULT.duplicate()
var _margins: MarginContainer
var _layout: BoxContainer
var _page: VBoxContainer
var _heading: Label
var _preview_card: PanelContainer
var _preview_turn: Node3D
var _preview_character: Actor
var _preview_name: Label
var _preview_camera: Camera3D
var _preview_zoom: Button
var _close_up := false
var _gender: OptionButton
var _hair: OptionButton
var _outfit: OptionButton
var _notice: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_add_background(art)
	var shade := ColorRect.new()
	shade.color = Color(NAVY, 0.96)
	_add_background(shade)

	var scroll := ScrollContainer.new()
	scroll.name = "CreatorScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.scroll_deadzone = 10
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margins = MarginContainer.new()
	_margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margins.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_margins.add_theme_constant_override("margin_top", 20)
	_margins.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(_margins)
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 14)
	_margins.add_child(_page)

	_heading = _label(_page, "Character creator", 39, CREAM)
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var type := FontVariation.new()
	type.base_font = ThemeDB.fallback_font
	type.variation_embolden = 0.8
	_heading.add_theme_font_override("font", type)

	_layout = BoxContainer.new()
	_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout.add_theme_constant_override("separation", 20)
	_page.add_child(_layout)
	_build_preview()
	_build_choices()
	resized.connect(_arrange.call_deferred)
	_arrange()
	_sync_controls()
	_gender.grab_focus.call_deferred()


func configure(initial: Dictionary) -> void:
	_selection = AvatarStyle.normalize(initial)
	if is_node_ready():
		_sync_controls()


func show_error(message: String) -> void:
	_notice.text = message
	_notice.show()


func dismiss_popup() -> bool:
	for choice: OptionButton in [_gender, _hair, _outfit]:
		var popup := choice.get_popup()
		if popup.visible:
			popup.hide()
			return true
	return false


func _add_background(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _arrange() -> void:
	_layout.vertical = size.x < 760.0
	_heading.add_theme_font_size_override("font_size", 33 if size.x < 410.0 else 39)
	_preview_card.custom_minimum_size.y = 430.0 if _layout.vertical else 475.0
	for edge: String in ["left", "right"]:
		_margins.add_theme_constant_override("margin_" + edge, 16 if _layout.vertical else 30)


func _build_preview() -> void:
	_preview_card = _card(Color("192637"))
	_preview_card.size_flags_stretch_ratio = 1.48
	_layout.add_child(_preview_card)
	var contents := _column(_preview_card, 11)
	_preview_name = _label(contents, "", 23, CREAM)
	_preview_name.name = "PreviewName"

	var display := SubViewportContainer.new()
	display.name = "CharacterPreview"
	display.stretch = true
	display.stretch_shrink = 1
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.custom_minimum_size = Vector2(0, 315)
	contents.add_child(display)

	var viewport := SubViewport.new()
	viewport.name = "PreviewViewport"
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.gui_disable_input = true
	if not OS.has_feature("mobile"):
		viewport.msaa_3d = Viewport.MSAA_2X
	display.add_child(viewport)

	var scene := Node3D.new()
	viewport.add_child(scene)
	var studio := WorldEnvironment.new()
	studio.environment = Environment.new()
	studio.environment.background_mode = Environment.BG_COLOR
	studio.environment.background_color = Color("27384c")
	studio.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	studio.environment.ambient_light_color = Color("d8e0f0")
	studio.environment.ambient_light_energy = 0.62
	scene.add_child(studio)
	_light(scene, Color("fff0d7"), 0.95, Vector3(-33, 148, 0))
	_light(scene, Color("c4dafb"), 0.55, Vector3(-25, -142, 0))
	_light(scene, Color("e8d0ad"), 0.55, Vector3(-36, 22, 0))

	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.55
	disc.height = 0.06
	disc.radial_segments = 40
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("40536a")
	surface.roughness = 0.94
	disc.material = surface
	base.mesh = disc
	base.position.y = -0.03
	scene.add_child(base)

	_preview_turn = Node3D.new()
	_preview_turn.rotation_degrees.y = -18.0
	scene.add_child(_preview_turn)
	_preview_camera = Camera3D.new()
	_preview_camera.fov = 35.0
	scene.add_child(_preview_camera)
	_preview_camera.make_current()

	var turns := HBoxContainer.new()
	turns.add_theme_constant_override("separation", 8)
	contents.add_child(turns)
	var turn_left := _button(turns, "RotateLeftButton", "Turn left", func(): _preview_turn.rotate_y(deg_to_rad(45.0)))
	_preview_zoom = _button(turns, "PreviewZoomButton", "Face view", _toggle_zoom)
	var turn_right := _button(turns, "RotateRightButton", "Turn right", func(): _preview_turn.rotate_y(deg_to_rad(-45.0)))
	for button: Button in [turn_left, _preview_zoom, turn_right]:
		button.add_theme_font_size_override("font_size", 15)
	_set_zoom(false)


func _toggle_zoom() -> void:
	_set_zoom(not _close_up)


func _set_zoom(close_up: bool) -> void:
	_close_up = close_up
	if close_up:
		_preview_camera.position = Vector3(0.0, 1.54, -0.69)
		_preview_camera.look_at(Vector3(0.0, 1.49, 0.0))
		_preview_zoom.text = "Full body"
	else:
		_preview_camera.position = Vector3(0.0, 1.12, -3.35)
		_preview_camera.look_at(Vector3(0.0, 0.81, 0.0))
		_preview_zoom.text = "Face view"


func _build_choices() -> void:
	var panel := _card(PANEL)
	_layout.add_child(panel)
	var controls := _column(panel, 10)
	_gender = _choice(controls, "GenderChoice", "Gender")
	_hair = _choice(controls, "HairChoice", "Hairstyle")
	_outfit = _choice(controls, "OutfitChoice", "Clothing")
	_gender.item_selected.connect(_select.bind("gender", _gender))
	_hair.item_selected.connect(_select.bind("hair", _hair))
	_outfit.item_selected.connect(_select.bind("outfit", _outfit))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	var scope := _label(controls, "Appearance is saved to this profile.", 17, MUTED)
	scope.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice = _label(controls, "", 17, ERROR)
	_notice.name = "SaveError"
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.hide()
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	controls.add_child(actions)
	_button(actions, "BackButton", "Back", func(): closed.emit())
	_button(actions, "ApplyButton", "Apply appearance", func(): applied.emit(_selection.duplicate()), true)


func _sync_controls() -> void:
	_fill(_gender, [{"id": "man", "label": "Man"}, {"id": "woman", "label": "Woman"}], _selection["gender"])
	_fill(_hair, AvatarStyle.hair_choices(_selection["gender"]), _selection["hair"])
	_fill(_outfit, AvatarStyle.outfit_choices(_selection["gender"]), _selection["outfit"])
	_refresh_preview()


func _fill(control: OptionButton, choices: Array, selected: String) -> void:
	control.clear()
	for entry: Dictionary in choices:
		var index := control.item_count
		control.add_item(entry["label"])
		control.set_item_metadata(index, entry["id"])
		if entry["id"] == selected:
			control.select(index)


func _select(index: int, key: String, control: OptionButton) -> void:
	if index < 0 or index >= control.item_count:
		return
	_selection[key] = control.get_item_metadata(index)
	_selection = AvatarStyle.normalize(_selection)
	_notice.hide()
	if key == "gender":
		_fill(_hair, AvatarStyle.hair_choices(_selection["gender"]), _selection["hair"])
		_fill(_outfit, AvatarStyle.outfit_choices(_selection["gender"]), _selection["outfit"])
	_refresh_preview()


func _refresh_preview() -> void:
	if is_instance_valid(_preview_character):
		_preview_turn.remove_child(_preview_character)
		_preview_character.queue_free()
	_preview_name.text = AvatarStyle.character_name(_selection)
	_preview_character = Actor.new()
	_preview_character.name = "PreviewCharacter"
	_preview_character.avatar_options = _selection.duplicate()
	_preview_turn.add_child(_preview_character)


func _light(scene: Node3D, color: Color, energy: float, rotation: Vector3) -> void:
	var light := DirectionalLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.rotation_degrees = rotation
	scene.add_child(light)


func _card(fill: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _box_style(fill, BORDER, 18))
	return card


func _column(parent: Control, spacing: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", spacing)
	parent.add_child(column)
	return column


func _label(parent: Control, value: String, pixels: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _choice(parent: Control, node_name: String, caption: String) -> OptionButton:
	var group := _column(parent, 5)
	_label(group, caption, 18, CREAM)
	var choice := OptionButton.new()
	choice.name = node_name
	choice.custom_minimum_size.y = 52
	choice.add_theme_font_size_override("font_size", 19)
	_style_button(choice)
	var popup := choice.get_popup()
	popup.add_theme_stylebox_override("panel", _box_style(PANEL, BORDER, 9))
	popup.add_theme_stylebox_override("hover", _box_style(Color("324760"), GOLD, 4))
	popup.add_theme_color_override("font_color", CREAM)
	popup.add_theme_font_size_override("font_size", 19)
	popup.add_theme_constant_override("v_separation", 16)
	group.add_child(choice)
	return choice


func _button(parent: Control, node_name: String, caption: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	_style_button(button, primary)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _style_button(button: Button, primary := false) -> void:
	var text := Color("221711") if primary else CREAM
	var normal := GOLD if primary else Color("22364c")
	var hover := Color("ffdda7") if primary else Color("304861")
	button.add_theme_stylebox_override("normal", _box_style(normal, GOLD if primary else BORDER, 11))
	button.add_theme_stylebox_override("hover", _box_style(hover, GOLD, 11))
	button.add_theme_stylebox_override("pressed", _box_style(hover.darkened(0.09), GOLD, 11))
	button.add_theme_stylebox_override("focus", _box_style(Color.TRANSPARENT, CREAM, 11, 2))
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, text)


func _box_style(fill: Color, outline: Color, padding: int, width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = outline
	box.set_border_width_all(width)
	box.set_corner_radius_all(7)
	for edge: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(edge, padding)
	return box
