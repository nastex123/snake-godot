extends Resource
class_name EnemyData

enum EnemyType { SLIME, SPIDER, TOWER, GHOST, WORM, ELITE }
enum TowerPattern { SINGLE_LEFT, SINGLE_RIGHT, SINGLE_UP, SINGLE_DOWN, DOUBLE_LR, DOUBLE_UD, CORNER }

var enemy_id: String = ""
var enemy_type: int = EnemyType.SLIME
var display_name: String = "Slime"
var max_hp: float = 30.0
var damage: float = 10.0
var speed: float = 1.0
var xp_drop: int = 10
var gold_drop: int = 5
var color: Color = Color(0.2, 0.6, 0.2)
var attack_cooldown: float = 1.0
var grid_size: Vector2i = Vector2i(1, 1)

# --- Slime: config data-driven (árbol de decisión, fusión, anti-tedio) ---
var hop_charge_time: float = 0.22
var hop_jump_time: float = 0.32
var hop_pause_time: float = 0.45
var hop_distance: int = 1
var hop_distance_direct: int = 2
var ally_radius: int = 4
var chase_radius: float = 7.0
var merge_harass_time: float = 4.0
var merge_group_radius: int = 2
var hit_cooldown_time: float = 0.5
var shrink_recover_time: float = 3.0
var shrink_recover_range: float = 9.0
var small_hp_mult: float = 0.4
var big_hp_mult: float = 1.2
var big_grid: Vector2i = Vector2i(2, 2)

# --- SlimePack: coordinación de manada (percepción compartida, presión, fusión) ---
var pack_contact_radius: float = 7.0
var pack_slot_distance: int = 3
var pack_memory_time: float = 1.2
var pack_pressure_wrap: float = 2.0
var pack_pressure_press: float = 3.0
var pack_pressure_fuse: float = 3.5
var pack_fuse_min_members: int = 2
var pack_fuse_hp_ratio: float = 0.6
var pack_fuse_max_shrunk: int = 1
var pack_channel_time: float = 1.0
var pack_regroup_speedup: float = 2.0
var pack_interrupt_on_hit: bool = true

# --- Tower: patrón de disparo fijo + tiempos de ciclo + dureza ---
var tower_pattern: int = TowerPattern.SINGLE_RIGHT
var tower_aim_time: float = 0.7
var tower_beam_duration: float = 0.3
var tower_reload_time: float = 1.2
var tower_core_color: Color = Color(1.0, 0.95, 0.5)
var personality: Dictionary = {
	"impulsive": 0.0,
	"cautious": 0.0,
	"heavy": 0.0,
	"light": 0.0,
	"social": 0.0,
}
