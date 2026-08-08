# SNAKE ROGUELITE
## Game Design Document (GDD)
**Versión:** 2.0  
**Motor:** Godot 4.x  
**Género:** Roguelite · Arcade · Acción · Bullet Hell · Pixel Art Retro

---

# High Concept

## ¿Qué es Snake Roguelite?

Snake Roguelite reinventa el clásico Snake convirtiéndolo en un roguelite de acción donde cada partida genera una combinación distinta de enemigos, mejoras, reliquias y salas.

El crecimiento de la serpiente continúa siendo el núcleo del juego, pero ahora el jugador deberá sobrevivir a enemigos, completar salas, derrotar jefes y construir una combinación única de habilidades.

Cada comida no solamente hace crecer la serpiente.

También representa experiencia, recursos y progreso.

La filosofía es sencilla:

> **"Cada partida debe sentirse diferente."**

---

# Pilares del juego

## 1. Gameplay basado en Snake

La esencia nunca desaparece.

- Movimiento sobre un grid.
- Crecimiento constante.
- El cuerpo continúa siendo un obstáculo.
- El posicionamiento sigue siendo el principal desafío.

---

## 2. Builds

Cada partida genera una build completamente distinta.

Ejemplo:

Partida A

- Veneno
- Explosiones
- Dash
- Críticos

Partida B

- Láser
- Congelación
- Escudos
- Imán

---

## 3. Feedback visual extremo

Todo debe sentirse satisfactorio.

Cada acción genera:

- partículas
- shaders
- screen shake
- sonidos
- flashes
- animaciones del HUD

El jugador debe sentir que su build se vuelve cada vez más poderosa.

---

# Objetivo

Superar una serie de biomas.

Cada bioma termina con un jefe.

Al derrotar el jefe se desbloquea el siguiente.

---

# Público objetivo

Jugadores de:

- Vampire Survivors
- Hades
- Brotato
- Enter the Gungeon
- Soul Knight
- Nuclear Throne

pero que quieran una experiencia diferente basada en Snake.

---

# Gameplay Loop

```
Inicio

↓

Sala

↓

Comida

↓

XP

↓

Subir nivel

↓

Elegir mejora

↓

Nueva sala

↓

Más enemigos

↓

Mini jefe

↓

Más mejoras

↓

Jefe

↓

Nuevo bioma

↓

Muerte

↓

Metaprogresión

↓

Nueva partida
```

---

# Arquitectura del proyecto

```
project/

autoload/
GameManager
RunManager
UpgradeManager
AudioManager
SaveManager

scenes/

player/
enemies/
food/
rooms/
pickups/
effects/
ui/
bosses/

scripts/

resources/

upgrades/
enemies/
items/
biomes/
skills/

shaders/

fonts/

assets/
```

---

# Roadmap

## Fase 1

Arquitectura

Sistema de estadísticas

Sistema de daño

Eventos

RunData

Máquina de estados

---

## Fase 2

HUD definitivo

Animaciones

UI modular

Inventario

---

## Fase 3

Sistema de salas

Mapa

Puertas

Generación procedural

---

## Fase 4

Enemigos

IA

Pathfinding

Combate

---

## Fase 5

Objetos

Reliquias

Habilidades

Builds

---

## Fase 6

Eventos

Tiendas

NPC

Altares

---

## Fase 7

Biomas

Jefes

Progresión

---

## Fase 8

Metaprogresión

Árbol de mejoras

Logros

Desbloqueos

---

# Mecánicas

## Movimiento

La serpiente continúa moviéndose por celdas.

No existe movimiento libre.

---

## Crecimiento

Cada comida:

- aumenta el tamaño
- otorga experiencia
- aumenta la racha
- puede generar recursos

---

## Muerte

La partida termina cuando:

- la vida llega a cero
- el jugador choca consigo mismo (según el modo de juego)
- un jefe ejecuta una mecánica letal

---

# Sistema de estadísticas

Toda estadística será modificable.

```
Vida

Vida máxima

Velocidad

Daño

Cadencia

Crítico

Daño crítico

Escudo

Armadura

Suerte

Experiencia

Oro

Radio de recogida

Velocidad del Snake

Multiplicador de racha
```

---

# Recursos

Durante una run

- Vida
- XP
- Oro
- Racha
- Nivel
- Tiempo

Fuera de la run

- Cristales
- Desbloqueos
- Logros

---

# Sistema de rachas

El sistema actual se mantiene.

Ahora afecta:

- daño
- experiencia
- velocidad
- rareza de objetos
- multiplicador de oro

Mientras mayor sea la racha:

más difícil

más rápido

más recompensas

---

# Sistema de niveles

Cada nivel ofrece tres opciones.

```
Escoge una mejora

Veneno

Turbo

Colmillos
```

Nunca aparecen exactamente las mismas.

---

# Rarezas

```
Común

Inusual

Raro

Épico

Legendario

Maldito
```

Cada rareza modifica:

- probabilidad
- estadísticas
- efectos visuales

---

# Reliquias

Ejemplos

## Colmillos

+30% daño

---

## Núcleo eléctrico

Cada cinco comidas lanza rayos.

---

## Corazón tóxico

Los enemigos reciben veneno.

---

## Imán

Mayor radio de recogida.

---

## Botas

Mayor velocidad.

---

# Habilidades activas

Ejemplos

Dash

Bomba

Escudo

Congelar

Teletransporte

Onda expansiva

Imán

Invocar clon

Cada habilidad posee:

- cooldown
- mejoras
- icono
- sonido

---

# Enemigos

## Slime

Enemigo base, gelatinoso y social. Daña solo por contacto (misma casilla que la
cabeza). Su dificultad proviene de la **coordinación en grupo** y de la **fusión**,
no de sus estadísticas individuales.

Balance data-driven: todos sus parámetros (HP, daño, tiempos de hop, radio de
aliados, umbrales de fusión, cooldowns) viven en la data del enemigo (EnemyData),
nunca como números mágicos en la lógica.

### Movimiento — Hop

Se mueve a **saltos**, nunca en línea recta:

1. **Cargar (windup)**: se aplasta y se hunde en su casilla; los ojos miran fijamente al jugador.
2. **Salto**: se estira y se lanza en arco; puede saltar en **diagonal** para acortar distancia.
3. **Aterrizar (land)**: squash elástico + partículas de «goo».
4. **Pausa**: respiración suave entre saltos.

Cada salto recalcula la dirección a partir del **árbol de decisión**.

### Árbol de decisión (por grupo)

Al iniciar cada salto, cada slime cuenta sus **aliados a ≤ 4 casillas**:

- **[Solo]** → Persecución directa y agresiva: salto de 2 casillas apuntando al **camino** del jugador (intercepta su rumbo, no su posición actual).
- **[1 aliado]** → **Pinza**: cada slime cierra el eje con menor hueco (perpendicular al otro), aproximándose por ejes distintos para **triangular** y recoger al jugador.
- **[Manada 3+]** → **Mural**: se reparten **Perseguidor** (el más cercano hostiga) y **Corte-de-salida** (el resto se reubica a los flancos del jugador para cortar el escape y empujarlo hacia un borde/esquina).

### IA de manada — SlimePack (coordinación compartida)

Pasa de un árbol reactivo por conteo de aliados a un **director de manada** (nodo
`SlimePack`, uno por sala) cuya lógica vive parcialmente en el grupo y no en cada
slime por separado. La pregunta deja de ser «¿cuántos aliados tengo?» y pasa a ser
«¿qué posición me conviene ocupar para el objetivo común?».

- **Estados de manada** (todos los miembros leen el mismo estado, no deciden por
  separado): `SEARCH` (sin contacto) → `REGROUP` (dispersos) → `WRAP` (2+ cerca) →
  `PRESS` (pocas rutas de escape) → `FUSE` (presión + elegibles).
- **Slots radiales únicos**: cada tick el pack asigna a cada slime vivo un slot
  alrededor del jugador, con un **pool compartido** → nunca dos slimes apuntan al
  mismo destino en el mismo tick (cumple la regla de separación; si el pool se agota,
  el miembro cae a persecución con dirección propia).
- **Pressure System**: la presión se calcula por **lados direccionales cubiertos**
  alrededor del jugador (1 lado = 1, 2 opuestos = 2.5, triángulo = 4.5, anillo = 6),
  no por la cantidad de slimes. La fusión, la agresividad y el rol dependen de la
  **calidad del cerco**, no del número bruto.
- **Roles ampliados**: `persecutor` (frente), `shepherd` (empuja al jugador hacia una
  dirección, le sostiene contra la pared), `anchor` (se coloca detrás del jugador y
  **cierra la retirada**, no ataca), `see` (corte, ocupa la salida probable). Asignados
  por posición del slot vs jugador + memoria.
- **Predicción del jugador**: la persecución no solo intercepta el camino; los slimes
  de corte ocupan la **salida más probable** (p. ej. si el jugador se mueve a la
  derecha con una pared arriba, la salida probable es abajo-derecha).
- **Memoria de sala**: dirección preferida y último lado por el que escapó el jugador;
  si escapó por la izquierda varias veces, el grupo prioriza cerrar la izquierda.
  Scoped a la sala (se resetea al entrar en una nueva). Evita las oscilaciones de
  recalcular todo en cada salto.
- **Personalidad como pesos de decisión** (no stats): impulsivo (wind-up corto),
  cauteloso (prefiere corte), pesado (salto/pausa larga), ligero (hops rápidos),
  social (prioriza reagruparse). Ajustan solo los pesos de la decisión; evitan la
  sincronía visual de la manada.

### Cooldown por golpe y encogimiento (anti-tedio)

- Al golpear a un slime entra en una ventana de **~0.5 s sin recibir daño** (no se puede stun-lockear en cadena).
- El golpe lo **encoge una talla** (Medium → Small): menos masa, y **pierde la elegibilidad para fusionar**.
- Al alejarse el jugador, **recrece lentamente** hacia Medium, recuperando su capacidad de fusión. Recompensa rematar la manada a tiempo.

### Fusión — Slime Grande (amenaza principal)

Decisión **táctica del pack** (no un timer oculto): cuando presión ≥ umbral y hay
**≥2 slimes MEDIUM elegibles** (no encogidos, sin candado) con **HP promedio de la
manada > 60%** y pocos encogidos, la manada entra en estado `FUSE` y los elegidos
ejecutan una **canalización visible e interrumpible**:

- **Canalización (~1 s)**: los elegidos **vibran, generan un aura** y dejan de
  perseguir mientras convergen.
- **Interactiva**: el jugador puede **interrumpirla golpeando** a cualquiera del grupo
  (cancela la fusión de todos), **separándolos** o **encogiéndolos** (un encogido
  pierde la elegibilidad). No rematar a tiempo = crear un Slime Grande.
- **Slime Grande**: talla **2×2**, color más oscuro, **HP y daño de contacto
  multiplicados** (suma de integrantes + bono).

### Animaciones detalladas (squash & stretch procedural con tween)

- **Ciclo de hop**: cargar (aplastar + mirar al jugador) → salt (estirar + arco) → aterrizar (squash + goo) → pausa (respirar ~±).
- **Ritmo por rol**: Perseguidor con wind-up corto (agresivo), Corte-de-salida con «acecho» agachado; pausas con variola (`±20%`) para no sincronizar saldos.
- **Daño/cooldown**: flash blanco en el golpe → **deflación** elástica a la talla menor con wobble de «recuperándose»; parpadeo ligero mientras no puede recibir daño.
- **Re-inflar**: tween lento de crecimiento al alejarse el jugador con pequeños «sip» de aire.
- **Fusión**: los elegidos entran en **canalización** (~1 s): vibran y generan un
  aura dorada mientras dejan de perseguir y convergen; si no se interrumpe, squash
  conjunto + shake → **inflado** del Slime Grande 2×2 con burst de partículas y
  anillo de impacto; idle lento y pesado.
- **Muerte**: deflate elástico + splash de goo en el suelo + mancha que se desvanece.

Toda la animación usa curvas elásticas (`TRANS_CUBIC`/`EASE_OUT`) con overshoot, coherente con los visuales `ColorRect` actuales (no requiere assets).

---

## Araña

Persigue.

---

## Torre

Estática (no se mueve). Dispara láseres en direcciones cardinales **fijas** (el patrón se define al spawn, no apunta al jugador). Ciclo: **AIM** (telegraph) → **FIRE** (láser) → **COOLDOWN**.

| Estado | Duración | Al ser golpeada |
|--------|----------|-----------------|
| AIM | `tower_aim_time` | El **jugador** recibe el daño (reflejo); la torre no pierde vida ni se cancela |
| FIRE | `tower_beam_duration` | Muere de **1 golpe** |
| COOLDOWN | `tower_reload_time` | Sobrevive al 1er golpe; muere al **2º** |

**Patrones** (fijos por spawn, enum `TowerPattern`):
- `SINGLE_LEFT` / `SINGLE_RIGHT` (A): 1 láser horizontal fijo
- `SINGLE_UP` / `SINGLE_DOWN` (B): 1 láser vertical fijo
- `DOUBLE_LR` (C): ← + → a la vez
- `DOUBLE_UD` (D): ↑ + ↓ a la vez
- `CORNER` (E): 2 perpendiculares; la esquina apunta hacia el **centro del tablero** según su posición

**Láser**: `TowerLaser.gd` (Area2D) — segmento torre→borde del grid; daña a la cabeza 1 sola vez por disparo (`EventBus.damage_taken`). El telegraph de AIM muestra la fila/columna/región afectada con alpha pulsante antes de disparar.

**Data-driven**: `EnemyData` — `tower_pattern`, `tower_aim_time`, `tower_beam_duration`, `tower_reload_time`, `tower_core_color`.

---

## Fantasma

Atraviesa obstáculos.

---

## Gusano

Ocupa varias casillas.

---

## Elite

Versiones potenciadas.

---

# Jefes

Cada bioma posee uno.

Con:

- múltiples fases
- ataques únicos
- mecánicas especiales
- barra de vida

---

# Biomas

## Laboratorio

Inicio.

---

## Bosque tóxico

Veneno.

---

## Ruinas digitales

Láseres.

---

## Volcán

Lava.

---

## Vacío

Distorsiones.

---

## Núcleo

Bioma final.

---

# Sistema de salas

Tipos

Normal

Elite

Evento

Tesoro

Tienda

Descanso

Jefe

El jugador elige la siguiente puerta.

---

# Eventos

Ejemplos

Mercader

Santuario

Ruleta

Altar

Maldición

NPC

Desafío

---

# HUD

## Objetivos

- Modular.
- Escalable.
- Preparado para nuevas mecánicas.
- Muy animado.
- Legible.

---

## Barra superior

```
HP ████████

LV 8

XP ███████░

ORO 532
```

Segunda línea

```
SCORE

STREAK

COMBO

BEST
```

---

## Inferior izquierda

Habilidades

```
Dash

Bomba

Escudo
```

Con cooldown radial.

---

## Inferior derecha

Reliquias

```
○

○

○

○

○
```

Tooltip al pasar el cursor.

---

## Lateral izquierdo

Buffs

```
🔥 Frenesí

⚡ Velocidad

❄ Congelación
```

---

## Lateral derecho

Debuffs

```
☠ Veneno

💀 Maldición
```

---

## Centro inferior

Notificaciones

```
+25 XP

Nivel 4

Nueva reliquia

Sala completada
```

---

## HUD del jefe

```
██████████████████████

GUARDIÁN DEL VACÍO
```

---

## Minimap

```
□──□──■
    │
    □
```

Tipos de sala:

- Normal
- Elite
- Evento
- Tienda
- Tesoro
- Jefe

---

# Efectos visuales

El proyecto busca un nivel de feedback muy alto.

Cada acción genera efectos.

## Comer

- Explosión.
- Partículas.
- Flash.
- Sonido.
- Onda.

---

## Racha

- Cambio de color.
- Shader.
- Border Scanner.
- HUD.
- Screen Shake.

---

## Subir nivel

- Oscurecer pantalla.
- Aparición de cartas.
- Animación del HUD.

---

## Derrotar jefe

- Explosión gigante.
- Cámara.
- Flash.
- Slow Motion.

---

# Audio

Cada acción posee sonido.

- Comer.
- Golpear.
- Dash.
- Reliquias.
- Jefes.
- UI.
- Tienda.
- Eventos.

La música cambia según el bioma.

---

# Filosofía de diseño

El objetivo no es hacer un Snake con enemigos.

El objetivo es crear un roguelite cuya identidad siga siendo reconocible como Snake.

La serpiente continúa siendo el centro de todas las mecánicas, mientras que las mejoras, las reliquias, los enemigos y los biomas amplían la experiencia sin perder la esencia del juego original.

Cada partida debe ser distinta.

Cada build debe sentirse poderosa.

Cada acción debe transmitir impacto mediante efectos visuales, sonido y animaciones.