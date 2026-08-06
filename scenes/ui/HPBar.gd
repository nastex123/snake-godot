extends ColorRect
class_name HPBar

@onready var fill: ColorRect = $HPFill
@onready var delay_bar: ColorRect = $HPDelay

var _target_ratio: float = 1.0

func set_hp(current: float, max_hp: float) -> void:
	_target_ratio = max(0.0, current / max_hp)
	_animate()

func _animate() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(fill, "scale", Vector2(_target_ratio, 1), 0.15)

	var tw2: Tween = create_tween()
	tw2.tween_interval(0.3)
	tw2.tween_property(delay_bar, "scale", Vector2(_target_ratio, 1), 0.3)
