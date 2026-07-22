extends Camera2D

var intensity := 0.0
var decay := 0.0

func shake(amount: float) -> void:
	intensity = amount
	decay = max(amount * 80.0, 120.0)

func _process(delta: float) -> void:
	if intensity > 0.0:
		offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		intensity = move_toward(intensity, 0.0, delta * decay)
	else:
		offset = Vector2.ZERO
