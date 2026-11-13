# walk_left — revisión final de recursos, 12 de noviembre de 2026

Informe histórico: superado por [la integración V2](walk_left_v2_validation.md).

**Resultado: integración incompleta por defectos persistentes en los PNG.**
No se modificaron SpriteFrames, escenas, scripts, texturas ni gameplay.
walk_left conserva su animación provisional; idle y las demás direcciones siguen
con los recursos ya integrados.

## Archivos verificados

Se revisaron individualmente los ocho `assets/characters/player/walk/player_walk_right_00.png`
a `_07.png`: por la asignación de direcciones previamente autorizada, estos son
los archivos que muestran la caminata hacia la izquierda. Los llamados
`player_walk_left_*` muestran la caminata derecha ya integrada; no deben sustituirse
como si representaran la orientación izquierda.

No se encontraron otras secuencias corregidas ni subcarpetas nuevas dentro de walk/.
Los ocho archivos relevantes siguen siendo RGBA 128 × 128 con alfa 0–255,
contenido vertical y=12–124. Sus hashes de píxeles coinciden con los obtenidos
en la revisión anterior: no se detecta una nueva versión corregida de esas imágenes.

| Archivo original | SHA-256 RGBA (12 caracteres) | Defecto visible |
|---|---|---|
| player_walk_right_00.png | 4e40c4a97984 | Restos amarillentos/claros junto a mochila y contorno |
| player_walk_right_01.png | 291cab594ddc | Mancha gris extensa detrás del cuerpo y bordes coloreados |
| player_walk_right_02.png | 9d8d860e68cf | Restos claros y amarillentos en contorno, especialmente espalda/pierna |
| player_walk_right_03.png | 5e59df101afd | Fondo gris entre/junto a piernas y contorno rojizo |
| player_walk_right_04.png | 5e094b1e6efb | Mancha gris detrás de espalda y piernas; halo amarillo |
| player_walk_right_05.png | d58457eae64f | Parche gris y borde rojo alrededor de espalda/piernas |
| player_walk_right_06.png | 3a39459ba7f9 | Restos claros/amarillentos en borde derecho y pie |
| player_walk_right_07.png | 045a0146c3a2 | Restos grises y borde rojizo en espalda y parte inferior |

Tener un canal alfa no demuestra que el fondo esté correctamente eliminado:
las manchas siguen formando parte visible de los sprites. No se certifica ausencia
de halo en ninguno de los ocho, ni se acepta una secuencia incompleta de frames.

## Acciones necesarias

Entregar/exportar los ocho fotogramas izquierdos completos con alfa limpio,
sin manchas grises ni bordes coloreados, conservando orden y pivote estable.
Pueden reemplazarse los `player_walk_right_*` manteniendo el mapa actual, o
entregarse con nombres nuevos inequívocos y actualizar el recurso después de
validarlos. No sobrescribir los `player_walk_left_*` usados por walk_right.

Una vez corregidos: verificar nuevamente 128 × 128, base de pies y escala frente
a idle_left; añadir walk_left al recurso existente a 8 FPS, loop=true; actualizar
la expectativa de fallback en las pruebas; revisar el ciclo real y sus transiciones.
La revisión artística debe evaluar todo el ciclo, no solo un frame limpio.

## Validación y alcance

Se inspeccionaron los ocho PNG, sus dimensiones, alfa, límites y hashes.
Las pruebas actuales se ejecutan sobre el estado existente, con walk_left
provisional: no validan una integración final que aún no se ha realizado.
Resultado: **221 comprobaciones aprobadas, 0 fallos**: fases 1–4 (146), idle_down
(13), walk_down (19), direcciones (43). No se observaron errores ni advertencias
de Godot en la salida filtrada. No se abrió una sesión nueva de renderizado ni
se inspeccionó el panel gráfico del depurador durante esta revisión.
No se generaron imágenes, no se retocaron fuentes ni se crearon commits.
La revisión de la animación final en Godot queda pendiente de PNG corregidos.
