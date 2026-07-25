extends Node
class_name StreakHUD

@onready var streak_label = get_node("/root/Game/HUD/CenterSection/StreakLabel")
@onready var streak_multiplier: Label = get_node("/root/Game/HUD/CenterSection/StreakMultiplier")
@onready var combo_timer: Control = get_node("/root/Game/HUD/CenterSection/ComboTimer")
@onready var border_scanner: Node2D = get_node("/root/Game/GameArea/BorderScanner")
@onready var bg_shader: ColorRect = get_node("/root/Game/GameArea/GridBackgroundShader")
@onready var score_value_label: Label = get_node("/root/Game/HUD/LeftSection/ScoreValue")
@onready var high_score_value_label: Label = get_node("/root/Game/HUD/RightSection/HighScoreValue")
@onready var game_over_frame: ColorRect = get_node("/root/Game/HUD/GameOverFrame")
@onready var game_over_label = get_node("/root/Game/HUD/GameOverFrame/GameOverLabel")
@onready var restart_label: Label = get_node("/root/Game/HUD/RestartLabel")

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
		streak_label.set_text_color(c)
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

func update_combo_bar(combo: float) -> void:
	combo_timer.set_ratio(combo / run_manager.run_data.stats.combo_max_time)

func animate_streak() -> void:
	streak_label.pulse()
	streak_multiplier.scale = Vector2(1.0, 1.0)
	var mt := create_tween().set_ease(Tween.EASE_OUT)
	mt.tween_property(streak_multiplier, "scale", Vector2(1.3, 1.3), 0.05)
	mt.tween_property(streak_multiplier, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_ELASTIC)
	combo_timer.bounce()
	border_scanner.trigger_dash()

func show_game_over(score: int) -> void:
	game_over_frame.visible = true
	game_over_label.visible = true
	game_over_label.pulse()
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
	var base = load("res://fonts/PressStart2P-Regular.ttf")
	if not base:
		return
	var ls := LabelSettings.new()
	ls.font = base
	ls.outline_size = 1
	ls.outline_color = Color.BLACK
	for lbl in [streak_multiplier, restart_label, score_value_label, high_score_value_label]:
		lbl.label_settings = ls

func set_game_over_fade(v: float) -> void:
	bg_shader.material.set("shader_parameter/game_over_fade", v)
