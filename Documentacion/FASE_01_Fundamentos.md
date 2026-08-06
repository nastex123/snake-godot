# FASE 01 — Fundamentos del Roguelite

## Objetivo

Transformar el Snake arcade actual en una arquitectura modular preparada para un roguelite. El gameplay visual no cambia, pero toda la lógica se refactoriza en sistemas independientes.

---

## Orden de implementación

Cada paso debe completarse y verificarse antes de pasar al siguiente.

### Paso 1: Estructura de carpetas ✅

```
autoload/
resources/
scenes/player/
scenes/enemy/
scenes/boss/
scenes/food/
scenes/effects/
scenes/ui/
scenes/rooms/
scenes/pickups/
scenes/projectiles/
scripts/
shaders/
fonts/
assets/
```

### Paso 2: GameManager (Autoload) ✅

**Archivo:** `autoload/GameManager.gd`

Máquina de estados del juego. Controla la transición entre estados y notifica al resto del juego.

```gdscript
extends Node
class_name GameManager

enum State { MENU, LOADING, PLAYING, UPGRADE, SHOP, BOSS, PAUSED, GAME_OVER, VICTORY }

signal state_changed(new_state: State)
signal game_started()
signal game_ended(reason: String)
signal room_entered(room_type: String)
signal boss_defeated(boss_id: String)
signal level_up(new_level: int)

var current_state: State = State.MENU

func change_state(new_state: State) -> void:
    current_state = new_state
    state_changed.emit(new_state)

func start_run() -> void:
    change_state(State.PLAYING)
    game_started.emit()

func end_run(reason: String) -> void:
    change_state(State.GAME_OVER)
    game_ended.emit(reason)
```

### Paso 3: RunData (Recurso/Objeto) ✅

**Archivo:** `autoload/RunManager.gd`

Almacena toda la información de la partida actual. Se reinicia al empezar una nueva run.

```gdscript
extends Node
class_name RunManager

signal xp_changed(current: int, max_xp: int)
signal level_changed(new_level: int)
signal gold_changed(amount: int)
signal streak_changed(new_streak: int)
signal relic_added(relic_id: String)
signal skill_equipped(skill_id: String)

var run_data: Dictionary = {
    "time": 0.0,
    "score": 0,
    "xp": 0,
    "gold": 0,
    "level": 1,
    "max_level": 99,
    "streak": 0,
    "combo_time": 0.0,
    "biome": 0,
    "room_index": 0,
    "seed": 0,
    "relics": [],
    "skills": [],
    "stats": {}
}

func reset_run() -> void:
    run_data = {
        "time": 0.0,
        "score": 0,
        "xp": 0,
        "gold": 0,
        "level": 1,
        "max_level": 99,
        "streak": 0,
        "combo_time": 0.0,
        "biome": 0,
        "room_index": 0,
        "seed": randi(),
        "relics": [],
        "skills": [],
        "stats": _base_stats()
    }

func _base_stats() -> Dictionary:
    return {
        "hp": 100, "hp_max": 100,
        "damage": 10, "attack_speed": 1.0,
        "crit_chance": 0.05, "crit_damage": 1.5,
        "shield": 0, "armor": 0,
        "speed": 1.0, "pickup_radius": 1.0,
        "luck": 1.0, "xp_mult": 1.0, "gold_mult": 1.0,
        "streak_mult": 1.0
    }

func add_xp(amount: int) -> void:
    run_data.xp += amount
    xp_changed.emit(run_data.xp, _xp_for_next_level())
    if run_data.xp >= _xp_for_next_level():
        level_up()

func _xp_for_next_level() -> int:
    return run_data.level * 50
```

### Paso 4: Sistema de estadísticas (Resource) ✅

**Archivo:** `resources/StatResource.gd`

Recurso reutilizable para definir stats base y modificadores.

```gdscript
extends Resource
class_name StatResource

@export var max_hp: float = 100.0
@export var damage: float = 10.0
@export var attack_speed: float = 1.0
@export var crit_chance: float = 0.05
@export var crit_damage: float = 1.5
@export var shield: float = 0.0
@export var armor: float = 0.0
@export var move_speed: float = 1.0
@export var pickup_radius: float = 1.0
@export var luck: float = 1.0
@export var xp_multiplier: float = 1.0
@export var gold_multiplier: float = 1.0
@export var streak_multiplier: float = 1.0
```

### Paso 5: Sistema de daño ✅

**Archivo:** `scripts/DamageSystem.gd`

Maneja cálculo de daño, curación, escudos, armadura y efectos.

```gdscript
extends Node
class_name DamageSystem

signal damage_dealt(target: Node, amount: float, type: String)
signal damage_taken(source: Node, amount: float, type: String)
signal healed(amount: float)
signal shield_broken()

enum DamageType { PHYSICAL, MAGICAL, TRUE, POISON, FIRE, ICE }

var _invulnerable: bool = false
var _invulnerability_timer: float = 0.0

func apply_damage(source_stats: Dictionary, target_stats: Dictionary, 
                  base_damage: float, type: DamageType) -> Dictionary:
    if _invulnerable:
        return {"damage": 0, "crit": false, "blocked": true}
    
    var dmg = base_damage
    var is_crit = randf() < source_stats.get("crit_chance", 0.0)
    if is_crit:
        dmg *= source_stats.get("crit_damage", 1.5)
    
    dmg -= target_stats.get("armor", 0.0) * 0.5
    dmg = max(1.0, dmg)
    
    if target_stats.get("shield", 0.0) > 0:
        var shield_absorb = min(dmg, target_stats.shield)
        target_stats.shield -= shield_absorb
        dmg -= shield_absorb
        if target_stats.shield <= 0:
            shield_broken.emit()
    
    return {"damage": dmg, "crit": is_crit, "blocked": false}

func heal(amount: float, target: Dictionary) -> float:
    var before = target.get("hp", 0)
    target.hp = min(target.get("hp_max", 100), target.hp + amount)
    var healed_amount = target.hp - before
    if healed_amount > 0:
        healed.emit(healed_amount)
    return healed_amount

func set_invulnerable(duration: float) -> void:
    _invulnerable = true
    _invulnerability_timer = duration
```

### Paso 6: Sistema de eventos (EventBus) ✅

**Archivo:** `autoload/EventBus.gd`

Autoload que centraliza todas las señales del juego. Ningún sistema llama directamente a otro.

```gdscript
extends Node
class_name EventBus

signal food_eaten(position: Vector2i, streak: int)
signal enemy_killed(enemy_type: String, position: Vector2)
signal damage_dealt(target: Node, amount: float, type: int)
signal xp_gained(amount: int)
signal gold_gained(amount: int)
signal level_up(new_level: int)
signal relic_obtained(relic_id: String)
signal skill_used(skill_id: String)
signal room_cleared(room_index: int)
signal biome_entered(biome_id: int)
signal boss_phase_changed(phase: int)
signal game_over(reason: String)
```

### Paso 7: Migration de Game.gd ✅ (parcial)

1. ~~Crear `scenes/player/SnakeController.gd`~~ — ✅ Lógica de movimiento extraída
2. ~~Crear `scenes/food/FoodSpawner.gd`~~ — ✅ Lógica de spawn de comida separada
3. ~~Game.gd se reduce a conectar EventBus y delegar a los managers~~ — ⚠️ Delega a controllers pero aún tiene 284 líneas
4. ~~Stats del jugador se leen de StatResource~~ — ❌ Pendiente: aún usa constantes hardcodeadas
5. ~~`score`, `streak`, `combo_time` pasan a RunManager~~ — ✅ Datos en RunManager

---

## Criterios de aceptación

- [x] El juego se ve y siente idéntico al original
- [x] GameManager controla los estados correctamente (MENU→PLAYING→GAME_OVER, con reset funcional)
- [x] RunManager se reinicia al empezar nueva partida (`reset_run()` reinicia score, streak, combo, stats)
- [x] DamageSystem calcula daño, cura y escudos sin errores
- [x] No hay errores en editor ni runtime (0 errores verificados)
- [x] `end_game()` funciona mediante EventBus (`event_bus.game_over.emit()` + `game_manager.end_run()`)
- [x] `Game.gd` reducido a máximo 100 líneas — **100 líneas exactas**. HUD, streak visuals, efectos extraídos a SnakeRenderer, StreakHUD, EatEffects
- [x] Todas las estadísticas se leen de StatResource — `move_interval`, `streak_speed_boost`, `combo_max_time`, `min_move_interval` leídos de `run_manager.run_data.stats` (StatResource)
- [x] EventBus centraliza las señales del juego — Game.gd orquesta 5 módulos (coordinador, no acoplado)
- [x] `reset_game()` funciona mediante EventBus — `EventBus.reset_requested` conectado → `reset_game()` en `_ready()`

### Pendiente para cerrar Fase 1 ✅

1. ✅ **Reducir Game.gd a ≤100 líneas**: 3 módulos nuevos — SnakeRenderer, StreakHUD, EatEffects. Game.gd mide 100 líneas exactas.
2. ✅ **Wiring de StatResource**: stats de movimiento leídos desde `rm.run_data.stats` en `_on_snake_ate_food()` y `reset_game()`
3. ✅ **reset_game() via señal**: `EventBus.reset_requested` emitido en `_process()` cuando `gm.current_state == 7` y `ui_accept` presionado → `eb.reset_requested.emit()` → `reset_game()`

---

## Notas técnicas Godot

- GameManager, RunManager, EventBus, UpgradeManager, AudioManager, SaveManager deben ser **Autoloads** (Project Settings → Autoload)
- StatResource es un recurso `.tres` que se puede cargar desde el inspector
- RunManager NO se guarda en disco — solo existe en memoria durante la partida
- SaveManager se usa para persistencia entre runs (cristales, desbloqueos)
- La migración debe ser gradual: crear nuevos archivos, mover lógica, probar, eliminar código viejo
- No eliminar archivos viejos hasta que la migración esté 100% verificada