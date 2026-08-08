extends "res://scenes/enemy/Enemy.gd"

# Torre estática con láser fijo. Ciclo AIM(telegraph) → FIRE(láser) → COOLDOWN.
# - AIM: el jugador que la golpee recibe el daño en su lugar (reflejo).
# - FIRE: muere de 1 golpe.
# - COOLDOWN: sobrevive al 1er golpe, muere al 2º.

const TILE := 24
const GRID_W := 30
const GRID_H := 18

enum TowerState { AIM, FIRE, COOLDOWN }

var state: int = TowerState.AIM
var state_time: float = 0.0
var _cooldown_hits := 0
var _barrel: ColorRect
var _core: ColorRect
var _telegraphs: Array = []
var _fx_root: Node2D
var _lasers_root: Node2D
var _eb: Node

func _ready() -> void:
	_eb = get_node("/root/EventBus")
	hit_cooldown_time = data.hit_cooldown_time
	_build_visual()
	_build_telegraphs()
	state = TowerState.AIM
	state_time = 0.0

func _build_visual() -> void:
	visual.color = Color(0, 0, 0, 0)
	var base := ColorRect.new()
	base.size = Vector2(28, 28)
	base.position = Vector2(-14, -14)
	base.color = data.color.darkened(0.45)
	add_child(base)
	_core = ColorRect.new()
	_core.size = Vector2(10, 10)
	_core.position = Vector2(-5, -5)
	_core.color = data.tower_core_color
	add_child(_core)
	_barrel = ColorRect.new()
	_barrel.size = Vector2(10, 4)
	_barrel.position = Vector2(-5, -2)
	_barrel.color = data.color.lightened(0.25)
	add_child(_barrel)

func _build_telegraphs() -> void:
	for _d in _dirs_for(data.tower_pattern):
		var t := ColorRect.new()
		t.color = Color(data.tower_core_color, 0.25)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.z_index = 2
		get_fx_root().add_child(t)
		_telegraphs.append(t)

func get_fx_root() -> Node2D:
	if not is_instance_valid(_fx_root):
		_fx_root = Node2D.new()
		_fx_root.z_index = 4
		var p := get_parent()
		if p:
			p.add_child.call_deferred(_fx_root)
	return _fx_root

func get_lasers_root() -> Node2D:
	if not is_instance_valid(_lasers_root):
		_lasers_root = Node2D.new()
		_lasers_root.z_index = 4
		var p := get_parent()
		if p:
			p.add_child.call_deferred(_lasers_root)
	return _lasers_root

func _process(delta: float) -> void:
	if not is_alive:
		return
	state_time += delta
	match state:
		TowerState.AIM:
			_pulse_telegraph()
			_rotate_barrel()
			if state_time >= data.tower_aim_time:
				_do_fire()
		TowerState.FIRE:
			if state_time >= data.tower_beam_duration:
				_to_cooldown()
		TowerState.COOLDOWN:
			if state_time >= data.tower_reload_time:
				state = TowerState.AIM
				state_time = 0.0

# ---------- geometría del láser (patrón fijo) ----------

func _dirs_for(pattern: int) -> Array:
	match pattern:
		data.TowerPattern.SINGLE_LEFT:
			return [Vector2(-1, 0)]
		data.TowerPattern.SINGLE_RIGHT:
			return [Vector2(1, 0)]
		data.TowerPattern.SINGLE_UP:
			return [Vector2(0, -1)]
		data.TowerPattern.SINGLE_DOWN:
			return [Vector2(0, 1)]
		data.TowerPattern.DOUBLE_LR:
			return [Vector2(-1, 0), Vector2(1, 0)]
		data.TowerPattern.DOUBLE_UD:
			return [Vector2(0, -1), Vector2(0, 1)]
		data.TowerPattern.CORNER:
			var dirs_pos: Array = []
			if grid_pos.x < GRID_W / 2:
				dirs_pos.append(Vector2(1, 0))
			else:
				dirs_pos.append(Vector2(-1, 0))
			if grid_pos.y < GRID_H / 2:
				dirs_pos.append(Vector2(0, 1))
			else:
				dirs_pos.append(Vector2(0, -1))
			return dirs_pos
	return [Vector2(1, 0)]

func _lane_rect(dir: Vector2) -> Rect2:
	var start := grid_pos
	var end: Vector2i = grid_pos + Vector2i(dir) * max(GRID_W, GRID_H)
	if dir.x > 0:
		end.x = GRID_W - 1
	elif dir.x < 0:
		end.x = 0
	if dir.y > 0:
		end.y = GRID_H - 1
	elif dir.y < 0:
		end.y = 0
	var a: Vector2 = Vector2(start) * TILE
	var b: Vector2 = Vector2(end) * TILE + Vector2(TILE, TILE)
	var pos: Vector2 = Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var size: Vector2 = (b - a).abs()
	return Rect2(pos, size)

func _aim_rects() -> Array:
	var rects: Array = []
	for d in _dirs_for(data.tower_pattern):
		rects.append(_lane_rect(d))
	return rects

# ---------- telegraph (AIM) ----------

func _pulse_telegraph() -> void:
	var t: float = state_time / data.tower_aim_time
	var dirs := _dirs_for(data.tower_pattern)
	for i in _telegraphs.size():
		var tg = _telegraphs[i]
		tg.color.a = 0.12 + 0.22 * absf(sin(t * PI))
		tg.show()
		var rect: Rect2 = _lane_rect(dirs[i])
		tg.position = rect.position
		tg.size = rect.size
	_core_pulse(t)

func _core_pulse(t: float) -> void:
	var flash := 0.6 + 0.4 * absf(sin(t * PI))
	_core.modulate = Color(flash, flash, flash)

func _rotate_barrel() -> void:
	var dirs := _dirs_for(data.tower_pattern)
	var d: Vector2 = dirs[0]
	_barrel.rotation = 0.0
	if d.x < 0:
		_barrel.rotation = PI
	elif d.y != 0:
		_barrel.rotation = PI / 2

# ---------- FIRE ----------

func _do_fire() -> void:
	state = TowerState.FIRE
	state_time = 0.0
	var dirs := _dirs_for(data.tower_pattern)
	for i in dirs.size():
		var rect := _lane_rect(dirs[i])
		var laser = preload("res://scenes/enemy/TowerLaser.tscn").instantiate()
		laser.setup(rect, data.damage, data.tower_core_color)
		get_lasers_root().add_child(laser)
	_hide_telegraphs()
	_flash()

func _hide_telegraphs() -> void:
	for tg in _telegraphs:
		tg.hide()

func _flash() -> void:
	var tw := create_tween()
	tw.tween_property(_core, "modulate", Color(3.0, 3.0, 3.0), 0.05)
	tw.tween_property(_core, "modulate", Color.WHITE, 0.15)

func _to_cooldown() -> void:
	if is_instance_valid(_lasers_root):
		for l in _lasers_root.get_children():
			l.queue_free()
	state = TowerState.COOLDOWN
	state_time = 0.0

# ---------- golpe: el daño depende del estado ----------

func take_damage(amount: float) -> bool:
	if not is_alive:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < _last_hit_time + hit_cooldown_time:
		return false
	_last_hit_time = now
	match state:
		TowerState.AIM:
			_eb.damage_taken.emit(data.damage, data.enemy_id)
			return false
		TowerState.FIRE:
			die()
			return true
		TowerState.COOLDOWN:
			_cooldown_hits += 1
			if _cooldown_hits >= 2:
				die()
			return true
	return true

func die() -> void:
	if is_instance_valid(_fx_root):
		_fx_root.queue_free()
	if is_instance_valid(_lasers_root):
		_lasers_root.queue_free()
	super.die()