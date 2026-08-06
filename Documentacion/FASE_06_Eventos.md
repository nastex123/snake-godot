# FASE 06 — Eventos y mundo

## Objetivo

Añadir variedad a la exploración con tiendas, eventos aleatorios, cofres y NPCs en las salas.

---

## Orden de implementación

### Paso 1: ShopSystem

**Archivo:** `scenes/events/Shop.tscn`
**Script:** `scenes/events/Shop.gd`

```gdscript
extends Control
class_name Shop

@export var item_slots: Array[ShopSlot] = []
@export var gold_label: Label
@export var refresh_button: Button

var items: Array = []

func open_shop() -> void:
    visible = true
    _generate_items(4)
    gold_label.text = "Oro: " + str(RunManager.run_data.gold)
    GameManager.change_state(GameManager.State.SHOP)

func _generate_items(count: int) -> void:
    items.clear()
    for i in count:
        var relic = _random_relic()
        var price = _calculate_price(relic)
        items.append({"item": relic, "price": price})
        item_slots[i].setup(relic, price)

func _random_relic() -> RelicData:
    var pool = UpgradeManager.available_relics.duplicate()
    pool.shuffle()
    return pool[0]

func _calculate_price(relic: RelicData) -> int:
    match relic.rarity:
        RelicData.Rarity.COMMON: return 50
        RelicData.Rarity.UNCOMMON: return 100
        RelicData.Rarity.RARE: return 200
        RelicData.Rarity.EPIC: return 400
        RelicData.Rarity.LEGENDARY: return 800
        RelicData.Rarity.CURSED: return 25  # barato porque es maldito
    return 50

func buy_item(index: int) -> void:
    if index >= items.size(): return
    var item = items[index]
    if RunManager.run_data.gold >= item.price:
        RunManager.run_data.gold -= item.price
        UpgradeManager.choose_upgrade(item.item)
        item_slots[index].sold_out()
        gold_label.text = "Oro: " + str(RunManager.run_data.gold)

func close_shop() -> void:
    visible = false
    GameManager.change_state(GameManager.State.PLAYING)
```

### Paso 2: EventSystem

**Archivo:** `scenes/events/EventRoom.tscn`
**Script:** `scenes/events/EventRoom.gd`

Sistema de eventos aleatorios con decisiones del jugador.

```gdscript
extends Control
class_name EventRoom

@export var title_label: Label
@export var description_label: Label
@export var choice_buttons: Array[Button]

var current_event: Dictionary = {}

func open_event(event_id: String) -> void:
    visible = true
    current_event = EventData.get_event(event_id)
    title_label.text = current_event.title
    description_label.text = current_event.description
    for i in choice_buttons.size():
        if i < current_event.choices.size():
            choice_buttons[i].text = current_event.choices[i].text
            choice_buttons[i].visible = true
        else:
            choice_buttons[i].visible = false
    GameManager.change_state(GameManager.State.EVENT)

func choose_option(index: int) -> void:
    var choice = current_event.choices[index]
    _apply_result(choice.result)
    close_event()

func _apply_result(result: Dictionary) -> void:
    if result.has("gold"): RunManager.run_data.gold += result.gold
    if result.has("hp"): GameManager.get_player().heal(result.hp)
    if result.has("relic"): UpgradeManager.choose_upgrade(result.relic)
    if result.has("curse"): _apply_curse(result.curse)
    if result.has("damage"): GameManager.get_player().take_damage(result.damage)

func close_event() -> void:
    visible = false
    GameManager.change_state(GameManager.State.PLAYING)
```

### Paso 3: EventData (Resource)

**Archivo:** `resources/EventData.gd`

```gdscript
extends Resource
class_name EventData

@export var event_id: String
@export var title: String
@export var description: String
@export var choices: Array[ChoiceData]

static func get_event(event_id: String) -> Dictionary:
    # Cargar eventos desde archivos .tres
    var event = load("res://resources/events/" + event_id + ".tres")
    return event

class ChoiceData:
    var text: String
    var result: Dictionary  # {"gold": 50, "hp": 20} o {"relic": relic_data}
```

### Paso 4: Eventos implementados

| Evento | Descripción | Opciones |
|--------|-------------|----------|
| **Mercader** | Un mercader ofrece intercambio | (a) 50 HP → 100 oro (b) 100 oro → reliquia |
| **Santuario** | Fuente de energía antigua | (a) Curar 30 HP (b) +10% daño permanente |
| **Ruleta** | Gira la ruleta | (a) Girar (aleatorio: oro/reliquia/daño) |
| **Altar** | Altar oscuro | (a) -20% HP → reliquia épica (b) Ignorar |
| **Maldición** | Aura de maldición | (a) Recibir maldición → 2 reliquias (b) Huir |
| **Desafío** | Sala de combate extra | (a) Pelear por oro extra (b) Ignorar |
| **NPC** | Un viajero herido | (a) Curarlo → recompensa (b) Ignorar |

### Paso 5: ChestSystem

**Archivo:** `scenes/pickups/Chest.tscn`
**Script:** `scenes/pickups/Chest.gd`

```gdscript
extends Area2D
class_name Chest

@export var chest_type: String = "normal"  # normal, rare, cursed
@export var gold_amount: int = 20
@export var relic_chance: float = 0.2

func open() -> void:
    # Animación de apertura
    var tw = create_tween()
    tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
    tw.tween_property(self, "scale", Vector2(0, 1), 0.2)
    
    RunManager.add_gold(gold_amount + randi() % gold_amount)
    
    if randf() < relic_chance:
        UpgradeManager.offer_upgrades(2)
    
    EventBus.gold_gained.emit(gold_amount)
    queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("snake_head"):
        open()
```

---

## Conexiones con EventBus

| Evento | Reacción |
|--------|----------|
| `room_entered` | Si room_type == SHOP → open_shop() |
| `room_entered` | Si room_type == EVENT → evento aleatorio |
| `gold_gained` | Actualizar HUD GoldLabel |
| `damage_taken` | Actualizar HPBar |

---

## Criterios de aceptación

- [ ] Tienda funcional con 4 items aleatorios, precios según rareza
- [ ] 7 tipos de evento con decisiones y consecuencias
- [ ] Cofres (normal, raro, maldito) con loot variable
- [ ] EventData como recurso `.tres` cargable
- [ ] Tienda se abre sin pausar el juego (modo SHOP)
- [ ] Eventos dan recompensas (oro, HP, reliquias) o castigos
- [ ] Maldiciones aplican efectos negativos permanentes
- [ ] NPC con dialogo básico y recompensa
- [ ] No hay errores de UI o transiciones de estado

---

## Notas técnicas Godot

- Shop, EventRoom, Chest son escenas independientes
- Cada evento es un recurso `.tres` en `resources/events/`
- Al entrar a sala EVENT, se selecciona un evento aleatorio del pool
- Cofres Malditos tienen relic_chance = 1.0 pero pueden dar reliquias Malditas
- La tienda permite comprar con oro acumulado en la run
- Las decisiones en eventos pueden tener requisitos (mínimo de oro, HP, etc.)