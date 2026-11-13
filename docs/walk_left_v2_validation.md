# walk_left V2 — integración y validación, 12 de noviembre de 2026

**Integrada:** ocho PNG nuevos `walk/player_walk_left_00.png` a `_07.png`,
exclusivamente en walk_left, a 8 FPS y loop=true. Se conserva la biblioteca
`idle/PlayerIdleDown.tres`; no cambian escena ni controlador visual.

## Recursos y bordes

Se compararon los píxeles RGBA con la versión de HEAD: los ocho son distintos
de sus anteriores. Todos miden 128 × 128, son RGBA y tienen alfa 0–255.
Se inspeccionaron individualmente y compuestos sobre fondo oscuro (#172027)
y claro (#eeeeee): no se observaron las manchas grises anteriores ni halos
apreciables a resolución nativa. No se modificó ni generó arte.

Límites alfa por frame, fin exclusivo:
00 (44,13,84,123), 01 (38,13,90,123), 02 (25,13,103,123),
03 (33,13,96,123), 04 (40,13,88,123), 05 (45,13,84,122),
06 (44,13,84,122), 07 (45,13,83,122).
Los ocho miran a la izquierda y conservan centro corporal y base con variación
de un píxel (0.4 px con la escala activa). Las extremidades explican la variación
de ancho del ciclo. Escala 0.4 y offset (0,-56), compartidos con idle_left.

## Conservación de walk_right

Antes de V2, walk_right utilizaba precisamente los archivos llamados
player_walk_left_*. V2 sustituyó sus píxeles por el sentido opuesto. Para conservar
la apariencia derecha se recuperaron las ocho imágenes anteriores de HEAD en
`walk/legacy_right/`, con los mismos nombres, y se reasignaron solo las rutas de
esa animación. Las copias coinciden byte a byte con los originales anteriores.
Su orden, tiempos y bucle permanecen idénticos. No se reflejaron imágenes.

walk_left apunta ahora a `walk/player_walk_left_*`; walk_right apunta a
`walk/legacy_right/player_walk_left_*`. No se usan los antiguos player_walk_right_*
defectuosos para ninguna de estas dos secuencias.

## Validación y archivos

Importación en Godot 4.7.2 correcta. Regresión: fases 1–4 (146), idle (13), walk
down (19), direcciones (52): **230 comprobaciones aprobadas, 0 fallos**.
Ejecución real OpenGL de direcciones: 60 aprobadas, incluyendo ocho capturas.
Se revisaron walk-left, idle-left y walk-right: orientación y transición correctas.
No hubo errores ni advertencias de Godot en las salidas revisadas.

Modificados: SpriteFrames, pruebas de direcciones y walk_down (se sustituye la
expectativa de atlas provisional), documentación. Creadas las ocho copias de
conservación de walk_right y sus metadatos. PNG V2 suministrados por el usuario,
sin retoques. Física, movimiento, cámara, combate, salud, IA e idle intactos.

Evidencia local ignorada por Git: test-results/walk-left-v2/dark.png y light.png;
capturas de Godot en test-results/directions/. Sin commits automáticos.

No quedan defectos nuevos identificados en walk_left V2 bajo esta inspección.
Queda pendiente valorar manualmente la fluidez del ciclo completo y diagonales
en tiempo real; las capturas no sustituyen esa evaluación. Los retoques ya
documentados de otras animaciones no forman parte de esta corrección.
