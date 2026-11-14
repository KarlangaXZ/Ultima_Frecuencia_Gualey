# Fase 4.4 — integración técnica del zombi base

## Resultado

Integradas las 16 animaciones idle/walk/attack/death en down/up/left/right.
Se verificaron **96 PNG** con el manifiesto real en
`assets/characters/zombies/MANIFEST.json` (fuera de base/): todos los hashes
SHA-256 coinciden, dimensiones 128 × 128, modo RGBA y alfa transparente presente.
El bloqueo anterior por falta de recursos queda resuelto.

| Estado | Frames por dirección | Reproducción |
| --- | ---: | --- |
| Idle | 4 | 4 FPS, bucle |
| Walk | 8 | 8 FPS, bucle |
| Attack | 6 | Sin bucle; ciclo sincronizado con attack_interval real |
| Death | 6 | 13.333333 FPS, una vez, conserva frame 05 |

Las direcciones visuales corresponden a los nombres de archivo; no se reflejaron
ni modificaron PNG. Se inspeccionaron las 16 previsualizaciones y doce capturas
de ejecución de walk/attack/death en las cuatro direcciones. No se detectaron
fondos grises extensos, recortes graves ni errores de orientación en esas revisiones.
Se acepta como **paquete técnico provisional**, no arte definitivo.

## Calidad y límites

Cada Idle tiene 3 poses únicas (00 y 02 idénticos); cada Walk tiene 7 (00 y 04
idénticos). La pose inicial también se comparte entre estados en una misma
dirección. Attack y Death tienen seis imágenes distintas por secuencia.
Se mantienen las repeticiones suministradas; no se crearon poses sustitutas.

El desplazamiento de pies, la zancada y el golpe son aproximaciones por
transformación de poses. La continuidad requiere valoración artística posterior.
Death es una caída simplificada. Estas limitaciones se aceptan para integración
técnica y no se presentan como ciclos dibujados de calidad final.

Contenido alfa dentro del lienzo (rango vertical global y=43–122), sin tocar su
borde inferior. Escala visual 0.85 y offset (0,-46), coherentes con el tamaño del
protagonista en las capturas. No se adaptaron cuerpos físicos al dibujo.

## Separación visual y gameplay

`scripts/visuals/zombie_visual.gd` extiende CharacterVisual y reutiliza la carga
de SpriteFrames, feedback de salud y señal de muerte, pero selecciona estados del
zombi sin cambiar el controlador del protagonista.

Lee velocidad, estado, objetivo, cooldown y attack_interval de la IA.
Walk corresponde al eje dominante del movimiento; Idle conserva la última
orientación. En ataque se orienta al objetivo y fija la dirección al comenzar
el ciclo. Cada renovación del cooldown real reinicia Attack. La duración visual
se adapta a attack_interval, sin cambiar ese valor; una reentrada en rango con
cooldown pendiente no inventa un golpe. La animación nunca aplica daño.

La IA conserva 105 px/s, 50 HP, detección 250 px, alcance 35 px, daño 10 HP y
1.5 segundos entre ataques. Conserva CharacterBody2D, radio 16, capas/máscaras
y NavigationAgent2D. No se editó zombie.gd, salud, navegación, jugador, HUD, armas
ni Game Over.

Al morir se mantiene DEAD, desactivación diferida de colisiones, una baja y el
desvanecimiento a alfa 0.25 durante 0.45 s. Los seis frames de muerte se reproducen
dentro de ese mismo flujo y conservan el último; no se retrasa ni cancela la
desactivación. El cadáver sigue inerte hasta el reinicio.

## Archivos

Creados:
- `assets/characters/zombies/base/ZombieBaseFrames.tres`.
- `scripts/visuals/zombie_visual.gd` y UID.
- `tests/zombie_visual_test.gd` y UID.
- Metadatos .import de los recursos suministrados.
- `docs/images/zombie-base.png`: composición de frames reales, sin arte inventado.

Modificados:
- `scenes/enemies/Zombie.tscn`: controlador, biblioteca, escala y pivote visuales.
- `tests/phase_four_test.gd`: espera ahora el frame final 05 en lugar de 03.
- README, guía de agentes y guía de recursos del zombi.
- Este informe, sustituyendo el diagnóstico previo de recursos faltantes.

## Validación

Regresión anterior: **307 aprobadas**. Nueva prueba: **76 aprobadas**.
Total: **383 comprobaciones distintas, 0 fallos**.
Prueba con OpenGL real: **88 aprobadas**, incluidas doce capturas en
`test-results/zombie/`, inspeccionadas en todas las direcciones.

Se comprueba biblioteca/bucles, detección y persecución, dirección, avance de
ataque sin daño adicional, segundo daño a 1.5 s, salud, muerte, frame final,
colisiones desactivadas, una baja y fade. Las pruebas previas conservan cobertura
de obstáculos/pathfinding, reinicio y Game Over.

La primera ejecución de la nueva prueba necesitó una anotación de tipo para su
nombre de animación; se corrigió en el test. Las ejecuciones finales no muestran
errores ni advertencias de Godot.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/zombie_visual_test.gd
godot --path . --fixed-fps 60 --script res://tests/zombie_visual_test.gd -- --capture
```

Pendiente: sesión manual, continuidad de ciclos y diagonales a velocidad real,
valoración artística y panel gráfico del depurador. Sin commits automáticos.

## Actualización de fase 8.1

La población actual es de hasta seis vivos y 18 apariciones totales. Se validó
movilidad con IA activa sin editar zombie.gd ni sus parámetros. El presupuesto
completo del capítulo ofrece 790 XP; los resultados anteriores conservan su
fixture histórica de tres enemigos. [Diagnóstico y pruebas actuales](zombie_population.md).
