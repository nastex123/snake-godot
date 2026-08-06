# FASE 07 — Biomas y Jefes

## Objetivo

Implementar 4 biomas visualmente distintos con jefes únicos, dificultad progresiva y transiciones.

---

## Orden de implementación

### Paso 1: BiomeData (Resource)

**Archivo:** `resources/BiomeData.gd`

```gdscript
extends Resource
class_name BiomeData

@export var biome_id: String
@export var display_name: String
@export var description: String
@export var appearance_weight: float = 1.0
@export var room_count: int = 5
@export var enemy_pool: Array[EnemyData] = []
@export var boss_id: String
@export var min_enemy_count: int = 2
@export var max_enemy_count: int = 5
@export var background_color: Color = Color.DARK_GREEN
@export var grid_color: Color = Color(0.1, 0.3, 0.1)
@export var ground_color: Color = Color(0.05, 0.15, 0.05)
@export var wall_color: Color = Color(0.2, 0.4, 0.2)
@export var ambient_sound: AudioStream
@export var music_track: AudioStream
@export var special_events: Array[String] = []  # eventos exclusivos del bioma
```

### Paso 2: BiomeManager

**Archivo:** `autoload/BiomeManager.gd`

```gdscript
extends Node
class_name BiomeManager

signal biome_changed(biome_id: String)

var biomes: Array[BiomeData] = []
var current_biome_index: int = 0
var current_biome: BiomeData

func _ready() -> void:
    _load_biomes()

func _load_biomes() -> void:
    biomes.append(load("res://resources/biomes/forest.tres"))
    biomes.append(load("res://resources/biomes/desert.tres"))
    biomes.append(load("res://resources/biomes/ice.tres"))
    biomes.append(load("res://resources/biomes/hell.tres"))

func enter_next_biome() -> void:
    if current_biome_index < biomes.size() - 1:
        current_biome_index += 1
    current_biome = biomes[current_biome_index]
    biome_changed.emit(current_biome.biome_id)
    _apply_biome_visuals()

func get_current_biome() -> BiomeData:
    return current_biome

func reset_to_first() -> void:
    current_biome_index = 0
    current_biome = biomes[current_biome_index]

func _apply_biome_visuals() -> void:
    # Cambiar colores del grid shader, fondo, música
    EventBus.biome_changed.emit(current_biome.biome_id)
```

### Paso 3: 4 Biomas

| Bioma | Tema | Enemigos | Jefe | Dificultad |
|-------|------|----------|------|------------|
| **Forest** | Verde, natural | Slime, Spider | Treant | Normal |
| **Desert** | Amarillo, árido | Slime+, Tower | Scorpion King | Normal+ |
| **Ice** | Azul, gélido | Ghost, Spider+ | Frost Giant | Difícil |
| **Hell** | Rojo, infernal | Worm, Elite, Tower+ | Demon Lord | Muy difícil |

```gdscript
# Ejemplo: configuración de bioma Forest
func create_forest_biome() -> BiomeData:
    var biome = BiomeData.new()
    biome.biome_id = "forest"
    biome.display_name = "Bosque Sombrío"
    biome.room_count = 5
    biome.enemy_pool = [ENEMY_SLIME, ENEMY_SPIDER]
    biome.boss_id = "treant"
    biome.min_enemy_count = 2
    biome.max_enemy_count = 4
    biome.background_color = Color(0.05, 0.15, 0.05)
    biome.grid_color = Color(0.1, 0.3, 0.1)
    biome.special_events = ["mushroom_circle", "fairy_well"]
    return biome
```

### Paso 4: Boss system

**Archivo:** `scenes/boss/Boss.gd`

```gdscript
extends Node2D
class_name Boss

@export var boss_id: String
@export var display_name: String
@export var max_hp: float
@export var boss_icon: Texture2D

var current_hp: float
var phase: int = 1
var is_active: bool = false
signal phase_changed(phase: int)
signal boss_died()

func _ready() -> void:
    $BossHPBar.max_value = max_hp
    $BossHPBar.value = max_hp

func activate() -> void:
    is_active = true
    current_hp = max_hp
    show()
    EventBus.boss_fight_started.emit(boss_id)

func take_damage(amount: float) -> void:
    current_hp -= amount
    $BossHPBar.value = current_hp
    
    # Cambio de fase cada 33% HP
    var new_phase = int((1.0 - current_hp / max_hp) * 3) + 1
    new_phase = clamp(new_phase, 1, 3)
    if new_phase != phase:
        phase = new_phase
        phase_changed.emit(phase)
        _on_phase_change()
    
    if current_hp <= 0:
        die()

func die() -> void:
    is_active = false
    boss_died.emit()
    EventBus.boss_killed.emit(boss_id, global_position)
    # Animación de muerte, loot masivo
    queue_free()

func _on_phase_change() -> void:
    match phase:
        2: _enter_phase2()
        3: _enter_phase3()

func _enter_phase2() -> void:
    # Más velocidad, nuevos patrones
    pass

func _enter_phase3() -> void:
    # Modo berserker
    pass
```

### Paso 5: 4 jefes

| Jefe | Archivo | Patrón Fase 1 | Patrón Fase 2 | Patrón Fase 3 |
|------|---------|---------------|---------------|---------------|
| **Treant** | `Treant.gd` | Raíces desde bordes | Lluvia de semillas | Regeneración + minions |
| **Scorpion King** | `ScorpionKing.gd` | Pinzas de persecución | Cola con veneno | Arena de pinzas |
| **Frost Giant** | `FrostGiant.gd` | Puñetazos en L | Hielo en columnas | Tormenta de hielo |
| **Demon Lord** | `DemonLord.gd` | Bolas de fuego | Invocar Worms | Explosión masiva |

```gdscript
# Treant.gd - ejemplo de patrón Fase 1
func _phase1_attack() -> void:
    # Raíces desde bordes: proyectiles lentos desde las 4 direcciones
    for x in range(0, 30, 5):
        _spawn_root(Vector2i(x, 0), Vector2.DOWN)
        _spawn_root(Vector2i(x, 17), Vector2.UP)
    for y in range(0, 18, 5):
        _spawn_root(Vector2i(0, y), Vector2.RIGHT)
        _spawn_root(Vector2i(29, y), Vector2.LEFT)
```

### Paso 6: TransitionScreen

**Archivo:** `scenes/ui/TransitionScreen.tscn`
**Script:** `scenes/ui/TransitionScreen.gd`

```gdscript
extends Control
class_name TransitionScreen

@export var biome_name_label: Label
@export var biome_desc_label: Label
@export var animation_player: AnimationPlayer
@export var duration: float = 3.0

func show_transition(biome: BiomeData) -> void:
    visible = true
    biome_name_label.text = biome.display_name
    biome_desc_label.text = biome.description
    animation_player.play("transition_in")
    await get_tree().create_timer(duration).timeout
    animation_player.play("transition_out")
    await animation_player.animation_finished
    visible = false
```

---

## Conexiones con EventBus

| Evento | Reacción |
|--------|----------|
| `biome_changed` | Cambiar colores de grid shader, música, fondo |
| `boss_fight_started` | Mostrar BossHUD, bloquear puertas |
| `boss_killed` | Mostrar TransitionScreen, abrir puertas, dropear loot |
| `room_cleared` | Avanzar progreso de bioma |

---

## Criterios de aceptación

- [ ] 4 biomas con paletas de colores únicas aplicadas al grid shader
- [ ] BiomaManager controla progresión: Forest → Desert → Ice → Hell
- [ ] 4 jefes con 3 fases de combate cada uno
- [ ] Boss toma espacio en grid (ocupa 2-3 tiles)
- [ ] TransitionScreen animada entre biomas
- [ ] Enemigos escalan con bioma (más duros en Hell)
- [ ] Progresión de salas por bioma: 5 salas normales + 1 jefe cada uno
- [ ] BossHUD muestra HP, nombre, fases
- [ ] Cada jefe dropea reliquia legendaria garantizada
- [ ] No hay errores de referencia o transición entre biomas

---

## Notas técnicas Godot

- BiomeData es Resource, no autoload — se carga desde archivos .tres
- Cada jefe es escena independiente en `scenes/boss/[boss_id]/`
- BossHPBar es parte de la escena del jefe, renderizada en pantalla
- La transición entre biomas incluye fundido a negro + reinicio de sala
- Los colores del bioma se aplican al shader de fondo via uniforms
- Boss usa sistema de fases con cambios de patrones a 66% y 33% HP
- Después del jefe, se muestra elección de mejora (boss reward)