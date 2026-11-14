# Fase 6.1 — HUD compacto, textos y audio base

Godot 4.7.2 Stable, Windows, GDScript y Compatibility. Validación del
**13 de noviembre de 2026**. Sin plugins, commits ni publicación.

## HUD y textos

El panel persistente pasa de **330 × 365** a **256 × 172** en reposo: **63.4 %
menos área**, 22.4 % menos anchura y 52.9 % menos altura. Márgenes internos
10 × 8, separación 3, fondo translúcido y bordes discretos. La recarga solo
reserva su línea mientras está activa; la prueba limita el panel a 260 × 205
también durante ese estado. El tema compartido de mochila y Game Over no cambia.

Se mantienen salud/barra, hambre, sed, arma/icono, cargador/reserva, arsenal,
bajas, tiempo y aviso de recarga. Conservan rutas y contratos anteriores del HUD.
No se recoloca la cámara ni se cambia resolución. El título completo deja de
mostrarse en el HUD persistente (nodo Text oculto); solo queda SECTOR 04 pequeño.
La ventana conserva el nombre oficial Última Frecuencia: Gualey. La mochila se
titula **MOCHILA**. El texto Gualey pintado en el escenario conserva su función
de ubicación; no se alteran esas imágenes ni la identidad del README.

## Audio integrado

La inspección no encontró WAV, OGG ni MP3 previos. Se crean **19 efectos y un loop
ambiental**, sintéticos originales, sin descargas ni voces/grabaciones ajenas.
Son recursos de prueba, no audio final realista. Generador reproducible con Python
estándar: tools/generate_placeholder_audio.py. No añade dependencias al juego.
Los archivos y sustituciones están documentados en [assets/audio](../assets/audio/README.md).

| Evento real | Sonido | Protección contra duplicados |
| --- | --- | --- |
| Abrir/cerrar mochila | inventory_open / inventory_close | Cambio efectivo de visibilidad, observador idempotente |
| Seleccionar espacio | ui_select | Una selección, sin reproducir además cada actualización visual |
| Abrir contenedor | container_open | Sustituye inventory_open para esa apertura |
| Recoger/transferir suministros | pickup_supply / pickup_ammo | Solo almacenamiento completado; cantidad de la pila no multiplica audio |
| Usar/incorporar objeto | item_use | Solo efecto completado, sin clic adicional del mismo botón |
| Inventario lleno/acción inválida | invalid | Intervalo sonoro mínimo de 0.2 s |
| Pistola/revólver/escopeta | Efecto propio de cada arma | Señal de ataque válido, nunca un efecto por perdigón |
| Inicio de recarga | reload | Solo transición real a recargando; cancelación/finalización no lo repiten |
| Machete | machete_swing + machete_hit si hay impactos | Un movimiento y hasta un impacto por ataque, no por cada enemigo |
| Intento vacío válido | dry_fire | Máximo un clic cada 0.3 s; sin modificar cooldown del arma |
| Gemidos de zombis | zombie_groan | Inicio y períodos escalonados por enemigo |
| Ataque de zombi | zombie_attack | Renovación real del cooldown en ATTACK |
| Daño/muerte de zombi | zombie_hurt / zombie_death | Heridas separadas ≥0.12 s; letal emite solo muerte |

Los timbres técnicos son breves: 0.045–0.7 s; los sonidos de disparo tienen
transitorio filtrado y los gemidos son síntesis no verbal. El ambiente combina
tonos bajos/viento sintético en un loop periódico de **8 segundos**, a **−30 dB**.
No hay composición musical ni sistema de día/noche. Cada arma mantiene todos sus
valores de daño, cadencia, cargador y recarga; los sonidos nunca generan daño.

## Arquitectura y ajustes

- **AudioCatalog**, resources/audio/TechnicalAudio.tres: diccionario exportado
  con AudioStream por evento. Banco compartido; el loop ambiental usa una copia.
- **SoundEmitter**: pool fijo, mute, volumen e intervalos únicamente sonoros.
  No crea nodos por ataque. Cuatro voces UI, cuatro de combate, tres por zombi;
  18 reproductores contando el ambiente con los tres enemigos iniciales.
- **GameAudio**, Main/Audio: observa eventos de inventario/uso/interacción y
  Equipment. No es autoload ni conoce consultas físicas o lógica de salud.
  UI a −18 dB, combate a −12 dB; ganancias exportadas. Métodos de ambiente
  set_ambience_volume y set_ambience_paused para cambios en vivo.
- **ZombieAudio**, Zombie/Audio: reacciones y gemidos espaciales a −18 dB,
  distancia máxima sonora 800 px. Lee estado/cooldown y escucha salud; no modifica
  IA, detección, navegación, cooldown, ataque ni muerte. Se aplica también a
  nuevas instancias de la escena del zombi.
- Se añaden señales semánticas item_used/action_rejected, item_collected,
  selection_changed y empty_triggered. No se deduce el éxito leyendo textos
  traducibles ni se cambian retornos o cantidades. Los listeners son presentación.

La mochila continúa bloqueando entradas del jugador como antes. El audio de
combate del jugador verifica además controls_blocked y muerte. Una recarga ya
iniciada termina sin un sonido nuevo detrás de la UI. Los ataques reales de zombis
y el ambiente pueden seguir oyéndose porque el mundo no se pausa. Game Over no
permite nuevos ataques/disparos del jugador; Reintentar destruye la capa sonora
anterior y crea una sola nueva, sin loops acumulados.

## Validación

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/hud_audio_test.gd
godot --path . --fixed-fps 60 --script res://tests/hud_audio_test.gd -- --capture
```

Las catorce suites anteriores aprueban **665 comprobaciones**. La nueva suite
hud_audio_test.gd aprueba **94**: **759 comprobaciones headless**, cero fallos.
Incluye reducción de HUD, datos visibles, recarga compacta, título neutral,
20 streams válidos con duraciones acotadas, loop independiente/pausable, eventos
UI e interacción, uso real, armas, clic vacío limitado, una descarga sonora por
ocho rayos, machete con/sin impacto, daño y muerte de zombis, observación de ataque,
mute, cien eventos sin crecimiento de nodos, muerte y reinicio.

En **headless** se comprueban eventos y configuración, sin iniciar reproducción
en el driver Dummy. Esto evita referencias de playback retenidas al salir de
pruebas aceleradas. Se detectó esa incidencia durante desarrollo y se separó
explícitamente de la validación de mezcla real; no se simula escucha auditiva.

También se observaron avisos intermitentes al terminar pruebas gráficas justo
después de iniciar una voz. tests/audio_cleanup.gd silencia sus reproductores y
cede 80 ms reales al mezclador antes de quit. Las suites gráficas de fases 4/5/6
añaden únicamente esa limpieza final: no se cambian sus aserciones ni el juego.

Con renderizado y audio habilitados, la suite aprueba **99 comprobaciones**:
dos PNG y tres verificaciones de una grabación real del bus Master mediante
AudioEffectRecord. Se guarda en test-results/hud-audio/mix.wav (ignorado). La
muestra analizada tiene dos canales a 48000 Hz, señal no nula y **cero muestras
recortadas**; la muestra final de 7.051 s dio pico 0.183/RMS 0.0116.
Los 20 WAV fuente son mono, 22050 Hz, 16 bits; picos ≤0.45 (ambiente ≤0.12), sin
silencio accidental. Son verificaciones de señal, no aprobación subjetiva de audio.

Regresiones gráficas repetidas: fase 4, **39** comprobaciones/cinco capturas;
fase 5, **80**/cuatro; fase 6, **107**/seis. Las pruebas gráficas repiten parte
de las aserciones headless y no se suman como cobertura independiente.
Importación y arranque normal del proyecto correctos, sin errores ni advertencias
del motor en la pasada final. git diff --check correcto (solo avisos de CRLF).

Las capturas actuales se inspeccionan a 1280 × 720; README renueva sus imágenes
existentes, sin añadir duplicados. Las posiciones y acciones son fixtures reales
en Godot. Cache/resultados siguen ignorados; WAV y .import son recursos fuente.

## Pendientes manuales

Escucha con altavoces/auriculares para percepción de timbre, mezcla, volumen y
fatiga; ambiente durante sesiones largas; lectura en pantallas pequeñas/escalado;
combate/exploración prolongados, panel gráfico del depurador y exportación Windows.
No se declaran aprobadas esas comprobaciones. Los sonidos son deliberadamente
provisionales, especialmente disparos y gemidos; falta audio realista final.

## Archivos

Nuevos: scripts/audio/{audio_catalog,sound_emitter,game_audio,zombie_audio}.gd y
sus .uid; resources/audio/TechnicalAudio.tres; veinte WAV en
assets/placeholders/audio/ con sus .import; tools/generate_placeholder_audio.py;
assets/audio/README.md; tests/hud_audio_test.gd y .uid; este informe.
También tests/audio_cleanup.gd y su .uid para cierre limpio de pruebas nativas.

Modificados: interfaces/{HUD,InventoryUI}.tscn; scenes/Main.tscn y
scenes/enemies/Zombie.tscn (solo nodo de audio); scripts/ui/{hud,inventory_ui}.gd;
scripts/player/player_interaction.gd; scripts/inventory/item_use.gd;
scripts/weapons/weapon.gd y scripts/components/equipment_component.gd (señales);
README.md, AGENTS.md, assets/README.md, docs/images/README.md y ocho capturas
existentes (gameplay, combat, game-over, inventory, loot-container y arsenal-*).
Las tres pruebas phase_four/five/six_test.gd añaden solo el cierre de audio.
Sin cambios a project.godot, configuración de armas, IA, salud, supervivencia,
navegación, cámara, físicas ni bibliotecas de animación. Sin commits automáticos.
