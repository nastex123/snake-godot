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

Lento.

---

## Araña

Persigue.

---

## Torre

Dispara.

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