@tool
extends Control
class_name LetterWaveText

@export var text: String = "TEXT":
	set(v):
		text = v
		_rebuild()
@export var font_size: int = 16
@export var color: Color = Color.WHITE
@export var amplitude: float = 2.0
@export var speed: float = 0.8
@export var wave_length: float = 1.2

var _labels: Array[Label] = []
var _base_y: Array[float] = []
var _time: float = 0.0
var _pulse: float = 0.0
var _preview: Label = null

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return

	if Engine.is_editor_hint():
		_show_preview()
	else:
		_build()

func _show_preview() -> void:
	if _preview:
		_preview.queue_free()
	for lb in _labels:
		lb.queue_free()
	_labels.clear()
	_base_y.clear()

	_preview = Label.new()
	_preview.text = text
	_preview.add_theme_color_override("font_color", color)
	var base = load("res://fonts/PressStart2P-Regular.ttf")
	if base:
		var ls := LabelSettings.new()
		ls.font = base
		ls.font_size = font_size
		ls.outline_size = 1
		ls.outline_color = Color.BLACK
		_preview.label_settings = ls
	else:
		_preview.add_theme_font_size_override("font_size", font_size)
	add_child(_preview)
	custom_minimum_size = _preview.get_combined_minimum_size()

func _build() -> void:
	for lb in _labels:
		lb.queue_free()
	if _preview:
		_preview.queue_free()
		_preview = null
	_labels.clear()
	_base_y.clear()

	var base = load("res://fonts/PressStart2P-Regular.ttf")
	var ls: LabelSettings
	if base:
		ls = LabelSettings.new()
		ls.font = base
		ls.font_size = font_size
		ls.outline_size = 1
		ls.outline_color = Color.BLACK

	var x: float = 0.0
	var y: float = 0.0
	for i in text.length():
		var ch = text[i]
		if ch == "\n":
			x = 0.0
			y += font_size * 1.3
			continue
		var lb := Label.new()
		lb.text = ch
		if ls:
			lb.label_settings = ls
		lb.add_theme_color_override("font_color", color)
		lb.position = Vector2(x, y)
		add_child(lb)
		_labels.append(lb)
		_base_y.append(y)
		x += lb.get_combined_minimum_size().x

	custom_minimum_size = Vector2(x, y + font_size * 1.3)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta * speed
	if _pulse > 0:
		_pulse = max(0.0, _pulse - delta * 3.0)
	var amp = amplitude + _pulse
	for i in _labels.size():
		var offset = sin(_time + i * wave_length) * amp
		_labels[i].position.y = _base_y[i] + offset

func pulse(extra_amp: float = 3.0) -> void:
	_pulse = extra_amp

func set_text_color(c: Color) -> void:
	color = c
	for lb in _labels:
		lb.add_theme_color_override("font_color", c)
