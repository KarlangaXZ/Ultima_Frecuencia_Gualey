# Música de menú y exploración — fase 15.1

## Integración

`MusicDirector` es un autoload con **un AudioStreamPlayer** y dos streams en
caché. No crea mundos, consulta física ni produce eventos de gameplay. Las
composiciones, procedencia, licencia CC0-1.0, formato y hashes están en
[`assets/music/README.md`](../assets/music/README.md) y su MANIFEST.json.
Son provisionales; no se presentan como banda sonora final.

TitleMenu solicita menú. Una partida nueva solicita gameplay únicamente después
de guardarse correctamente; una carga lo solicita después del commit del candidato
validado. GameAudio activa gameplay al ejecutar Main directamente o reintentar,
pero no durante preparación/restauración. Los candidatos ocultos no se adueñan
de la mezcla. El propietario nuevo conserva la atenuación de sus ventanas visibles.

Cada cambio desvanece la voz actual durante 0,65 s, sustituye el stream y aplica
entrada de 0,65 s. No superpone pistas. Solicitudes del mismo contexto mantienen
la posición; una solicitud nueva cancela el fundido previo de forma segura.
La exploración atraviesa los cuatro mapas con el mismo player. Volver al inicio
libera el audio del mundo y solicita la música de presentación.

MusicDirector procesa durante pausa. InterfaceCoordinator comunica la visibilidad
real de PauseUI y RadioUI: pausa atenúa −6 dB; radio −12 dB, en 0,25 s. Cerrar o
finalizar recupera el nivel. Un fundido de viaje no pausa la música. La referencia
al propietario es débil; un mundo ajeno no modifica la mezcla. Al salir se detiene
la voz, se quitan sus streams y se cancelan los tweens.

## Buses y preferencias

AppPreferences añade **Music → Master** junto a Effects, Ambience e Interface.
El slider Música mantiene rango 0–100 %, respuesta inmediata y mute al llegar a
cero. Guardar y volver persiste en settings.cfg; Restablecer devuelve 100 %.
Un archivo anterior sin music usa 100 % sin reescribirlo al leer. Los JSON de
partidas no cambian. Efectos, ambiente y sus ganancias/pools se conservan.
La radio es textual con avisos existentes; no se añaden voces.

## Validación reproducible

```powershell
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/music_test.gd
godot --path . --fixed-fps 60 --script res://tests/music_test.gd -- --capture
godot --headless --path . --script res://tests/preferences_restart_test.gd -- --write
godot --headless --path . --script res://tests/preferences_restart_test.gd -- --read
python tools/validate_music.py --captures
```

La captura nativa usa el driver real. Headless/Dummy comprueba estados y no se
presenta como prueba de audibilidad. Logs y WAV quedan en
`test-results/phase-fifteen-one/`, ignorados por Git. Las pruebas solo escriben
en `user://tests/`, sin tocar ajustes personales ni ranuras normales.

Se prueban portada → nueva partida, carga transaccional, pausa/reanudación,
radio, seis viajes entre cuatro mapas, retorno mediante confirmación y continuar
una ranura. Se verifica una voz, identidad de streams y cuarenta solicitudes
rápidas de contexto. La fixture desbloquea zonas en memoria y aísla IA al viajar;
la regresión separada conserva pruebas de IA activa, daño, navegación y capítulos.

Las capturas cruzan el final de ambas pistas con reproducción real. Se validan
hashes, formato, duración, margen de señal y variación en el límite de las fuentes
(menor que sus variaciones internas). No sustituye escuchar varias vueltas.

**Medición:** AudioEffectRecord registra antes del fader de su propio bus.
Música se mide en muestras del Master; Master, en el máximo de su medidor de
salida durante toda la ventana. No se confunde el WAV pre-fader con la ganancia
final. Las mezclas capturadas tampoco representan una grabación del dispositivo.

## Resultados y pendientes

| Validación ejecutada | Resultado |
| --- | --- |
| Importación Godot 4.7.2 | Sin errores de scripts/importación |
| Regresión existente completa, 55 procesos incluyendo escritura/lectura | 2.793 comprobaciones, 0 fallos; incluye dos nuevas de preferencias |
| Música headless | 33 comprobaciones, 0 fallos |
| Música en ventana, driver real | 62 comprobaciones, 0 fallos |
| Recursos/hashes/ondas y diez capturas | 33 comprobaciones, 0 fallos |
| Inicio y configuración en ventana | 51 comprobaciones, 0 fallos |
| HUD/audio de armas y zombis en ventana | 99 comprobaciones, 0 fallos |

La primera ejecución de referencia encontró un fallo intermitente en el último
reemplazo de ranura del test de menú, antes de añadir música. La repetición
aislada aprobó 47/47 y la regresión completa posterior también aprobó; no se
modificó el flujo de creación de partidas para ocultarlo. Si reaparece, investigar
por separado la inicialización/guardado de la fixture y el mensaje de estado.

Señal medida: Música 50 % reduce aproximadamente 6 dB y al 0 % la captura es
silencio digital. Master 50 % reduce **6,02 dB** en su medidor de salida. Ambas
pistas cruzan su final y continúan reproduciéndose. La mezcla de música, ambiente,
armas y zombi capturada durante 2,432 s alcanzó **−18,60 dBFS de pico**, sin muestras
recortadas. Es una muestra de validación, no certificación de todas las mezclas.
La radio atenúa −12 dB y recupera nivel al cerrar/finalizar; las pruebas existentes
siguen verificando que disparos, recargas y ataques producen sus eventos correctos.

Archivos nuevos: MusicDirector y su UID; dos WAV con `.import`, MANIFEST, README
y licencia; generador y validador Python; music_test y UID; este informe.
Archivos modificados: project.godot (solo autoload), AppPreferences, TitleMenu,
GameAudio, InterfaceCoordinator, SaveCoordinator (solo activación musical), prueba
de preferencias, README/AGENTS, documentación de audio/menú e índice/captura de
Configuración. No se modificó ninguna escena, mapa ni archivo de balance.

Configuración revisada visualmente en 1280 × 720, sin desbordamiento. Captura
actual: `docs/images/title-settings.png`. Los volúmenes mostrados son fixtures.

Pendiente humano: escuchar vueltas completas, aprobar carácter musical y mezcla
en auriculares/altavoces, probar niveles cómodos y claridad con varios enemigos
en sesiones largas. Las mediciones no garantizan ausencia de clipping para todas
las combinaciones futuras. Sin cambios a mapas, paleta, misiones, IA, armas,
balance ni VSync; sin commits ni push.
