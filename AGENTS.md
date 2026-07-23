# Snake — Godot 4.7.1

## Project layout

| Path | Role |
|------|------|
| `Game.tscn` | Main scene, root entrypoint |
| `Game.gd` | All game logic: input, movement, streak, HUD, visual effects |
| `GameArea` (Node2D at y=56) | Contains grid, food, snake, scanner — 720×432 local coords |
| `TopBar` (ColorRect, y=0-56) | HUD background above game area |
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
- Streak cap: **5**. Colors cycle: orange→gold→green→cyan→purple
- Speed: resets to `BASE_MOVE_INTERVAL` (0.15s) on streak end; `max(0.06, BASE - streak * 0.008)` per eat
- Combo timer: 3s window, resets on eat
- `update_streak_visuals()` called whenever streak changes — handles label, food color, scanner color, combo timer bar color, shader streak level, speed reset, and explosion color
- `get_streak_color(s) -> Color`: single source of truth for all streak colors
- `move_interval` recalcula desde BASE en cada eat, no se acumula

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
