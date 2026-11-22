extends Control

signal play_requested
signal resume_requested
signal main_menu_requested
signal quit_requested

const BACKDROP := "res://startup/art/mumbai-dusk.webp"
const MARK := "res://startup/art/amg-mark.png"
const DEVANAGARI := "res://startup/art/NotoSansDevanagari.ttf"
const CREDITS := "res://startup/credits_data.gd"
const NAVY := Color("0c1725")
const PANEL := Color("182638")
const BORDER := Color("405268")
const CREAM := Color("f9f1e3")
const MUTED := Color("bfc9d4")
const GOLD := Color("f3c684")

var preferences: Node
var _paused_menu := false
var _page: StringName = &"top"
var _canvas: ColorRect
var _art: TextureRect
var _shade: TextureRect
var _scroll: ScrollContainer
var _content: VBoxContainer
var _notice: Label
var _profile_name: LineEdit
var _volume: HSlider
var _look: HSlider
var _fullscreen: CheckButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()
	_canvas = ColorRect.new()
	_canvas.color = NAVY
	_add_backdrop(_canvas)
	_art = TextureRect.new()
	_art.texture = _read_texture(BACKDROP)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_add_backdrop(_art)
	_shade = TextureRect.new()
	_shade.texture = _make_shade()
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_add_backdrop(_shade)
	_scroll = ScrollContainer.new()
	_scroll.name = "MenuScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.scroll_deadzone = 10
	add_child(_scroll)
	resized.connect(_position_content)
	show_home()


func show_home() -> void:
	_paused_menu = false
	show()
	_show_page(&"top")


func show_pause() -> void:
	_paused_menu = true
	show()
	_show_page(&"top")


func back_requested() -> bool:
	if not is_visible_in_tree() or _page == &"top":
		return false
	_show_page(&"top")
	return true


func _show_page(page: StringName) -> void:
	_page = page
	_canvas.color = Color(0.03, 0.06, 0.10, 0.68) if _paused_menu else NAVY
	_art.visible = not _paused_menu
	if is_instance_valid(_content):
		_scroll.remove_child(_content)
		_content.queue_free()
	_content = VBoxContainer.new()
	_content.name = "Page"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_content.alignment = BoxContainer.ALIGNMENT_CENTER if page == &"top" else BoxContainer.ALIGNMENT_BEGIN
	_scroll.add_child(_content)
	_scroll.set_deferred("scroll_vertical", 0)
	_position_content()
	match page:
		&"profiles": _show_profiles()
		&"settings": _show_settings()
		&"credits": _show_credits()
		_: _show_top()


func _show_top() -> void:
	if _paused_menu:
		_label(_content, "Paused", 54, CREAM)
		_label(_content, "Playing as %s" % preferences.active_profile_name, 19, MUTED).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_space(_content, 12)
		_focus.call_deferred(_button(_content, "ResumeButton", "Resume", func(): resume_requested.emit(), true))
		_route_button("SettingsButton", "Settings", &"settings")
		_route_button("CreditsButton", "Credits", &"credits")
		_button(_content, "MainMenuButton", "Main menu", func(): main_menu_requested.emit())
		return
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 15)
	_content.add_child(identity)
	var mark := TextureRect.new()
	mark.texture = _read_texture(MARK)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(58, 58)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mark.texture != null:
		identity.add_child(mark)
	else:
		mark.free()
	_label(identity, "RANWAR, BANDRA WEST", 16, GOLD)
	var title := _label(_content, "Aamchi\nMumbai Game", 57, CREAM)
	title.add_theme_font_override("font", _display_font())
	title.add_theme_constant_override("line_spacing", -7)
	var name_meaning := HBoxContainer.new()
	name_meaning.add_theme_constant_override("separation", 15)
	_content.add_child(name_meaning)
	if ResourceLoader.exists(DEVANAGARI, "Font"):
		var marathi := _label(name_meaning, "आमची मुंबई", 24, GOLD)
		marathi.add_theme_font_override("font", load(DEVANAGARI) as Font)
	_label(name_meaning, "Our Mumbai", 20, GOLD)
	_label(_content, "Playing as %s" % preferences.active_profile_name, 17, MUTED).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_space(_content, 7)
	_focus.call_deferred(_button(_content, "PlayButton", "Play", func(): play_requested.emit(), true))
	_route_button("ProfilesButton", "Profiles", &"profiles")
	_route_button("SettingsButton", "Settings", &"settings")
	_route_button("CreditsButton", "Credits", &"credits")
	_button(_content, "QuitButton", "Quit", func(): quit_requested.emit())


func _show_profiles() -> void:
	_page_header("Profiles")
	_label(_content, "Active profile", 19, MUTED)
	var selector := OptionButton.new()
	selector.name = "ProfileSelector"
	selector.custom_minimum_size.y = 50
	selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_button(selector)
	var active_index := 0
	for profile: Dictionary in preferences.profiles:
		if String(profile["id"]) == preferences.active_profile_id:
			active_index = selector.item_count
		selector.add_item(String(profile["name"]))
	selector.select(active_index)
	selector.item_selected.connect(_select_profile)
	_content.add_child(selector)
	_space(_content, 5)
	_label(_content, "Profile name", 19, MUTED)
	_profile_name = LineEdit.new()
	_profile_name.name = "ProfileNameInput"
	_profile_name.placeholder_text = "Enter a name"
	_profile_name.max_length = 32
	_profile_name.custom_minimum_size.y = 50
	_profile_name.clear_button_enabled = true
	_content.add_child(_profile_name)
	_button(_content, "CreateProfileButton", "Create profile", _create_profile, true)
	_button(_content, "RenameProfileButton", "Rename active profile", _rename_profile)
	_notice = _label(_content, "", 17, GOLD)
	_back_button()
	_focus.call_deferred(selector)


func _select_profile(index: int) -> void:
	var profile: Dictionary = preferences.profiles[index]
	var result: Error = preferences.select_profile(String(profile["id"]))
	_show_page(&"profiles")
	_notice.text = "Profile selected." if result == OK else _profile_error(result)


func _create_profile() -> void:
	var result: Error = preferences.create_profile(_profile_name.text)
	if result == OK:
		_show_page(&"profiles")
	_notice.text = "Profile created." if result == OK else _profile_error(result)


func _rename_profile() -> void:
	var result: Error = preferences.rename_profile(preferences.active_profile_id, _profile_name.text)
	if result == OK:
		_show_page(&"profiles")
	_notice.text = "Profile renamed." if result == OK else _profile_error(result)


func _profile_error(result: Error) -> String:
	match result:
		ERR_INVALID_PARAMETER: return "Enter a valid name of up to 32 characters."
		ERR_ALREADY_EXISTS: return "A profile already uses that name."
		ERR_OUT_OF_MEMORY: return "This device has reached its profile limit."
		_: return "The profile change could not be saved."


func _show_settings() -> void:
	_page_header("Settings")
	_volume = _slider("MasterVolumeSlider", "Master volume", 0.0, 1.0, 0.01, preferences.master_volume, true)
	_look = _slider("LookSensitivitySlider", "Camera sensitivity", 0.25, 2.0, 0.05, preferences.look_sensitivity, false)
	_fullscreen = CheckButton.new()
	_fullscreen.name = "FullscreenToggle"
	_fullscreen.text = "Fullscreen"
	_fullscreen.custom_minimum_size.y = 48
	_fullscreen.button_pressed = preferences.fullscreen
	_fullscreen.disabled = not preferences.supports_fullscreen
	_content.add_child(_fullscreen)
	_notice = _label(_content, "", 17, GOLD)
	_button(_content, "ApplySettingsButton", "Apply settings", _apply_settings, true)
	_back_button()
	_focus.call_deferred(_volume)


func _apply_settings() -> void:
	var result: Error = preferences.set_settings(_volume.value, _fullscreen.button_pressed, _look.value)
	_notice.text = "Settings saved." if result == OK else "Settings could not be saved."


func _slider(node_name: String, caption: String, minimum: float, maximum: float, step: float, value: float, percent: bool) -> HSlider:
	var row := HBoxContainer.new()
	_content.add_child(row)
	_label(row, caption, 20, CREAM).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var readout := _label(row, _setting_value(value, percent), 18, GOLD)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size.y = 42
	slider.value_changed.connect(func(updated: float): readout.text = _setting_value(updated, percent))
	_content.add_child(slider)
	return slider


func _setting_value(value: float, percent: bool) -> String:
	return "%d%%" % roundi(value * 100.0) if percent else "%.2f×" % value


func _show_credits() -> void:
	_page_header("Credits")
	var back := _back_button()
	if not ResourceLoader.exists(CREDITS):
		_label(_content, "Credit information is unavailable.", 18, MUTED)
		_focus.call_deferred(back)
		return
	var credit_data: Script = load(CREDITS)
	var sections: Array = credit_data.get_script_constant_map()[&"SECTIONS"]
	for section: Dictionary in sections:
		_space(_content, 5)
		_label(_content, String(section["title"]), 21, GOLD)
		var paragraph := _label(_content, String(section["body"]), 17, CREAM)
		paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for item: Dictionary in section.get("links", []):
			var address := String(item["url"])
			# Credits use authored external web URLs. No user data is passed to the shell.
			if address.begins_with("https://"):
				_button(_content, "CreditLink", String(item["label"]), _open_credit.bind(address))
	_notice = _label(_content, "", 17, GOLD)
	_focus.call_deferred(back)


func _open_credit(address: String) -> void:
	var result := OS.shell_open(address)
	_notice.text = "" if result == OK else "The link could not be opened."


func _page_header(caption: String) -> void:
	_label(_content, "AAMCHI MUMBAI GAME", 16, GOLD)
	var title := _label(_content, caption, 49, CREAM)
	title.add_theme_font_override("font", _display_font())
	_space(_content, 7)


func _back_button() -> Button:
	return _button(_content, "BackButton", "Back", func(): _show_page(&"top"))


func _route_button(node_name: String, caption: String, page: StringName) -> void:
	_button(_content, node_name, caption, _show_page.bind(page))


func _focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()


func _button(parent: Control, node_name: String, caption: String, handler: Callable, primary := false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.custom_minimum_size.y = 48
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(button, primary)
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _label(parent: Control, caption: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _space(parent: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)


func _position_content() -> void:
	var left := clampf(size.x * 0.052, 22.0, 80.0)
	var top := clampf(size.y * 0.063, 16.0, 48.0)
	var preferred_width := 460.0 if _page == &"top" else 510.0
	_scroll.position = Vector2(left, top)
	_scroll.size = Vector2(minf(preferred_width, size.x - left * 2.0), size.y - top * 2.0)


func _add_backdrop(backdrop: Control) -> void:
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _read_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null


func _make_shade() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.36, 0.65, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.035, 0.067, 0.109, 0.99), Color(0.035, 0.067, 0.109, 0.96),
		Color(0.035, 0.067, 0.109, 0.31), Color(0.035, 0.067, 0.109, 0.06),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 2
	return texture


func _display_font() -> FontVariation:
	var type := FontVariation.new()
	type.base_font = ThemeDB.fallback_font
	type.variation_embolden = 0.8
	return type


func _make_theme() -> Theme:
	var skin := Theme.new()
	skin.default_font_size = 20
	skin.set_color("font_color", "Label", CREAM)
	skin.set_color("font_color", "LineEdit", CREAM)
	skin.set_color("font_placeholder_color", "LineEdit", MUTED)
	skin.set_stylebox("normal", "LineEdit", _panel(PANEL, BORDER))
	skin.set_stylebox("focus", "LineEdit", _panel(Color.TRANSPARENT, GOLD, 2))
	skin.set_stylebox("slider", "HSlider", _panel(PANEL, BORDER))
	skin.set_stylebox("grabber_area", "HSlider", _panel(Color("a7804e"), Color("a7804e")))
	skin.set_stylebox("grabber_area_highlight", "HSlider", _panel(GOLD, GOLD))
	return skin


func _style_button(button: Button, primary := false) -> void:
	var normal := GOLD if primary else PANEL
	var edge := Color("f8d9a7") if primary else BORDER
	var text := Color("1b1410") if primary else CREAM
	var hover := Color("ffdda7") if primary else Color("28405a")
	button.add_theme_stylebox_override("normal", _panel(normal, edge))
	button.add_theme_stylebox_override("hover", _panel(hover, GOLD))
	button.add_theme_stylebox_override("pressed", _panel(hover.darkened(0.09), GOLD))
	button.add_theme_stylebox_override("focus", _panel(Color.TRANSPARENT, Color("fff0c9"), 2))
	for style: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(style, text)


func _panel(fill: Color, edge: Color, width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	return style
