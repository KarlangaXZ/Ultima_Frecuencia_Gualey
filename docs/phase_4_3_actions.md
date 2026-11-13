# Fase 4.3 — acciones visuales provisionales

## Resultado

Integradas **Reload y Death en cuatro direcciones**, 48 PNG. Los 16 PNG Shoot
se revisaron, pero no se integraron por los defectos descritos abajo. La fase no
se declara completa en Shoot. Se conserva el disparo funcional y su feedback
existente. Todo este paquete es **técnico y provisional**, no arte definitivo.

Se verificó `assets/characters/player/shoot/MANIFEST.json`: las 64 rutas existen,
los 64 SHA-256 de archivo coinciden, todos los PNG son RGBA 128 × 128 y tienen
píxeles transparentes. Se inspeccionaron las doce previsualizaciones, orientación,
borde de alfa y límites de contenido. No se modificaron PNG ni manifiesto.

## Selección por calidad

| Secuencia de Godot | Fuente integrada | Decisión |
|---|---|---|
| reload_down / death_down | archivos *_down_00–05 | Aceptación técnica provisional |
| reload_left / death_left | archivos *_left_00–05 | Aceptación técnica provisional |
| reload_up / death_up | archivos *_right_00–05 | Corregida: muestran espalda |
| reload_right / death_right | archivos *_up_00–05 | Corregida: muestran perfil derecho |
| shoot_down / shoot_left | No integradas | Destello incrustado y pose poco representativa |
| shoot_up / shoot_right | No integradas | Destello incrustado y orientación intercambiada |

Los archivos `shoot/player_shoot_{down,left,right,up}_02.png` contienen un destello
dibujado. Reproducirlos junto al destello del hitscan duplicaría el efecto, en
momentos distintos. Además, la fuente right muestra espalda y up muestra perfil
derecho. La mayoría de frames mantienen brazos bajos sin una postura de arma
convincente. No se eliminaron frames ni se simularon secuencias de cuatro poses.
Para integrar Shoot: entregar cuatro ciclos con posturas y orientación correctas,
sin destello dibujado, que se puedan activar exclusivamente desde shot_fired.
Mientras tanto no existe un estado nuevo de Shoot; el comportamiento anterior
de disparo, trazo, partículas y munición continúa intacto.

Reload representa oscilación corporal, no manipulación real de cargador.
Death representa giro/caída por transformación de la silueta, no poses redibujadas.
Se aceptan como aproximación funcional, con retoques artísticos pendientes.
Hay variaciones de escala/huella durante la caída y pequeñas diferencias de base
entre el arte de acciones y idle. No son animaciones con calidad final certificada.

## Integración sin cambiar gameplay

`PlayerActionAnimations.tres` es una biblioteca separada; no modifica los recursos
Idle/Walk. Player/Visual combina animation_library con action_library. Solo el
controlador visual escucha Weapon.reload_changed, lee reload_remaining y duración,
y escucha HealthComponent.died. No modifica datos del arma ni de salud.

Reload usa seis frames nominales a 4 FPS, sin bucle. Su reproducción se controla
por el progreso **real** de la recarga existente: 0–1 durante sus 1.5 segundos.
La transferencia de balas sigue siendo responsabilidad de Weapon. Terminar o
cancelar la recarga libera la presentación; la muerte tiene prioridad y no queda
atrapada en Reload. La dirección queda fijada al comenzar la acción visual.

Death usa seis frames a 7 FPS, sin bucle, activada únicamente por died. Conserva
el frame 05 después de terminar. El personaje permanece deshabilitado por la lógica
anterior; no se altera Game Over ni se retrasa su panel. La caída sucede detrás
del overlay existente. Solo las capturas de prueba ocultan ese panel para poder
inspeccionar el cadáver; la partida normal no lo hace.

No se cambiaron movimiento, física, cámara, colisiones, IA, salud, daño, munición,
duración de recarga, cadencia ni efectos de disparo. No se añadieron dependencias.

## Archivos

Creado: `assets/characters/player/PlayerActionAnimations.tres`,
`tests/player_actions_test.gd` y metadatos correspondientes.
Modificados: Player.tscn para asignar action_library, character_visual.gd y
pruebas previas que esperaban 16 animaciones o muerte provisional de cuatro frames.
Ahora se comprueban 20 animaciones y muerte de seis frames, sin eliminar cobertura
de gameplay. Documentación actualizada; no se generaron placeholders ni commits.

## Validación

- Importación Godot 4.7.2 correcta.
- Regresión anterior: 230 comprobaciones aprobadas.
- Acciones: 48 comprobaciones aprobadas; total **278**, cero fallos.
- Prueba con renderizado: 56 comprobaciones aprobadas, incluidas ocho capturas.
- Se revisaron las ocho capturas de Reload/Death de todas las direcciones en
  `test-results/actions/`. No se observaron errores de Godot en las pruebas.
- Se comprobó duración real, transferencia 11/48→12/47, cancelación por muerte,
  selección de dirección, vuelta a Idle, frame final persistente y ausencia de
  las secuencias Shoot descartadas. Las pruebas anteriores verifican el combate.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/player_actions_test.gd
godot --path . --fixed-fps 60 --script res://tests/player_actions_test.gd -- --capture
```

Pendiente: arte Shoot apto, valoración manual de continuidad y sincronización
percibida, prueba manual de acciones mientras se camina y panel gráfico del
depurador. Las comprobaciones automáticas/capturas no sustituyen esa evaluación.
