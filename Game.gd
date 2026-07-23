extends Node2D

const TILE_SIZE := 24
const GRID_WIDTH := 30
const GRID_HEIGHT := 18
const COMBO_MAX_TIME := 3.0
const STREAK_SPEED_BOOST := 0.008
const BASE_MOVE_INTERVAL := 0.15

@onready var food: Area2D = $GameArea/Food
@onready var snake_head: Area2D = $GameArea/SnakeHead
@onready var snake_body: Node2D = $GameArea/SnakeBody
@onready var score_value_label: Label = $HUD/ScoreValue
@onready var best_value_label: Label = $HUD/BestValue
@onready var streak_label: Label = $HUD/StreakLabel
@onready var combo_timer: Control = $HUD/ComboTimer
@onready var game_over_label: Label = $HUD/GameOverLabel
@onready var restart_label: Label = $HUD/RestartLabel
@onready var border_scanner: Node2D = $GameArea/BorderScanner
@onready var screen_shake: Camera2D = $Camera2D
@onready var audio_manager: Node = $AudioManager
@onready var game_area: Node2D = $GameArea
@onready var bg_shader: ColorRect = $GameArea/GridBackgroundShader

var floating_text_scene = preload("res://FloatingText.gd")
const EXPLOSION_EFFECT = preload("res://ExplosionEffect.gd")

var snake: Array = []
var body_parts: Array = []
var direction := Vector2i.RIGHT
var next_direction := Vector2i.RIGHT
var score := 0
var best_score := 0
var game_over := false
var move_timer := 0.0
var move_interval := BASE_MOVE_INTERVAL
var food_pos := Vector2i.ZERO
var streak := 0
var combo_time := 0.0
var wave_time := 0.0
var wave_flash := 0.0
const WAVE_DURATION := 0.6

var head_visual
var food_visual: ColorRect

func _ready() -> void:
	randomize()

	head_visual = preload("res://SnakeHead.gd").new()
	head_visual.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	snake_head.add_child(head_visual)

	food_visual = ColorRect.new()
	food_visual.size = Vector2(TILE_SIZE, TILE_SIZE)
	food_visual.color = Color(1, 0, 0, 1)
	food.add_child(food_visual)

	reset_game()
	bg_shader.material.set("shader_parameter/streak_level", 0)
	bg_shader.material.set("shader_parameter/wave_flash", 0.0)

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			reset_game()
		return

	handle_input()
	move_timer += delta
	if move_timer >= move_interval:
		move_timer = 0.0
		move_snake()

	update_combo(delta)

	if wave_time > 0:
		wave_time = max(0.0, wave_time - delta)
		if wave_time > 0:
			bg_shader.material.set("shader_parameter/wave_time", wave_time)

	if wave_flash > 0:
		wave_flash = max(0.0, wave_flash - delta)
		bg_shader.material.set("shader_parameter/wave_flash", wave_flash)

func update_combo(delta: float) -> void:
	if combo_time > 0:
		combo_time -= delta
		if combo_time <= 0:
			combo_time = 0.0
			streak = 0
			update_streak_visuals()

	combo_timer.set_ratio(combo_time / COMBO_MAX_TIME)
	if streak == 0:
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

	if dir != Vector2i.ZERO and dir != -direction:
		next_direction = dir

func move_snake() -> void:
	direction = next_direction
	head_visual.update_direction(direction)
	var head_pos: Vector2i = snake[0] + direction

	if head_pos.x < 0 or head_pos.x >= GRID_WIDTH or head_pos.y < 0 or head_pos.y >= GRID_HEIGHT:
		end_game()
		return

	if head_pos in snake:
		end_game()
		return

	snake.insert(0, head_pos)

	var ate: bool = head_pos == food_pos
	if ate:
		streak = min(streak + 1, 5)
		combo_time = COMBO_MAX_TIME
		score += streak
		score_value_label.text = str(score)
		move_interval = max(0.06, BASE_MOVE_INTERVAL - streak * STREAK_SPEED_BOOST)
		update_streak_visuals()
		border_scanner.trigger_dash()
		audio_manager.play_eat(streak)
		screen_shake.shake((streak - 1) * 0.8 + 0.5)
		var ft := floating_text_scene.new()
		ft.play(food_pos, get_streak_color(streak), streak)
		game_area.add_child(ft)
		var exp := EXPLOSION_EFFECT.new()
		game_area.add_child(exp)
		exp.play(food_pos, get_streak_color(streak), streak)
		wave_time = WAVE_DURATION
		bg_shader.material.set("shader_parameter/wave_time", WAVE_DURATION)
		bg_shader.material.set("shader_parameter/wave_center", Vector2(
			float(food_pos.x) / GRID_WIDTH,
			float(food_pos.y) / GRID_HEIGHT
		))
		if streak == 5:
			wave_flash = 0.15
			bg_shader.material.set("shader_parameter/wave_flash", wave_flash)
		spawn_food()
	else:
		snake.pop_back()

	update_body()
	if ate:
		trigger_growth_flash()

func update_streak_visuals() -> void:
	if streak > 0:
		streak_label.text = "STREAK x" + str(streak)
		var c := get_streak_color(streak)
		food_visual.color = c
		border_scanner.set_streak(streak)
		border_scanner.set_active(true)
		combo_timer.set_color(c)
		bg_shader.material.set("shader_parameter/streak_level", streak)
	else:
		streak_label.text = ""
		food_visual.color = Color(1, 0, 0, 1)
		border_scanner.set_streak(0)
		border_scanner.set_active(false)
		combo_timer.set_color(Color(1.0, 0.53, 0.0, 1.0))
		bg_shader.material.set("shader_parameter/streak_level", 0)
		move_interval = BASE_MOVE_INTERVAL

static func get_streak_color(s: int) -> Color:
	match s:
		1: return Color(1.0, 0.53, 0.0)
		2: return Color(1.0, 0.84, 0.0)
		3: return Color(0.2, 0.9, 0.48)
		4: return Color(0.2, 0.67, 1.0)
		5: return Color(0.8, 0.27, 1.0)
		_: return Color(1, 0, 0, 1)

func update_body() -> void:
	for part in body_parts:
		part.queue_free()
	body_parts.clear()

	for i in range(1, snake.size()):
		var rect := ColorRect.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		rect.position = Vector2(snake[i]) * TILE_SIZE
		rect.color = Color(0, 0.7, 0, 1)
		snake_body.add_child(rect)
		body_parts.append(rect)

	snake_head.position = Vector2(snake[0]) * TILE_SIZE

func trigger_growth_flash() -> void:
	for i in body_parts.size():
		var part: ColorRect = body_parts[i]
		var delay := i * 0.01
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(part, "color", Color.WHITE, 0.01)
		tween.tween_property(part, "color", Color(0, 0.7, 0, 1), 10.0).set_ease(Tween.EASE_OUT)

func spawn_food() -> void:
	var free_cells: Array = []
	for x in GRID_WIDTH:
		for y in GRID_HEIGHT:
			var cell := Vector2i(x, y)
			if not cell in snake:
				free_cells.append(cell)

	if free_cells.is_empty():
		return

	food_pos = free_cells[randi() % free_cells.size()]
	food.position = Vector2(food_pos) * TILE_SIZE

func end_game() -> void:
	game_over = true
	game_over_label.visible = true
	restart_label.visible = true

	if score > best_score:
		best_score = score
		best_value_label.text = str(best_score)

	combo_time = 0.0
	streak = 0
	update_streak_visuals()

	var tw := create_tween()
	tw.tween_method(_set_game_over_fade, 0.0, 0.8, 0.5).set_ease(Tween.EASE_IN)

func _set_game_over_fade(v: float) -> void:
	bg_shader.material.set("shader_parameter/game_over_fade", v)

func reset_game() -> void:
	snake.clear()
	snake.append(Vector2i(15, 9))
	snake.append(Vector2i(14, 9))
	snake.append(Vector2i(13, 9))
	snake.append(Vector2i(12, 9))
	direction = Vector2i.RIGHT
	next_direction = Vector2i.RIGHT
	score = 0
	move_interval = BASE_MOVE_INTERVAL
	move_timer = 0.0
	game_over = false
	streak = 0
	combo_time = 0.0
	wave_time = 0.0
	wave_flash = 0.0
	bg_shader.material.set("shader_parameter/wave_time", 0.0)
	bg_shader.material.set("shader_parameter/wave_flash", 0.0)
	game_over_label.visible = false
	restart_label.visible = false
	bg_shader.material.set("shader_parameter/game_over_fade", 0.0)
	score_value_label.text = "0"
	update_streak_visuals()

	snake_head.position = Vector2(snake[0]) * TILE_SIZE
	head_visual.update_direction(direction)

	update_body()
	spawn_food()
