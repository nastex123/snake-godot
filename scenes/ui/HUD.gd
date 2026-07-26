extends CanvasLayer
class_name HUD

@onready var streak_label = $CenterSection/StreakLabel
@onready var streak_multiplier: Label = $CenterSection/StreakMultiplier
@onready var combo_timer: Control = $CenterSection/ComboTimer
@onready var score_value_label: Label = $LeftSection/ScoreValue
@onready var gold_value: Label = $LeftSection/GoldValue
@onready var high_score_value_label: Label = $RightSection/HighScoreValue
@onready var level_value: Label = $RightSection/LevelValue
@onready var hp_bar: HPBar = $LeftSection/HPBar
@onready var hp_label: Label = $LeftSection/HPLabel
@onready var xp_bar: XPBar = $RightSection/XPBar
@onready var xp_label: Label = $RightSection/XPLabel
@onready var game_over_frame: ColorRect = $GameOverFrame
@onready var game_over_label = $GameOverFrame/GameOverLabel
@onready var restart_label: Label = $RestartLabel
@onready var notification_system: NotificationSystem = $NotificationContainer
@onready var border_scanner: Node2D = get_node("/root/Game/GameArea/BorderScanner")
@onready var bg_shader: ColorRect = get_node("/root/Game/GameArea/GridBackgroundShader")

var best_score := 0
var run_manager
var food_spawner

func setup(rm, fs) -> void:
	run_manager = rm
	food_spawner = fs

func update_streak(streak: int) -> void:
	if streak > 0:
		streak_label.text = "STREAK"
		streak_label.visible = true
		streak_multiplier.text = "x" + str(streak)
		streak_multiplier.visible = true
		var c := get_streak_color(streak)
		streak_label.add_theme_color_override("font_color", c)
		streak_multiplier.add_theme_color_override("font_color", c)
		food_spawner.set_food_color(c)
		border_scanner.set_streak(streak)
		border_scanner.set_active(true)
		combo_timer.set_color(c)
		bg_shader.material.set("shader_parameter/streak_level", streak)
	else:
		streak_label.text = ""
		streak_label.visible = false
		streak_multiplier.visible = false
		food_spawner.set_food_color(Color(1, 0, 0, 1))
		border_scanner.set_streak(0)
		border_scanner.set_active(false)
		combo_timer.set_color(Color(1.0, 0.53, 0.0, 1.0))
		bg_shader.material.set("shader_parameter/streak_level", 0)

static func get_streak_color(s: int) -> Color:
	match s:
		1: return Color("#33CC33")
		2: return Color("#3399FF")
		3: return Color("#FFCC00")
		4: return Color("#FF6600")
		5: return Color("#CC33FF")
		_: return Color(1, 0, 0, 1)

func update_score(score: int) -> void:
	score_value_label.text = "%06d" % score

func update_gold(amount: int) -> void:
	gold_value.text = "%03d" % amount

func update_level(level: int) -> void:
	level_value.text = "%02d" % level

func set_hp(current: float, max_hp: float) -> void:
	hp_bar.set_hp(current, max_hp)

func set_xp(current: float, max_xp: float) -> void:
	xp_bar.set_xp(current, max_xp)

func update_combo_bar(combo: float) -> void:
	combo_timer.set_ratio(combo / run_manager.run_data.stats.combo_max_time)

func animate_streak() -> void:
	combo_timer.bounce()
	border_scanner.trigger_dash()

func show_game_over(score: int) -> void:
	game_over_frame.visible = true
	game_over_label.visible = true
	restart_label.visible = true
	if score > best_score:
		best_score = score
	high_score_value_label.text = "%06d" % best_score

func hide_game_over() -> void:
	game_over_frame.visible = false
	game_over_label.visible = false
	restart_label.visible = false

func reset_visuals() -> void:
	bg_shader.material.set("shader_parameter/wave_time", 0.0)
	bg_shader.material.set("shader_parameter/wave_flash", 0.0)
	bg_shader.material.set("shader_parameter/game_over_fade", 0.0)
	update_streak(0)

func setup_font() -> void:
	pass

func set_game_over_fade(v: float) -> void:
	bg_shader.material.set("shader_parameter/game_over_fade", v)

func notify_xp(amount: int) -> void:
	notification_system.notify("+" + str(amount) + " XP", Color(0.0, 0.9, 1.0))

func notify_gold(amount: int) -> void:
	notification_system.notify("+" + str(amount) + " GOLD", Color(1.0, 0.85, 0.0))

func notify_streak(level: int) -> void:
	notification_system.notify("STREAK x" + str(level), get_streak_color(level))
