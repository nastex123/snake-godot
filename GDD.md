# Snake — GDD & High Concept

## High Concept

**¿Qué es el juego?**

Snake clásico recreado en Godot 4.7.1 con una estética retro-cómic moderna: fondos de halftone dots que respiran, tipografía Press Start 2P con contorno, colores neón que cambian con cada racha, y animaciones que hacen que cada comida se sienta impactante.

**¿Qué lo hace único?**

El sistema de **racha (streak)** es el núcleo emocional. Comer seguido dentro de una ventana de 3s acumula combo hasta x5. Cada nivel de racha transforma el juego visual y mecánicamente:

| Aspecto | Evolución por racha |
|---------|-------------------|
| Color | 🟢 Verde → 🔵 Azul → 🟡 Amarillo → 🟠 Naranja → 🟣 Magenta |
| Velocidad | 0.15s → 0.142s → 0.134s → 0.126s → 0.118s → 0.06s (mín) |
| Partículas al comer | Cuadrados → +Rayos → +Estrella 8 puntas → +Anillo → +Estrella central + doble anillo |
| Onda de fondo | Simple → → → Dual wave → Flash blanco |
| Texto HUD | Wave animation pulse con intensidad creciente |
| Cámara | Temblor 0.5px → 3.7px |
| Escáneres borde | Se activan con color de racha |

El resultado es una montaña rusa visual que recompensa el riesgo: mantener la racha acelera el juego, intensifica los efectos, y pide más precisión. Perder la racha resetea todo de golpe.

**¿A quién va dirigido?**

Jugadores casuales que buscan una experiencia arcade pulida, con feedback inmediato y satisfactorio. No hay tutoriales ni curvas de aprendizaje — se juega en segundos pero dominarlo requiere reflejos.

---

## Game Design Document (GDD)

### 1. Mecánicas

| Elemento | Detalle |
|----------|---------|
| **Tablero** | 30×18 tiles de 24px = 720×432px. Viewport stretch "viewport", aspect "keep". |
| **Movimiento** | Basado en grid. La serpiente avanza un tile cada `move_interval` segundos. |
| **Crecimiento** | Al comer, la serpiente agrega un segmento al final (no se elimina cola en ese turno). |
| **Muerte** | Colisión con borde del grid o con cualquier segmento propio. |
| **Puntuación** | Cada comida suma `streak` puntos (1→2→3→4→5). Score se muestra padding a 6 dígitos (`%06d`). |
| **Best score** | Persiste en sesión (no guarda a disco). Se actualiza al morir si score actual lo supera. |
| **Comida** | Aparece en una celda vacía aleatoria tras comer. Sin mecánicas especiales de spawn. |
| **Combo timer** | Ventana de 3s que se resetea al comer. Al llegar a 0, streak vuelve a 0. |
| **Velocidad** | `move_interval = max(0.06, 0.15 - streak * 0.008)`. Se resetea a 0.15s al perder racha. |

### 2. Controles

| Entrada | Acción |
|---------|--------|
| ← ↑ ↓ → | Cambiar dirección de la serpiente (no puede invertir 180° sobre sí misma) |
| Space (tras muerte) | `reset_game()` — reinicia la partida |
| (Sin pausa) | No hay botón de pausa intencionalmente — diseño arcade puro |

Implementación: `handle_input()` en `_process()` captura `Input.is_action_just_pressed()` para las 4 direcciones. El input se almacena en `next_direction` y se aplica en el próximo `move_snake()`.

### 3. Enemigos

No hay. El único peligro es:
- La serpiente misma (auto-colisión)
- El borde del tablero (paredes invisibles en x<0, x≥30, y<0, y≥18)

Diseño intencional: la experiencia es auto-competitiva (mejorar best score).

### 4. Progresión

- **No hay niveles, vidas, ni power-ups.** Partida única infinita hasta game over.
- **Dificultad autogestionada**: el jugador decide cuándo arriesgar para mantener la racha.
- **Curva de tensión**: a mayor streak, mayor velocidad, más intensidad visual, mayor presión.
- **Reinicio**: muerte → fade rojo en shader (0.5s) → Space → todo vuelve a cero.

### 5. HUD

Distribución en 3 secciones sobre una barra superior semitransparente (alpha 0.85) de 720×56px:

```
┌──────────────────────────────────────────────────────┐
│  SCORE              STREAK                    BEST   │
│  000000           x1                    000000       │
│                     ▓▓░░░░░░░░ (barra combo)         │
└──────────────────────────────────────────────────────┘
```

| Sección | Elementos | Tipo |
|---------|-----------|------|
| **Left** | `ScoreLabel` ("SCORE") + `ScoreValue` ("000000") | LetterWaveText + Label |
| **Center** | `StreakLabel` ("STREAK") + `StreakMultiplier` ("x1") + `ComboTimer` | LetterWaveText + Label + Control |
| **Right** | `HighScoreLabel` ("BEST") + `HighScoreValue` ("000000") | LetterWaveText + Label |

**LetterWaveText**: Control tool que divide el texto en Labels individuales (uno por carácter) y aplica un offset Y sinusoidal. Método `pulse()` para efecto extra al comer.

**ComboTimer**: Barra rectangular de dos capas (gris de fondo, color de streak encima). `set_ratio(0.0–1.0)` según tiempo restante. `bounce()` con tween elástico al comer.

**Game Over**: Frame negro centrado (ColorRect, alpha 0.85) con "GAME OVER" rojo (LetterWaveText animado) + "PRESS SPACE" abajo. Fondo se tiñe rojo vía shader.

### 6. Niveles

No existen. Partida única en un tablero fijo de 30×18 tiles.

### 7. Arte

#### Estilo general
- **Fondo**: `#090A0C` (gris muy oscuro) con halftone dots vía shader.
- **Barra HUD**: `#080809` con alpha 0.85, separador cyan fino (#4DCCFF alpha 0.35) en y=56.
- **Grid**: `#FFFFFF` alpha 0.176 (tiled TextureRect 24×24).
- **Borde grid**: 2px black outline.
- **Serpiente**: cabeza verde con ojos blancos rotatorios; cuerpo verde `#00B300`. Growth flash secuencial (blanco → verde).

#### Paleta de rachas

| Streak | Color | Uso |
|--------|-------|-----|
| 1 | `#33CC33` (verde) | Comida, streak label, barra combo, escáner, partículas |
| 2 | `#3399FF` (azul) | Ídem |
| 3 | `#FFCC00` (amarillo) | Ídem |
| 4 | `#FF6600` (naranja) | Ídem |
| 5 | `#CC33FF` (magenta) | Ídem + flash blanco de pantalla |

#### LetterWaveText
- Font: Press Start 2P (TrueType, cargado desde `res://fonts/`)
- Outline: 1px negro vía `LabelSettings`
- `_build()`: crea un Label por carácter, posicionado secuencialmente
- `_process()`: desplaza cada Label con `sin(time + i * wave_length) * amplitude`
- `pulse()`: suma amplitud extra que decae en ~1s

#### Shader de fondo (`grid_background.gdshader`)

| Efecto | Descripción |
|--------|-------------|
| **Halftone** | Cuadrados por tile (efecto cómic) |
| **Breathing** | Onda desde el centro del grid (ciclo 2.5s) |
| **Eat wave** | Onda Chebyshev (diamante) desde la comida, grosor/brillo según racha |
| **Multi-wave** | Dos ondas simultáneas para streak ≥3 |
| **Flash** | Pantalla blanca 150ms en streak 5 |
| **Game-over fade** | Dots grises → rojos (0→0.8 en 0.5s) |

#### Border Scanner
- Dos nodos escáner en lados opuestos del perímetro
- Animación lineal que viaja por el borde
- Color según racha (via `set_streak()`)
- `trigger_dash()`: aceleración momentánea al comer
- Se activan solo cuando streak > 0

#### Partículas de explosión (`ExplosionEffect.gd`)
Ráfaga de ColorRects que se expanden desde la comida:

| x1 | Cuadrados (8) en dispersión radial |
| x2 | +4 rayos alargados (4×24px) en direcciones cardinales |
| x3 | +8 partículas rotadas formando estrella de 8 puntas |
| x4 | +4 líneas finas formando anillo cuadrado |
| x5 | + estrella central blanca + doble anillo concéntrico |

#### Floating text (`FloatingText.gd`)
"STREAK xN" animado que aparece en la posición de la comida y se desvanece mientras sube.

#### Screen shake (`ScreenShake.gd`)
`shake(intensidad)` via `offset = Vector2(randf_range(-i,i), randf_range(-i,i))` con decaimiento exponencial. Intensidad = `(streak - 1) * 0.8 + 0.5`.

### 8. Audio

| Evento | Efecto |
|--------|--------|
| Comer (racha 1-4) | `play_eat(1..4)` — tono ascendente por racha |
| Comer (racha 5) | Sonido especial de máxima racha |
| Game over | (Sin efecto específico — el fade visual es suficiente) |

No hay música de fondo. Diseño intencional para mantener la atención en el feedback táctil/visual.

---

## Estructura del proyecto

```
snake/
├── Game.tscn                  # Escena principal (todo en una)
├── Game.gd                    # Lógica completa del juego
├── LetterWaveText.gd          # Control wave animado para texto
├── ComboTimer.gd              # Barra combo + bounce
├── SnakeHead.gd               # Cabeza con ojos rotatorios
├── GridTexture.gd             # Fondo tileado 24×24
├── GridBorder.gd              # Borde 2px del grid
├── BorderScanner.gd           # Escáneres animados perímetro
├── ScreenShake.gd             # Cámara shake
├── FloatingText.gd            # Texto "STREAK xN" flotante
├── ExplosionEffect.gd         # Partículas al comer
├── AudioManager.gd            # Efectos de sonido
├── grid_background.gdshader   # Shader de fondo dinámico
├── fonts/
│   └── PressStart2P-Regular.ttf
└── README.md
```

## Testing con godot-mcp

```bash
# Iniciar juego congelado (frame 0)
godot_editor_edit stop && godot_editor_edit run frozen=true

# Avanzar tiempo
godot_game_time step duration_ms=1000

# Inyectar input
godot_input sequence [{"action_name":"ui_up","duration_ms":50}]

# Leer estado
godot_runtime_state digest
godot_editor_read get_log_messages severity=error
```