# CHANGELOG

Registro de cambios del proyecto. Formato: fecha · qué · por qué · archivos.

---

## 2026-08-05 — Slime: IA por grupo, fusión y anti-tedio (Fase 4)

**Qué:** Comportamiento completo del Slime según el GDD actualizado: movimiento a
saltos (hop) con árbol de decisión por grupo (Solo/Pinza/Mural), cooldown de golpe
con encogimiento, recuperación de tamaño, y fusión en Slime Grande 2×2.

**Por qué:** Convierte al enemigo base en una amenaza viva cuya dificultad nace de
la coordinación en grupo y la fusión (no de stats), y evita el combate tedioso con
el cooldown anti-stun-lock.

**Archivos tocados:**
- `Documentacion/GDD.md` — sección Slime reescrita (comportamiento + animaciones).
- `resources/EnemyData.gd` — config data-driven del Slime (hops, radios, umbrales,
  cooldowns, tallas) en vez de números mágicos.
- `scenes/enemy/Enemy.gd` — footprint por `grid_size` (`occupies_cell`), cooldown de
  golpe (`hit_cooldown_time`), señal `merged`, hook `_on_hit_started`, miembro `max_hp`.
- `scenes/enemy/Slime.gd` — reescrito: máquina de fases hop, árbol de decisión,
  fusión, encoger/recuperar, ojos que miran al jugador, gotas de goo al aterrizar.
- `Game.gd` — colisión usa `occupies_cell` (soporta 2×2), filtra drops no-enemigo,
  conecta `merged` → decrementa `enemies_alive`.

**Correcciones durante prueba:**
- `take_damage` en `Enemy.gd`: aplicar el daño **antes** de `_on_hit_started()` para
  evitar doble conteo al encoger (30→12→7 a 30→12). El encogimiento solo ajusta el
  tope de masa.
- `_check_enemy_collision`: filtra las gotas de «goo» (ColorRect) que viven en el
  contiene no enemigos tras `_land_fx`.

**Validación:** scripts parsean (`--check-only`), 25s headless sin errores de
runtime, tests headless de fusión (3 slimes → Slime Grande 2×2) y de anti-stun-lock
(golpe→encoge, cooldown bloquea el 2º, 3º tras el cooldown).

**Correcciones por bugs reportados (mismo día):**
- `Game.gd` — daño simétrico: el jugador solo recibe daño cuando el golpe al slime
  realmente aterriza (`take_damage` devuelve `true`). Antes, durante el cooldown de
  golpe, el jugador podía sufrir daño repetido sin que el slime recibiera nada.
- `Slime.gd` — `grid_pos` se commitea al **aterrizar** el salto (no al despegar).
  La colisión (por `grid_pos`) coincidía con una casilla que el cuerpo aún no había
  alcanzado, permitiendo «pasar por encima» del slime y quedarse sin dañarlo.
  `_try_hop` → `_try_hop_cell` calcula el destino sin commitearlo.
- `Slime.gd` — fusión clampeada: el centroide del Slime Grande 2×2 se limita a
  `0..GRID_W-2` / `0..GRID_H-2` (antes podía quedar fuera del grid jugable, p.ej.
  x=29). Su `global_position` se sincroniza con el footprint resultante.
- `Slime.gd` — gotas de goo de `_land_fx` se posicionan en coordenadas locales del
  contenedor (`to_local`), no globales (estaban desplazadas por el offset del área).

**Validación (bugs):** test headless con teleport de la cabeza sobre el slime:
1er contacto slime 30→12 y jugador 100→90; 2º contacto (cooldown) ambos intactos
(12→12 y 90→90). Test de fusión en el borde: 2 slimes en x=28,29 → Big en (28,9),
footprint 2×2 dentro del grid. Regresión headless 1500 frames sin errores.

**Ajuste de balance (mismo día):** SMALL y MEDIUM mueren de **1 toque**;
solo el Slime Grande (BIG 2×2) aguanta golpes múltiples. El encogimiento
MEDIUM→SMALL queda sin uso y se retira de `_on_hit_started`. Además, el spawn de
enemigos se clampea a `0..29`×`0..17` para que ningún slime pueda nacer fuera del grid.

**Validación (balance):** test headless — MEDIUM: `take_damage` → muere (is_alive
false); BIG: sobrevive con 26 HP tras 10 de daño. Fuga de grid no reproducible:
8 escenarios sintéticos (spawn en borde + jugador más allá del borde, 30s) y
reproducción en vivo con el Game real (30s patrullando bordes) → 0 violaciones de
`grid_pos` y 0 de posición visual.

**Bug: slimes se veían en el HUD al saltar (mismo día):** el sprite del slime se
salía del grid por arriba durante el arco del salto (y un Slime Grande 2×2 asomaba
incluso en reposo en la fila 0). Fix en `Slime.gd`: `_clamp_visual_y()` mantiene el
sprite (arriba y abajo) dentro del área del grid en todo momento — se aplica durante
el JUMP, al aterrizar y en `_apply_tier_visual`.

**Bug: `_clamp_visual_y` no contemplaba el offset de GameArea (mismo día):** la fórmula
usaba `clampf(pos.y, -ny, GRID_H*TILE - ny - size.y)` asumiendo que el grid empieza
en y=0 global, pero `GameArea` está en y=76. Para un slime en fila 0 (ny=88), el
límite inferior era -88, pero el arco del salto alcanzaba -18 → global_y=70 < 76
(grid top). Fix:constante `GRID_TOP_Y = 76` y bounds correctos
`clampf(pos.y, GRID_TOP_Y - ny, GRID_TOP_Y + GRID_H*TILE - ny - size.y)`.

**Validación (clamp visual):** verificación analítica: fila 0 (ny=88), arco salto
-18 → clamped a -12 → global 76 = grid top ✓; fila 17 (ny=496), reposo -10 → clamped
a -8 → bottom 508 = grid bottom ✓; BIG fila 17 reposo -22 → clamped a -32 → bottom
508 ✓. Regresión headless 600 frames sin errores.

**Bug: el jugador «pasaba por encima» de un slime saltando sin dañarlo (mismo día):**
`occupies_cell` solo comprobaba `grid_pos`, pero ese valor solo se commitea al
aterrizar. Durante el JUMP el sprite ya se desplaza por el arco, así que la hitbox
(retenida en la casilla de partida) quedaba desincronizada del cuerpo visible: la
cabeza entraba en la casilla de destino y atravesaba al slime sin colisión. Fix en
`Slime.gd`: override de `occupies_cell` que durante `Phase.JUMP` marca todo el camino
`grid_pos → _target_grid_pos` (inclusive), y delega en la base el resto. Verificado:
regresión headless 600 frames sin errores.

**Migración a colisión por física (mismo día):** la detección discreta por celdas
se ejecutaba solo en el tick de la serpiente (~0.15s), pero el slime se mueve de
forma continua cada frame; podía cruzar la casilla de la cabeza entre dos ticks sin
que ninguna comprobación lo detectara. Se reemplaza por física real:
- `project.godot` — capas 2D `snake`/`enemies`/`food` (`layer_names/2d_physics`).
- `Game.tscn` — `SnakeHead`: layer 1, mask 6 (enemies|food), shape 24×24 centrado
  en (12,12); `Food`: layer 4.
- `Enemy.gd` — `CollisionShape2D` dinámico por `grid_size` (24×24 o 48×48), layer 2.
  La hitbox viaja con el nodo, que a su vez sigue el lerp continuo del salto.
- `Slime.gd` — `_update_collision_shape()` tras fusionar (BIG 48×48 centrado).
- `Game.gd` — `_physics_process` llama `_check_enemy_collision()` cada frame usando
  `snake_head.get_overlapping_areas()` (cooldown anti-spam en `take_damage`).

**Validación (física):** test headless — head lejos→0 overlaps; head sobre slime
1×1→1 overlap (is_alive); Slime Grande 2×2 shape 48×48, head en celda interior del
footprint→detectado. Regresión headless 1200 frames sin errores.

---

## 2026-08-06 — SlimePack: manada táctica con coordinación compartida (Fase 4)

**Qué:** La IA del Slime deja de ser un árbol reactivo por conteo de aliados
(Solo/Pinza/Mural por hop) y pasa a un coordinador de manada con percepción
compartida, asignación de slots/roles, presión espacial, memoria de sala y fusión
táctica interactiva. La dificultad emerge de la coordinación, no de inflar stats.

**Por qué:** El comportamiento "correcto" pero predecible no era suficiente; cada
slime decidía en cada salto según el número de aliados, generando oscilaciones y
sin que la manada pareciera aprender del jugador.

**Arquitectura (3 capas):**
- `Slime.gd` = locomoción (hop) + animación + combate básico + rasgos de personalidad.
- `SlimePack.gd` (nuevo) = percepción compartida + estados de manada + slots + roles
  + memoria + decisión de fusión.
- `Pressure System` (en SlimePack) = evaluación espacial continua del cerco.

**Archivos tocados:**
- `scenes/enemy/SlimePack.gd` (nuevo) + `SlimePack.tscn` (nuevo) — nodo coordinador
  por sala: máquina `SEARCH → REGROUP → WRAP → PRESS → FUSE`, presión direccional
  (1/2.5/4.5/6 por lados cubiertos), slots radiales alrededor del jugador con pool
  único por tick (sin duplicados), roles (persecutor/shepherd/anchor/see), memoria
  `preferred_dir`/`last_escape` (scoped a la sala, damping por `pack_memory_time`),
  y fusión por canalización interrumpible.
- `scenes/enemy/Slime.gd` — `_begin_jump()` delega el destino al pack
  (`_pack_jump()`); rasgos de personalidad (impulsivo/cauteloso/pesado/ligero/social)
  como pesos de decisión con jitter determinista; `begin_channel()`/`end_channel()`/
  `_process_channel()` (vibra + aura, no persigue); `do_pack_merge()` para fusión
  pack-driven; `_on_hit_started()` notifica al pack (interrupción).
- `Game.gd` — `_spawn_enemies()` instancia un `SlimePack` por sala si hay slimes,
  registra cada slime y lo enlaza.
- `resources/EnemyData.gd` — bloque `pack_*` data-driven (presión wrap/press/fuse,
  canalización, memoria, `pack_fuse_*`, personalidad).
- `Documentacion/GDD.md` — sección Slime reescrita: IA de manada (SlimePack),
  roles ampliados, presión espacial, memoria de sala, personalidad y fusión táctica
  interrumpible.

**Validación (tests headless):** pack registra 4 miembros; presión 6.0 con 4 lados
cubiertos; 4 slimes → 0 slots duplicados con pool completo y fallback distinto por
miembro cuando el pool se agota; canalización arranca/termina; golpe a un miembro
interrumpe la canalización del grupo entero. Regresión Game.tscn 1200 frames sin
errores.

**Bug: slimes quedaban congelados tras la fusión (mismo día):** con 3+ slimes la
presión alcanzaba `FUSE`, el pack canalizaba 2 elegidos y, al completarse el canal,
`_finish_fusion()` llamaba `do_pack_merge(group)` cuyo guard usaba `can_merge()`
(que exige `not _channeling`). Como el líder estaba **a propósito** canalizando, el
guard devolvía `false` y salía sin limpiar `_channeling` ni llamar `end_channel` —
el pack ya había reseteado su propio `_channeling` y vaciado `fuse_group`, así que
nadie soltaba a esos slimes: se quedaban vibrando para siempre, sin moverse, y la
sala no se podía limpiar. Fix:
- `Slime.gd` — `do_pack_merge()` deja de usar `can_merge()` (la canalización es el
  estado normal al completarse); gate propio (vivo/absorbido/lock/talla ≥2 miembros).
- `SlimePack.gd` — `_finish_fusion()` suelta `end_channel()` a **todos** los miembros
  del grupo antes de intentar la fusión, pase lo que pase con el líder.

**Validación (bug):** test headless — 3 slimes, fusión natural: 0 congelados,
1 Slime Grande formado, pack sin canalizar; tras golpe a un miembro: 0 congelados.
Regresión Game.tscn 150 frames sin errores.

---

## Fases previas

- Fase 3: sistema de salas con transiciones y puerta (commit `b4b1b71`).
- Fase 2: HUD modular completo (commit `85ed0a3`).
- Fase 1: refactor a autoloads + SnakeRenderer/StreakHUD/EatEffects (commit `a88c070`).
