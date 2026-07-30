extends Node2D
const TILE_SIZE := 24
@onready var snake_head = $GameArea/SnakeHead
@onready var snake_body = $GameArea/SnakeBody
@onready var snake_controller: SnakeController = $GameArea/SnakeController
@onready var food_spawner: FoodSpawner = $GameArea/FoodSpawner
@onready var snake_renderer: SnakeRenderer = $GameArea/SnakeRenderer
@onready var hud: HUD = $HUD
@onready var eat_effects: EatEffects = $GameArea/EatEffects
@onready var door: Door = $GameArea/Door
@onready var enemy_container: Node2D = $GameArea/EnemyContainer
@onready var eb = get_node("/root/EventBus")
@onready var gm = get_node("/root/GameManager")
@onready var rm = get_node("/root/RunManager")
@onready var mm = get_node("/root/MapManager")
var move_timer := 0.0
var move_interval := 0.15
var enemies_alive := 0

var SlimeScene = preload("res://scenes/enemy/Slime.tscn")
var EnemyDataRes = preload("res://resources/EnemyData.gd")
func _ready() -> void:
	food_spawner.setup($GameArea/Food)
	snake_renderer.setup(snake_head, snake_body, snake_controller)
	snake_head.add_to_group("snake_head")
	hud.setup(rm, food_spawner)
	hud.setup_font()
	eb.game_over.connect(_on_game_over)
	eb.reset_requested.connect(reset_game)
	snake_controller.ate_food.connect(_on_snake_ate_food)
	snake_controller.hit_wall.connect(_on_snake_hit)
	snake_controller.hit_self.connect(_on_snake_hit)
	snake_controller.reached_door.connect(_on_reached_door)
	eb.damage_taken.connect(_on_damage_taken)
	eb.enemy_killed.connect(_on_enemy_killed)
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
		_check_enemy_collision()

func _check_enemy_collision() -> void:
	var head_pos = snake_controller.get_head_pos()
	for enemy in enemy_container.get_children():
		if not enemy.is_alive:
			continue
		if enemy.grid_pos == head_pos:
			enemy.take_damage(rm.run_data.stats.damage)
			eb.damage_taken.emit(enemy.data.damage, enemy.data.enemy_id)

func _on_snake_ate_food(pos: Vector2i) -> void:
	var s = rm.run_data.stats
	var streak_val = min(rm.run_data.streak + 1, 5)
	rm.set_streak(streak_val)
	rm.set_combo_time(s.combo_max_time)
	eb.food_eaten.emit(pos, streak_val)
	rm.add_score(streak_val)
	move_interval = max(s.min_move_interval, s.base_move_interval - streak_val * s.streak_speed_boost)
	hud.update_streak(streak_val)
	hud.animate_streak()
	hud.update_score(rm.run_data.score)
	rm.add_gold(streak_val)
	hud.update_gold(rm.run_data.gold)
	hud.notify_gold(streak_val)
	rm.add_xp(streak_val)
	hud.set_xp(rm.run_data.xp, rm.run_data.level * 50)
	hud.notify_xp(streak_val)
	hud.update_level(rm.run_data.level)
	hud.notify_streak(streak_val)
	eat_effects.play(pos, streak_val)
	if enemies_alive == 0:
		mm.mark_room_cleared()
		door.set_open(true)
		snake_controller.set_doors([Vector2i(29, 9)], true)
	food_spawner.spawn(snake_controller.snake)
	snake_renderer.trigger_growth_flash()

func _on_snake_hit() -> void: end_game()

func _on_reached_door() -> void:
	if not mm.advance_room():
		end_game()
		return
	enter_room()

func enter_room() -> void:
	var room = mm.get_current_room()
	door.set_open(false)
	snake_controller.reset(Vector2i(2, 9), Vector2i.RIGHT)
	snake_controller.set_doors([Vector2i(29, 9)], false)
	snake_renderer.update_body(snake_controller.snake)
	_spawn_enemies(room)
	food_spawner.spawn(snake_controller.snake)
	move_interval = rm.run_data.stats.base_move_interval
	move_timer = 0.0

func _spawn_enemies(room: RoomData) -> void:
	for child in enemy_container.get_children():
		child.queue_free()
	enemies_alive = 0
	for spawn in room.enemy_spawns:
		var pos = Vector2i(spawn.x, spawn.y)
		var etype = spawn.get("type", "slime")
		match etype:
			"slime":
				var data = EnemyDataRes.new()
				data.enemy_id = "slime"
				data.display_name = "Slime"
				data.max_hp = 30.0
				data.damage = 10.0
				data.speed = 1.0
				data.xp_drop = 10
				data.gold_drop = 5
				data.color = Color(0.2, 0.6, 0.2)
				var slime = SlimeScene.instantiate()
				slime.setup(data, pos)
				slime.died.connect(_on_enemy_died)
				enemy_container.add_child(slime)
				enemies_alive += 1

func _on_enemy_died(_enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		mm.mark_room_cleared()
		door.set_open(true)
		snake_controller.set_doors([Vector2i(29, 9)], true)

func _on_enemy_killed(_type: String, _pos: Vector2, xp: int, gold: int) -> void:
	rm.add_score(gold)
	rm.add_gold(gold)
	rm.add_xp(xp)
	hud.update_score(rm.run_data.score)
	hud.update_gold(rm.run_data.gold)
	hud.set_xp(rm.run_data.xp, rm.run_data.level * 50)
	hud.notify_xp(xp)
	hud.notify_gold(gold)

func _on_damage_taken(amount: float, _source: String) -> void:
	rm.take_damage(amount)
	hud.set_hp(rm.run_data.stats.hp, rm.run_data.stats.hp_max)

func _update_combo(delta: float) -> void:
	var combo = rm.run_data.get("combo_time", 0.0)
	if combo > 0:
		combo -= delta
		if combo <= 0:
			rm.set_streak(0)
			hud.update_streak(0)
	rm.set_combo_time(combo)
	hud.update_combo_bar(combo)

func reset_game() -> void:
	rm.reset_run()
	mm.generate_map()
	gm.current_state = gm.State.PLAYING
	hud.hide_game_over()
	hud.update_score(0)
	hud.update_gold(0)
	hud.update_level(1)
	hud.set_hp(rm.run_data.stats.hp, rm.run_data.stats.hp_max)
	hud.set_xp(0, rm.run_data.level * 50)
	hud.reset_visuals()
	enter_room()

func end_game() -> void:
	eb.game_over.emit("death")
	gm.end_run("death")

func _on_game_over(_reason: String) -> void:
	rm.set_streak(0)
	hud.update_streak(0)
	hud.show_game_over(rm.run_data.score)
	var tw: Tween = create_tween()
	tw.tween_method(hud.set_game_over_fade, 0.0, 0.8, 0.5).set_ease(Tween.EASE_IN)
