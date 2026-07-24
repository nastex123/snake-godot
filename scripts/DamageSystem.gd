extends Node
class_name DamageSystem

signal damage_dealt(target: Node, amount: float, type: int)
signal damage_taken(source: Node, amount: float, type: int)
signal healed(amount: float)
signal shield_broken()

enum DamageType { PHYSICAL, MAGICAL, TRUE, POISON, FIRE, ICE }

var _invulnerable: bool = false
var _invulnerability_timer: float = 0.0

func apply_damage(source_stats: Dictionary, target_stats: Dictionary, base_damage: float, type: DamageType) -> Dictionary:
	if _invulnerable:
		return {"damage": 0, "crit": false, "blocked": true}

	var dmg = base_damage
	var is_crit = randf() < source_stats.get("crit_chance", 0.0)
	if is_crit:
		dmg *= source_stats.get("crit_damage", 1.5)

	dmg -= target_stats.get("armor", 0.0) * 0.5
	dmg = max(1.0, dmg)

	if target_stats.get("shield", 0.0) > 0:
		var shield_absorb = min(dmg, target_stats.shield)
		target_stats.shield -= shield_absorb
		dmg -= shield_absorb
		if target_stats.shield <= 0:
			shield_broken.emit()

	return {"damage": dmg, "crit": is_crit, "blocked": false}

func heal(amount: float, target: Dictionary) -> float:
	var before = target.get("hp", 0)
	target["hp"] = min(target.get("hp_max", 100), target.get("hp", 0) + amount)
	var healed_amount = target.get("hp", 0) - before
	if healed_amount > 0:
		healed.emit(healed_amount)
	return healed_amount

func set_invulnerable(duration: float) -> void:
	_invulnerable = true
	_invulnerability_timer = duration