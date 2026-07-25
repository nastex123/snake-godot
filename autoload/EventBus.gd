extends Node
class_name EventBus

signal food_eaten(position: Vector2i, streak: int)
signal enemy_killed(enemy_type: String, position: Vector2)
signal damage_dealt(target: Node, amount: float, type: int)
signal xp_gained(amount: int)
signal gold_gained(amount: int)
signal level_up(new_level: int)
signal relic_obtained(relic_id: String)
signal skill_used(skill_id: String)
signal room_cleared(room_index: int)
signal biome_entered(biome_id: int)
signal boss_phase_changed(phase: int)
signal game_over(reason: String)
signal reset_requested()
