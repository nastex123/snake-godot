# Snake

Retro arcade Snake hecho en Godot 4.7.1.

## Gameplay

- Tablero 30×18 tiles — 720×432px
- Come la comida para sumar puntos y crecer
- **Racha (streak)**: come seguido dentro de 3s para aumentar el combo. Máximo x5.
- Cada nivel de racha cambia el color de la comida, el escáner de borde y la barra de tiempo
- La velocidad aumenta con cada comida y se resetea al terminar la racha

### Colores por racha

| x1 | x2 | x3 | x4 | x5 |
|----|----|----|----|----|
| 🟠 | 🟡 | 🟢 | 🔵 | 🟣 |

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
