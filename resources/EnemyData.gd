extends Resource

enum EnemyType { SLIME, SPIDER, TOWER, GHOST, WORM, ELITE }

var enemy_id: String = ""
var enemy_type: int = EnemyType.SLIME
var display_name: String = "Slime"
var max_hp: float = 30.0
var damage: float = 10.0
var speed: float = 1.0
var xp_drop: int = 10
var gold_drop: int = 5
var color: Color = Color(0.2, 0.6, 0.2)
