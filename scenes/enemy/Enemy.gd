extends Area2D

signal died(enemy)
signal merged(enemy)
signal hp_changed(current: float, max_hp: float)

const LAYER_ENEMIES := 2
const TILE_SIZE := 24

var data
var current_hp: float = 0.0
var max_hp: float = 0.0
var is_alive: bool = true
var grid_pos: Vector2i
var grid_size: Vector2i = Vector2i(1, 1)
var hit_cooldown_time: float = 0.0
var _last_hit_time: float = -999.0
var visual: ColorRect
var collision_shape: CollisionShape2D

func setup(enemy_data, position: Vector2i) -> void:
	data = enemy_data
	grid_pos = position
	grid_size = data.grid_size
	global_position = Vector2(position) * 24 + Vector2(12, 12)
	collision_layer = LAYER_ENEMIES
	collision_mask = 0
	max_hp = data.max_hp
	current_hp = data.max_hp
	hp_changed.emit(current_hp, max_hp)
	_add_visual()
	_update_collision_shape()

# ---------- anclaje de huella ----------
# El nodo vive en el CENTRO de su celda base (grid_pos). Todos los elementos
# visuales deben centrarse en el centro de la huella completa (footprint), que
# para bloques >1x1 no coincide con la celda base: quedarían descentrados y
# sobresaldrían fuera del área jugable sin poder golpearse en su casilla.

func _footprint_center() -> Vector2:
	return Vector2(grid_size - Vector2i.ONE) * TILE_SIZE * 0.5

func _visual_base() -> Vector2:
	return _footprint_center() - visual.size * 0.5

func _add_visual() -> void:
	visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = _visual_base()
	visual.color = data.color
	add_child(visual)
	collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.shape = RectangleShape2D.new()
		add_child(collision_shape)

# Hitbox física que sigue al nodo (y por tanto al sprite en movimiento continuo).
# Tamaño = footprint real (grid_size * TILE), centrado en la celda.

func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	var rect: RectangleShape2D = collision_shape.shape
	rect.size = Vector2(grid_size) * TILE_SIZE
	collision_shape.position = Vector2(grid_size) * TILE_SIZE * 0.5 - Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)

func occupies_cell(cell: Vector2i) -> bool:
	for dy in grid_size.y:
		for dx in grid_size.x:
			if grid_pos + Vector2i(dx, dy) == cell:
				return true
	return false

func take_damage(amount: float) -> bool:
	if not is_alive:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < _last_hit_time + hit_cooldown_time:
		return false
	_last_hit_time = now
	current_hp -= amount
	_on_hit_started()
	hp_changed.emit(current_hp, max_hp)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.05)
	if current_hp <= 0:
		die()
	return true

func _on_hit_started() -> void:
	pass

func die() -> void:
	is_alive = false
	died.emit(self)
	var eb = get_node("/root/EventBus")
	if eb:
		eb.enemy_killed.emit(data.enemy_id, global_position, data.xp_drop, data.gold_drop)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
