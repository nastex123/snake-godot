# Snake — Godot 4.7.1

## Project layout

| Path | Role |
|------|------|
| `Game.tscn` | Main scene, root entrypoint |
| `Game.gd` | ~284 lines — connects EventBus, delegates to SnakeController/FoodSpawner |
| `GameArea` (Node2D at y=56) | Contains grid, food, snake, scanner — 720×432 local coords |
| `TopBar` (ColorRect, y=0-56) | HUD background above game area |
| `autoload/GameManager.gd` | State machine (Autoload) |
| `autoload/RunManager.gd` | Run data: score, streak, gold, xp, level, stats (Autoload) |
| `autoload/EventBus.gd` | Centralized signals between systems (Autoload) |
| `scripts/DamageSystem.gd` | Damage calc, healing, shields, armor |
| `resources/StatResource.gd` | Reusable stat resource (Resource) |
| `scenes/player/SnakeController.gd` | Snake movement, input, collision logic |
| `scenes/food/FoodSpawner.gd` | Food spawn logic (free cells, random position) |
| `ComboTimer.gd` | Rectangular two-layer timer bar (gray buffer, streak-colored fill) |
| `GridTexture.gd` | Seamless 24×24 tile → tiled across 720×432 |
| `GridBorder.gd` | 2px black outline around the grid |
| `SnakeHead.gd` | Head with rotating eyes (pivot at tile center +12,+12) |
| `BorderScanner.gd` | Dual-opposing animated scanners on perimeter, streak-colored |
| `grid_background.gdshader` | Dynamic background shader: halftone squares, breathing, eat wave, game-over red fade |
| `ExplosionEffect.gd` | Retro-comic particle burst on eat, shapes scale by streak level |
| `ScreenShake.gd` | Camera shake on eat |
| `FloatingText.gd` | Animated "STREAK xN" text on eat |
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
- `Documentacion/FASE_02_HUD.md` a `FASE_09_Pulido.md` — fases restantes

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