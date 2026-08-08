# CHANGELOG

Registro de cambios del proyecto. Formato: fecha · qué · por qué · archivos.

---

## 2026-08-07 — Convención de escenas: SlimeGrande 2×2 y Torre con CollisionShape2D propio

**Qué:** Aplica la convención de `AGENTS.md` (cada enemigo/item = `Area2D` con hijo
`CollisionShape2D`; cada variante = escena/script propios, no flag de runtime):

- `scenes/enemy/SlimeGrande.gd` + `.tscn` — variante 2×2 del Slime como escena/script
  propias. Solo nace por fusión del pack.
- `Slime.gd` — `_do_merge` ahora instancia el `SlimeGrande` (nodo nuevo) en el
  centroide del grupo y absorbe a todos los miembros (incluido el líder). El flag
  `size_tier = BIG` ya no se reasigna en runtime.
- `Enemy._add_visual()` — reutiliza el `CollisionShape2D` declarado en la `.tscn`
  si existe (antes siempre creaba uno en código, duplicando la hitbox).
- `Tower.tscn` — añade hijo `CollisionShape2D` (gracias al reuso, una sola hitbox).
- `Game.gd` — `_on_merge_spawned()` cuenta el grande como enemigo vivo de la sala
  (absorbe `merged` × miembros, suma 1 por el grande; abre la puerta al morir).

**Por qué:** Cumple AGENTS.md y elimina dos hitboxes físicas duplicadas por enemigo
(nueva la declarada en escena + la que creaba `_add_visual`).

**Validación:** test headless 17/17 — estructura de escenas (Area2D + CollisionShape2D
del RectangleShape2D en Slime/Tower/SlimeGrande), grande 2×2 (grid 2×2, hitbox 48×48,
sprite 44px, `can_merge` false), fusión (2 slimes → 1 SlimeGrande, absorbed ×2).
Playtest en vivo: fusión inyectada crea la grande y el contador se mantiene. Regresión
`Game.tscn --quit-after 240` sin errores.

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

## 2026-08-07 — Torre: láser fijo con 5 patrones (Fase 4)

**Qué:** Nuevo enemigo estático que dispara láseres en direcciones cardinales
**fijas** (definidas al spawn, no apuntan al jugador). Ciclo de 3 estados +
comportamiento de golpe distinto en cada uno + 5 patrones.

**Por qué:** Dar variedad de amenazas contra el jugador en movimiento (el láser
con telegraph obliga a leer qué fila/columna se bloquea) y enemigos de control de
zona sin IA de persecución.

**Diseño:**

- **Máquina de estados**: `AIM` (telegraph de dirección, `tower_aim_time`) →
  `FIRE` (instancia láseres `tower_beam_duration`) → `COOLDOWN`
  (`tower_reload_time`) → `AIM`.
- **Golpe según estado** (override de `take_damage` en `Tower.gd`):
  - `AIM`: el jugador recibe `data.damage` reflejado (no pierde vida ni se cancela).
  - `FIRE`: muerte de 1 golpe.
  - `COOLDOWN`: contador `_cooldown_hits` — 1er golpe sobrevive, 2º muere.
- **Patrones** (`TowerPattern`): `SINGLE_LEFT/RIGHT`, `SINGLE_UP/DOWN`,
  `DOUBLE_LR`, `DOUBLE_UD`, `CORNER` (2 perpendiculares apuntando al centro del
  tablero según la posición de la torre).
- **Láser**: `TowerLaser.gd` (Area2D) — segmento torre→borde del grid, `mask=1`
  (cabeza), daño 1x por rayo; el telegraph de AIM lo muestra con α pulsante.

**Archivos tocados:**
- `scenes/enemy/Tower.gd` + `Tower.tscn` — nuevo: `_process` con estados, geometría
  por patrón (`_dirs_for`/`_lane_rect`, rect normalizado min), preview y láseres en
  `_fx_root`/`_lasers_root` (hijos del parent del grid, creación perezosa), `die()`
  limpiando ambos roots antes del `super.die()`.
- `scenes/enemy/TowerLaser.gd` + `TowerLaser.tscn` — nuevo: Area2D con `setup(rect,
  dmg, col)`, detecta `snake_head`, daño 1x.
- `resources/EnemyData.gd` — enum `TowerPattern` + `tower_pattern`,
  `tower_aim_time`, `tower_beam_duration`, `tower_reload_time`, `tower_core_color`.
- `Game.gd` — `_spawn_enemies()` case `"tower"` (lee `pattern` del spawn, registra
  `died` → cuenta).
- `autoload/MapManager.gd` — torres en salas NORMAL/EVENT/SHOP/BOSS con patrones
  variados.

**Correcciones durante prueba (tests headless):**
- Inferencia de tipos (Variant) en `Tower.gd` (`end`/`t` con tipo explícito;
  `start + dir*N` era `Vector2i + Vector2` → cast a `Vector2i(dir)`).
- `_lane_rect` normaliza con `minf`/`.abs()` para direcciones −X/−Y (tamaño
  negativo salía negativo).
- `get_fx_root`/`get_lasers_root` usan `add_child.call_deferred` (el parent puede
  estar "busy" durante `_ready`) + `is_instance_valid` para no ceder en el 1er frame.
- `Tower.gd.die()` libera ambos roots antes de `super.die()` (no quedar huérfanos
  en `EnemyContainer`).

**Validación (tests headless):** los 5 patrones pasan de AIM→FIRE al tiempo
correcto con `n` telegraphs/láseres; `FIRE` mata de 1 golpe; `COOLDOWN` sobrevive
al 1er golpe y muere al 2º; `AIM` bloquea el daño a la torre y refleja `data.damage`
al jugador. Regresión `Game.tscn --quit-after` sin errores.

---

## 2026-08-07 — Hitbox vs sprite: desfases de anclaje y del salto (Fase 4)

**Qué:** Corrección de los desfases entre la representación visual del enemigo y su
área de colisión que impedían al jugador dañarlo en su casilla (slimes 1×1 que
maniobran en el tope del grid y Slime Grande 2×2).

**Por qué:** (a) el sprite 44px y el aura del 2×2 se pintaban centrados en la celda
esquina del bloque (el nodo vive en el centro de `grid_pos`), no en el centro de la
huella completa → sobresalían ~10px fuera y quedaban cortos; (b) en el salto,
`_hop_from`/`global_position` usa coordenadas de mundo (con el offset +76 del
GameArea) mientras `_hop_to` usa locales — la hitbox se hundía ~76px hacia arriba en
cada salto mientras el sprite quedaba clampeado dentro del grid: inalcanzable para
la cabeza del jugador.

**Archivos tocados:**
- `scenes/enemy/Enemy.gd` — helpers `_footprint_center()` (`(grid_size−1)×TILE/2`) y
  `_visual_base()`; `_add_visual()` ancla el sprite por la huella.
- `scenes/enemy/Slime.gd` — `visual.position` pasa por `_visual_base()` en JUMP/
  LAND/`_process_channel`/`_apply_tier_visual`; `_recenter_aura()` re-posiciona el
  aura sobre el centro del sprite; `_land_fx()` centra el goo en la huella;
  `_clamp_visual_y` solo recorta el arco (sin desacoplar sprite↔hitbox); el salto se
  mantiene en coordenadas **locales** (`position`) en `_start_hop_to`, `Phase.JUMP` y
  `_do_merge` (ya no mezcla con `global_position`).

**Validación:** test headless 15/15 — 1×1 (fila 0 y 17) y 2×2 (0,0)/(0,16) con hitbox
centrada en la celda y sprite dentro de la huella; la cabeza (colisión física)
alcanza al enemigo en reposo, en pleno salto (celda destino) y en las 4 celdas del
bloque. Regresión `Game.tscn --quit-after 180` sin errores.

---

## Fases previas

- Fase 3: sistema de salas con transiciones y puerta (commit `b4b1b71`).
- Fase 2: HUD modular completo (commit `85ed0a3`).
- Fase 1: refactor a autoloads + SnakeRenderer/StreakHUD/EatEffects (commit `a88c070`).
