extends Node
class_name RunManager

signal xp_changed(current: int, max_xp: int)
signal level_changed(new_level: int)
signal gold_changed(amount: int)
signal streak_changed(new_streak: int)
signal relic_added(relic_id: String)
signal skill_equipped(skill_id: String)

var run_data: Dictionary = {}

func reset_run() -> void:
	run_data = {
		"time": 0.0,
		"score": 0,
		"xp": 0,
		"gold": 0,
		"level": 1,
		"max_level": 99,
		"streak": 0,
		"combo_time": 0.0,
		"biome": 0,
		"room_index": 0,
		"seed": randi(),
		"relics": [],
		"skills": [],
		"stats": _base_stats()
	}

func _base_stats() -> Dictionary:
	return {
		"hp": 100, "hp_max": 100,
		"damage": 10, "attack_speed": 1.0,
		"crit_chance": 0.05, "crit_damage": 1.5,
		"shield": 0, "armor": 0,
		"speed": 1.0, "pickup_radius": 1.0,
		"luck": 1.0, "xp_mult": 1.0, "gold_mult": 1.0,
		"streak_mult": 1.0,
		"base_move_interval": 0.15,
		"min_move_interval": 0.06,
		"combo_max_time": 3.0,
		"streak_speed_boost": 0.008,
	}

func add_score(amount: int) -> void:
	run_data.score += amount

func add_gold(amount: int) -> void:
	run_data.gold += amount
	gold_changed.emit(amount)

func add_xp(amount: int) -> void:
	run_data.xp += amount
	xp_changed.emit(run_data.xp, _xp_for_next_level())
	if run_data.xp >= _xp_for_next_level():
		level_up()

func level_up() -> void:
	run_data.level += 1
	run_data.xp = 0
	level_changed.emit(run_data.level)

func _xp_for_next_level() -> int:
	return run_data.level * 50

func set_streak(value: int) -> void:
	run_data.streak = value
	streak_changed.emit(value)

func set_combo_time(value: float) -> void:
	run_data.combo_time = value

func take_damage(amount: float) -> void:
	var stats = run_data.stats
	stats.hp = max(0.0, stats.hp - amount)
	if stats.hp <= 0:
		get_node("/root/EventBus").game_over.emit("death")
