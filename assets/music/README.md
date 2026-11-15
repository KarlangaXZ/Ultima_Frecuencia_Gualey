# Música instrumental provisional — fase 15.1

Dos composiciones originales generadas localmente para Última Frecuencia: Gualey.
No contienen voces, muestras descargadas ni melodías tomadas de otras obras.
Son **música técnica provisional**, no una banda sonora final aprobada.

| Archivo | Uso | Estructura | Duración |
| --- | --- | --- | --- |
| menu_last_frequency.wav | Menú | 72 BPM, ocho compases; acordes menores, motivo de campanas, pad y bajo | 26,667 s |
| gameplay_streets.wav | Cuatro zonas | 60 BPM, doce compases; seis armonías, pads, notas espaciadas y pulso grave | 48 s |

Fuente reproducible: `tools/generate_provisional_music.py` (Python + NumPy, solo
herramienta de autoría; Godot no depende de Python). Síntesis aditiva con envolventes,
panorámica y retardos circulares: las colas del final continúan al inicio del bucle.
No se añaden sonidos al catálogo de efectos TechnicalAudio.

Origen: generación local durante esta fase, sin bibliotecas musicales externas.
Licencia de ambos WAV y su generador: **CC0-1.0**, ver `LICENSE.txt`.
`MANIFEST.json` conserva SHA-256, duración, formato y métricas de las fuentes.

WAV PCM estéreo de 16 bits, 22.050 Hz, pico −6,02 dBFS; 6.585.688 bytes en total
(6,28 MiB). Se usa WAV porque no había un codificador Vorbis disponible y no se
instalaron dependencias. Los `.import` fijan PCM sin compresión; no cambiarla sin
revisar límites y continuidad. Una futura entrega puede sustituirlos por OGG
revisados: MusicDirector admite AudioStreamOggVorbis y configura su bucle sobre
una copia del recurso. No se modifican los streams compartidos.

Niveles iniciales: −14 dB en menú y −20 dB en gameplay, además de Music/Master.
Pausa añade −6 dB; radio −12 dB. La valoración musical y auditiva humana sigue
pendiente; una señal no nula no equivale a aprobar la composición.
