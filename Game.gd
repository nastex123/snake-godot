extends Node2D
const TILE_SIZE := 24
@onready var snake_head = $GameArea/SnakeHead
@onready var snake_body = $GameArea/SnakeBody
@onready var snake_controller: SnakeController = $GameArea/SnakeController
@onready var food_spawner: FoodSpawner = $GameArea/FoodSpawner
@onready var snake_renderer: SnakeRenderer = $GameArea/SnakeRenderer
@onready var streak_hud: StreakHUD = $StreakHUD
@onready var eat_effects: EatEffects = $GameArea/EatEffects
@onready var eb = get_node("/root/EventBus")
@onready var gm = get_node("/root/GameManager")
@onready var rm = get_node("/root/RunManager")
var move_timer := 0.0
var move_interval := 0.15
func _ready() -> void:
	food_spawner.setup($GameArea/Food)
	snake_renderer.setup(snake_head, snake_body, snake_controller)
	streak_hud.setup(rm, food_spawner)
	streak_hud.setup_font()
	eb.game_over.connect(_on_game_over)
	eb.reset_requested.connect(reset_game)
	snake_controller.ate_food.connect(_on_snake_ate_food)
	snake_controller.hit_wall.connect(_on_snake_hit)
	snake_controller.hit_self.connect(_on_snake_hit)
	reset_game()
func _process(delta: float) -> void:
	if gm.current_state == 7:
		if Input.is_action_just_pressed("ui_accept"): eb.reset_requested.emit()
		return
	handle_input()
	move_timer += delta
	if move_timer >= move_interval:
		move_timer = 0.0
		move_snake()
	_update_combo(delta)
	eat_effects.update_wave(delta, rm.run_data)

func handle_input() -> void:
	var dir = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"): dir = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down"): dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left"): dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right"): dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO: snake_controller.handle_input(dir)

func move_snake() -> void:
	if snake_controller.move(food_spawner.get_food_pos()):
		snake_renderer.update_body(snake_controller.snake)

func _on_snake_ate_food(pos: Vector2i) -> void:
	var s = rm.run_data.stats
	var streak_val = min(rm.run_data.streak + 1, 5)
	rm.set_streak(streak_val)
	rm.set_combo_time(s.combo_max_time)
	eb.food_eaten.emit(pos, streak_val)
	rm.add_score(streak_val)
	move_interval = max(s.min_move_interval, s.base_move_interval - streak_val * s.streak_speed_boost)
	streak_hud.update_streak(streak_val)
	streak_hud.animate_streak()
	streak_hud.update_score(rm.run_data.score)
	eat_effects.play(pos, streak_val)
	food_spawner.spawn(snake_controller.snake)
	snake_renderer.trigger_growth_flash()

func _on_snake_hit() -> void: end_game()

func _update_combo(delta: float) -> void:
	var combo = rm.run_data.get("combo_time", 0.0)
	if combo > 0:
		combo -= delta
		if combo <= 0:
			rm.set_streak(0)
			streak_hud.update_streak(0)
	rm.set_combo_time(combo)
	streak_hud.update_combo_bar(combo)

func reset_game() -> void:
	rm.reset_run()
	gm.current_state = gm.State.PLAYING
	snake_controller.reset(Vector2i(15, 9), Vector2i.RIGHT)
	move_interval = rm.run_data.stats.base_move_interval
	move_timer = 0.0
	rm.run_data.wave_time = 0.0
	rm.run_data.wave_flash = 0.0
	streak_hud.hide_game_over()
	streak_hud.update_score(0)
	streak_hud.reset_visuals()
	snake_renderer.update_body(snake_controller.snake)
	food_spawner.spawn(snake_controller.snake)

func end_game() -> void:
	eb.game_over.emit("death")
	gm.end_run("death")

func _on_game_over(_reason: String) -> void:
	rm.set_streak(0)
	streak_hud.update_streak(0)
	streak_hud.show_game_over(rm.run_data.score)
	var tw := create_tween()
	tw.tween_method(streak_hud.set_game_over_fade, 0.0, 0.8, 0.5).set_ease(Tween.EASE_IN)
