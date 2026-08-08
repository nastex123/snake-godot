# FASE 04 — Enemigos y combate

## Objetivo

Transformar el Snake en un juego de acción con 5 tipos de enemigos, IA, proyectiles y sistema de combate completo.

---

## Orden de implementación

### Paso 1: EnemyData (Resource)

**Archivo:** `resources/EnemyData.gd`

```gdscript
extends Resource
class_name EnemyData

enum EnemyType { SLIME, SPIDER, TOWER, GHOST, WORM, ELITE }

@export var enemy_id: String
@export var enemy_type: EnemyType
@export var display_name: String
@export var max_hp: float = 50.0
@export var damage: float = 10.0
@export var speed: float = 1.0
@export var attack_cooldown: float = 1.0
@export var xp_drop: int = 10
@export var gold_drop: int = 5
@export var grid_size: Vector2i = Vector2i(1, 1)  # para Worm
@export var projectile_scene: PackedScene
@export var sprite: Texture2D
@export var color: Color = Color.WHITE
```

### Paso 2: Enemy base

**Archivo:** `scenes/enemy/Enemy.gd`

```gdscript
extends Area2D
class_name Enemy

@export var data: EnemyData
signal died(enemy: Enemy)
signal hp_changed(current: float, max_hp: float)

var current_hp: float = 0.0
var is_alive: bool = true
var grid_pos: Vector2i
var _attack_timer: float = 0.0

func setup(enemy_data: EnemyData, position: Vector2i) -> void:
    data = enemy_data
    grid_pos = position
    global_position = Vector2(position) * 24
    current_hp = data.max_hp

func take_damage(amount: float) -> void:
    if not is_alive: return
    current_hp -= amount
    hp_changed.emit(current_hp, data.max_hp)
    if current_hp <= 0:
        die()

func die() -> void:
    is_alive = false
    died.emit(self)
    # partículas, sonido, loot
    EventBus.enemy_killed.emit(data.enemy_type, global_position)
    queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("snake_head") and is_alive:
        # Daño al jugador (vía DamageSystem)
        pass
```

### Paso 3: Slime

**Archivo:** `scenes/enemy/Slime.gd`

```gdscript
extends Enemy
class_name Slime

var move_timer: float = 0.0
var move_interval: float = 0.8

func _process(delta: float) -> void:
    if not is_alive: return
    move_timer += delta
    if move_timer >= move_interval:
        move_timer = 0.0
        _move_toward_player()

func _move_toward_player() -> void:
    var player_pos = GameManager.get_player_grid_pos()
    if player_pos == Vector2i.ZERO: return
    
    var dir = player_pos - grid_pos
    var move_dir = Vector2i.ZERO
    if abs(dir.x) > abs(dir.y):
        move_dir = Vector2i(sign(dir.x), 0)
    else:
        move_dir = Vector2i(0, sign(dir.y))
    
    var new_pos = grid_pos + move_dir
    if RoomManager.is_cell_available(new_pos):
        grid_pos = new_pos
        var tw = create_tween()
        tw.tween_property(self, "global_position", Vector2(new_pos) * 24, move_interval * 0.9)
```

### Paso 4: Spider

**Archivo:** `scenes/enemy/Spider.gd`

```gdscript
extends Enemy
class_name Spider

var move_timer: float = 0.0
var move_interval: float = 0.3  # más rápido que Slime

func _process(delta: float) -> void:
    if not is_alive: return
    move_timer += delta
    if move_timer >= move_interval:
        move_timer = 0.0
        _move_toward_player()

func _move_toward_player() -> void:
    var player_pos = GameManager.get_player_grid_pos()
    if player_pos == Vector2i.ZERO: return
    var dir = player_pos - grid_pos
    var move_dir = Vector2i(sign(dir.x), 0) if abs(dir.x) > 0 else Vector2i(0, sign(dir.y))
    var new_pos = grid_pos + move_dir
    if RoomManager.is_cell_available(new_pos):
        grid_pos = new_pos
        global_position = Vector2(new_pos) * 24
```

### Paso 5: Tower

**Archivo:** `scenes/enemy/Tower.gd`

```gdscript
extends Enemy
class_name Tower

func _ready() -> void:
    _attack_timer = data.attack_cooldown

func _process(delta: float) -> void:
    if not is_alive: return
    _attack_timer -= delta
    if _attack_timer <= 0:
        _attack_timer = data.attack_cooldown
        _shoot()

func _shoot() -> void:
    var player_pos = GameManager.get_player_grid_pos()
    var dir = (Vector2(player_pos) - Vector2(grid_pos)).normalized()
    var proj = data.projectile_scene.instantiate()
    proj.setup(grid_pos, dir, data.damage)
    get_parent().add_child(proj)
```

### Paso 6: Ghost

**Archivo:** `scenes/enemy/Ghost.gd`

Atraviesa obstáculos (no colisiona con el cuerpo de la serpiente ni con otras entidades).

```gdscript
extends Enemy
class_name Ghost

func _ready() -> void:
    # Sin colisión física — solo daño al superponerse
    monitoring = false
    set_process(true)

func _process(delta: float) -> void:
    if not is_alive: return
    _move_toward_player()
    _check_overlap()

func _move_toward_player() -> void:
    var player_pos = GameManager.get_player_grid_pos()
    var dir = sign(Vector2(player_pos - grid_pos))
    grid_pos += Vector2i(dir)
    global_position = Vector2(grid_pos) * 24

func _check_overlap() -> void:
    var player_pos = GameManager.get_player_grid_pos()
    if grid_pos == player_pos:
        EventBus.damage_taken.emit(data.damage, "ghost")
```

### Paso 7: Worm

**Archivo:** `scenes/enemy/Worm.gd`

Ocupa 2+ casillas. Se mueve como un mini-snake.

```gdscript
extends Enemy
class_name Worm

var segments: Array[Vector2i] = []
var move_timer: float = 0.0
var move_interval: float = 0.5

func setup(enemy_data: EnemyData, position: Vector2i) -> void:
    super.setup(enemy_data, position)
    segments = [position, position + Vector2i.LEFT, position + Vector2i.LEFT * 2]
    _update_visuals()

func _process(delta: float) -> void:
    if not is_alive: return
    move_timer += delta
    if move_timer >= move_interval:
        move_timer = 0.0
        _move()

func _move() -> void:
    var player_pos = GameManager.get_player_grid_pos()
    var dir = _choose_best_dir(player_pos)
    var new_head = segments[0] + dir
    # Check colisión con bordes/propio cuerpo
    if RoomManager.is_cell_available(new_head) and not new_head in segments:
        segments.push_front(new_head)
        segments.pop_back()
        _update_visuals()

func die() -> void:
    for seg in segments:
        # liberar celdas ocupadas
        pass
    super.die()
```

### Paso 8: Elite

**Archivo:** `scenes/enemy/Elite.gd`

Versión potenciada de cualquier enemigo base. Stats multiplicados, loot mejorado.

```gdscript
extends Enemy
class_name Elite

func setup(enemy_data: EnemyData, position: Vector2i) -> void:
    var elite_data = enemy_data.duplicate()
    elite_data.max_hp *= 3.0
    elite_data.damage *= 2.0
    elite_data.speed *= 1.5
    elite_data.xp_drop *= 5
    elite_data.gold_drop *= 10
    super.setup(elite_data, position)
    modulate = Color(1, 0.8, 0.2)  # dorado
```

### Paso 9: Projectile system

**Archivo:** `scenes/projectiles/Projectile.gd`

```gdscript
extends Area2D
class_name Projectile

var grid_pos: Vector2i
var direction: Vector2
var speed: float = 200.0
var damage: float = 10.0
var pierce: bool = false

func setup(pos: Vector2i, dir: Vector2, dmg: float) -> void:
    grid_pos = pos
    direction = dir
    damage = dmg
    global_position = Vector2(pos) * 24 + Vector2(12, 12)

func _process(delta: float) -> void:
    global_position += direction * speed * delta
    # Si sale del grid, queue_free()
    if global_position.x < -24 or global_position.x > 720 or global_position.y < -24 or global_position.y > 432:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("snake_head"):
        EventBus.damage_taken.emit(damage, "projectile")
        if not pierce:
            queue_free()
```

---

## Spawn de enemigos

En RoomManager, al entrar a una sala:

```gdscript
func spawn_enemies(room_data: RoomData) -> void:
    for spawn in room_data.enemy_spawns:
        var data = load(spawn.data_path)
        var enemy_scene = load(spawn.scene_path)
        var enemy = enemy_scene.instantiate()
        enemy.setup(data, Vector2i(spawn.x, spawn.y))
        add_child(enemy)
```

---

## Conexiones con EventBus

| Evento | Reacción |
|--------|----------|
| `damage_taken` | Restar vida en RunManager, animación de daño |
| `enemy_killed` | Sumar XP/oro, verificar sala limpia |
| `room_cleared` | Desactivar spawn, abrir puertas de salida |

---

## Criterios de aceptación

- [ ] 5 tipos de enemigos funcionales (Slime, Spider, Tower, Ghost, Worm)
- [ ] Elite version potenciada con color dorado
- [ ] Proyectiles viajan y hacen daño al impactar
- [ ] IA básica funcional: persecución, disparo, ataque
- [ ] Ghost atraviesa obstáculos correctamente
- [ ] Worm ocupa múltiples casillas y se mueve como mini-snake
- [ ] Enemigos dropean XP y oro al morir
- [ ] Daño al jugador reduce vida (no muerte instantánea)
- [ ] Spawn de enemigos desde RoomData
- [ ] Sala se limpia cuando todos los enemigos mueren
- [ ] No hay errores de colisión o pathfinding

### Slime (mejorado — completado ✅ 2026-08-05)

A diferencia del MVP (persecución recta), el Slime ahora:

- **Movimiento a saltos (hop)**: fases cargar→salto→aterrizar→pausa, salto 1-2 casillas
  con diagonal, curvas elásticas y gotas de goo.
- **Árbol de decisión por grupo** (aliados a ≤4 casillas): Solo (persecución directa,
  intercepta el rumbo), Pinza (cierra el eje con menor hueco para triangular) y Mural
  (Perseguidor + Corte-de-salida empujan hacia bordes).
- **Cooldown por golpe + encogimiento**: ~0.5 s sin daño tras ser golpeado (anti
  stun-lock); el golpe encoge Medium→Small (pierde elegibilidad de fusión) y
  recupera tamaño al alejarse el jugador.
- **Fusión → Slime Grande 2×2**: disparada por tiempo de acoso (2-3 elegibles
  adyacentes); suma HP/daño; footprint 2×2 con `occupies_cell`; `merged` decrementa
  contador de sala.
- Balance data-driven en `EnemyData.gd` (hops, radios, umbrales, cooldowns, tallas)
  — sin números mágicos.

Ver `Documentacion/GDD.md` → `# Enemigos → ## Slime` para el diseño completo.

### SlimePack — manada táctica (completado ✅ 2026-08-06)

El árbol reactivo por conteo de aliados pasó a un **coordinador de manada** por sala:

- **Nodo `SlimePack`** (uno por sala, en `EnemyContainer`): percepción compartida,
  estados de manada, asignación de slots, roles, memoria y decisión de fusión.
- **Estados**: `SEARCH` (sin contacto) → `REGROUP` (dispersos) → `WRAP` (2+ cerca) →
  `PRESS` (pocas rutas de escape) → `FUSE` (presión + elegibles). Todos los miembros
  leen el mismo estado, no deciden por separado.
- **Pressure System**: la presión se calcula por **lados direccionales cubiertos**
  alrededor del jugador (1 lado=1, 2=2.5, 3=4.5, 4=6), no por cantidad de slimes.
  La fusión/agresividad dependen de la calidad del cerco.
- **Slots reservados**: cada tick el pack asigna a cada vivo un slot radial único
  alrededor del jugador (pool compartido → sin dos slimes al mismo destino; respeta
  la regla de separación de `notas.md`). Si el pool se agota, el miembro cae a
  persecución con dirección propia.
- **Roles**: `persecutor` (frente), `shepherd` (empuja a pared), `anchor` (cierra la
  retirada), `see` (corte). Asignados por posición del slot vs jugador + memoria.
- **Memoria de sala**: `preferred_dir` / `last_escape`, con damping de
  `pack_memory_time` — el grupo recuerda por dónde escapó el jugador y cierra ese lado.
- **Fusión táctica**: la manada decide fusionar cuando presión ≥ `pack_pressure_fuse`
  + ≥ `pack_fuse_min_members` MEDIUM elegibles + HP promedio > `pack_fuse_hp_ratio`
  + pocos encogidos. Reemplaza al timer de acoso (`merge_harass_time`).
- **Canalización interactiva**: los elegidos entran en `CHANNEL` (1s, vibración + aura,
  dejan de perseguir). El jugador puede interrumpir golpeando (el pack cancela todo el
  grupo), separándolos o encogiéndolos.
- **Personalidad como pesos de decisión** (no stats): `impulsive`/`cautious`/`heavy`/
  `light`/`social` con jitter determinista por posición — evita la sincronía visual.

Balance data-driven en `EnemyData.gd` (`pack_*`), sin números mágicos. Estado scoped
a la sala (se resetea al entrar en una nueva).

Ver `Documentacion/CHANGELOG.md` (2026-08-06) para la validación headless.

### Torre — láser fijo (completado ✅ 2026-08-07)

Enemigo **estático** que dispara láseres en direcciones cardinales fijas (el patrón
se define al spawn, no apunta al jugador):

- **Ciclo**: `AIM` (telegraph) → `FIRE` (láser) → `COOLDOWN` → `AIM`.
- **Golpe según estado** (override de `take_damage`):
  - `AIM`: el **jugador** recibe `data.damage` (reflejo); la torre no pierde vida ni
    se cancela (`return false` + emitir `damage_taken` nosotros, sin doble-emit).
  - `FIRE`: muere de **1 golpe**.
  - `COOLDOWN`: contador `_cooldown_hits` — sobrevive al 1er golpe, muere al 2º.
- **Patrones** (`TowerPattern`): `SINGLE_LEFT/RIGHT` (A), `SINGLE_UP/DOWN` (B),
  `DOUBLE_LR` (C), `DOUBLE_UD` (D), `CORNER` (E — 2 perpendiculares apuntando al
  centro del tablero según posición).
- **Telegraph**: 1 ColorRect por dirección, alpha pulsante sobre el segmento
  torre→borde durante `AIM`; `FIRE` instancia `TowerLaser.gd` (Area2D, `mask=1`
  cabeza, daño 1x por rayo) y los libera en `COOLDOWN`.
- **Data-driven** en `EnemyData.gd` (`tower_pattern`, `tower_aim_time`,
  `tower_beam_duration`, `tower_reload_time`, `tower_core_color`).
- Spawn desde `Game.gd._spawn_enemies()` (case `"tower"` + `pattern`); torres en
  todas las salas vía `MapManager._generate_spawns()`.

Ver `Documentacion/GDD.md` → `# Enemigos → ## Torre` para el diseño completo.

### Hitbox vs sprite — desfases corregidos (✅ 2026-08-07)

Desfases entre la representación visual del enemigo y su área de colisión que
impedían al jugador dañarlo en su casilla:

- **Slime Grande 2×2**: el sprite 44px y el aura se pintaban centrados en la **celda
  esquina** del bloque (el nodo vive en el centro de `grid_pos`, no del footprint) →
  sobresalían ~10px arriba/izquierda y quedaban cortos abajo/derecha. Ahora todos los
  elementos visuales (`visual`, `aura`, goo del `_land_fx`) se centran en el **centro
  de la huella** (`_footprint_center()` = `(grid_size−1)×TILE/2`).
- **Salto en el tope del grid**: `_hop_to` usaba coordenadas locales (`celda×24+12`)
  mientras `_hop_from`/`global_position` incluyen el offset del mundo (+76 del
  GameArea). Mezclar esas bases hundía la hitbox ~76px hacia arriba en cada salto: el
  sprite (clampeado) se veía dentro del grid pero la colisión quedaba inalcanzable.
  El salto ahora vive en coordenadas **locales** (`position`), igual que el grid de la
  serpiente, y `_clamp_visual_y` solo recorta el arco sin desacoplar sprite y hitbox.

Cambios: `Enemy.gd` — helpers `_footprint_center()`/`_visual_base()`, `_add_visual`
ancla por huella; `Slime.gd` — `visual.position` rebaselineado en
JUMP/LAND/channel/`_apply_tier_visual`, `_recenter_aura()`, `_land_fx()` centrado,
`_start_hop_to`/`Phase.JUMP`/`_do_merge` en coordenadas locales.

**Validación:** test headless 15/15 — 1×1 (fila 0 y 17) y 2×2 (0,0)/(0,16) con hitbox
centrada en la celda y sprite dentro de la huella; la cabeza golpea al slime en
reposo, en pleno salto (celda destino) y en las 4 celdas del bloque. Regresión
`Game.tscn --quit-after 180` sin errores.

---

## Notas técnicas Godot

- Enemies usan Area2D para detección de colisiones con la cabeza de la serpiente
- El grid detection se hace por coordenadas, no físicas (más preciso)
- Ghost no usa física — solo verifica superposición de grid_pos cada frame
- Worm mantiene un array de segmentos que ocupan el grid
- Proyectiles se manejan como Area2D con movimiento libre (no grid)
- El daño se envía via EventBus, no directo al jugador
- Para pathfinding simple: movimiento cardinal hacia el jugador (priorizar eje X o Y)