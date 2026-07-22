extends Node2D

const TILE_SIZE := 24
const EYE_SIZE := 6

func update_direction(new_dir: Vector2i) -> void:
	if new_dir == Vector2i.RIGHT:
		rotation = 0
	elif new_dir == Vector2i.DOWN:
		rotation = deg_to_rad(90)
	elif new_dir == Vector2i.LEFT:
		rotation = deg_to_rad(180)
	elif new_dir == Vector2i.UP:
		rotation = deg_to_rad(270)

func _draw() -> void:
	var half := TILE_SIZE / 2.0
	draw_rect(Rect2(-half, -half, TILE_SIZE, TILE_SIZE), Color(0, 1, 0, 1))
	draw_rect(Rect2(4, -9, EYE_SIZE, EYE_SIZE), Color.WHITE)
	draw_rect(Rect2(4, 3, EYE_SIZE, EYE_SIZE), Color.WHITE)
