# Snake Roguelite

Retro arcade Snake transformado en un **roguelite de acción** con salas procedurales, enemigos, builds, reliquias, habilidades, biomas, jefes y metaprogresión. Hecho en Godot 4.7.1 con estilo cómic retro y font Press Start 2P.

**Documentación completa:** [`Documentacion/`](Documentacion/)

| Archivo | Contenido |
|---------|-----------|
| [`GDD.md`](Documentacion/GDD.md) | Game Design Document v2.0 — visión completa del juego |
| [`ROADMAP.md`](Documentacion/ROADMAP.md) | Plan de desarrollo en 9 fases |
| [`FASE_01_Fundamentos.md`](Documentacion/FASE_01_Fundamentos.md) | Arquitectura, stats, daño, eventos, RunData, migración |
| [`FASE_02_HUD.md`](Documentacion/FASE_02_HUD.md) | HUD modular: HPBar, XPBar, SkillBar, RelicSlot, Minimap |
| [`FASE_03_Salas.md`](Documentacion/FASE_03_Salas.md) | Sistema de salas, generación procedural, puertas |
| [`FASE_04_Enemigos.md`](Documentacion/FASE_04_Enemigos.md) | 5 tipos de enemigos + élites + proyectiles |
| [`FASE_05_Objetos.md`](Documentacion/FASE_05_Objetos.md) | 100+ reliquias, 7 habilidades, sinergias, builds |
| [`FASE_06_Eventos.md`](Documentacion/FASE_06_Eventos.md) | Tiendas, eventos aleatorios, cofres, NPCs |
| [`FASE_07_Biomas.md`](Documentacion/FASE_07_Biomas.md) | 4 biomas con paletas únicas, 4 jefes con 3 fases |
| [`FASE_08_Metaprogresion.md`](Documentacion/FASE_08_Metaprogresion.md) | Mejoras permanentes, logros, persistencia |
| [`FASE_09_Pulido.md`](Documentacion/FASE_09_Pulido.md) | Menús, audio, partículas, balance, exportación |

## Estado actual

Implementando **Fase 1** — arquitectura modular completa con autoloads, EventBus, sistema de daño, RunData y máquina de estados.

### Fase 1 completada

- Autoloads: `GameManager`, `RunManager`, `EventBus`
- `SnakeController.gd` — movimiento, input, colisiones
- `FoodSpawner.gd` — spawn en celdas libres
- `Game.gd` refactorizado (~284 líneas) delegando a controladores
- `DamageSystem.gd` — cálculo de daño, cura, escudos, invulnerabilidad
- Game over + restart funcional (Enter reinicia)
- `best_score` persistente entre runs

### Gameplay base

- Tablero 30×18 tiles — 720×432px
- Movimiento grid-based clásico de Snake
- **Streak**: combo al comer seguido (máx x5), colores: verde→azul→amarillo→naranja→púrpura
- Velocidad: `max(0.06, 0.15 - streak * 0.008)` — se acelera con cada comida
- Puntuación: cada comida suma `streak` puntos

### Visuales

- Font **Press Start 2P** con contorno negro vía `LabelSettings`
- `LetterWaveText.gd`: texto con animación sine-wave por carácter (`@tool` + `_show_preview()`)
- `ComboTimer.gd`: barra de combo con animación elástica
- `grid_background.gdshader`: halftone squares, breathing, eat wave, multi-wave, flash, game-over fade
- `ExplosionEffect.gd`: partículas con formas progresivas según racha
- `BorderScanner.gd`: escáneres duales animados en el perímetro
- `ScreenShake.gd`: cámara tiembla al comer (intensidad según racha)
- `FloatingText.gd`: texto "STREAK xN" en posición de la comida

## Controles

| Tecla | Acción |
|-------|--------|
| ← ↑ ↓ → | Dirección de la serpiente |
| Space | Reiniciar tras Game Over |
| Q/E/R/F | Habilidades activas (Fase 5) |

## Ejecutar

Abrir `Game.tscn` como escena principal en Godot 4.7.1 y ejecutar.

### Testing con godot-mcp

```bash
godot_editor_edit stop && godot_editor_edit run frozen=true
godot_game_time step duration_ms=1000
godot_input sequence [{"action_name":"ui_up","duration_ms":50}]
godot_runtime_state digest
godot_editor_read get_log_messages severity=error
```