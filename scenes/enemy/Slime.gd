extends "res://scenes/enemy/Enemy.gd"

var move_timer: float = 0.0
var move_interval: float = 0.8
var _target_pos: Vector2

func _ready() -> void:
	move_interval = 0.8 / data.speed

func _process(delta: float) -> void:
	if not is_alive:
		return
	move_timer += delta
	if move_timer >= move_interval:
		move_timer = 0.0
		_move_toward_player()

func _move_toward_player() -> void:
	var game = get_node("/root/Game")
	if not game:
		return
	var sc = game.get_node("GameArea/SnakeController")
	var player_pos = sc.get_head_pos()
	if player_pos == grid_pos:
		return
	var dir = player_pos - grid_pos
	var move_dir: Vector2i
	if abs(dir.x) > abs(dir.y):
		move_dir = Vector2i(sign(dir.x), 0)
	else:
		move_dir = Vector2i(0, sign(dir.y))
	var new_pos = grid_pos + move_dir
	if new_pos.x < 0 or new_pos.x >= 30 or new_pos.y < 0 or new_pos.y >= 18:
		return
	grid_pos = new_pos
	_target_pos = Vector2(grid_pos) * 24 + Vector2(12, 12)
	var tw = create_tween()
	tw.tween_property(self, "global_position", _target_pos, move_interval * 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
