extends Label

const WORDS := {
	1: ["NICE!", "GOOD!", "YUM!"],
	2: ["COOL!", "SWEET!", "TASTY!"],
	3: ["GREAT!", "WOW!", "CLEAN!"],
	4: ["AWESOME!", "EPIC!", "SICK!"],
	5: ["INCREDIBLE!", "UNSTOPPABLE!", "GODLIKE!"],
}

var TILE_SIZE := 24.0

static func random_word(streak_level: int) -> String:
	var pool: Array = WORDS[clamp(streak_level, 1, 5)]
	return pool[randi() % pool.size()]

func play(cell_pos: Vector2, color: Color, streak_level: int) -> void:
	text = random_word(streak_level)
	modulate = Color(color.r, color.g, color.b, 0)
	position = cell_pos * TILE_SIZE + Vector2(12, -8)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var font_size := 20 + streak_level * 2
	add_theme_font_size_override("font_size", font_size)

	var float_duration := 0.7 + streak_level * 0.08
	var pop_scale := 1.0 + streak_level * 0.04
	var rise := 48.0 + streak_level * 4.0

	scale = Vector2.ZERO

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", color, 0.04)
	tween.tween_property(self, "position", position + Vector2(0, -rise), float_duration)
	tween.parallel().tween_property(self, "modulate", Color(color.r, color.g, color.b, 0), float_duration * 0.3).set_delay(float_duration * 0.7)

	var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(self, "scale", Vector2(pop_scale, pop_scale), 0.1)
	pop.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)

	await tween.finished
	queue_free()
