# Integración de direcciones del protagonista — fase 4.2

Estado histórico anterior a V2. La caminata izquierda ya está integrada;
consultar [validación V2 y mapa actualizado](walk_left_v2_validation.md).

## Resultado y limitación

Integración parcial segura: idle real en cuatro direcciones (4 frames a 4 FPS)
y walk real en down/up/right (8 frames a 8 FPS), todos en bucle.
**walk_left conserva el atlas provisional**: los PNG que representan realmente
esa dirección tienen restos visibles de fondo. El usuario autorizó corregir la
asignación en SpriteFrames, conservando los PNG y sus nombres originales.

Se mantiene la ruta `idle/PlayerIdleDown.tres` y las dos secuencias down previas,
sin modificar orden, FPS, texturas ni sus archivos. Se integran 28 de los 36 nuevos
frames; ocho pendientes. Total actual: 40 frames reales de los 112 objetivo.

## Mapa de recursos autorizado

| Animación de Godot | PNG utilizados, relativos a player/ | FPS | Estado |
|---|---|---:|---|
| idle_down | idle/player_idle_down_00–03.png | 4 | Conservada |
| walk_down | walk/player_walk_down_00–07.png | 8 | Conservada |
| idle_left | idle/player_idle_left_00–03.png | 4 | Integrada |
| idle_up | idle/player_idle_right_00–03.png | 4 | Asignación corregida: muestran espalda |
| idle_right | idle/player_idle_up_00–03.png | 4 | Asignación corregida: miran a la derecha |
| walk_up | walk/player_walk_up_00–07.png | 8 | Integrada |
| walk_right | walk/player_walk_left_00–07.png | 8 | Asignación corregida: miran a la derecha |
| walk_left | Atlas SVG preexistente | 10 | Pendiente de PNG limpios |

No se reflejaron ni retocaron imágenes. Los PNG `player_walk_right_*`, que miran
a la izquierda, no se enlazaron al recurso. No se añadieron animaciones nuevas de
disparo o recarga; el flujo actual de armas se conserva. Death/attack provisionales
mantienen sus recursos y comportamiento.

## Verificación de archivos y presentación

Los 36 PNG nuevos existen en orden 00–03/00–07, son 128 × 128 RGBA con alfa
0–255 y hashes de píxeles distintos. Transparencia presente no implica limpieza
del fondo: se inspeccionaron las previsualizaciones y PNG individuales.

Walk up/left/right mantiene contenido entre y=12 y y=124; los idle nuevos
oscilan entre y=12–20 y y=121–124. Se conserva escala visual 0.4, offset (0,-56)
y orientación fija, coherentes con las secuencias down. Las bases nuevas pueden
variar hasta 2 px respecto a y=122 de down (0.8 px en pantalla). No se alteraron
archivos ni escalas de cuerpos físicos para ocultar estas diferencias.

Retoques pendientes por nombre de archivo original:

- `walk/player_walk_right_00–07.png`: revisar toda la secuencia. Hay manchas grises
  extensas, especialmente 01, 03, 04, 05 y 07, y bordes coloreados/restos de fondo.
  Reexportar alfa limpio antes de usarla como walk_left; no basta con cambiar FPS.
- `walk/player_walk_left_00–07.png` y `walk/player_walk_up_00–07.png`: halo claro
  visible en varios contornos. Integradas como material revisable, sin fondo gris
  extenso. Evaluar el ciclo completo y limpiar bordes desde los originales.
- `idle/player_idle_left_02.png` y `_03.png`: píxeles periféricos amplían el límite
  alfa hasta x=9 y x=22; comprobar limpieza del margen y estabilidad entre frames.
- `idle/player_idle_right_03.png`: contenido periférico hasta x=8. Esta secuencia
  se usa como idle_up; revisar también la variación de ancho/centro de sus frames.
- Resto de idle: revisar halo, desplazamientos pequeños y continuidad antes de
  considerar terminado el paquete artístico. No se certifica ausencia total de halo.

## Selección de estado

La velocidad determina walk y su dirección. En reposo se conserva la última
dirección de movimiento, incluso si cambia el mouse. Antes del primer movimiento
se conserva la orientación inicial basada en Aim. Aim y el hitscan siguen
apuntando al mouse independientemente del dibujo del cuerpo. En diagonales se
usa el eje dominante; en empate se mantiene la prioridad vertical existente.

No se cambiaron Player.tscn, movimiento, física, cámara, salud, armas, IA ni HUD.

## Archivos y validación

Modificados: PlayerIdleDown.tres, character_visual.gd, pruebas de idle/walk para
reemplazar expectativas de placeholders ya sustituidos, README y guías de recursos.
Creada `tests/player_directions_test.gd` y su UID. Se conservan los PNG y metadatos
de importación; no se tocaron los borradores que ya estaban presentes.

Importación en Godot 4.7.2: correcta. Pruebas: fases 1–4 (146), idle_down (13),
walk_down (19), direcciones (43): **221 comprobaciones distintas aprobadas**.
Prueba real con OpenGL y ocho capturas: 51 comprobaciones aprobadas, sin errores.
Se inspeccionaron idle/walk de las cuatro direcciones en `test-results/directions/`.
Esto confirma expresamente que la caminata izquierda sigue siendo provisional.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/player_directions_test.gd
godot --path . --fixed-fps 60 --script res://tests/player_directions_test.gd -- --capture
```

Pendiente: sustituir walk_left, revisión manual de ciclos y diagonales, valoración
de pivote/halo a velocidad real y panel gráfico del depurador. No hubo commits
automáticos ni generación de placeholders. La integración total de arte en las
cuatro caminatas requiere los ocho PNG limpios pendientes.
