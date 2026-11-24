extends Control

const DIRECTORY := "res://shared/dialogue/"
const STANDARD_SIZE := 19
const LARGE_SIZE := 25
const MAX_WIDTH := 680.0

var _lines: Dictionary[String, Dictionary] = {}
var _player := AudioStreamPlayer.new()
var _card := PanelContainer.new()
var _caption := Label.new()
var _speaker := ""
var _line := ""
var _remaining := 0.0
var _enabled := true
var _speaker_names := true
var _touch := false


func _ready() -> void:
	name = "RanwarDialogue"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_player)
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.045, 0.065, 0.073, 0.94)
	backdrop.border_color = Color("956b44")
	backdrop.set_border_width_all(1)
	backdrop.set_corner_radius_all(7)
	backdrop.content_margin_left = 14.0
	backdrop.content_margin_right = 14.0
	backdrop.content_margin_top = 8.0
	backdrop.content_margin_bottom = 8.0
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_stylebox_override("panel", backdrop)
	add_child(_card)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_color_override("font_color", Color("fff5e6"))
	_card.add_child(_caption)
	_card.hide()
	_caption.add_theme_font_size_override("font_size", STANDARD_SIZE)
	resized.connect(_layout)
	_card.resized.connect(_layout)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "lines.json"))
	if data is Array:
		for item: Variant in data:
			if item is Dictionary and item.has_all(["id", "text", "speaker", "duration"]):
				_lines[String(item["id"])] = item
	set_process(false)


func configure(enabled: bool, speaker_names: bool, large: bool, volume: float, touch: bool) -> void:
	_enabled = enabled
	_speaker_names = speaker_names
	_touch = touch
	_caption.add_theme_font_size_override("font_size", LARGE_SIZE if large else STANDARD_SIZE)
	_player.volume_linear = clampf(volume, 0.0, 1.0)
	_refresh()


func speak(id: String) -> float:
	var record: Dictionary = _lines.get(id, {})
	if record.is_empty():
		return 0.0
	_player.stop()
	_speaker = String(record["speaker"])
	_line = String(record["text"])
	_remaining = maxf(float(record["duration"]) + 0.35, 2.0)
	_player.stream = load(DIRECTORY + id + ".wav") as AudioStream
	if _player.stream != null:
		_player.play()
	set_process(true)
	_refresh()
	return _remaining


func stop() -> void:
	_player.stop()
	_remaining = 0.0
	set_process(false)
	_refresh()


func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		stop()


func _refresh() -> void:
	_card.visible = _enabled and _remaining > 0.0
	_caption.text = "%s: %s" % [_speaker, _line] if _speaker_names else _line
	_layout.call_deferred()


func _layout() -> void:
	var width := minf(MAX_WIDTH, maxf(100.0, size.x - 44.0))
	_card.size = Vector2(width, 0.0)
	var bottom := 218.0 if _touch else 74.0
	_card.position = Vector2((size.x - width) * 0.5, maxf(8.0, size.y - bottom - _card.size.y))
