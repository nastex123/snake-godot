extends Control
class_name NotificationSystem

const POOL_SIZE := 8
const CARD_W := 150
const CARD_H := 30
const STACK_GAP := 34
const ENTRY_DUR := 0.25
const SHINE_DELAY := 0.2
const SHINE_DUR := 0.3
const VISIBLE_DUR := 1.0
const EXIT_DUR := 0.3

var _pool: Array[Control] = []
var _active: Array[Control] = []

func _ready() -> void:
	for i in POOL_SIZE:
		_pool.append(_create_card())

func _create_card() -> Control:
	var c = Control.new()
	c.size = Vector2(CARD_W, CARD_H)
	c.clip_contents = true

	var bg = ColorRect.new()
	bg.size = Vector2(CARD_W, CARD_H)
	bg.color = Color(0, 0, 0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(bg)

	var accent = ColorRect.new()
	accent.name = "accent"
	accent.size = Vector2(3, CARD_H)
	c.add_child(accent)

	var icon = Label.new()
	icon.name = "icon"
	icon.add_theme_font_size_override("font_size", 14)
	icon.position = Vector2(12, 4)
	icon.size = Vector2(20, 22)
	c.add_child(icon)

	var lbl = Label.new()
	lbl.name = "lbl"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.position = Vector2(34, 5)
	lbl.size = Vector2(100, 20)
	c.add_child(lbl)

	var shine = ColorRect.new()
	shine.name = "shine"
	shine.size = Vector2(20, 50)
	shine.color = Color(1, 1, 1, 0.35)
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.rotation = 0.6
	c.add_child(shine)

	c.visible = false
	add_child(c)
	return c

func notify(text: String, icon_text: String, accent_color: Color) -> void:
	var card = _get_from_pool()
	if not card:
		return

	card.get_node("icon").text = icon_text
	card.get_node("icon").add_theme_color_override("font_color", accent_color)
	card.get_node("lbl").text = text
	card.get_node("accent").color = accent_color

	var base_y = size.y - 50
	var idx = _active.size()
	card.position = Vector2(-CARD_W, base_y - idx * STACK_GAP)
	card.modulate = Color(1, 1, 1, 0)
	card.visible = true
	_active.append(card)

	var tw = card.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "position:x", 8.0, ENTRY_DUR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate", Color.WHITE, 0.15)

	var shine = card.get_node("shine")
	shine.position = Vector2(-30, -10)
	var tw2 = card.create_tween()
	tw2.tween_interval(SHINE_DELAY)
	tw2.tween_property(shine, "position:x", 180.0, SHINE_DUR)

	var tw3 = card.create_tween()
	tw3.tween_interval(SHINE_DELAY + SHINE_DUR + VISIBLE_DUR)
	tw3.tween_callback(_start_exit.bind(card))

func _get_from_pool() -> Control:
	if _pool.is_empty():
		return null
	return _pool.pop_back()

func _start_exit(card: Control) -> void:
	var tw = card.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "position:x", -CARD_W, EXIT_DUR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(card, "modulate:a", 0.0, EXIT_DUR * 0.8)
	tw.tween_callback(_return_to_pool.bind(card))

func _return_to_pool(card: Control) -> void:
	card.visible = false
	_active.erase(card)
	_pool.append(card)
	_reposition()

func _reposition() -> void:
	var base_y = size.y - 50
	for i in _active.size():
		var target_y = base_y - i * STACK_GAP
		var tw = _active[i].create_tween()
		tw.tween_property(_active[i], "position:y", target_y, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
