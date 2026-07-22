extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var border_width := 2.0
	var color := Color.BLACK
	var rect := Rect2(0, 0, 720, 432)
	draw_rect(rect, color, false, border_width)
