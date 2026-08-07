extends "res://scenes/enemy/Enemy.gd"

const TILE := 24
const GRID_W := 30
const GRID_H := 18
const GRID_TOP_Y := 76

enum SizeTier { SMALL, MEDIUM, BIG }
enum Phase { PAUSE, CHARGE, JUMP, LAND }

var size_tier: int = SizeTier.MEDIUM
var phase: int = Phase.PAUSE
var phase_time: float = 0.0
var hop_direct := false
var _hop_from := Vector2.ZERO
var _hop_to := Vector2.ZERO
var _target_grid_pos := Vector2i.ZERO
var _recovering := false
var _recover_timer := 0.0
var _harass_time := 0.0
var _merge_lock := false
var _absorbed := false
var _merge_cooldown := 0.0
var _sc: Node
var _eye_l: ColorRect
var _eye_r: ColorRect
var pack = null
var traits := {}
var _channeling := false
var _aura: ColorRect

func _ready() -> void:
	_sc = get_node_or_null("/root/Game/GameArea/SnakeController")
	hit_cooldown_time = data.hit_cooldown_time
	_traits_from_data()
	_apply_tier_visual()
	_add_eyes()
	_add_aura()

func _traits_from_data() -> void:
	# Personalidad = pesos de decisión (no stats). Jitter determinista por posición.
	traits = data.personality.duplicate()
	var h := hash(grid_pos.x * 1000 + grid_pos.y)
	seeded_mix(["impulsive", "cautious", "heavy", "light", "social"], h)

func seeded_mix(keys: Array, seed: int) -> void:
	for k in keys:
		var v: float = traits.get(k, 0.0)
		var j := (float((seed + keys.find(k) * 137) % 100) - 50.0) / 100.0
		traits[k] = clampf(v + j * 0.3, -1.0, 1.0)

func trait_weight(key: String) -> float:
	return traits.get(key, 0.0)

func _add_aura() -> void:
	_aura = ColorRect.new()
	_aura.size = Vector2(56, 56)
	_aura.position = Vector2(-28, -28)
	_aura.pivot_offset = _aura.size * 0.5
	_aura.color = Color(1, 0.9, 0.5, 0.0)
	_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(_aura)

func _add_eyes() -> void:
	_eye_l = ColorRect.new()
	_eye_r = ColorRect.new()
	_eye_l.size = Vector2(4, 5)
	_eye_r.size = Vector2(4, 5)
	_eye_l.color = Color(0.03, 0.05, 0.06)
	_eye_r.color = Color(0.03, 0.05, 0.06)
	visual.add_child(_eye_l)
	visual.add_child(_eye_r)

func _process(delta: float) -> void:
	if not is_alive or _absorbed or _channeling:
		if _channeling:
			_process_channel(delta)
		return
	_update_recovery(delta)
	_update_harass(delta)
	_advance_phase(delta)
	_update_look()

# ---------- utilidades jugador ----------

func _player_pos() -> Vector2i:
	if _sc == null:
		return Vector2i.ZERO
	return _sc.get_head_pos()

func _player_dir() -> Vector2i:
	if _sc == null:
		return Vector2i.RIGHT
	return _sc.direction

# ---------- recuento y estado ----------

func _update_recovery(delta: float) -> void:
	if size_tier == SizeTier.MEDIUM or size_tier == SizeTier.BIG:
		return
	if _recovering:
		_recover_timer += delta
		if _recover_timer >= data.shrink_recover_time:
			_recover_timer = 0.0
			_recovering = false
			size_tier = SizeTier.MEDIUM
			max_hp = data.max_hp
			current_hp = max_hp
			_merge_lock = false
			_harass_time = 0.0
			_merge_cooldown = 1.0
			_apply_tier_visual()
		return
	var pp := _player_pos()
	var d: float = Vector2(pp - grid_pos).length()
	if d > data.shrink_recover_range:
		_recovering = true
		_recover_timer = 0.0

func _update_harass(delta: float) -> void:
	var pp := _player_pos()
	var d: float = Vector2(pp - grid_pos).length()
	if d <= data.chase_radius:
		_harass_time += delta
	else:
		_harass_time = maxf(0.0, _harass_time - delta * 2.0)

# ---------- máquina de fases (hop) ----------

func _advance_phase(delta: float) -> void:
	phase_time += delta
	match phase:
		Phase.PAUSE:
			_breathe()
			if phase_time >= data.hop_pause_time * randf_range(0.8, 1.2):
				phase = Phase.CHARGE
				phase_time = 0.0
		Phase.CHARGE:
			var t := clampf(phase_time / data.hop_charge_time, 0.0, 1.0)
			_set_squash(1.0 + 0.35 * (1.0 - t), 1.0 - 0.25 * (1.0 - t))
			if phase_time >= data.hop_charge_time:
				_begin_jump()
		Phase.JUMP:
			var t := clampf(phase_time / data.hop_jump_time, 0.0, 1.0)
			var e := _smoothstep(t)
			global_position = _hop_from.lerp(_hop_to, e)
			visual.position.y = -visual.size.y * 0.5 - sin(t * PI) * 8.0
			_clamp_visual_y()
			_set_squash(1.0 - 0.3 * sin(t * PI), 1.0 + 0.4 * sin(t * PI))
			if phase_time >= data.hop_jump_time:
				grid_pos = _target_grid_pos
				visual.position.y = -visual.size.y * 0.5
				_clamp_visual_y()
				phase = Phase.LAND
				phase_time = 0.0
				_land_fx()
		Phase.LAND:
			var t := clampf(phase_time / 0.18, 0.0, 1.0)
			_set_squash(1.0 + 0.5 * (1.0 - t), 1.0 - 0.3 * (1.0 - t))
			if phase_time >= 0.18:
				_set_squash(1.0, 1.0)
				phase = Phase.PAUSE
				phase_time = 0.0

func _smoothstep(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func _set_squash(sx: float, sy: float) -> void:
	if visual:
		visual.scale = Vector2(sx, sy)

func _breathe() -> void:
	var s := sin(phase_time * 6.0) * 0.05
	_set_squash(1.0 + s, 1.0 - s)

func _begin_jump() -> void:
	if pack != null:
		_pack_jump()
		return
	var pp := _player_pos()
	var allies := _allies_near()
	var target: Vector2i
	if allies.is_empty():
		hop_direct = true
		target = _solo_target(pp)
	elif allies.size() == 1:
		hop_direct = false
		target = _pinza_target(pp)
	else:
		hop_direct = false
		target = _mural_target(pp, allies)
	_start_hop_to(target)

func _pack_jump() -> void:
	var goal: Dictionary = pack.goal_for(self)
	hop_direct = goal.get("direct", false)
	var target: Vector2i = goal["cell"]
	# Rasgos ajustan solo el destino (pesos de decisión, no stats).
	var t := traits
	var nudge: float = t.get("heavy", 0.0)
	if absf(nudge) > 0.05 and randf() < absf(nudge) * 0.3:
		target = grid_pos
	_start_hop_to(target)

func _start_hop_to(target: Vector2i) -> void:
	_move_towards(target)
	_hop_from = global_position
	_hop_to = Vector2(_target_grid_pos) * TILE + Vector2(TILE * 0.5, TILE * 0.5)
	phase = Phase.JUMP
	phase_time = 0.0
	if _hop_from.distance_to(_hop_to) < 1.0:
		phase_time = data.hop_jump_time * 0.5

func _land_fx() -> void:
	for i in 4:
		var drop := ColorRect.new()
		drop.size = Vector2(3, 3)
		drop.color = data.color
		var local: Vector2 = get_parent().to_local(global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6)))
		drop.position = local
		get_parent().add_child(drop)
		var tw := create_tween()
		tw.tween_property(drop, "modulate:a", 0.0, 0.35)
		tw.tween_callback(drop.queue_free)

# Mantiene el sprite dentro del grid (la fila 0 queda pegada al HUD, y el arco
# del salto levanta el cuerpo por encima de la línea superior del grid).

func _clamp_visual_y() -> void:
	if visual == null:
		return
	var ny := global_position.y
	visual.position.y = clampf(visual.position.y, GRID_TOP_Y - ny, GRID_TOP_Y + GRID_H * TILE - ny - visual.size.y)

# ---------- árbol de decisión ----------

func _solo_target(pp: Vector2i) -> Vector2i:
	return pp + _player_dir()

func _pinza_target(pp: Vector2i) -> Vector2i:
	var rel := pp - grid_pos
	if absf(rel.x) < absf(rel.y):
		return grid_pos + Vector2i(signi(rel.x), 0)
	return grid_pos + Vector2i(0, signi(rel.y))

func _mural_target(pp: Vector2i, allies: Array) -> Vector2i:
	var closest := self
	var best := 99999
	for a in allies:
		var d := maxi(absi(a.grid_pos.x - pp.x), absi(a.grid_pos.y - pp.y))
		if d < best:
			best = d
			closest = a
	if closest == self:
		return pp
	var rel := pp - grid_pos
	if absf(rel.x) >= absf(rel.y):
		return pp + Vector2i(signi(rel.x), 0)
	return pp + Vector2i(0, signi(rel.y))

func _move_towards(target: Vector2i) -> void:
	var rel := target - grid_pos
	if rel == Vector2i.ZERO:
		_target_grid_pos = grid_pos
		return
	var dir := Vector2i(signi(rel.x), signi(rel.y))
	var dist: int = data.hop_distance_direct if hop_direct else data.hop_distance
	_target_grid_pos = _try_hop_cell(dir, dist)
	if _target_grid_pos == grid_pos:
		_target_grid_pos = _try_hop_cell(dir, 1)

func _try_hop_cell(dir: Vector2i, dist: int) -> Vector2i:
	var size := grid_size
	var cand := grid_pos
	for i in dist:
		cand += dir
		if cand.x < 0 or cand.x + size.x > GRID_W or cand.y < 0 or cand.y + size.y > GRID_H:
			return grid_pos
	return cand

# ---------- colisión (hitbox sincronizada con el salto) ----------
# `grid_pos` solo se commitea al aterrizar; durante el JUMP el sprite ya se está
# moviendo hacia `_target_grid_pos`, así que la huella debe incluir la casilla de
# origen Y la de destino (y el camino entre ambas) para que el jugador no «pase
# por encima» de un slime en pleno salto sin dañarlo.

func occupies_cell(cell: Vector2i) -> bool:
	if phase != Phase.JUMP:
		return super.occupies_cell(cell)
	var size := grid_size
	var start := grid_pos
	var end := _target_grid_pos
	var d := end - start
	var steps := maxi(absi(d.x), absi(d.y))
	for step in steps + 1:
		var p: Vector2i
		if steps == 0:
			p = start
		elif d.x != 0:
			p = start + Vector2i(int(signi(d.x)) * step, 0)
		else:
			p = start + Vector2i(0, int(signi(d.y)) * step)
		for dy in size.y:
			for dx in size.x:
				if p + Vector2i(dx, dy) == cell:
					return true
	return false

# ---------- aliados y fusión ----------

func _allies_near() -> Array:
	var res: Array = []
	var parent := get_parent()
	if parent == null:
		return res
	for child in parent.get_children():
		if child == self or child.get("grid_pos") == null:
			continue
		if not child.is_alive or child.get("_absorbed") == true:
			continue
		var d := maxi(absi(child.grid_pos.x - grid_pos.x), absi(child.grid_pos.y - grid_pos.y))
		if d <= data.ally_radius:
			res.append(child)
	return res

func _merge_group() -> Array:
	var group: Array = [self]
	var parent := get_parent()
	if parent == null:
		return group
	for child in parent.get_children():
		if child == self or child.get("grid_pos") == null or child.get("_absorbed") == true:
			continue
		if child.get("size_tier") == null or child.get("_merge_lock") == null:
			continue
		if not child.is_alive or child.size_tier != SizeTier.MEDIUM or child._merge_lock:
			continue
		if child.data.enemy_id != data.enemy_id:
			continue
		var d := maxi(absi(child.grid_pos.x - grid_pos.x), absi(child.grid_pos.y - grid_pos.y))
		if d <= data.merge_group_radius:
			group.append(child)
	return group

# ---------- coordinación con SlimePack (fusión interactiva) ----------

func can_merge() -> bool:
	return is_alive and not _absorbed and not _merge_lock \
		and size_tier == SizeTier.MEDIUM and not _channeling

func begin_channel() -> void:
	if _channeling or not can_merge():
		return
	_channeling = true
	phase = Phase.PAUSE
	phase_time = 0.0
	_tween_aura(true)

func end_channel() -> void:
	if not _channeling:
		return
	_channeling = false
	_tween_aura(false)
	_harass_time = 0.0
	_merge_cooldown = 0.5

func _process_channel(delta: float) -> void:
	phase_time += delta
	# Vibración + aura mientras canaliza; se queda quieto (no persigue).
	var sh = sin(phase_time * 42.0) * 1.2
	visual.position.x = -visual.size.x * 0.5 + sh
	visual.position.y = -visual.size.y * 0.5 + cos(phase_time * 37.0) * 1.2
	_clamp_visual_y()

func _tween_aura(on_: bool) -> void:
	if _aura == null:
		return
	var tw := create_tween()
	if on_:
		tw.tween_property(_aura, "color:a", 0.35, 0.2)
	else:
		tw.tween_property(_aura, "color:a", 0.0, 0.2)

func do_pack_merge(group: Array) -> void:
	if not is_alive or _absorbed or _merge_lock or size_tier != SizeTier.MEDIUM or group.size() < 2:
		return
	_channeling = false
	_tween_aura(false)
	var sorted := group.duplicate()
	sorted.sort_custom(func(a, b):
		return (a.grid_pos.x < b.grid_pos.x) or (a.grid_pos.x == b.grid_pos.x and a.grid_pos.y < b.grid_pos.y))
	var leader = sorted[0]
	for m in sorted:
		if m != self and m != leader:
			m._merge_lock = true
			m._channeling = false
	if self == leader:
		_do_merge(sorted)
	else:
		_merge_lock = true

func _do_merge(group: Array) -> void:
	var total_hp := 0.0
	var total_max := 0.0
	var cx := 0.0
	var cy := 0.0
	for m in group:
		total_hp += m.current_hp
		total_max += m.data.max_hp
		cx += m.grid_pos.x
		cy += m.grid_pos.y
	for m in group:
		if m != self:
			m._absorb()
	size_tier = SizeTier.BIG
	grid_size = data.big_grid
	max_hp = total_max * data.big_hp_mult
	current_hp = minf(total_hp, max_hp)
	var gx := clampi(roundi(cx / group.size()), 0, GRID_W - data.big_grid.x)
	var gy := clampi(roundi(cy / group.size()), 0, GRID_H - data.big_grid.y)
	grid_pos = Vector2i(gx, gy)
	_target_grid_pos = grid_pos
	global_position = Vector2(grid_pos) * TILE + Vector2(TILE * 0.5, TILE * 0.5)
	_apply_tier_visual()
	_update_collision_shape()
	_merge_lock = true
	_harass_time = 0.0
	_merge_anim()

func _absorb() -> void:
	_absorbed = true
	is_alive = false
	merged.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tw.tween_callback(queue_free)

func _merge_anim() -> void:
	scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)

func _try_merge() -> void:
	if _merge_lock or size_tier != SizeTier.MEDIUM or not is_alive:
		return
	if _harass_time < data.merge_harass_time:
		return
	var group := _merge_group()
	if group.size() < 2:
		return
	group.sort_custom(func(a, b):
		return (a.grid_pos.x < b.grid_pos.x) or (a.grid_pos.x == b.grid_pos.x and a.grid_pos.y < b.grid_pos.y))
	var leader = group[0]
	for m in group:
		if m != self:
			m._merge_lock = true
	if self == leader:
		_do_merge(group)
	else:
		_merge_lock = true

# ---------- golpe (anti-tedio: cooldown) ----------
# SMALL/MEDIUM mueren de 1 toque; el Slime Grande (BIG) aguanta golpes múltiples.

func _on_hit_started() -> void:
	if size_tier != SizeTier.BIG:
		current_hp = 0.0
	if pack:
		pack.on_member_damaged(self)

func _apply_tier_visual() -> void:
	var s := 20.0
	match size_tier:
		SizeTier.SMALL:
			s = 14.0
		SizeTier.BIG:
			s = 44.0
	visual.size = Vector2(s, s)
	visual.position = Vector2(-s * 0.5, -s * 0.5)
	visual.pivot_offset = visual.size * 0.5
	visual.scale = Vector2.ONE
	visual.color = data.color
	if size_tier == SizeTier.BIG:
		visual.color = data.color.darkened(0.25)
	elif size_tier == SizeTier.SMALL:
		visual.color = data.color.lightened(0.3)
	_clamp_visual_y()

func _update_look() -> void:
	if visual == null:
		return
	var pp := _player_pos()
	var d := pp - grid_pos
	var look := Vector2.ZERO
	if d != Vector2i.ZERO:
		look = Vector2(d).normalized() * 2.0
	var s := visual.size.x
	var bw := 5.0
	_eye_l.position = Vector2(s * 0.5 - bw - 3.0 + look.x, s * 0.5 - 8.0 + look.y)
	_eye_r.position = Vector2(s * 0.5 + 2.0 + look.x, s * 0.5 - 8.0 + look.y)