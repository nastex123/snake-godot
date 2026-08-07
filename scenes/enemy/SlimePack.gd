extends Node
class_name SlimePack

# Coordinador de manada: percepción compartida + asignación de slots/roles +
# presión espacial + decisión de fusión. Un nodo por sala. Estado scoped a la sala.

const TILE := 24
const GRID_W := 30
const GRID_H := 18

enum PackState { SEARCH, REGROUP, WRAP, PRESS, FUSE }

var state: int = PackState.SEARCH
var pressure: float = 0.0
var avg_hp_ratio: float = 1.0
var shrunk_count: int = 0
var members: Array = []
var slots: Array = []
var memory := {
	"preferred_dir": Vector2i.ZERO,
	"last_escape": Vector2i.ZERO,
	"timer": 0.0,
}
var fuse_group: Array = []
var goal_map: Dictionary = {}
var _channeling := false
var _channel_time := 0.0
var _sc: Node = null

func setup(sc: Node) -> void:
	_sc = sc

func register(m) -> void:
	if m and not members.has(m):
		members.append(m)

func unregister(m) -> void:
	var i := members.find(m)
	if i >= 0:
		members.remove_at(i)
	if fuse_group.has(m):
		fuse_group.erase(m)

func is_empty() -> bool:
	return members.is_empty()

func has_member(m) -> bool:
	return members.has(m)

func _process(delta: float) -> void:
	var alive := []
	for m in members:
		if is_instance_valid(m) and m.is_alive:
			alive.append(m)
		else:
			unregister(m)
	members = alive
	if members.is_empty():
		return
	memory["timer"] = maxf(0.0, memory["timer"] - delta)
	if _channeling:
		_channel_time -= delta
		if _channel_time <= 0.0:
			_finish_fusion()
		return
	_recompute_stats()
	_decide_state()
	_assign_goals()

func _pack_data():
	return members[0].data if not members.is_empty() else null

func _recompute_stats() -> void:
	if members.is_empty():
		return
	var total_ratio := 0.0
	shrunk_count = 0
	for m in members:
		total_ratio += (m.current_hp / m.max_hp) if m.max_hp > 0.0 else 1.0
		if m.size_tier == m.SizeTier.SMALL:
			shrunk_count += 1
	avg_hp_ratio = total_ratio / members.size()
	var pp := _player_pos()
	var covered := {}
	for m in members:
		var d := Vector2i(signi(m.grid_pos.x - pp.x), signi(m.grid_pos.y - pp.y))
		var key := _dir_key(d)
		if key != "":
			covered[key] = true
	pressure = _pressure_from(covered.size())

func _pressure_from(sides: int) -> float:
	match sides:
		0: return 0.0
		1: return 1.0
		2: return 2.5
		3: return 4.5
		_: return 6.0

func _dir_key(d: Vector2i) -> String:
	if d == Vector2i.ZERO:
		return ""
	if absf(d.x) >= absf(d.y):
		return "r" if d.x > 0 else "l"
	return "d" if d.y > 0 else "u"

func _player_pos() -> Vector2i:
	return _sc.get_head_pos() if _sc else Vector2i.ZERO

func _player_facing() -> Vector2i:
	return _sc.direction if _sc else Vector2i.RIGHT

func _decide_state() -> void:
	if _channeling:
		state = PackState.FUSE
		return
	var data = _pack_data()
	if data == null:
		return
	var eligible: Array = _eligible_mediums()
	var fuse_ok: bool = pressure >= data.pack_pressure_fuse
	fuse_ok = fuse_ok and eligible.size() >= data.pack_fuse_min_members
	fuse_ok = fuse_ok and avg_hp_ratio > data.pack_fuse_hp_ratio
	fuse_ok = fuse_ok and shrunk_count <= data.pack_fuse_max_shrunk
	if fuse_ok:
		state = PackState.FUSE
		_start_fuse(eligible)
		return
	if pressure >= data.pack_pressure_press:
		state = PackState.PRESS
	elif pressure >= data.pack_pressure_wrap:
		state = PackState.WRAP
	elif shrunk_count >= members.size() * 0.5:
		state = PackState.REGROUP
	else:
		state = PackState.SEARCH

func _is_cell_open(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_W or cell.y < 0 or cell.y >= GRID_H:
		return false
	for seg in _sc.snake if _sc else []:
		if seg == cell:
			return false
	for m in members:
		if is_instance_valid(m) and m.is_alive and m.occupies_cell(cell):
			return false
	return true

func _recompute_slots() -> void:
	slots.clear()
	var pp := _player_pos()
	var data = _pack_data()
	var dist: int = int(data.pack_slot_distance) if data else 3
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
	]
	for d in dirs:
		var target := pp + d * dist
		if _is_cell_open(target):
			slots.append(target)

# Asigna a cada vivo un slot único cada tick (pool compartido → sin duplicados).
func _assign_goals() -> void:
	goal_map.clear()
	_recompute_slots()
	if state == PackState.SEARCH:
		for m in members:
			goal_map[m] = {"cell": m._player_pos() + m._player_dir(), "role": "pursue", "direct": true}
		return
	if state == PackState.REGROUP:
		for m in members:
			goal_map[m] = {"cell": _nearest_anchor(m), "role": "wander", "direct": false}
		return
	if slots.is_empty():
		for m in members:
			goal_map[m] = {"cell": m._player_pos(), "role": "pursue", "direct": false}
		return
	var pp := _player_pos()
	var pref: Vector2i = memory["preferred_dir"]
	var pool := slots.duplicate()
	for m in members:
		var dir := _dir_to_player(m)
		if pool.is_empty():
			goal_map[m] = {"cell": pp + dir, "role": "pursue", "direct": false}
			continue
		var best: Vector2i = pool[0]
		var best_score := 99999.0
		for s in pool:
			var score := _slot_score(s, pp, pref, m.grid_pos)
			if score < best_score:
				best_score = score
				best = s
		pool.erase(best)
		goal_map[m] = {"cell": best, "role": _role_for(best, pp), "direct": false}

func _dir_to_player(m) -> Vector2i:
	var rel: Vector2i = _player_pos() - m.grid_pos
	return Vector2i(signi(rel.x), signi(rel.y))

func goal_for(m) -> Dictionary:
	var g: Dictionary = goal_map.get(m, {})
	if g.is_empty():
		return {"cell": m._player_pos(), "role": "pursue", "direct": false}
	return g

func _slot_score(s: Vector2i, pp: Vector2i, pref: Vector2i, from: Vector2i) -> float:
	var rel: Vector2i = s - pp
	var score := float(absf(rel.x) + absf(rel.y))
	if pref != Vector2i.ZERO:
		var dp := float(rel.x * pref.x + rel.y * pref.y)
		if dp > 0:
			score -= 2.0
	score += Vector2(from - s).length() * 0.01
	return score

func _role_for(slot: Vector2i, pp: Vector2i) -> String:
	var rel := pp - slot
	if absf(rel.x) >= absf(rel.y):
		return "shepherd" if rel.x < 0 else "persecutor"
	var facing := _player_facing()
	if facing.y != 0 and rel.y * facing.y > 0:
		return "anchor"
	return "see"

func _nearest_anchor(m) -> Vector2i:
	var nearest = members[0]
	var bd := 99999.0
	for o in members:
		if o == m:
			continue
		var d := Vector2(o.grid_pos - m.grid_pos).length()
		if d < bd:
			bd = d
			nearest = o
	return nearest.grid_pos

func memory_direction() -> Vector2i:
	if memory["preferred_dir"] != Vector2i.ZERO:
		return memory["preferred_dir"]
	return _player_facing()

func update_escape(esc: Vector2i) -> void:
	memory["last_escape"] = esc
	var data = _pack_data()
	if memory["timer"] <= 0.0:
		memory["preferred_dir"] = esc
		memory["timer"] = data.pack_memory_time if data else 0.0

# ---------- fusión (canalización interactiva, interrumpible) ----------

func _eligible_mediums() -> Array:
	var res := []
	for m in members:
		if is_instance_valid(m) and m.is_alive \
			and m.size_tier == m.SizeTier.MEDIUM and m.can_merge():
			res.append(m)
	return res

func _start_fuse(eligible: Array) -> void:
	var group: Array = [eligible[0]]
	for m in eligible:
		if group.size() >= 2:
			break
		if m != group[0]:
			group.append(m)
	fuse_group = group
	for m in group:
		m.begin_channel()
	_channeling = true
	var data = _pack_data()
	_channel_time = data.pack_channel_time if data else 1.0

func on_channel_hit(m) -> void:
	if _channeling and fuse_group.has(m):
		_channeling = false
		for fm in fuse_group:
			if is_instance_valid(fm):
				fm.end_channel()
		fuse_group.clear()

func _finish_fusion() -> void:
	_channeling = false
	if fuse_group.is_empty():
		return
	for fm in fuse_group:
		if is_instance_valid(fm):
			fm.end_channel()
	var leader = fuse_group[0]
	if is_instance_valid(leader) and leader.is_alive:
		leader.do_pack_merge(fuse_group)
	fuse_group.clear()

func on_member_damaged(m) -> void:
	var rel: Vector2i = m.grid_pos - m._player_pos()
	update_escape(Vector2i(signi(rel.x), signi(rel.y)))
	if _channeling and fuse_group.has(m):
		on_channel_hit(m)