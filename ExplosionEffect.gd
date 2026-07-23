extends Node2D

var TILE_SIZE := 24.0

func play(cell_pos: Vector2, color: Color, streak_level: int) -> void:
	position = cell_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

	var count := 20 + streak_level * 6
	var duration := 0.6 + streak_level * 0.1

	for i in count:
		var s := 4.0 + streak_level * 1.0
		var rect := ColorRect.new()
		rect.size = Vector2(s, s)
		rect.color = color
		rect.position = Vector2(-s / 2, -s / 2)
		add_child(rect)

		var angle := randf_range(0, TAU)
		var speed := randf_range(50.0, 100.0 + streak_level * 15.0)
		var dist := speed * duration
		var target: Vector2 = Vector2(cos(angle), sin(angle)) * dist

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(rect, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(rect, "scale", Vector2.ZERO, duration * 0.7).set_delay(duration * 0.3)
		tw.tween_property(rect, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)

	if streak_level >= 2:
		var dirs := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		for d in dirs:
			var rect := ColorRect.new()
			rect.size = Vector2(4, 10)
			rect.color = color
			rect.position = Vector2(-2, -5)
			add_child(rect)
			var target: Vector2 = d * (40.0 + streak_level * 10.0) * duration
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(rect, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(rect, "scale", Vector2.ZERO, duration * 0.7).set_delay(duration * 0.3)
			tw.tween_property(rect, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)

	if streak_level >= 3:
		for a in range(8):
			var angle := a * TAU / 8
			var rect := ColorRect.new()
			rect.size = Vector2(4, 12)
			rect.color = color
			rect.position = Vector2(-2, -6)
			rect.rotation = angle
			add_child(rect)
			var spread := 30.0 + streak_level * 12.0
			var target: Vector2 = Vector2(cos(angle), sin(angle)) * spread * duration
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(rect, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(rect, "scale", Vector2.ZERO, duration * 0.7).set_delay(duration * 0.3)
			tw.tween_property(rect, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)

	if streak_level >= 4:
		for a in range(4):
			var angle := a * TAU / 4 + TAU / 8
			var rect := ColorRect.new()
			rect.size = Vector2(3, 18)
			rect.color = color
			rect.position = Vector2(-1, -9)
			rect.rotation = angle
			add_child(rect)
			var spread := 20.0 + streak_level * 8.0
			var target: Vector2 = Vector2(cos(angle), sin(angle)) * spread * duration
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(rect, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(rect, "scale", Vector2.ZERO, duration * 0.7).set_delay(duration * 0.3)
			tw.tween_property(rect, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)

	if streak_level >= 5:
		var star := ColorRect.new()
		star.size = Vector2(8, 8)
		star.color = Color.WHITE
		star.position = Vector2(-4, -4)
		star.rotation = PI / 4
		add_child(star)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(star, "scale", Vector2(3, 3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(star, "scale", Vector2.ZERO, 0.2).set_delay(0.15)
		tw.tween_property(star, "modulate:a", 0.0, 0.15).set_delay(0.15)

		for a in range(4):
			var angle := a * TAU / 4
			for j in 2:
				var ring_p := ColorRect.new()
				ring_p.size = Vector2(3, 6)
				ring_p.color = color
				ring_p.position = Vector2(-1, -3)
				ring_p.rotation = angle + j * 0.2
				add_child(ring_p)
				var spread := 15.0 + j * 10.0
				var target: Vector2 = Vector2(cos(angle + j * 0.2), sin(angle + j * 0.2)) * spread * duration
				var tw2 := create_tween()
				tw2.set_parallel(true)
				tw2.tween_property(ring_p, "position", target, duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw2.tween_property(ring_p, "scale", Vector2.ZERO, duration * 0.5).set_delay(duration * 0.1)
				tw2.tween_property(ring_p, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.2)

	await get_tree().create_timer(duration + 0.3).timeout
	queue_free()
