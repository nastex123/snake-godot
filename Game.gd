extends Node2D

# Snake Game - Main entrypoint

const TILE_SIZE := 24
const GRID_WIDTH := 30
const GRID_HEIGHT := 18
const COMBO_MAX_TIME := 3.0
const STREAK_SPEED_BOOST := 0.008
const BASE_MOVE_INTERVAL := 0.15
const WAVE_DURATION := 0.6

@onready var food: Area2D = $GameArea/Food
@onready var snake_head: Area2D = $GameArea/SnakeHead
@onready var snake_body: Node2D = $GameArea/SnakeBody
@onready var score_value_label: Label = $HUD/LeftSection/ScoreValue
@onready var high_score_value_label: Label = $HUD/RightSection/HighScoreValue
@onready var streak_label = $HUD/CenterSection/StreakLabel
@onready var streak_multiplier: Label = $HUD/CenterSection/StreakMultiplier
@onready var combo_timer: Control = $HUD/CenterSection/ComboTimer
@onready var game_over_label = $HUD/GameOverFrame/GameOverLabel
@onready var game_over_frame: ColorRect = $HUD/GameOverFrame
@onready var restart_label: Label = $HUD/RestartLabel
@onready var border_scanner: Node2D = $GameArea/BorderScanner
@onready var screen_shake: Camera2D = $Camera2D
@onready var audio_manager: Node = $AudioManager
@onready var game_area: Node2D = $GameArea
@onready var bg_shader: ColorRect = $GameArea/GridBackgroundShader

@onready var event_bus = get_node("/root/EventBus")
@onready var game_manager = get_node("/root/GameManager")
@onready var run_manager = get_node("/root/RunManager")

var floating_text_scene = preload("res://FloatingText.gd")
const EXPLOSION_EFFECT = preload("res://ExplosionEffect.gd")

var snake_controller: SnakeController
var food_spawner: FoodSpawner
var best_score := 0
var body_parts: Array = []
var move_timer := 0.0
var move_interval := BASE_MOVE_INTERVAL

func _ready() -> void:
	randomize()
	snake_controller = SnakeController.new()
	snake_controller.name = "SnakeController"
	game_area.add_child(snake_controller)

	var head_visual = preload("res://SnakeHead.gd").new()
	snake_controller.set_head_visual(head_visual)

	food_spawner = FoodSpawner.new()
	food_spawner.name = "FoodSpawner"
	game_area.add_child(food_spawner)
	food_spawner.setup(food)

	event_bus.game_over.connect(_on_game_over)
	game_manager.game_started.connect(_on_game_started)

	snake_controller.ate_food.connect(_on_snake_ate_food)
	snake_controller.hit_wall.connect(_on_snake_hit)
	snake_controller.hit_self.connect(_on_snake_hit)

	_setup_retro_font()
	game_manager.start_run()
	reset_game()

func _process(delta: float) -> void:
	if game_manager.current_state == 7:
		if Input.is_action_just_pressed("ui_accept"):
			reset_game()
		return

	handle_input()
	move_timer += delta
	if move_timer >= move_interval:
		move_timer = 0.0
		move_snake()

	update_combo(delta)

	if run_manager.run_data.get("wave_time", 0.0) > 0:
		run_manager.run_data.wave_time = max(0.0, run_manager.run_data.wave_time - delta)
		bg_shader.material.set("shader_parameter/wave_time", run_manager.run_data.wave_time)

	if run_manager.run_data.get("wave_flash", 0.0) > 0:
		run_manager.run_data.wave_flash = max(0.0, run_manager.run_data.wave_flash - delta)
		bg_shader.material.set("shader_parameter/wave_flash", run_manager.run_data.wave_flash)

func update_combo(delta: float) -> void:
	var combo = run_manager.run_data.get("combo_time", 0.0)
	if combo > 0:
		combo -= delta
		if combo <= 0:
			combo = 0.0
			run_manager.set_streak(0)
			update_streak_visuals()
	run_manager.set_combo_time(combo)
	combo_timer.set_ratio(combo / COMBO_MAX_TIME)
	if run_manager.run_data.streak == 0:
		border_scanner.set_active(false)

func handle_input() -> void:
	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"):
		dir = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down"):
		dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		snake_controller.handle_input(dir)

func move_snake() -> void:
	var food_pos = food_spawner.get_food_pos()
	var success = snake_controller.move(food_pos)
	if not success:
		return

	update_body()

func _on_snake_ate_food(pos: Vector2i) -> void:
	var old_streak = run_manager.run_data.streak
	var streak_val = min(old_streak + 1, 5)
	run_manager.set_streak(streak_val)
	run_manager.set_combo_time(COMBO_MAX_TIME)
	event_bus.food_eaten.emit(pos, streak_val)

	run_manager.add_score(streak_val)
	score_value_label.text = "%06d" % run_manager.run_data.score
	move_interval = max(0.06, BASE_MOVE_INTERVAL - streak_val * STREAK_SPEED_BOOST)
	update_streak_visuals()
	streak_label.pulse()
	streak_multiplier.scale = Vector2(1.0, 1.0)
	var mt := create_tween().set_ease(Tween.EASE_OUT)
	mt.tween_property(streak_multiplier, "scale", Vector2(1.3, 1.3), 0.05)
	mt.tween_property(streak_multiplier, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_ELASTIC)
	combo_timer.bounce()
	border_scanner.trigger_dash()
	audio_manager.play_eat(streak_val)
	screen_shake.shake((streak_val - 1) * 0.8 + 0.5)
	var ft := floating_text_scene.new()
	ft.play(food_spawner.get_food_pos(), get_streak_color(streak_val), streak_val)
	game_area.add_child(ft)
	var exp := EXPLOSION_EFFECT.new()
	game_area.add_child(exp)
	exp.play(food_spawner.get_food_pos(), get_streak_color(streak_val), streak_val)
	run_manager.run_data.wave_time = WAVE_DURATION
	bg_shader.material.set("shader_parameter/wave_time", WAVE_DURATION)
	bg_shader.material.set("shader_parameter/wave_center", Vector2(
		float(food_spawner.get_food_pos().x) / GRID_WIDTH,
		float(food_spawner.get_food_pos().y) / GRID_HEIGHT
	))
	if streak_val == 5:
		run_manager.run_data.wave_flash = 0.15
		bg_shader.material.set("shader_parameter/wave_flash", 0.15)
	food_spawner.spawn(snake_controller.snake)
	trigger_growth_flash()

func _on_snake_hit() -> void:
	end_game()

func update_streak_visuals() -> void:
	var streak = run_manager.run_data.streak
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
		move_interval = BASE_MOVE_INTERVAL

static func get_streak_color(s: int) -> Color:
	match s:
		1: return Color("#33CC33")
		2: return Color("#3399FF")
		3: return Color("#FFCC00")
		4: return Color("#FF6600")
		5: return Color("#CC33FF")
		_: return Color(1, 0, 0, 1)

func update_body() -> void:
	for part in body_parts:
		part.queue_free()
	body_parts.clear()

	for i in range(1, snake_controller.snake.size()):
		var rect := ColorRect.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		rect.position = Vector2(snake_controller.snake[i]) * TILE_SIZE
		rect.color = Color(0, 0.7, 0, 1)
		snake_body.add_child(rect)
		body_parts.append(rect)

	snake_head.position = Vector2(snake_controller.snake[0]) * TILE_SIZE

func trigger_growth_flash() -> void:
	for i in body_parts.size():
		var part: ColorRect = body_parts[i]
		var delay := i * 0.01
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(part, "color", Color.WHITE, 0.01)
		tween.tween_property(part, "color", Color(0, 0.7, 0, 1), 10.0).set_ease(Tween.EASE_OUT)

func _on_game_over(_reason: String) -> void:
	game_over_frame.visible = true
	game_over_label.visible = true
	game_over_label.pulse()
	restart_label.visible = true

	if run_manager.run_data.score > best_score:
		best_score = run_manager.run_data.score
		high_score_value_label.text = "%06d" % best_score

	run_manager.set_streak(0)
	update_streak_visuals()

	var tw := create_tween()
	tw.tween_method(_set_game_over_fade, 0.0, 0.8, 0.5).set_ease(Tween.EASE_IN)

func _set_game_over_fade(v: float) -> void:
	bg_shader.material.set("shader_parameter/game_over_fade", v)

func _setup_retro_font() -> void:
	var base = load("res://fonts/PressStart2P-Regular.ttf")
	if not base:
		return
	var ls := LabelSettings.new()
	ls.font = base
	ls.outline_size = 1
	ls.outline_color = Color.BLACK
	var labels := [score_value_label, high_score_value_label, streak_multiplier, restart_label]
	for lbl in labels:
		lbl.label_settings = ls

func _on_game_started() -> void:
	reset_game()

func reset_game() -> void:
	run_manager.reset_run()
	snake_controller.reset(Vector2i(15, 9), Vector2i.RIGHT)
	move_interval = BASE_MOVE_INTERVAL
	move_timer = 0.0
	run_manager.run_data.wave_time = 0.0
	run_manager.run_data.wave_flash = 0.0
	bg_shader.material.set("shader_parameter/wave_time", 0.0)
	bg_shader.material.set("shader_parameter/wave_flash", 0.0)
	game_over_frame.visible = false
	game_over_label.visible = false
	restart_label.visible = false
	bg_shader.material.set("shader_parameter/game_over_fade", 0.0)
	score_value_label.text = "000000"
	high_score_value_label.text = "%06d" % best_score
	update_streak_visuals()

	snake_head.position = Vector2(snake_controller.snake[0]) * TILE_SIZE
	update_body()
	food_spawner.spawn(snake_controller.snake)

func end_game() -> void:
	event_bus.game_over.emit("death")
	game_manager.end_run("death")
