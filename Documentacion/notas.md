## Problema de superposición entre slimes

Actualmente, durante la partida, dos o más slimes pueden ocupar la misma casilla al mismo tiempo. Esto provoca que varios slimes se superpongan completamente, reproduzcan sus animaciones en el mismo lugar y ejecuten sus comportamientos de forma simultánea, lo que afecta tanto la legibilidad del combate como la calidad de la IA.

### Objetivo

Implementar un sistema de separación y coordinación entre slimes para que nunca compartan la misma casilla durante su comportamiento normal.

### Requisitos

* Los slimes deben mantener una distancia mínima entre sí y evitar ocupar la misma casilla.
* Antes de iniciar un salto, cada slime debe verificar si la casilla objetivo está ocupada por otro slime.
* Si la casilla está ocupada, debe seleccionar una alternativa válida o esperar un breve tiempo antes de volver a calcular su movimiento.
* Los slimes deben conservar sus patrones de ataque (persecución, pinza, mural, etc.) sin perder coordinación.
* Debe existir una separación visual y lógica entre ellos para que el jugador pueda distinguir claramente a cada enemigo.
* La única excepción a esta regla es el comportamiento de fusión.

### Fusión

Los slimes solo podrán acercarse y compartir espacio cuando estén ejecutando el proceso de fusión para formar un slime de mayor tamaño (medium/big, según la lógica del juego). En ese estado, la superposición es intencional y debe formar parte de la animación y del proceso de absorción.

### Resultado esperado

Los slimes deben comportarse como un grupo organizado: mantener formación, evitar colisiones entre ellos, coordinar sus ataques y únicamente converger cuando la IA determine que deben fusionarse.
