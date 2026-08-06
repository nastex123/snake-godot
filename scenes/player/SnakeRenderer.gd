extends Node2D
class_name SnakeRenderer

const TILE_SIZE := 24

var body_parts: Array = []
var head: Area2D
var body_node: Node2D
var ctrl

func setup(head_node: Area2D, body_parent: Node2D, controller) -> void:
	head = head_node
	body_node = body_parent
	ctrl = controller
	var hv = preload("res://SnakeHead.gd").new()
	hv.position = Vector2(12, 12)
	head.add_child(hv)
	ctrl.set_head_visual(hv)

func update_body(snake: Array) -> void:
	for c in body_node.get_children():
		c.queue_free()
	body_parts.clear()

	for i in range(1, snake.size()):
		var rect := ColorRect.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		rect.position = Vector2(snake[i]) * TILE_SIZE
		rect.color = Color(0, 0.7, 0, 1)
		body_node.add_child(rect)
		body_parts.append(rect)

	head.position = Vector2(snake[0]) * TILE_SIZE

func trigger_growth_flash() -> void:
	for i in body_parts.size():
		var part: ColorRect = body_parts[i]
		var delay := i * 0.01
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(part, "color", Color.WHITE, 0.01)
		tween.tween_property(part, "color", Color(0, 0.7, 0, 1), 10.0).set_ease(Tween.EASE_OUT)
