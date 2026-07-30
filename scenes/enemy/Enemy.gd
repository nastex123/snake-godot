extends Area2D

signal died(enemy)
signal hp_changed(current: float, max_hp: float)

var data
var current_hp: float = 0.0
var is_alive: bool = true
var grid_pos: Vector2i

func setup(enemy_data, position: Vector2i) -> void:
	data = enemy_data
	grid_pos = position
	global_position = Vector2(position) * 24 + Vector2(12, 12)
	current_hp = data.max_hp
	hp_changed.emit(current_hp, data.max_hp)


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	current_hp -= amount
	hp_changed.emit(current_hp, data.max_hp)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.05)
	if current_hp <= 0:
		die()

func die() -> void:
	is_alive = false
	died.emit(self)
	var eb = get_node("/root/EventBus")
	if eb:
		eb.enemy_killed.emit(data.enemy_id, global_position, data.xp_drop, data.gold_drop)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
