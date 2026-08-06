extends ColorRect
class_name XPBar

@onready var fill: ColorRect = $XPFill

func set_xp(current: float, max_xp: float) -> void:
	fill.scale.x = max(0.0, current / max_xp)

func animate_level_up() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(fill, "modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.15)
	tw.tween_property(fill, "modulate", Color(0.3, 0.8, 1, 1), 0.2)
