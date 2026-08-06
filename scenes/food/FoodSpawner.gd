extends Node2D
class_name FoodSpawner

const TILE_SIZE := 24
const GRID_WIDTH := 30
const GRID_HEIGHT := 18

var food: Area2D
var food_pos := Vector2i.ZERO
var food_visual: ColorRect

func setup(food_node: Area2D) -> void:
	food = food_node
	food_visual = ColorRect.new()
	food_visual.size = Vector2(TILE_SIZE, TILE_SIZE)
	food_visual.color = Color(1, 0, 0, 1)
	food.add_child(food_visual)

func spawn(snake: Array) -> void:
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

func get_food_pos() -> Vector2i:
	return food_pos

func set_food_color(color: Color) -> void:
	if food_visual:
		food_visual.color = color