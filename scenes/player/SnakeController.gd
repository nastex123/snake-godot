extends Node2D
class_name SnakeController

const TILE_SIZE := 24
const GRID_WIDTH := 30
const GRID_HEIGHT := 18

signal moved(head_pos: Vector2i)
signal ate_food(head_pos: Vector2i)
signal hit_wall()
signal hit_self()

var snake: Array = []
var direction := Vector2i.RIGHT
var next_direction := Vector2i.RIGHT
var head_visual: Node

func setup(start_pos: Vector2i, start_dir: Vector2i) -> void:
	snake = [start_pos, start_pos + Vector2i.LEFT, start_pos + Vector2i.LEFT * 2, start_pos + Vector2i.LEFT * 3]
	direction = start_dir
	next_direction = start_dir

func set_head_visual(visual: Node) -> void:
	head_visual = visual

func handle_input(dir: Vector2i) -> void:
	if dir != Vector2i.ZERO and dir != -direction:
		next_direction = dir

func move(food_pos: Vector2i) -> bool:
	direction = next_direction
	if head_visual and head_visual.has_method("update_direction"):
		head_visual.update_direction(direction)

	var head_pos: Vector2i = snake[0] + direction

	if head_pos.x < 0 or head_pos.x >= GRID_WIDTH or head_pos.y < 0 or head_pos.y >= GRID_HEIGHT:
		hit_wall.emit()
		return false

	if head_pos in snake:
		hit_self.emit()
		return false

	snake.insert(0, head_pos)

	var ate := head_pos == food_pos
	if ate:
		ate_food.emit(head_pos)
	else:
		snake.pop_back()

	moved.emit(snake[0])
	return true

func get_head_pos() -> Vector2i:
	return snake[0]

func reset(start_pos: Vector2i, start_dir: Vector2i) -> void:
	snake.clear()
	setup(start_pos, start_dir)