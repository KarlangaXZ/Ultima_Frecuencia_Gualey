# Shoot corregido — fase 4.3

## Recursos y asignación

Se verificaron los 16 archivos de shoot/MANIFEST.json: todos existen y sus SHA-256
de archivo coinciden. Todos son RGBA 128 × 128 con transparencia. Las cuatro
secuencias corregidas ya no muestran el destello dibujado del paquete anterior.
No se modificaron ni generaron PNG. Son recursos **provisionales**, no arte final.

Up y down corresponden a espalda y frente. Los perfiles left/right continúan
intercambiados en los nombres de archivo; se corrigió su asignación únicamente
en SpriteFrames, siguiendo el criterio previamente autorizado para este personaje:

| Animación | Fuente, índices 00–03 |
|---|---|
| shoot_down | player_shoot_down_XX.png |
| shoot_up | player_shoot_up_XX.png |
| shoot_left | player_shoot_right_XX.png |
| shoot_right | player_shoot_left_XX.png |

La metadata source_pose del manifiesto es descriptiva y no garantiza la orientación:
la selección anterior se basa en la inspección visual de perfiles y espalda.
Se revisaron las cuatro previsualizaciones y PNG individuales laterales. No se
aprecia un destello extra ni fondo gris en los recursos corregidos inspeccionados.
Las poses siguen siendo variaciones técnicas sutiles, con brazos bajos; necesitan
redibujo artístico si se busca una postura de arma convincente.

## Integración

Se añadieron cuatro animaciones sin bucle a PlayerActionAnimations.tres, manteniendo
Reload/Death y la biblioteca Idle/Walk. FPS nominal: 4/0.3 ≈ 13.333333.
El controlador visual escucha exclusivamente **Weapon.shot_fired**, emitida después
de validar munición, recarga y cooldown. Un clic rechazado no activa Shoot.

La reproducción se posiciona según el cooldown real dividido por fire_interval:
los cuatro frames ocupan los 0.3 segundos existentes. Un tiro válido reinicia
el ciclo. La dirección se toma del vector del disparo, independientemente del
movimiento del cuerpo. Al terminar vuelve al Idle/Walk actual; si el jugador se
detuvo durante Shoot se conserva la última dirección de movimiento.

Prioridad: Death > Reload > Shoot > locomoción. Recargar interrumpe Shoot y morir
cancela ambas presentaciones. Estas decisiones no bloquean movimiento ni escriben
salud, munición, daño o tiempos del arma. No se duplican partículas ni destello:
Combat/Effects continúa siendo el único efecto de boca del arma. La nueva capa
no crea efectos adicionales.

## Archivos y pruebas

Modificados: PlayerActionAnimations.tres y character_visual.gd; pruebas anteriores
que esperaban Shoot ausente/20 animaciones ahora validan Shoot presente/24 estados.
Nueva prueba: tests/player_shoot_test.gd y su UID. Documentación actualizada.
Los .import de las previsualizaciones se actualizaron al nombre real PREVIEW_*.
No se cambiaron Weapon, Player, hitscan, física, cámara, salud, IA, HUD ni Idle/Walk.

Resultados finales: **307 comprobaciones aprobadas, 0 fallos**: regresión (278)
y Shoot (29). Importación final sin errores ni advertencias de Godot.
Ejecución real OpenGL: 34 comprobaciones aprobadas, incluyendo cinco PNG.
Se revisaron las capturas down/up/left/right y moving de test-results/shoot/.
Se verificó inicio por tiro real, avance, fin a 0.3 s, rechazo de segundo tiro
en cooldown, una señal de efecto por tiro, movimiento perpendicular al apuntado,
vuelta a caminar/reposo y prioridades de recarga/muerte.

Los primeros intentos de pruebas necesitaron ajustar el muestreo de frames y
colocar el cursor real en modo gráfico, donde Godot consulta Windows. La importación
inicial avisó de PREVIEW/preview en metadatos antiguos; tras reimportar los nombres
reales no se repitió el aviso. Los resultados finales son los indicados arriba.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/player_shoot_test.gd
godot --path . --fixed-fps 60 --script res://tests/player_shoot_test.gd -- --capture
```

Pendiente: valoración artística del retroceso y continuidad a velocidad real,
sesión manual de combate y panel gráfico del depurador. Sin commits automáticos.
