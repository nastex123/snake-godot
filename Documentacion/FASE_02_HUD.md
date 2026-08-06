# FASE 02 — Rediseño completo del HUD

## Objetivo

Crear un HUD profesional, modular y preparado para todas las mecánicas futuras. No volverá a rediseñarse durante el desarrollo.

---

## Orden de implementación

### Paso 1: Estructura del HUD

**Archivo:** `scenes/ui/HUD.tscn`
**Script:** `scenes/ui/HUD.gd`

CanvasLayer como raíz. Todos los elementos del HUD como hijos de este nodo. Game.tscn instancia HUD.tscn en lugar de tener nodos HUD inline.

```
HUD (CanvasLayer)
├── TopSection (Control)
│   ├── HPBar (HPBar.gd)
│   ├── XPBar (XPBar.gd)
│   ├── LevelLabel (Label / LetterWaveText)
│   ├── GoldLabel (Label)
│   ├── ScoreLabel (LetterWaveText)
│   ├── StreakLabel (LetterWaveText)
│   ├── ComboTimer (ComboTimer.gd)
│   └── BestLabel (Label)
├── SkillSection (Control) — anclado abajo-izquierda
│   ├── SkillSlot (x4-6) — cooldown radial
├── RelicSection (Control) — anclado abajo-derecha
│   ├── RelicSlot (x5-8) — icono + rareza + tooltip
├── BuffSection (Control) — lateral izquierdo
│   ├── BuffIcon (x4)
├── DebuffSection (Control) — lateral derecho
│   ├── DebuffIcon (x4)
├── NotificationContainer (Control) — centro inferior
│   ├── NotificationItem (pool)
├── BossSection (Control) — centro superior, oculto por defecto
│   ├── BossHPBar
│   └── BossNameLabel
└── Minimap (Minimap.gd) — esquina
```

### Paso 2: HPBar

**Archivo:** `scenes/ui/HPBar.gd`

```gdscript
extends ColorRect
class_name HPBar

@export var fill: ColorRect
@export var background: ColorRect
@export var delay_bar: ColorRect
@export var label: Label

var _target_ratio: float = 1.0
var _delay_ratio: float = 1.0

func set_hp(current: float, max_hp: float) -> void:
    _target_ratio = current / max_hp
    _animate()

func _animate() -> void:
    var tw = create_tween()
    tw.tween_property(fill, "scale", Vector2(_target_ratio, 1), 0.15)
    
    var tw2 = create_tween().set_delay(0.3)
    tw2.tween_property(delay_bar, "scale", Vector2(_target_ratio, 1), 0.3)

func set_color(c: Color) -> void:
    fill.color = c
```

### Paso 3: XPBar

**Archivo:** `scenes/ui/XPBar.gd`

Similar a HPBar pero con:
- Color fijo (cyan #4DCCFF)
- Sin delay bar (la barra de XP sube inmediato)
- Animación de destello al subir de nivel

### Paso 4: SkillBar (cooldown radial)

**Archivo:** `scenes/ui/SkillSlot.gd`

```gdscript
extends Control
class_name SkillSlot

@export var icon: TextureRect
@export var cooldown_overlay: ColorRect  # circular mask
@export var keybind_label: Label

var skill_id: String = ""
var cooldown: float = 0.0
var max_cooldown: float = 0.0
var on_cooldown: bool = false

func setup(id: String, icon_texture: Texture, cd: float, key: String) -> void:
    skill_id = id
    icon.texture = icon_texture
    max_cooldown = cd
    keybind_label.text = key
    cooldown_overlay.material.set("shader_parameter/progress", 0.0)

func start_cooldown() -> void:
    on_cooldown = true
    cooldown = max_cooldown

func _process(delta: float) -> void:
    if on_cooldown:
        cooldown -= delta
        var progress = cooldown / max_cooldown
        cooldown_overlay.material.set("shader_parameter/progress", progress)
        if cooldown <= 0:
            on_cooldown = false
            cooldown_overlay.material.set("shader_parameter/progress", 0.0)
```

### Paso 5: RelicSlot

**Archivo:** `scenes/ui/RelicSlot.gd`

```gdscript
extends Control
class_name RelicSlot

@export var icon: TextureRect
@export var rarity_border: ColorRect

var relic_data: Resource

func set_relic(resource: Resource) -> void:
    relic_data = resource
    icon.texture = resource.icon
    rarity_border.color = _rarity_color(resource.rarity)
    tooltip_text = resource.description

func _rarity_color(rarity: String) -> Color:
    match rarity:
        "common": return Color.GRAY
        "uncommon": return Color.GREEN
        "rare": return Color.BLUE
        "epic": return Color.PURPLE
        "legendary": return Color.GOLD
        "cursed": return Color.RED
    return Color.WHITE
```

### Paso 6: Buff / Debuff

**Archivo:** `scenes/ui/StatusIcon.gd`

```gdscript
extends Control
class_name StatusIcon

@export var icon: TextureRect
@export var timer_bar: ColorRect

var duration: float = 0.0
var max_duration: float = 0.0

func apply(icon_texture: Texture, dur: float) -> void:
    icon.texture = icon_texture
    max_duration = dur
    duration = dur
    visible = true

func _process(delta: float) -> void:
    if duration > 0:
        duration -= delta
        timer_bar.scale.x = duration / max_duration
        if duration <= 0:
            visible = false
```

### Paso 7: NotificationSystem

**Archivo:** `scenes/ui/NotificationSystem.gd`

```gdscript
extends Control
class_name NotificationSystem

@export var notification_scene: PackedScene

var pool: Array = []

func notify(text: String, color: Color = Color.WHITE, duration: float = 2.0) -> void:
    var n = _get_from_pool()
    n.label.text = text
    n.label.add_theme_color_override("font_color", color)
    n.modulate = Color(1, 1, 1, 0)
    
    var tw = create_tween()
    tw.tween_property(n, "modulate", Color(1, 1, 1, 1), 0.2)
    tw.tween_interval(duration)
    tw.tween_property(n, "modulate", Color(1, 1, 1, 0), 0.3)
    tw.tween_callback(func(): _return_to_pool(n))
```

### Paso 8: BossHUD

**Archivo:** `scenes/ui/BossHUD.gd`

```gdscript
extends Control
class_name BossHUD

@export var hp_bar: ColorRect
@export var name_label: Label
@export var phase_label: Label

func show_boss(name: String, max_hp: float) -> void:
    name_label.text = name
    visible = true
    # Animación de entrada
    modulate = Color(1, 1, 1, 0)
    var tw = create_tween()
    tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func update_hp(current: float, max_hp: float) -> void:
    hp_bar.scale.x = current / max_hp

func hide_boss() -> void:
    var tw = create_tween()
    tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
    tw.tween_callback(func(): visible = false)
```

### Paso 9: Minimap

**Archivo:** `scenes/ui/Minimap.gd`

```gdscript
extends Control
class_name Minimap

@export var room_icon_scene: PackedScene
@export var map_size: Vector2 = Vector2(200, 200)

var rooms: Dictionary = {}

func build_map(room_data: Array) -> void:
    for r in room_data:
        var icon = room_icon_scene.instantiate()
        icon.position = _room_to_position(r.position)
        icon.type = r.type
        add_child(icon)
        rooms[r.id] = icon

func highlight_current(room_id: String) -> void:
    for id in rooms:
        rooms[id].modulate = Color(0.5, 0.5, 0.5, 0.5)
    if rooms.has(room_id):
        rooms[room_id].modulate = Color(1, 1, 1, 1)

func _room_to_position(pos: Vector2i) -> Vector2:
    return Vector2(pos.x * 30 + 10, pos.y * 30 + 10)
```

---

## Conexiones con EventBus

| Evento | Reacción en HUD |
|--------|----------------|
| `food_eaten` | ScoreLabel.pulse(), StreakLabel.pulse(), ComboTimer.bounce(), notificación "+XP" |
| `xp_gained` | XPBar.set_xp(), notificación "+X XP" |
| `level_up` | LevelLabel animación, pantalla de mejora |
| `gold_gained` | GoldLabel actualiza texto, animación bounce |
| `damage_taken` | HPBar.set_hp(), flash rojo en borde pantalla |
| `relic_obtained` | RelicSlot animación entrada, notificación |
| `boss_phase_changed` | BossHUD.phase_label, flash |
| `game_over` | GameOverScreen con fade |

---

## Criterios de aceptación

- [ ] HUD cargado desde escena separada (`HUD.tscn`), no desde Game.tscn
- [ ] HPBar muestra vida actual con delay bar y animación
- [ ] XPBar sube con destello al nivelar
- [ ] SkillBar con 4+ slots, cooldown radial funcional
- [ ] RelicBar con tooltips y colores por rareza
- [ ] Buff/Debuff se muestran y expiran correctamente
- [ ] NotificationSystem muestra texto con fade in/out
- [ ] BossHUD aparece con animación al enfrentar jefe
- [ ] Minimap muestra salas con iconos distinguibles
- [ ] Todas las animaciones: wave, bounce, pulse, glow, shake, fade
- [ ] No hay errores en editor ni runtime
- [ ] LetterWaveText existente se reutiliza para etiquetas de texto

---

## Notas técnicas Godot

- `HUD.tscn` se instancia desde Game.tscn como hijo
- Los slots de habilidades y reliquias usan `Tooltip` nativo de Godot (control `tooltip_text`)
- El Minimap usa coordenadas relativas, no absolutas
- NotificationSystem usa pooling para reciclar nodos
- BossHUD empieza invisible (`visible = false`) y se anima al entrar
- El cooldown radial en SkillSlot usa un shader simple (TextureProgress con modo radial)