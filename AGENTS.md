# Snake — Godot 4.7.1

## Project layout

| Path | Role |
|------|------|
| `Game.tscn` | Main scene, root entrypoint |
| `Game.gd` | ~109 lines — connects EventBus, delegates to SnakeController/FoodSpawner |
| `GameArea` (Node2D at y=76) | Contains grid, food, snake, scanner — 720×432 local coords |
| `TopBar` (ColorRect, y=0-76) | HUD background above game area |
| `autoload/GameManager.gd` | State machine (Autoload) |
| `autoload/RunManager.gd` | Run data: score, streak, gold, xp, level, stats (Autoload) |
| `autoload/EventBus.gd` | Centralized signals between systems (Autoload) |
| `scripts/DamageSystem.gd` | Damage calc, healing, shields, armor |
| `resources/StatResource.gd` | Reusable stat resource (Resource) |
| `scenes/player/SnakeController.gd` | Snake movement, input, collision logic |
| `scenes/food/FoodSpawner.gd` | Food spawn logic (free cells, random position) |
| `scenes/enemy/Enemy.gd` | Enemy base (Area2D) — physics collision, take_damage, footprint |
| `scenes/enemy/Slime.gd` | Hop locomotion, animation, combat, personality traits, pack interaction |
| `scenes/enemy/SlimePack.gd` + `.tscn` | Per-room pack coordinator: states, unique slots, roles, memory, pressure, interactive fuse |
| `scenes/enemy/Tower.gd` + `.tscn` | Static laser tower: AIM/FIRE/COOLDOWN cycle, 5 fixed cardinal patterns, state-dependant hit response |
| `scenes/enemy/TowerLaser.gd` + `.tscn` | Drum-beam Area2D (torre→border segment), 1-hit damage to head |
| `ComboTimer.gd` | Rectangular two-layer timer bar (gray buffer, streak-colored fill) |
| `GridTexture.gd` | Seamless 24×24 tile → tiled across 720×432 |
| `GridBorder.gd` | 2px black outline around the grid |
| `SnakeHead.gd` | Head with rotating eyes (pivot at tile center +12,+12) |
| `BorderScanner.gd` | Dual-opposing animated scanners on perimeter, streak-colored |
| `grid_background.gdshader` | Dynamic background shader: halftone squares, breathing, eat wave, game-over red fade |
| `ExplosionEffect.gd` | Retro-comic particle burst on eat, shapes scale by streak level |
| `ScreenShake.gd` | Camera shake on eat |
| `scenes/ui/HUD.tscn` | HUD scene (CanvasLayer), instanced from Game.tscn |
| `scenes/ui/HUD.gd` | HUD script — score, gold, level, streak, combo, HP/XP bars, notifications |
| `scenes/ui/HPBar.gd` | HP bar with delay animation |
| `scenes/ui/XPBar.gd` | XP bar with level-up flash |
| `scenes/ui/NotificationSystem.gd` | Pooled notification labels (fade in/out, stacking) |
| `FloatingText.gd` | Animated "STREAK xN" text at food position |
| `AudioManager.gd` | Sound effects |
| `GameOverFade` | Shader uniform `game_over_fade` — dots turn red |

## Key mechanics

- Board: 30×18 tiles at 24px = 720×432
- Streak cap: **5**. Colors cycle: green→blue→yellow→orange→purple
- Speed: resets to `BASE_MOVE_INTERVAL` (0.15s) on streak end; `max(0.06, BASE - streak * 0.008)` per eat
- Combo timer: 3s window, resets on eat
- `update_streak_visuals()` called whenever streak changes
- `get_streak_color(s) -> Color`: single source of truth for all streak colors

## Shader uniforms

| Uniform | Role |
|---------|------|
| `streak_level` | Controls wave speed, thickness, brightness, multi-wave, dot deformation |
| `wave_center` | UV of food position for eat-wave |
| `wave_time` | Countdown for eat-wave animation |
| `wave_flash` | Full-screen white flash (streak 5 only) |
| `wave_duration` | Length of eat-wave (0.6s) |
| `game_over_fade` | 0→0.8 on death, dots interpolate gray→red |

## Visual effects

- **Background**: Halftone squares, breathing pulse from grid center (2.5s cycle), eat-wave (Chebyshev diamond), multi-wave for streak≥3, flash for streak 5
- **Explosion particles**: ColorRect squares burst — shapes vary by streak (squares, rays, star, ring lines, central star)
- **Growth flash**: Body segments turn white→green sequentially on eat
- **Border scanner**: Dual opposing scanners, streak-colored
- **Screen shake**: Intensity scales with streak
- **Floating text**: Streak level popup at food position
- **Game-over fade**: Halftone dots turn red via shader

## Fase 1 — Estado actual ✅

### Completado
- [x] Estructura de carpetas (`autoload/`, `resources/`, `scripts/`, `scenes/player/`, `scenes/food/`, etc.)
- [x] `GameManager.gd` — autoload con máquina de estados
- [x] `RunManager.gd` — autoload con datos de run, stats base, XP, oro
- [x] `StatResource.gd` — resource con stats exportables
- [x] `DamageSystem.gd` — cálculo de daño, cura, escudos, invulnerabilidad
- [x] `EventBus.gd` — autoload con señales centralizadas
- [x] `SnakeController.gd` — lógica de movimiento extraída de Game.gd
- [x] `FoodSpawner.gd` — lógica de spawn de comida extraída de Game.gd
- [x] `Game.gd` refactorizado (100 líneas) usando SnakeController, FoodSpawner, SnakeRenderer, StreakHUD, EatEffects
- [x] `scenes/player/SnakeRenderer.gd` — render de body/head + growth flash
- [x] `scenes/ui/StreakHUD.gd` — streak visuals, combo bar, game over UI, font setup
- [x] `scenes/effects/EatEffects.gd` — explosion, floating text, shake, eat-wave shader
- [x] Autoloads registrados en `project.godot`
- [x] Game.gd reducido a 100 líneas exactas
- [x] Stats de movimiento leídos de StatResource via RunManager
- [x] `reset_game()` vía `EventBus.reset_requested`

### Bugs resueltos
- [x] `best_score` se resetea entre runs — mover a Game.gd como variable persistente
- [x] `end_game()` no emite `EventBus.game_over` — arreglar flujo
- [x] Compilación y runtime sin errores (Godot)
- [x] Commit y push en rama `fase_01`
- [x] Stack overflow por recursión infinita: `reset_game()` → `start_run()` → `game_started` → `_on_game_started()` → `reset_game()`
- [x] Body accumulation: `update_body()` itera `snake_body.get_children()` para limpiar
- [x] Game over + restart funciona correctamente
- [x] Parse error: scripts sin `class_name` → agregados a SnakeRenderer, StreakHUD, EatEffects
- [x] LetterWaveText (extends Control) no tiene `label_settings` → excluido del loop de font

### Validación funcional (verificada runtime)
- [x] Movimiento básico (RIGHT por defecto, 6 tiles en 1s)
- [x] Cambio de dirección vía input (`ui_down`, `ui_left`, `ui_up`)
- [x] Comer comida → score +1, streak +1, snake_len +1
- [x] Game over por colisión (pared derecha)
- [x] Restart con Enter (ui_accept) → estado PLAYING, score 0, snake reset

### Documentación
- `Documentacion/GDD.md` — Game Design Document v2.0
- `Documentacion/ROADMAP.md` — 9 fases de desarrollo
- `Documentacion/FASE_01_Fundamentos.md` — diseño de Fase 1 (completado ✅)
- `Documentacion/FASE_02_HUD.md` — diseño de Fase 2 (en progreso)
- `Documentacion/FASE_03_Pulido.md` a `FASE_09_Pulido.md` — fases restantes

## How to test

1. `godot_editor_edit stop && godot_editor_edit run frozen=true` (enter frozen mode)
2. `godot_game_time step` or `godot_game_time step_until` to advance
3. `godot_input sequence` for input injection
4. `godot_runtime_state digest` to check node positions/state
5. `godot_editor_read get_log_messages` to check runtime errors
6. Check scene in editor: `godot_node_read get_scene_tree`

## Editor workflow

- Edit `.gd` files on disk → `godot_scene reload` → `godot_editor_edit stop + run` to test (game loads fresh)
- Edit `Game.tscn` or `project.godot` on disk → `godot_editor_edit restart save=true` (editor re-reads project settings)
- `godot_editor_read get_log_messages severity=error` after every mutation
- Z-order: GridBackground(-1) → GridBorder(1) → Food(2) → BorderScanner(3) → HUD(CanvasLayer)

## Fase 2 — HUD (en progreso)

### Completado
- [x] HUD.tscn como escena independiente (CanvasLayer)
- [x] HPBar.gd con delay animation
- [x] XPBar.gd con level-up flash
- [x] Font PressStart2P visible en editor (theme_override_fonts)
- [x] NotificationSystem.gd — pooling de 8 labels, fade in/out, stacking vertical
- [x] Notificaciones: +XP (cyan), +Gold (yellow), Streak (streak_color)
- [x] Viewport ajustado a 720×508 (TopBar extendido 56→76px)
- [x] Labels convertidos de LetterWaveText a Label puro (visible en editor)

## Fase 3 — Sistema de Salas (completado ✅)

### Completado
- [x] `resources/RoomData.gd` — Resource con enum Type (NORMAL, ELITE, EVENT, REST, TREASURE, SHOP, BOSS)
- [x] `autoload/MapManager.gd` — genera mapa de 7 salas (lineal), `advance_room()`, `mark_room_cleared()`
- [x] `scenes/Door.gd` — puerta visual (rojo cerrada / verde abierta) en (29,9)
- [x] `SnakeController.gd` — señal `reached_door`, `door_positions`/`doors_open`, `set_doors()`
- [x] `Game.gd` — `enter_room()` con reset de snake + spawn comida, `_on_reached_door()` para transición
- [x] Puerta se abre al comer primera comida (`mark_room_cleared()` + `door.set_open(true)`)
- [x] Transición sala→sala funcional (verificada runtime: room 0 → 1)
- [x] MapManager registrado como autoload en `project.godot`
- [x] Door en `Game.tscn` (z_index=2)

### Bugs resueltos
- [x] `reset()` en SnakeController limpiaba `door_positions` → mover `set_doors` después de `reset` en `enter_room()`
- [x] `var room := mm.get_current_room()` no infería tipo → cambiar a `var room = mm.get_current_room()`

### Pendiente (futuras fases)
- [ ] Branching: mostrar 2-3 opciones de puerta al finalizar sala
- [ ] GameManager State UPGRADE/SHOP para salas especiales
- [ ] Boss en sala BOSS (room 6)
- [ ] Minimap — requiere Fase 3

### Pendiente (requieren dependencias)
- [ ] SkillSlot (cooldown radial) — requiere Fase 5
- [ ] RelicSlot (icono + rareza) — requiere Fase 5
- [ ] StatusIcon (buff/debuff) — requiere Fase 4/5
- [ ] BossHUD — requiere Fase 7

## Fase 4 — Enemigos (en progreso)

### Completado
- [x] `EnemyData.gd` — config data-driven (drops, tallas, hops, radios, umbrales, cooldowns)
- [x] `Enemy.gd` base — footprint por `grid_size` (`occupies_cell`), cooldown de golpe,
  señal `merged`, hook `_on_hit_started`, miembro `max_hp`
- [x] `Slime.gd` mejorado — hops (máquina de fases cargar→saltar→aterrizar→pausa),
  árbol de decisión por grupo: Solo / Pinza / Mural; cooldown de golpe + encoger
  (Medium→Small) + recuperación; fusión en **Slime Grande 2×2** por tiempo de acoso
- [x] `SlimePack.gd` + `.tscn` — coordinador de manada por sala: estados de manada
  (SEARCH→REGROUP→WRAP→PRESS→FUSE), percepción compartida, slots radiales únicos
  por tick, roles, memoria scoped + pressure system, fusión por canalización
  interrumpible (reemplaza el timer de acoso)
- [x] `Slime.gd` (SlimePack) — `_begin_jump` delega el destino al pack; rasgos de
  personalidad como pesos de decisión; `begin/end_channel` canalización; `do_pack_merge`
- [x] `Game.gd` — colisión por `occupies_cell` (2×2), filtra drops no-enemigo,
  conecta `merged` → decrementa `enemies_alive`
- [x] Balance data-driven en `EnemyData.gd` (sin magic numbers)
- [x] GDD: sección Slime completa; CHANGELOG y FASE_04 actualizados
- [x] `Tower.gd` + `.tscn` — torre estática con láser fijo: ciclo AIM→FIRE→COOLDOWN;
  golpe según estado (AIM reflexiona al jugador, FIRE muere de 1, COOLDOWN 2 golpes)
- [x] `TowerLaser.gd` + `.tscn` — rayo Area2D (segmento torre→borde, daño 1x al head)
- [x] `EnemyData.gd` — enum `TowerPattern` + datos `tower_*`
- [x] `Game.gd` — case `"tower"` (spawnea con `pattern`); `MapManager.gd` torres por sala

### Bugs resueltos (Slime)
- [x] Daño asimétrico: el jugador recibía daño repetido durante el cooldown de golpe
  sin que el slime recibiera nada → `take_damage` devuelve `bool` y `Game.gd` solo emite
  `damage_taken` si aterrizó el golpe
- [x] Slime «pasaba» por el jugador sin ser dañado: `grid_pos` se commitaba al despegar,
  desincronizado del cuerpo visual → ahora se commitea al aterrizar (`_try_hop_cell`)
- [x] Slime Grande 2×2 se salía del grid: el centroide de fusión no estaba clampeado →
  `clampi` a `0..GRID_W-2`/`0..GRID_H-2` + sincronización de `global_position`
- [x] Gotas de goo desplazadas: posicionadas en coordenadas locales (`to_local`)
- [x] Sprite del slime se veía en el HUD al saltar (fila 0, arco del salto y Slime
  Grande en reposo): `_clamp_visual_y()` mantiene el sprite dentro del grid.
  Fix adicional: la fórmula original ignoraba el offset de GameArea (y=76) — bounds
  corregidos con `GRID_TOP_Y = 76` para que el clamp funcione en coordenadas globales
- [x] `_on_hit_started`: SMALL/MEDIUM mueren de 1 toque; solo el BIG aguanta golpes
  múltiples. Spawn de enemigos clampeado a `0..29`×`0..17`
- [x] El jugador «pasaba por encima» de un slime saltando sin dañarlo: `grid_pos` se
  commitea al aterrizar, así que durante el JUMP la hitbox quedaba retenida en la
  casilla de partida. Override de `occupies_cell` en `Slime.gd` que durante `Phase.JUMP`
  marca todo el camino `grid_pos → _target_grid_pos` (inclusive).
- [x] Colisión migrada a **física** (área continua en vez de celdas discretas):
  `SnakeHead` layer 1/mask 6 + shape 24×24; `Enemy/CollisionShape2D` dinámico por
  `grid_size` (layer 2); `Game._physics_process` usa `get_overlapping_areas()`.
  Capas en `layer_names/2d_physics`. Resuelve el hueco de temporización del tick.
- [x] Hitbox vs sprite desalineados: el **Slime Grande 2×2** pintaba sprite/aura
  centrados en la celda esquina (no en el centro del bloque) y el **salto** mezclaba
  coordenadas locales (`_hop_to`) con de mundo (`global_position`, +76 del GameArea)
  → la hitbox se hundía ~76px fuera del área jugable. Fix: `_footprint_center()`/
  `_visual_base()` en `Enemy.gd`; `Slime.gd` rebasea `visual.position`, recentra aura
  y goo, y traba el salto en coordenadas **locales** (`position`).

### Pendiente (resto de la Fase 4)
- [ ] Spider, Ghost, Worm, Elite
- [ ] Projectile.gd + disparo de torre
- [ ] Spawn multi-tipo desde RoomData/MapManager (ahora slime + torre)
- [ ] `room_cleared` conexión EventBus
- [ ] Probar los nuevos tipos en editor (vía godot-mcp)