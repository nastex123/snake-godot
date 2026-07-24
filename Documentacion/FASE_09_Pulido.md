# FASE 09 — Pulido y arte final

## Objetivo

Transformar el prototipo en un producto terminado con arte final, audio, pantallas, animaciones fluidas, balance y testing exhaustivo.

---

## Orden de implementación

### Paso 1: MainMenu completo

**Archivo original:** `scenes/ui/MainMenu.tscn`
**Script:** `scenes/ui/MainMenu.gd`

Sustituir el menú placeholder por uno completo:

```gdscript
extends Control
class_name MainMenu

@export var play_button: Button
@export var upgrades_button: Button
@export var stats_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var title_label: Label
@export var version_label: Label
@export var particle_bg: GPUParticles2D

func _ready() -> void:
    play_button.pressed.connect(_on_play)
    upgrades_button.pressed.connect(_on_upgrades)
    stats_button.pressed.connect(_on_stats)
    settings_button.pressed.connect(_on_settings)
    quit_button.pressed.connect(_on_quit)
    title_label.text = "SNAKE ROGUELITE"
    version_label.text = "v1.0"
    
    # Animación de entrada
    modulate = Color(1, 1, 1, 0)
    var tw = create_tween()
    tw.set_trans(Tween.TRANS_BOUNCE)
    tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.0)

func _on_play() -> void:
    # Animación de salida
    var tw = create_tween()
    tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
    await tw.finished
    GameManager.start_new_run()

func _on_upgrades() -> void:
    MetaUpgradeScreen.open()

func _on_stats() -> void:
    StatsScreen.open()

func _on_settings() -> void:
    SettingsScreen.open()

func _on_quit() -> void:
    get_tree().quit()
```

### Paso 2: GameOverScreen

**Archivo:** `scenes/ui/GameOverScreen.tscn`
**Script:** `scenes/ui/GameOverScreen.gd`

```gdscript
extends Control
class_name GameOverScreen

@export var stats_container: VBoxContainer
@export var run_stats_label: Label
@export var upgrades_button: Button
@export var retry_button: Button
@export var main_menu_button: Button

func show_stats() -> void:
    visible = true
    var text = "RESUMEN DE LA PARTIDA\n"
    text += "Enemigos eliminados: " + str(StatsTracker.run_kills) + "\n"
    text += "Daño infligido: " + str(StatsTracker.run_damage_dealt) + "\n"
    text += "Daño recibido: " + str(StatsTracker.run_damage_taken) + "\n"
    text += "Oro ganado: " + str(StatsTracker.run_gold_earned) + "\n"
    text += "Salas limpiadas: " + str(StatsTracker.run_rooms_cleared) + "\n"
    text += "Jefes eliminados: " + str(StatsTracker.run_bosses_killed) + "\n"
    text += "Mejor racha: " + str(StatsTracker.max_streak) + "\n"
    run_stats_label.text = text
    
    retry_button.pressed.connect(_on_retry)
    main_menu_button.pressed.connect(_on_main_menu)

func _on_retry() -> void:
    hide()
    GameManager.start_new_run()

func _on_main_menu() -> void:
    hide()
    get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_upgrades() -> void:
    MetaUpgradeScreen.open()
```

### Paso 3: SettingsScreen

**Archivo:** `scenes/ui/SettingsScreen.tscn`
**Script:** `scenes/ui/SettingsScreen.gd`

```gdscript
extends Control
class_name SettingsScreen

@export var master_volume: HSlider
@export var sfx_volume: HSlider
@export var music_volume: HSlider
@export var fullscreen_check: CheckButton
@export var vsync_check: CheckButton

func open() -> void:
    visible = true
    _load_settings()

func _load_settings() -> void:
    master_volume.value = SaveSystem.settings.master_volume
    sfx_volume.value = SaveSystem.settings.sfx_volume
    music_volume.value = SaveSystem.settings.music_volume
    fullscreen_check.button_pressed = SaveSystem.settings.fullscreen
    vsync_check.button_pressed = SaveSystem.settings.vsync

func _on_save() -> void:
    SaveSystem.settings.master_volume = master_volume.value
    SaveSystem.settings.sfx_volume = sfx_volume.value
    SaveSystem.settings.music_volume = music_volume.value
    SaveSystem.settings.fullscreen = fullscreen_check.button_pressed
    SaveSystem.settings.vsync = vsync_check.button_pressed
    _apply_settings()
    SaveSystem.save_settings()

func _apply_settings() -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(SaveSystem.settings.master_volume))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(SaveSystem.settings.sfx_volume))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(SaveSystem.settings.music_volume))
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if SaveSystem.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
```

### Paso 4: Animaciones finales

| Elemento | Animación |
|----------|-----------|
| Snake movement | Transición suave entre tiles (Tween, 0.1s) |
| Comer food | Scale bounce en comida antes de desaparecer |
| Damage shake | Camera shake con ScreenShake (distinto al actual) |
| Level up | Flash + partículas + escalado |
| Boss entrada | Fundido negro → aparición con temblor |
| Transición bioma | Fundido a color del nuevo bioma |
| Muerte | Cámara lenta 0.3s → zoom out → fade rojo |
| Apertura cofre | Animación de tapa + brillo + partículas |
| Compra tienda | Moneda volando → desvanecerse |

### Paso 5: Audio final

**Archivo:** `autoload/AudioManager.gd` (expandir)

```gdscript
extends Node
class_name AudioManager

@export var music_player: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer

var current_biome_music: String = ""

func play_sfx(sfx_id: String) -> void:
    var stream = _get_sfx(sfx_id)
    if stream:
        sfx_player.stream = stream
        sfx_player.play()

func play_music(music_id: String) -> void:
    if music_id == current_biome_music: return
    current_biome_music = music_id
    var stream = _get_music(music_id)
    if stream:
        var tw = create_tween()
        tw.tween_property(music_player, "volume_db", -80, 0.5)
        await tw.finished
        music_player.stream = stream
        music_player.play()
        var tw2 = create_tween()
        tw2.tween_property(music_player, "volume_db", -10, 0.5)

func _get_sfx(sfx_id: String) -> AudioStream:
    match sfx_id:
        "eat": return preload("res://audio/sfx/eat.wav")
        "damage": return preload("res://audio/sfx/damage.wav")
        "level_up": return preload("res://audio/sfx/level_up.wav")
        "enemy_kill": return preload("res://audio/sfx/enemy_kill.wav")
        "boss_roar": return preload("res://audio/sfx/boss_roar.wav")
        "shop_buy": return preload("res://audio/sfx/shop_buy.wav")
        "open_chest": return preload("res://audio/sfx/chest_open.wav")
        "game_over": return preload("res://audio/sfx/game_over.wav")
        "teleport": return preload("res://audio/sfx/teleport.wav")
        "explosion": return preload("res://audio/sfx/explosion.wav")
        "fire": return preload("res://audio/sfx/fire.wav")
        "ice": return preload("res://audio/sfx/ice.wav")
        "lightning": return preload("res://audio/sfx/lightning.wav")
    return null

func _get_music(music_id: String) -> AudioStream:
    match music_id:
        "menu": return preload("res://audio/music/menu.ogg")
        "forest": return preload("res://audio/music/forest.ogg")
        "desert": return preload("res://audio/music/desert.ogg")
        "ice": return preload("res://audio/music/ice.ogg")
        "hell": return preload("res://audio/music/hell.ogg")
        "boss": return preload("res://audio/music/boss.ogg")
    return null
```

### Paso 6: Partículas finales

| Efecto | Descripción |
|--------|-------------|
| Comer | Partículas de comida + brillo |
| Daño | Partículas rojas + sangre pixel |
| Muerte enemigo | Explosión de cuadrados (similar a streak pero color del enemigo) |
| Level up | Partículas doradas radiales |
| Reliquia obtenida | Partículas del color de rareza |
| Jefe muere | Explosión masiva + pantalla blanca |
| Bioma transición | Partículas de hielo/arena/fuego |
| Aura | Partículas alrededor del jugador según builds |

### Paso 7: Balance

**Archivo:** `scripts/BalanceManager.gd`

```gdscript
extends Node
class_name BalanceManager

static func get_enemy_hp(room_index: int, biome_level: int) -> float:
    var base = 20.0
    var biome_mult = [1.0, 1.5, 2.5, 4.0]
    return base * biome_mult[biome_level] * (1.0 + room_index * 0.1)

static func get_enemy_damage(biome_level: int) -> float:
    var base = 5.0
    var biome_mult = [1.0, 1.3, 2.0, 3.0]
    return base * biome_mult[biome_level]

static func get_xp_required(level: int) -> int:
    return int(100 * pow(1.3, level - 1))

static func get_relic_rarity_chances(biome_level: int) -> Dictionary:
    match biome_level:
        0: return {"common": 0.6, "uncommon": 0.3, "rare": 0.08, "epic": 0.02}
        1: return {"common": 0.4, "uncommon": 0.35, "rare": 0.15, "epic": 0.08, "legendary": 0.02}
        2: return {"common": 0.25, "uncommon": 0.3, "rare": 0.2, "epic": 0.15, "legendary": 0.1}
        3: return {"uncommon": 0.2, "rare": 0.3, "epic": 0.25, "legendary": 0.2, "cursed": 0.05}
    return {}

static func get_gold_drop(biome_level: int, is_elite: bool) -> int:
    var base = 5 + biome_level * 3
    return base * (3 if is_elite else 1)
```

### Paso 8: Testing plan

```gdscript
# tests/test_game_flow.gd
func test_full_run() -> void:
    # Simular run completa: Forest → Desert → Ice → Hell → Jefe final
    pass

func test_all_enemies() -> void:
    # Verificar que cada tipo de enemigo spawnea y muere correctamente
    pass

func test_all_relics() -> void:
    # Verificar que cada reliquia se obtiene y aplica efectos
    pass

func test_all_skills() -> void:
    # Verificar cada habilidad activa
    pass

func test_biome_transition() -> void:
    # Verificar transición entre biomas
    pass

func test_save_load() -> void:
    # Guardar, cerrar, cargar, verificar datos
    pass

func test_performance() -> void:
    # Verificar FPS con muchos enemigos en pantalla
    pass

func test_no_errors() -> void:
    # Recorrer todas las pantallas y acciones sin errores
    pass
```

### Paso 9: Performance optimization

- Pool de proyectiles (ObjectPool)
- LOD para enemigos lejanos (desactivar process)
- Tile culling fuera de pantalla
- Shader optimizaciones: reducir cálculos de wave con streak=0
- Resource preloading en pantalla de carga
- ObjectPool para partículas frecuentes
- CanvasItem visibility en Area2Ds

### Paso 10: Export config

**Archivo:** `export_presets.cfg`

- Windows: x86_64, release, embed PCK
- Linux: x86_64, release
- HTML5: WebGL2, thread support
- Icono del juego, splash screen personalizada
- Vsync on, fullscreen default

---

## Criterios de aceptación finales

- [ ] Menú principal completo con animaciones
- [ ] Pantalla de GameOver con estadísticas de la run
- [ ] Pantalla de Settings con persistencia
- [ ] 20+ SFX implementados (comer, daño, nivel, ataques, jefe, tienda)
- [ ] 6 pistas de música (menú, 4 biomas, boss)
- [ ] Transiciones suaves entre todas las pantallas
- [ ] Partículas en todas las acciones principales
- [ ] Balance jugable: difícil pero justo
- [ ] 0 errores en editor y runtime
- [ ] 60 FPS constantes con 20+ enemigos
- [ ] Export builds funcionales
- [ ] Playtest feedback aplicado

---

## Notas técnicas Godot

- Las animaciones usan Tween con easing (TRANS_BOUNCE, TRANS_ELASTIC)
- Audio usa buses Master/SFX/Music con control de volumen independiente
- ObjectPool reduce allocaciones de proyectiles y partículas
- Las transiciones de pantalla usan AnimationPlayer con fundidos
- El balance se ajusta con constantes en BalanceManager (no hardcodeadas)
- Testing se hace con el sistema de frozen step de godot-mcp
- Export presets configurados para Windows, Linux y HTML5
- El juego completo pesa menos de 100MB