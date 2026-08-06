# FASE 08 — Metaprogresión y Persistencia

## Objetivo

Implementar progresión entre runs con árbol de mejoras permanentes, desbloqueables, estadísticas y sistema de guardado.

---

## Orden de implementación

### Paso 1: SaveSystem

**Archivo:** `autoload/SaveSystem.gd`

```gdscript
extends Node
class_name SaveSystem

const SAVE_PATH := "user://savegame.sav"
const SETTINGS_PATH := "user://settings.sav"

var save_data: SaveData
var settings: SettingsData

func _ready() -> void:
    save_data = SaveData.new()
    settings = SettingsData.new()
    load_game()
    load_settings()

func save_game() -> void:
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_var(save_data.to_dict())
    file.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        save_data = SaveData.new()
        return false
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var data = file.get_var()
    save_data.from_dict(data)
    file.close()
    return true

func save_settings() -> void:
    var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
    file.store_var(settings.to_dict())
    file.close()

func load_settings() -> bool:
    if not FileAccess.file_exists(SETTINGS_PATH):
        settings = SettingsData.new()
        return false
    var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
    var data = file.get_var()
    settings.from_dict(data)
    file.close()
    return true
```

### Paso 2: SaveData (Resource)

**Archivo:** `resources/SaveData.gd`

```gdscript
extends Resource
class_name SaveData

var total_runs: int = 0
var total_wins: int = 0
var best_streak: int = 0
var total_kills: int = 0
var total_gold_earned: int = 0
var total_xp_earned: int = 0
var upgrades_purchased: Dictionary = {}  # upgrade_id: level
var unlocked_relics: Array = []
var unlocked_bosses: Array = []
var highest_biome_reached: int = 0
var achievements_unlocked: Array = []

func to_dict() -> Dictionary:
    return {
        "total_runs": total_runs,
        "total_wins": total_wins,
        "best_streak": best_streak,
        "total_kills": total_kills,
        "total_gold_earned": total_gold_earned,
        "total_xp_earned": total_xp_earned,
        "upgrades_purchased": upgrades_purchased,
        "unlocked_relics": unlocked_relics,
        "unlocked_bosses": unlocked_bosses,
        "highest_biome_reached": highest_biome_reached,
        "achievements_unlocked": achievements_unlocked
    }

func from_dict(data: Dictionary) -> void:
    total_runs = data.get("total_runs", 0)
    total_wins = data.get("total_wins", 0)
    best_streak = data.get("best_streak", 0)
    total_kills = data.get("total_kills", 0)
    total_gold_earned = data.get("total_gold_earned", 0)
    total_xp_earned = data.get("total_xp_earned", 0)
    upgrades_purchased = data.get("upgrades_purchased", {})
    unlocked_relics = data.get("unlocked_relics", [])
    unlocked_bosses = data.get("unlocked_bosses", [])
    highest_biome_reached = data.get("highest_biome_reached", 0)
    achievements_unlocked = data.get("achievements_unlocked", [])
```

### Paso 3: MetaUpgradeTree

**Archivo:** `scenes/ui/MetaUpgradeScreen.tscn`
**Script:** `scenes/ui/MetaUpgradeScreen.gd`

```gdscript
extends Control
class_name MetaUpgradeScreen

@export var tree_container: GridContainer
@export var points_label: Label
@export var upgrade_card_scene: PackedScene

var available_points: int = 0
var upgrades: Array[MetaUpgrade] = []

class MetaUpgrade:
    var id: String
    var name: String
    var description: String
    var max_level: int = 5
    var base_cost: int = 100
    var cost_mult: float = 1.5
    var icon: Texture2D
    var effects: Dictionary  # "start_gold": 50
    var category: String  # "offense", "defense", "utility"
    var prerequisites: Array[String] = []

func open() -> void:
    visible = true
    _calculate_points()
    points_label.text = "Puntos de mejora: " + str(available_points)
    _build_tree()
    GameManager.change_state(GameManager.State.META_UPGRADE)

func _calculate_points() -> void:
    # Puntos basados en total_gold_earned y logros
    var total = SaveSystem.save_data.total_gold_earned
    var earned = SaveSystem.save_data.total_xp_earned
    available_points = floor((total + earned * 10) / 1000)  # 1 punto cada 1000

func _build_tree() -> void:
    for child in tree_container.get_children():
        child.queue_free()
    
    for upgrade in upgrades:
        var card = upgrade_card_scene.instantiate()
        card.setup(upgrade, _get_current_level(upgrade.id))
        card.buy.connect(_on_buy_upgrade)
        tree_container.add_child(card)

func _get_current_level(upgrade_id: String) -> int:
    return SaveSystem.save_data.upgrades_purchased.get(upgrade_id, 0)

func _on_buy_upgrade(upgrade_id: String) -> void:
    var upgrade = _find_upgrade(upgrade_id)
    if not upgrade: return
    var current_level = _get_current_level(upgrade_id)
    if current_level >= upgrade.max_level: return
    var cost = _calculate_cost(upgrade)
    if available_points < cost: return
    
    available_points -= cost
    SaveSystem.save_data.upgrades_purchased[upgrade_id] = current_level + 1
    SaveSystem.save_game()
    points_label.text = "Puntos de mejora: " + str(available_points)
    _build_tree()

func _calculate_cost(upgrade: MetaUpgrade) -> int:
    var level = _get_current_level(upgrade.id)
    return int(upgrade.base_cost * pow(upgrade.cost_mult, level))
```

### Paso 4: MetaUpgrades implementados

| ID | Nombre | Categoría | Máx nivel | Efecto por nivel |
|----|--------|-----------|-----------|------------------|
| start_gold | Oro inicial | Utilidad | 5 | +50 oro/run |
| start_hp | Vida inicial | Defensa | 5 | +10 HP/run |
| extra_relics | Reliquias extra | Utilidad | 3 | +1 reliquia inicial/nivel |
| dash_range | Alcance Dash | Ofensa | 5 | +1 tile/nivel |
| magnet_radius | Imán ampliado | Utilidad | 3 | +2 tiles radio/nivel |
| damage_mult | Multiplicador daño | Ofensa | 5 | +10%/nivel |
| revive_chance | Oportunidad revive | Defensa | 3 | 25%/nivel de revivir al morir |
| xp_bonus | Bono XP | Utilidad | 5 | +20% XP/nivel |
| gold_bonus | Bono oro | Utilidad | 5 | +20% oro/nivel |
| rare_chance | Más rareza | Utilidad | 3 | +5% rareza/nivel |
| max_shield | Escudo inicial | Defensa | 3 | +15 escudo/nivel |
| skill_slots | Slots habilidad | Ofensa | 3 | +1 slot/nivel |

### Paso 5: AchievementSystem

**Archivo:** `autoload/AchievementSystem.gd`

```gdscript
extends Node
class_name AchievementSystem

signal achievement_unlocked(achievement_id: String)

var achievements: Array = []

func _ready() -> void:
    _init_achievements()

func _init_achievements() -> void:
    achievements = [
        {"id": "first_kill", "name": "Primera sangre", "condition": "kill_count >= 1"},
        {"id": "100_kills", "name": "Cazador", "condition": "kill_count >= 100"},
        {"id": "streak_10", "name": "Racha", "condition": "streak >= 10"},
        {"id": "first_boss", "name": "Cazabosses", "condition": "boss_kills >= 1"},
        {"id": "win_run", "name": "Victoria", "condition": "runs_won >= 1"},
        {"id": "10_wins", "name": "Invencible", "condition": "runs_won >= 10"},
        {"id": "full_health", "name": "Intocable", "condition": "finished_run_full_hp"},
        {"id": "biome_hell", "name": "Infierno", "condition": "reached_biome >= 4"},
        {"id": "no_hit_boss", "name": "Sin rasguño", "condition": "boss_no_hit"},
        {"id": "all_relics", "name": "Coleccionista", "condition": "unlocked_all_relics"},
    ]

func check_achievements(event: String, data: Dictionary) -> void:
    for achievement in achievements:
        if achievement.id in SaveSystem.save_data.achievements_unlocked:
            continue
        if _evaluate_condition(achievement.condition, event, data):
            _unlock(achievement)

func _unlock(achievement: Dictionary) -> void:
    SaveSystem.save_data.achievements_unlocked.append(achievement.id)
    SaveSystem.save_game()
    achievement_unlocked.emit(achievement.id)
    EventBus.notify.emit("¡Logro: " + achievement.name + "!", Color.GOLD)
```

### Paso 6: StatsTracker

**Archivo:** `autoload/StatsTracker.gd`

```gdscript
extends Node
class_name StatsTracker

var run_kills: int = 0
var run_damage_dealt: float = 0.0
var run_damage_taken: float = 0.0
var run_gold_earned: int = 0
var run_rooms_cleared: int = 0
var run_bosses_killed: int = 0
var run_relics_obtained: int = 0
var max_streak: int = 0

func start_run() -> void:
    run_kills = 0
    run_damage_dealt = 0.0
    run_damage_taken = 0.0
    run_gold_earned = 0
    run_rooms_cleared = 0
    run_bosses_killed = 0
    run_relics_obtained = 0
    max_streak = 0

func end_run(won: bool) -> void:
    SaveSystem.save_data.total_runs += 1
    SaveSystem.save_data.total_kills += run_kills
    SaveSystem.save_data.total_gold_earned += run_gold_earned
    SaveSystem.save_data.total_xp_earned += RunManager.run_data.xp if RunManager.run_data else 0
    if won:
        SaveSystem.save_data.total_wins += 1
    SaveSystem.save_game()

func enemy_killed() -> void:
    run_kills += 1

func damage_dealt(amount: float) -> void:
    run_damage_dealt += amount

func damage_taken(amount: float) -> void:
    run_damage_taken += amount
```

---

## Conexiones con EventBus

| Evento | Reacción |
|--------|----------|
| `enemy_killed` | StatsTracker.enemy_killed(), AchievementSystem.check() |
| `boss_killed` | StatsTracker.run_bosses_killed++, AchievementSystem.check() |
| `gold_gained` | StatsTracker.run_gold_earned += amount |
| `game_over` | StatsTracker.end_run(false), mostrar resumen |
| `run_started` | StatsTracker.start_run(), aplicar meta-upgrades |
| `achievement_unlocked` | Mostrar notificación en HUD |

---

## Criterios de aceptación

- [ ] SaveSystem guarda/carga datos en user://
- [ ] 12 mejoras permanentes con 3-5 niveles cada una
- [ ] Árbol de mejoras con requisitos entre nodos
- [ ] 10 logros detectables y desbloqueables
- [ ] StatsTracker registra datos de cada run
- [ ] Pantalla de mejoras con UI de árbol/jerarquía
- [ ] Puntos de mejora calculados por oro total ganado
- [ ] Cargas de partida persisten entre sesiones (cierre y reapertura)
- [ ] Meta-upgrades se aplican correctamente al empezar run
- [ ] No hay errores de FileAccess o serialización

---

## Notas técnicas Godot

- SaveSystem es autoload con persistencia en user://
- FileAccess.store_var/load_var serializa directamente Dictionarys
- MetaUpgradeScreen se abre desde el menú principal
- AchievementSystem escucha EventBus para detectar condiciones
- StatsTracker se resetea al empezar cada run
- Los puntos de mejora se calculan cada vez que se abre la pantalla
- 12 mejoras permanentes distribuidas en 3 categorías: ofensa, defensa, utilidad
- Logros no retroactivos — solo se checkean en adelante