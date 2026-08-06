# FASE 03 — Sistema de salas

## Objetivo

Eliminar el tablero único. Crear un sistema de habitaciones conectadas que el jugador explora en cada run.

---

## Orden de implementación

### Paso 1: RoomData (Resource)

**Archivo:** `resources/RoomData.gd`

```gdscript
extends Resource
class_name RoomData

enum RoomType { NORMAL, ELITE, EVENT, REST, TREASURE, SHOP, BOSS, START }

@export var room_id: String
@export var room_type: RoomType
@export var grid_width: int = 30
@export var grid_height: int = 18
@export var enemy_spawns: Array[Dictionary] = []
@export var connections: Array[Vector2i] = []
@export var decoration_tiles: Array[Vector2i] = []
@export var ambient_color: Color = Color(0.035, 0.039, 0.047, 1)

func get_type_name() -> String:
    match room_type:
        RoomType.NORMAL: return "Normal"
        RoomType.ELITE: return "Elite"
        RoomType.EVENT: return "Evento"
        RoomType.REST: return "Descanso"
        RoomType.TREASURE: return "Tesoro"
        RoomType.SHOP: return "Tienda"
        RoomType.BOSS: return "Jefe"
        RoomType.START: return "Inicio"
    return "Desconocido"
```

### Paso 2: RoomManager

**Archivo:** `scripts/RoomManager.gd`

```gdscript
extends Node
class_name RoomManager

signal room_changed(room_id: String, room_type: int)
signal room_cleared(room_id: String)
signal door_opened(door_index: int, target_room_id: String)

var current_room: RoomData = null
var rooms: Dictionary = {}
var cleared_rooms: Array[String] = []

func generate_run(seed_value: int) -> void:
    seed(seed_value)
    rooms.clear()
    cleared_rooms.clear()
    _generate_room_tree()

func _generate_room_tree() -> void:
    # Algoritmo simple: 3-4 ramas con 2-4 salas cada una
    # Sala inicial (START) → ramas → jefe al final
    var room_id = 0
    var start = _create_room(room_id, RoomData.RoomType.START, Vector2i(0, 0))
    rooms[str(room_id)] = start
    room_id += 1
    
    var branches = randi() % 2 + 3  # 3-4 ramas
    for b in branches:
        var depth = randi() % 3 + 2  # 2-4 salas por rama
        var prev_pos = Vector2i(0, 0)
        for d in depth:
            var pos = Vector2i(b + 1, d)
            var type = _random_room_type()
            var room = _create_room(room_id, type, pos)
            rooms[str(room_id)] = room
            _connect_rooms(str(room_id - 1), str(room_id))
            room_id += 1
            prev_pos = pos
        # Sala de jefe al final de cada rama
        var boss = _create_room(room_id, RoomData.RoomType.BOSS, Vector2i(b + 1, depth))
        rooms[str(room_id)] = boss
        _connect_rooms(str(room_id - 1), str(room_id))
        room_id += 1

func _random_room_type() -> RoomData.RoomType:
    var roll = randf()
    if roll < 0.4: return RoomData.RoomType.NORMAL
    elif roll < 0.6: return RoomData.RoomType.ELITE
    elif roll < 0.75: return RoomData.RoomType.EVENT
    elif roll < 0.85: return RoomData.RoomType.TREASURE
    elif roll < 0.95: return RoomData.RoomType.SHOP
    else: return RoomData.RoomType.REST

func enter_room(room_id: String) -> void:
    current_room = rooms[room_id]
    room_changed.emit(room_id, current_room.room_type)

func mark_cleared(room_id: String) -> void:
    cleared_rooms.append(room_id)
    room_cleared.emit(room_id)
```

### Paso 3: Room scene

**Archivo:** `scenes/rooms/Room.tscn`
**Script:** `scenes/rooms/Room.gd`

```gdscript
extends Node2D
class_name Room

@export var room_data: RoomData
@export var grid: Node2D
@export var border: Node2D
@export var doors: Array[Door]

func setup(data: RoomData) -> void:
    room_data = data
    _build_grid()
    _place_doors()

func _build_grid() -> void:
    # Usar GridBackgroundShader y GridBorder existentes
    # Ajustar shader según room_data.ambient_color

func _place_doors() -> void:
    for i in doors.size():
        var door = doors[i]
        var target = room_data.connections[i]
        door.setup(target, room_data.room_type)
```

### Paso 4: Door scene

**Archivo:** `scenes/rooms/Door.tscn`
**Script:** `scenes/rooms/Door.gd`

```gdscript
extends Area2D
class_name Door

signal entered(target_room_id: String)

@export var target_room_id: String = ""
@export var icon: Sprite2D
@export var label: Label

var door_type: int = 0

func setup(target_id: String, type: int) -> void:
    target_room_id = target_id
    door_type = type
    label.text = _type_name(type)
    icon.modulate = _type_color(type)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        entered.emit(target_room_id)

func _type_name(type: int) -> String:
    match type:
        0: return ""
        1: return "⚔"
        2: return "⭐"
        3: return "?"
        4: return "🛌"
        5: return "💎"
        6: return "🛒"
        7: return "👹"
    return "?"
```

### Paso 5: RoomMap (minimap data)

**Archivo:** `scripts/RoomMap.gd`

```gdscript
extends Resource
class_name RoomMap

@export var nodes: Dictionary = {}  # room_id → { pos, type, connections, cleared }

func get_available_rooms(room_id: String) -> Array:
    var result = []
    if nodes.has(room_id):
        for conn_id in nodes[room_id].connections:
            if not nodes[conn_id].cleared:
                result.append(conn_id)
    return result
```

---

## Conexiones con EventBus

| Evento | Reacción |
|--------|----------|
| `room_changed` | Minimap.highlight_current(), parar/pausar sala anterior |
| `room_cleared` | Marcar sala como completada, activar puertas de salida |
| `door_opened` | Transición animada (fade out → cargar sala → fade in) |
| `enemy_killed` | Verificar si todos los enemigos han muerto → room_cleared |

---

## Criterios de aceptación

- [ ] Cada run genera un árbol de salas diferente (semilla controlada)
- [ ] 7 tipos de sala funcionales con iconos y colores distintos
- [ ] Puertas con iconos visibles (⚔️⭐💎🛒🛌👹)
- [ ] Al cruzar puerta, transición animada a nueva sala
- [ ] RoomData carga configuración (tamaño, enemigos, color)
- [ ] Minimap refleja el árbol de salas correctamente
- [ ] Salas de jefe bloquean el avance hasta derrotar al jefe
- [ ] Salas de EVENT/REST/TREASURE/SHOP funcionales (contenido básico)
- [ ] No hay errores (grid no se duplica, puertas se conectan)

---

## Notas técnicas Godot

- Room se instancia como hijo de GameArea (o un nodo contenedor)
- Al cambiar de sala, la anterior se oculta o se elimina (según memoria)
- Usar `change_scene_to_file()` para salas grandes, o simplemente cambiar nodos hijos para salas pequeñas
- La transición usa AnimationPlayer con fade out/in
- Las puertas son Area2D con CollisionShape2D en el borde de la sala
- El grid_background.gdshader existente se reutiliza, ajustando parámetros por sala