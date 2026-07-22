extends Control

const TRACK_HEIGHT := 6
const CATCHUP_SPEED := 5.0

const COLOR_TRACK := Color(0.08, 0.08, 0.08, 0.85)
const COLOR_BUFFER := Color(0.5, 0.5, 0.5, 0.5)
const COLOR_FILL := Color(1.0, 0.53, 0.0, 1.0)

var ratio := 0.0
var fill_ratio := 0.0
var fill_color := COLOR_FILL

func set_ratio(v: float) -> void:
	ratio = clampf(v, 0.0, 1.0)

func set_color(c: Color) -> void:
	fill_color = c

func _process(delta: float) -> void:
	fill_ratio = move_toward(fill_ratio, ratio, delta * CATCHUP_SPEED)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	draw_rect(Rect2(0, 0, w, h), COLOR_TRACK)

	var bw := w * ratio
	if bw > 0:
		draw_rect(Rect2(0, 0, bw, h), COLOR_BUFFER)

	var fw := w * fill_ratio
	if fw > 0:
		draw_rect(Rect2(0, 0, fw, h), fill_color)
