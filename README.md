# Snake

Retro arcade Snake hecho en Godot 4.7.1 con efectos visuales dinámicos.

## Gameplay

- Tablero 30×18 tiles — 720×432px (viewport stretch "viewport", aspect "keep")
- Come la comida para sumar puntos y crecer
- **Racha (streak)**: come seguido dentro de 3s para aumentar el combo. Máximo x5.
- La velocidad aumenta con cada comida (`max(0.06, 0.15 - streak * 0.008)`) y se resetea al terminar la racha
- Puntuación: cada comida suma `streak` puntos (1→2→3→4→5)

### Colores por racha

| x1 | x2 | x3 | x4 | x5 |
|----|----|----|----|----|
| 🟠 | 🟡 | 🟢 | 🔵 | 🟣 |

## Visuales

### Shader de fondo (`grid_background.gdshader`)

- Halftone squares (cuadraditos) por tile — efecto cómic
- **Breathing**: onda expansiva que respira desde el centro del grid cada 2.5s
- **Eat wave**: onda cuadrada (Chebyshev distance) que se expande desde la comida al comer, con grosor y brillo según racha
- **Multi-wave**: dos ondas simultáneas para racha ≥3
- **Flash**: pantallazo blanco en racha 5 (`wave_flash`, 150ms)
- **Game-over fade**: los cuadraditos se vuelven rojos gradualmente al morir

### Partículas de explosión (`ExplosionEffect.gd`)

Al comer, una ráfaga de ColorRects con formas progresivas por racha:

| Racha | Efecto |
|-------|--------|
| x1 | Cuadrados base en dispersión radial |
| x2 | +4 rayos alargados en direcciones cardinales |
| x3 | +8 partículas rotadas (estrella 8 puntas) |
| x4 | +4 líneas finas formando un anillo cuadrado |
| x5 | + estrella central blanca + doble anillo |

### Growth flash

Al comer, cada segmento del cuerpo se vuelve blanco por 0.2s y vuelve a verde en 0.6s, con 0.1s de retardo entre segmentos.

### Border Scanner

Animación de escáneres duales opuestos en el perímetro del grid, con color según racha.

### Screen Shake

La cámara tiembla al comer con intensidad según racha (0.5–3.7).

### Floating text

Texto "STREAK xN" flotante animado que aparece en la posición de la comida al comer.

### Game Over

- Label "GAME OVER" rojo + "Press SPACE to restart"
- Los cuadraditos del fondo se tiñen de rojo (fade vía shader)

## Controles

| Tecla | Acción |
|-------|--------|
| ← ↑ ↓ → | Dirección de la serpiente |
| Space | Reiniciar tras Game Over |

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
