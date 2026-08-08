extends "res://scenes/enemy/Slime.gd"

# Slime Grande 2×2 — variante fusionada del Slime. Escena y script propios
# (convención: cada variante de enemigo tiene su propio .tscn, no un flag de
# runtime sobre una escena compartida). Hereda hop/fusión física del base.

const SIZE := 44.0

func _ready() -> void:
	size_tier = SizeTier.BIG
	grid_size = data.big_grid
	super._ready()
	_update_collision_shape()

func _apply_tier_visual() -> void:
	visual.size = Vector2(SIZE, SIZE)
	visual.position = _visual_base()
	visual.pivot_offset = visual.size * 0.5
	visual.scale = Vector2.ONE
	visual.color = data.color.darkened(0.25)
	_recenter_aura()
	_clamp_visual_y()

func _on_hit_started() -> void:
	if pack:
		pack.on_member_damaged(self)

func can_merge() -> bool:
	return false
