extends Control
class_name NotificationSystem

const POOL_SIZE := 8
const NOTIFICATION_DURATION := 1.5
const FADE_IN := 0.15
const FADE_OUT := 0.3
const STACK_SPACING := 22.0

var _pool: Array[Label] = []
var _active: Array[Label] = []

func _ready() -> void:
	for i in POOL_SIZE:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.visible = false
		add_child(lbl)
		_pool.append(lbl)

func notify(text: String, color: Color = Color.WHITE) -> void:
	var lbl := _get_from_pool()
	if not lbl:
		return
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.modulate = Color(1, 1, 1, 0)
	lbl.visible = true
	_active.append(lbl)
	_reposition()

	var tw: Tween = create_tween()
	tw.tween_property(lbl, "modulate", Color.WHITE, FADE_IN)
	tw.tween_interval(NOTIFICATION_DURATION)
	tw.tween_property(lbl, "modulate", Color(1, 1, 1, 0), FADE_OUT)
	tw.tween_callback(_return_to_pool.bind(lbl))

func _get_from_pool() -> Label:
	if _pool.is_empty():
		return null
	return _pool.pop_back()

func _return_to_pool(lbl: Label) -> void:
	lbl.visible = false
	_active.erase(lbl)
	_pool.append(lbl)
	_reposition()

func _reposition() -> void:
	var center_x := size.x * 0.5
	var start_y := size.y - 20.0 - (_active.size() - 1) * STACK_SPACING * 0.5
	for i in _active.size():
		var lbl := _active[i]
		lbl.position = Vector2(center_x - lbl.size.x * 0.5, start_y + i * STACK_SPACING)
