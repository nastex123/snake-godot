extends Area2D
class_name TowerLaser

# Láser de la Torre: cubre un segmento del grid (fila/columna) en píxeles.
# Daña a la cabeza una sola vez por disparo; se desvanece y se elimina solo.

var damage: float = 10.0
var source: String = "tower"
var _size := Vector2.ZERO
var _hit := false
var _core: ColorRect
var _glow: ColorRect

func setup(rect: Rect2, dmg: float, col: Color) -> void:
	damage = dmg
	position = rect.position + rect.size * 0.5
	_size = rect.size
	var shape = RectangleShape2D.new()
	shape.size = _size
	var cd = CollisionShape2D.new()
	cd.shape = shape
	add_child(cd)
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	_add_visuals(col)
	area_entered.connect(_on_area_entered)

func _add_visuals(col: Color) -> void:
	_glow = ColorRect.new()
	_glow.size = _size + Vector2(12, 12)
	_glow.position = -_size * 0.5 - Vector2(6, 6)
	_glow.color = Color(col.r, col.g, col.b, 0.3)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)
	_core = ColorRect.new()
	_core.size = _size
	_core.position = -_size * 0.5
	_core.color = col
	_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_core)

func _on_area_entered(area: Area2D) -> void:
	if _hit or not area.is_in_group("snake_head"):
		return
	_hit = true
	get_node("/root/EventBus").damage_taken.emit(damage, "tower")