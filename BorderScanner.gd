extends Node2D

const INSET := 3.0
const BOARD_W := 720.0 - INSET * 2.0
const BOARD_H := 432.0 - INSET * 2.0
const PERIMETER := 2.0 * (BOARD_W + BOARD_H)
const HALF_PERIMETER := PERIMETER / 2.0

const TRAIL_COUNT := 100
const TRAIL_SPACING := 4.0
const TRAIL_SIZE := 12.0
const HEAD_SIZE := 12.0

const NORMAL_SPEED := 70.0
const DASH_TOP_SPEED := 450.0
const DASH_DURATION := 0.15
const FADE_RATE := 4.0

var pos := 0.0
var dash_time := 0.0
var alpha := 0.0
var target_alpha := 0.0
var active := false
var streak := 0

func set_active(v: bool) -> void:
	active = v
	target_alpha = 1.0 if v else 0.0

func set_streak(v: int) -> void:
	streak = v

static func base_color(level: int) -> Color:
	match level:
		1: return Color(1.0, 0.53, 0.0)
		2: return Color(1.0, 0.84, 0.0)
		3: return Color(0.2, 0.9, 0.48)
		4: return Color(0.2, 0.67, 1.0)
		5: return Color(0.8, 0.27, 1.0)
		_: return Color(1, 1, 1)

func trigger_dash() -> void:
	if alpha > 0.01:
		dash_time = DASH_DURATION

func _process(delta: float) -> void:
	alpha = move_toward(alpha, target_alpha, delta * FADE_RATE)
	if alpha < 0.01 and not active:
		return

	var speed := NORMAL_SPEED
	if dash_time > 0:
		dash_time -= delta
		var dash_progress := dash_time / DASH_DURATION
		speed = NORMAL_SPEED + (DASH_TOP_SPEED - NORMAL_SPEED) * dash_progress

	pos = fmod(pos + speed * delta, PERIMETER)
	queue_redraw()

func _draw() -> void:
	if alpha < 0.01:
		return

	var is_dash := dash_time > 0.0

	var p1 := pos
	var p2 := fmod(pos + HALF_PERIMETER, PERIMETER)

	draw_one(p1, is_dash)
	draw_one(p2, is_dash)

func draw_one(p: float, dash: bool) -> void:
	var bc := base_color(streak)
	var sz := TRAIL_SIZE * (1.5 if dash else 1.0)

	for i in TRAIL_COUNT:
		var t := float(i) / TRAIL_COUNT
		var tp := fmod(p - i * TRAIL_SPACING + PERIMETER, PERIMETER)
		var a := (1.0 - t) * alpha
		var c := bc * (1.0 - t * 0.5)
		if dash:
			c = Color(min(1.0, c.r * 1.15), min(1.0, c.g * 1.15), min(1.0, c.b * 1.15))
			a = min(1.0, a * 1.4)
		draw_at(tp, sz, Color(c.r, c.g, c.b, a))

	var head_a := alpha
	draw_at(p, HEAD_SIZE * (1.3 if dash else 1.0), Color(bc.r, bc.g, bc.b, head_a))

	if dash:
		draw_at(p, HEAD_SIZE * 2.5, Color(bc.r, bc.g, bc.b, alpha * 0.15))

func draw_at(p: float, size: float, color: Color) -> void:
	var v := perimeter_to_pos(p)
	var half := size / 2.0
	draw_rect(Rect2(v.x - half, v.y - half, size, size), color)

func perimeter_to_pos(p: float) -> Vector2:
	var pp := fmod(p, PERIMETER)
	if pp < BOARD_W:
		return Vector2(INSET + pp, INSET)
	pp -= BOARD_W
	if pp < BOARD_H:
		return Vector2(INSET + BOARD_W, INSET + pp)
	pp -= BOARD_H
	if pp < BOARD_W:
		return Vector2(INSET + BOARD_W - pp, INSET + BOARD_H)
	pp -= BOARD_W
	return Vector2(INSET, INSET + BOARD_H - pp)
