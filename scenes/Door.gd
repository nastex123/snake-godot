extends Node2D
class_name Door

var _rect: ColorRect

func _ready() -> void:
	_rect = ColorRect.new()
	_rect.size = Vector2(24, 24)
	_rect.position = Vector2(29 * 24, 9 * 24)
	add_child(_rect)
	set_open(false)

func set_open(open: bool) -> void:
	if open:
		_rect.color = Color(0, 1, 0, 0.3)
		modulate = Color(1, 1, 1, 1)
	else:
		_rect.color = Color(1, 0, 0, 0.3)
		modulate = Color(1, 1, 1, 0.5)
