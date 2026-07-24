# FASE 05 — Objetos y Builds

## Objetivo

Crear partidas únicas mediante un sistema de reliquias, habilidades activas y objetos pasivos con sinergias y rarezas.

---

## Orden de implementación

### Paso 1: RelicData (Resource)

**Archivo:** `resources/RelicData.gd`

```gdscript
extends Resource
class_name RelicData

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, CURSED }

@export var relic_id: String
@export var display_name: String
@export var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var icon: Texture2D
@export var stat_modifiers: Dictionary = {}  # "damage": 10, "crit_chance": 0.05
@export var skill_unlock: String = ""  # habilidad activa que desbloquea
@export var synergy_group: String = ""  # para sinergias entre reliquias
@export var stackable: bool = false
@export var max_stacks: int = 1

func get_rarity_name() -> String:
    match rarity:
        Rarity.COMMON: return "Común"
        Rarity.UNCOMMON: return "Inusual"
        Rarity.RARE: return "Raro"
        Rarity.EPIC: return "Épico"
        Rarity.LEGENDARY: return "Legendario"
        Rarity.CURSED: return "Maldito"
    return ""

func get_rarity_color() -> Color:
    match rarity:
        Rarity.COMMON: return Color.GRAY
        Rarity.UNCOMMON: return Color(0.2, 0.8, 0.2)
        Rarity.RARE: return Color(0.2, 0.4, 0.9)
        Rarity.EPIC: return Color(0.6, 0.2, 0.9)
        Rarity.LEGENDARY: return Color(1, 0.7, 0.1)
        Rarity.CURSED: return Color(0.9, 0.1, 0.1)
    return Color.WHITE
```

### Paso 2: SkillData (Resource)

**Archivo:** `resources/SkillData.gd`

```gdscript
extends Resource
class_name SkillData

@export var skill_id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var cooldown: float = 5.0
@export var damage: float = 0.0
@export var duration: float = 0.0
@export var range: float = 0.0
@export var skill_scene: PackedScene  # escena del efecto visual
@export var sound_effect: AudioStream
```

### Paso 3: UpgradeManager

**Archivo:** `autoload/UpgradeManager.gd`

```gdscript
extends Node
class_name UpgradeManager

signal upgrade_chosen(relic_id: String)
signal upgrade_offered(options: Array)

var available_relics: Array[RelicData] = []
var owned_relics: Array[RelicData] = []
var upgrade_pool: Array[RelicData] = []

func init_pool() -> void:
    upgrade_pool = available_relics.duplicate()
    # Excluir reliquias ya obtenidas
    for owned in owned_relics:
        upgrade_pool.erase(owned)

func offer_upgrades(count: int = 3) -> Array:
    var options = []
    init_pool()
    upgrade_pool.shuffle()
    for i in range(min(count, upgrade_pool.size())):
        options.append(upgrade_pool[i])
    upgrade_offered.emit(options)
    return options

func choose_upgrade(relic_data: RelicData) -> void:
    owned_relics.append(relic_data)
    upgrade_pool.erase(relic_data)
    upgrade_chosen.emit(relic_data.relic_id)
    # Aplicar stat_modifiers al jugador
    GameManager.get_player().apply_relic_stats(relic_data.stat_modifiers)

func has_synergy(group: String) -> Array:
    var result = []
    for relic in owned_relics:
        if relic.synergy_group == group:
            result.append(relic)
    return result

func get_active_synergies() -> Array:
    var synergies = []
    var groups = {}
    for relic in owned_relics:
        if not relic.synergy_group.is_empty():
            if not groups.has(relic.synergy_group):
                groups[relic.synergy_group] = 0
            groups[relic.synergy_group] += 1
    for group in groups:
        if groups[group] >= 2:
            synergies.append(group)
    return synergies
```

### Paso 4: UpgradeScreen

**Archivo:** `scenes/ui/UpgradeScreen.tscn`
**Script:** `scenes/ui/UpgradeScreen.gd`

Pantalla que aparece al subir de nivel. Muestra 3 cartas con reliquias para elegir.

```gdscript
extends Control
class_name UpgradeScreen

@export var card_scene: PackedScene
@export var card_container: HBoxContainer

func show_upgrades(options: Array) -> void:
    visible = true
    modulate = Color(1, 1, 1, 0)
    var tw = create_tween()
    tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
    
    for i in options.size():
        var card = card_scene.instantiate()
        card.setup(options[i], i)
        card.selected.connect(_on_card_selected)
        card_container.add_child(card)

func _on_card_selected(index: int) -> void:
    UpgradeManager.choose_upgrade(UpgradeManager.owned_relics[owned_relics.size()-1])
    # Animación de salida
    var tw = create_tween()
    tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
    tw.tween_callback(func(): visible = false; card_container.queue_free_children())
    GameManager.change_state(GameManager.State.PLAYING)
```

### Paso 5: 7 Habilidades activas

**Archivo por habilidad:** `scenes/player/skills/`

Cada habilidad se implementa como un script individual:

| Habilidad | Archivo | Efecto |
|-----------|---------|--------|
| Dash | `DashSkill.gd` | Teletransporte 3 tiles en dirección actual, invulnerabilidad 0.3s |
| Bomba | `BombSkill.gd` | Explosión 3x3 alrededor de la cabeza, 50 daño |
| Escudo | `ShieldSkill.gd` | Invulnerabilidad 2s + escudo 50 HP |
| Congelar | `FreezeSkill.gd` | Congela enemigos en 5x5 por 3s |
| Teletransporte | `TeleportSkill.gd` | Teletransporta a una celda vacía aleatoria |
| Imán | `MagnetSkill.gd` | Atrae todos los pickups en 8 tiles |
| Onda | `ShockwaveSkill.gd` | Empuja enemigos 3 tiles, 25 daño |

```gdscript
# Ejemplo: DashSkill.gd
extends Node
class_name DashSkill

func activate(snake: SnakeController) -> void:
    if not snake: return
    var dir = snake.direction
    var target = snake.grid_pos + dir * 3
    # Verificar que target esté dentro del grid
    target.x = clamp(target.x, 0, 29)
    target.y = clamp(target.y, 0, 17)
    snake.grid_pos = target
    snake.global_position = Vector2(target) * 24
    snake.set_invulnerable(0.3)
    EventBus.skill_used.emit("dash")
```

### Paso 6: Sinergias

**Archivo:** `resources/SynergyData.gd`
**Archivo:** `scripts/SynergySystem.gd`

```gdscript
extends Resource
class_name SynergyData

@export var synergy_id: String
@export var display_name: String
@export var description: String
@export var required_groups: Array[String]  # ["poison", "explosion"]
@export var effect: String  # "toxic_cloud", "chain_lightning"
@export var stat_modifiers: Dictionary
```

```gdscript
extends Node
class_name SynergySystem

signal synergy_activated(synergy_id: String)

var active_synergies: Array = []

func check_synergies() -> void:
    var owned_groups = UpgradeManager.get_active_synergies()
    for syn in SynergyManager.all_synergies:
        var has_all = true
        for group in syn.required_groups:
            if not group in owned_groups:
                has_all = false
                break
        if has_all and not syn.synergy_id in active_synergies:
            activate_synergy(syn)

func activate_synergy(syn: SynergyData) -> void:
    active_synergies.append(syn.synergy_id)
    GameManager.get_player().apply_relic_stats(syn.stat_modifiers)
    synergy_activated.emit(syn.synergy_id)
    EventBus.notify.emit("¡Sinergia!: " + syn.display_name, Color.GOLD)
```

---

## Lista de 100+ reliquias (primeras 30)

| ID | Nombre | Rareza | Efecto |
|----|--------|--------|--------|
| fangs | Colmillos | Común | +30% daño |
| electric_core | Núcleo eléctrico | Raro | Cada 5 comidas, rayos |
| toxic_heart | Corazón tóxico | Épico | Enemigos reciben veneno |
| magnet | Imán | Común | +50% radio de recogida |
| boots | Botas | Común | +20% velocidad |
| shield_core | Escudo nuclear | Raro | +30 escudo |
| poison_fang | Colmillo venenoso | Inusual | Daño aplica veneno (3s) |
| crystal_armor | Armadura de cristal | Raro | +15 armadura |
| lucky_coin | Moneda de la suerte | Inusual | +30% suerte |
| gold_ring | Anillo de oro | Común | +50% oro |
| xp_orb | Orbe de XP | Común | +40% XP |
| crit_lens | Lente crítica | Inusual | +15% crítico |
| rage_blade | Espada de furia | Raro | +100% daño crítico |
| vamp_fangs | Colmillos vampiros | Épico | 10% robo de vida |
| thunder_heart | Corazón de trueno | Legendario | Rayos al comer streak |
| frost_core | Núcleo de hielo | Raro | Congelar enemigos al dañar |
| flame_ring | Anillo de fuego | Inusual | Daño de fuego 5/s |
| shadow_cloak | Capa de sombras | Épico | Invulnerabilidad al dañar |
| echo_stone | Piedra eco | Raro | 20% dañar a 2 enemigos |
| chain_belt | Cinturón de cadenas | Inusual | +15% daño en cadena |
| steel_scale | Escama de acero | Común | +10 armadura |
| regen_ring | Anillo de regeneración | Inusual | 2 HP/s |
| swift_feather | Pluma veloz | Raro | +30% velocidad |
| poison_spore | Espora venenosa | Épico | Nube tóxica al morir enemigo |
| explosion_gland | Glándula explosiva | Raro | Enemigos explotan al morir |
| lightning_rod | Pararrayos | Legendario | Rayo al jefe cada 10s |
| cursed_mask | Máscara maldita | Maldito | +100% daño, -50% HP |
| blood_pact | Pacto de sangre | Maldito | Doble daño, perder HP/s |
| void_fragment | Fragmento del vacío | Legendario | 5% daño verdadero |
| mirror_shield | Escudo espejo | Épico | 20% reflejar daño |

---

## Conexiones con EventBus

| Evento | Reacción |
|--------|----------|
| `level_up` | UpgradeManager.offer_upgrades(), UpgradeScreen.show_upgrades() |
| `upgrade_chosen` | Aplicar stat_modifiers, añadir a HUD RelicBar |
| `skill_used` | Activar cooldown en SkillSlot, ejecutar efecto |
| `relic_obtained` | SynergySystem.check_synergies() |
| `food_eaten` | Verificar reliquias tipo "cada N comidas" |

---

## Criterios de aceptación

- [ ] 100+ reliquias implementadas con datos en recursos .tres
- [ ] 3 rarezas+ funcionales con colores y probabilidades distintas
- [ ] Pantalla de mejora con 3 cartas animadas al subir nivel
- [ ] 7 habilidades activas funcionales con cooldown
- [ ] Sinergias detectadas automáticamente al tener 2+ reliquias del grupo
- [ ] Stats se aplican correctamente al jugador vía RunManager
- [ ] Builds se sienten distintas entre partidas
- [ ] No hay errores de referencia o Resource loading

---

## Notas técnicas Godot

- Cada reliquia es un archivo `.tres` que se carga desde Resources
- UpgradeManager mantiene el pool de reliquias disponibles en la run
- Las habilidades activas se enlazan a teclas (Q, E, R, F, C, X, Z)
- Las sinergias se checkean cada vez que se obtiene una nueva reliquia
- La pantalla de mejora pausa el juego (GameManager.State.UPGRADE)
- Reliquias Malditas aparecen con más frecuencia si el jugador tiene poca vida