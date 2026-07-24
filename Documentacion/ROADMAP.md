# ROADMAP DE DESARROLLO
## Snake Roguelite

**Versión:** 1.0

---

# Introducción

Este documento define las fases de desarrollo del proyecto **Snake Roguelite**.

Cada fase tiene un objetivo específico y solo se avanza cuando la anterior está completamente terminada.

La filosofía del proyecto es:

> **Primero construir una base sólida. Después añadir contenido. Finalmente pulir la experiencia.**

Cada fase debe dejar el proyecto en un estado completamente funcional.

---

# FASE 1
# Fundamentos del Roguelite

## Objetivo

Transformar el Snake arcade en una arquitectura preparada para un roguelite sin modificar todavía el gameplay principal.

Al finalizar esta fase el juego debe sentirse igual, pero internamente debe estar preparado para crecer durante todo el desarrollo.

---

## 1. Arquitectura

### Objetivos

Separar completamente el proyecto.

Eliminar scripts gigantes.

Cada sistema debe tener una única responsabilidad.

---

### Crear

Autoloads

- GameManager
- RunManager
- UpgradeManager
- AudioManager
- SaveManager

---

Carpetas

```
autoload/
assets/
fonts/
resources/
scenes/
scripts/
shaders/
```

---

Subcarpetas

```
player/
enemy/
boss/
food/
effects/
ui/
rooms/
pickups/
projectiles/
```

---

## 2. Sistema de estadísticas

Eliminar valores escritos directamente en el código.

Todo debe depender de estadísticas.

Ejemplo

```
Vida

Vida máxima

Daño

Velocidad

Cadencia

Crítico

Daño crítico

Escudo

Armadura

Experiencia

Oro

Suerte

Radio de recogida

Velocidad Snake

Multiplicador de racha
```

Todas deberán poder modificarse mediante objetos.

---

## 3. Sistema de daño

Aunque todavía no existan enemigos.

Crear el sistema completo.

Debe soportar

- daño
- curación
- escudos
- invulnerabilidad
- armadura
- efectos de daño

---

## 4. Máquina de estados

Estados principales

```
Menu

Loading

Playing

Upgrade

Shop

Boss

Paused

Game Over

Victory
```

Todo el juego dependerá de este sistema.

---

## 5. Sistema de eventos

Desacoplar completamente los scripts.

Ejemplo

```
El jugador come

↓

Evento

↓

HUD

↓

Audio

↓

Shader

↓

Screen Shake

↓

Partículas

↓

Experiencia

↓

Racha
```

Nunca un sistema llamará directamente a otro.

---

## 6. RunData

Crear un objeto que almacene toda la información de la partida.

Debe guardar

- tiempo
- score
- experiencia
- oro
- vida
- reliquias
- mejoras
- habilidades
- estadísticas
- sala actual
- semilla procedural

---

## 7. Recursos

Definir todos los recursos del juego.

Durante la partida

- Oro
- XP
- Nivel
- Vida
- Racha

Fuera de la partida

- Cristales
- Desbloqueos
- Logros

---

## Resultado esperado

El jugador prácticamente verá el mismo Snake.

Internamente el proyecto ya será un roguelite preparado para crecer.

---

# FASE 2
# Rediseño completo del HUD

## Objetivo

Crear un HUD profesional, modular y preparado para todas las futuras mecánicas.

No volverá a rediseñarse durante el desarrollo.

---

## Barra superior

Información principal

```
HP

XP

Nivel

Oro
```

---

Segunda línea

```
Score

Streak

Combo

Best
```

---

## Barra inferior izquierda

Reservada para habilidades.

Debe soportar entre cuatro y seis habilidades activas.

Cada habilidad tendrá

- icono
- cooldown
- animación
- tooltip

---

## Barra inferior derecha

Reservada para reliquias.

Cada reliquia tendrá

- icono
- rareza
- tooltip
- animación al obtenerla

---

## Barra izquierda

Buffs

Ejemplo

```
Velocidad

Frenesí

Escudo

Daño doble
```

---

## Barra derecha

Debuffs

Ejemplo

```
Veneno

Congelación

Maldición

Quemadura
```

---

## Centro inferior

Sistema de notificaciones

Debe mostrar

- XP
- Reliquias
- Eventos
- Salas
- Objetivos

---

## HUD del jefe

Barra enorme superior.

Nombre.

Animaciones.

---

## Minimap

Mostrar

- sala actual
- élite
- jefe
- tienda
- evento
- tesoro

---

## Animaciones

Todo el HUD debe sentirse vivo.

- Wave
- Bounce
- Pulse
- Glow
- Shake
- Fade

---

## Resultado esperado

El HUD ya soporta todas las mecánicas futuras.

---

# FASE 3
# Sistema de salas

## Objetivo

Eliminar el tablero único.

Crear un sistema de habitaciones.

---

## Tipos

- Normal
- Elite
- Evento
- Descanso
- Tesoro
- Tienda
- Jefe

---

## Generación

Cada run genera un recorrido diferente.

Las salas tendrán conexiones.

Ejemplo

```
□──□──□
   │
   □──□
      │
      ■
```

---

## Puertas

Cada puerta representa una decisión.

Ejemplo

```
Tesoro

Elite

Tienda
```

---

## Resultado esperado

El jugador comienza a explorar.

---

# FASE 4
# Enemigos y combate

## Objetivo

Transformar el Snake en un juego de acción.

---

## Crear IA

Slime

Araña

Fantasma

Torre

Gusano

Elite

---

## Sistemas

Movimiento

Ataque

Daño

Persecución

Estados

Spawn

Loot

---

## Proyectiles

Balas

Láseres

Explosiones

Áreas

---

## Resultado esperado

El jugador ya combate.

---

# FASE 5
# Objetos y Builds

## Objetivo

Crear partidas únicas.

---

## Reliquias

Más de 100.

---

## Habilidades

Dash

Bomba

Escudo

Congelar

Teletransporte

Imán

---

## Objetos pasivos

Modificarán

- daño
- velocidad
- veneno
- explosiones
- críticos

---

## Sistema de rarezas

Común

Inusual

Raro

Épico

Legendario

Maldito

---

## Sinergias

Las reliquias deben combinarse.

Ejemplo

```
Veneno

+

Explosiones

=

Nube tóxica
```

---

## Resultado esperado

Cada partida se siente distinta.

---

# FASE 6
# Eventos y mundo

## Objetivo

Añadir variedad.

---

## Tiendas

Comprar

Vender

Mejorar

Curar

---

## Eventos

Ruleta

Altar

Mercader

Santuario

NPC

Maldición

---

## Cofres

Normales

Raros

Malditos

---

## Resultado esperado

La exploración gana profundidad.

---

# FASE 7
# Biomas y Jefes

## Objetivo

Crear una campaña.

---

## Biomas

Laboratorio

Bosque

Ruinas

Volcán

Vacío

Núcleo

---

Cada uno tendrá

- enemigos propios
- música
- shader
- colores
- peligros ambientales

---

## Jefes

Uno por bioma.

Con múltiples fases.

Ataques únicos.

Drops exclusivos.

---

## Resultado esperado

El juego ya tiene progresión completa.

---

# FASE 8
# Metaprogresión

## Objetivo

Dar motivos para seguir jugando.

---

## Árbol de mejoras

Vida

Daño

Suerte

Oro

XP

Nuevas reliquias

Nuevos enemigos

Nuevos biomas

---

## Logros

Desafíos.

Skins.

Cosméticos.

Secretos.

---

## Estadísticas

Tiempo jugado

Runs

Victorias

Derrotas

Reliquias encontradas

Enemigos eliminados

---

## Resultado esperado

Cada partida contribuye al progreso permanente del jugador.

---

# FASE 9
# Pulido final

## Objetivo

Llevar el juego a calidad comercial.

---

## Mejoras

Optimización.

Balance.

Efectos visuales.

Shaders.

Animaciones.

Audio.

Accesibilidad.

Configuración.

Idiomas.

Guardado.

Soporte para mando.

Steam.

Logros.

Nube.

---

## Resultado esperado

Versión 1.0 lista para publicar.

---

# Filosofía del desarrollo

Cada fase debe terminar con un juego completamente funcional.

No se comenzará una fase nueva mientras existan errores importantes en la anterior.

El objetivo no es desarrollar rápido, sino construir una base sólida que permita añadir nuevas mecánicas sin reescribir sistemas completos.