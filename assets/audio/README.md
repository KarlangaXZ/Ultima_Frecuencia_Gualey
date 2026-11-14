# Audio sustituible

El audio activo de fase 6.1 es **sintético y provisional**, original del proyecto.
Sus WAV fuente están separados en `assets/placeholders/audio/`. No son efectos
realistas ni música final, y no requieren licencias de terceros.

`resources/audio/TechnicalAudio.tres` es un AudioCatalog: el diccionario sounds
permite reasignar cada evento desde el inspector conservando sus identificadores.
Los efectos aceptan AudioStream de Godot. El ambiente se duplica por partida y
se configura en bucle (WAV/OGG/MP3); no se altera el recurso compartido.

| Eventos | Uso |
| --- | --- |
| inventory_open, inventory_close, ui_select | Mochila y selección de espacio |
| container_open | Abrir contenedor; sustituye el sonido de apertura de mochila |
| pickup_supply, pickup_ammo | Recogida/transferencia completada |
| item_use, invalid | Uso/incorporación completados o acción rechazada |
| pistol_shot, revolver_shot, shotgun_shot | Un sonido por disparo real |
| reload, dry_fire | Inicio válido de recarga y clic vacío limitado |
| machete_swing, machete_hit | Ataque válido e impacto confirmado |
| zombie_groan, zombie_attack, zombie_hurt, zombie_death | Observación por enemigo |
| ambience | Loop ambiental tenue de ocho segundos |

Fuente: PCM mono, 22050 Hz, 16 bits. Efectos de 0.045–0.7 segundos, pico máximo
0.45; ambiente de 8 segundos, pico 0.12. Ganancias iniciales adicionales: UI
−18 dB, combate −12 dB, zombis −18 dB con atenuación espacial, ambiente −30 dB.
GameAudio expone ganancias y métodos set_ambience_paused/set_ambience_volume;
SoundEmitter permite mute y set_volume. No se agregaron controles ni buses globales.

`tools/generate_placeholder_audio.py` los reproduce con Python estándar y semilla
determinista; solo escribe placeholders/audio/. Python no es necesario para jugar.
Los WAV y sus `.import` son recursos fuente; las cachés `.godot/` y mezclas de
prueba `test-results/` permanecen ignoradas. Revisar percepción de volumen y timbre
antes de sustituirlos por audio final. [Validación](../../docs/hud_audio_polish.md).
