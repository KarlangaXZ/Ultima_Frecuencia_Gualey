# Fase 10 — zonas conectadas y Mercado abandonado

**Actualización Fase 11:** [variantes, distribución, XP y persistencia](zombie_archetypes.md).
Los valores de enemigo común y resultados históricos de este informe se conservan;
las variantes actuales se configuran mediante ZombieArchetype.

Godot 4.7.2 Stable oficial, Windows, GDScript, Compatibility. Validación:
14 de noviembre de 2026. No se cambian resolución, armas, RPG, IA ni misiones.

## Viajar

1. Completar las tres misiones de **La señal perdida** en la zona evacuada.
2. Buscar la salida de la calle este, junto a **2120,800**.
3. Acercarse a 56 px, sin un sólido World entre el personaje y el indicador.
4. Pulsar **E**: fundido breve, nombre del mercado, entrada en **320,800**.
5. Para volver, usar E en el indicador oeste del mercado, en **240,800**.
   La entrada de regreso a la zona evacuada está en **2020,800**.

No se viaja por tocar el área. La salida inicial permanece bloqueada hasta
completar el capítulo. El regreso queda disponible tras desbloquear el mercado.
El nombre de zona aparece unos dos segundos y se desvanece. HUD conserva su
tamaño; MOCHILA, PERSONAJE, MISIONES y PAUSA mantienen su presentación.

## Arquitectura

- **ZoneDefinition**: Resource con ID, nombre, escena confiable, misión de
  desbloqueo, dimensiones, entradas, IDs de suministros, prefijo de enemigos,
  semillas y configuración de población. Recursos en resources/zones/.
- **ZoneCatalog**: registro de definiciones permitidas y comprobación geométrica
  de posiciones a partir de las colisiones rectangulares serializadas. No carga
  rutas aportadas por el jugador o por el JSON.
- **ZoneManager**: dueño del mapa activo, desbloqueos y datos de mapas inactivos.
  Instanciado en Main, sin autoload. Cambia World y los hijos de Zombies; conserva
  exactamente el mismo Player, componentes, arsenal, radio e interfaz/audio globales.
- **ZoneExit**: Area transitable consultada por PlayerInteraction existente.
  Reutiliza alcance, visibilidad World, E y señales de rechazo; no duplica entrada.
- **ZoneOverlay**: fundidos de 0.2 s por sentido y nombre breve de ubicación.
- **InterfaceCoordinator**: sigue siendo el único dueño de pausa/bloqueo. Añade
  un estado de transición que congela física, daño automático, necesidades y
  temporizadores. Esc, disparo, nuevas interacciones y guardado/carga se bloquean
  durante el fundido. Un segundo viaje simultáneo se rechaza.

Main.gd no se reestructura: Main.tscn añade únicamente los dos nodos de zonas.
ChapterController vuelve a enlazar puntos del mapa y tolera mapas sin radio o
generador, sin cambiar objetivos, textos ni recompensas de las tres misiones.
Nuevas zonas se registran con recursos y escenas; nuevos capítulos/versiones
deberán ampliar el catálogo y el esquema de forma explícita.

## Cambio de escenario y estado

Antes de descargar se captura WorldSaveState del mapa activo. Se desactiva su
región, se retiran World y los enemigos, y se liberan sus nodos/audio. Los
inactivos quedan como diccionarios, sin física, navegación, timers o reproductores.
Se instala la escena destino, se configura la población y se restaura su registro
si ya fue visitada; en primera visita se crean sus tres semillas y se completa
la población hasta seis en puntos seguros. El mundo vuelve al índice 0 de Main,
conservando suelo/props detrás de los personajes.

El mapa nuevo se sincroniza con navegación y cámara antes de terminar el fundido.
El llenado inicial usa delta cero, sin avanzar relojes. Las consultas físicas
normales se comprueban después de sincronizar el broadphase tras retirar pausa.
El registro de mapas inactivos nunca incluye el mapa actualmente activo.

Se conservan salud, hambre/sed, reloj de privación, nivel, XP, puntos, rangos,
pilas, armas, cargadores, reservas, equipada y cooldown. Una recarga iniciada se
pausa durante el viaje y continúa: aquí no se reconstruye el personaje. Cargar
desde disco conserva la normalización de Fase 9, que cancela esa recarga sin
transferir munición. Al terminar un viaje se exige soltar el disparo.

Los suministros, contenedores y premios cobrados, cadáveres, enemigos heridos,
posiciones, cursor y espera de población se guardan por zona. Bajas y tiempo de
partida continúan globalmente en Main. WorldSaveState.kills se deriva de los
cadáveres locales; no es otro contador de gameplay. Su campo survival_time se
mantiene como marca de captura compatible con v1; el reloj autorizado de v2 es
stats.survival_time y no se rebobina al volver a una zona.

## Los dos mapas

| Zona | ID | Escena | Población |
| --- | --- | --- | --- |
| Gualey — Zona evacuada | gualey_sector_04 | scenes/world/World.tscn, existente | 6 vivos / 18 totales |
| Mercado abandonado | market_abandoned | scenes/world/MarketWorld.tscn | 6 vivos / 18 totales |

Ambos conservan 2400 × 1600 y la cámara usa los límites de su definición; la
resolución sigue en 1280 × 720. La zona original conserva sus 28 sólidos, casas,
colmado, vehículos, radio, generador, suministros y apariciones. Solo añade una
salida transitable dentro de ChapterPoints, sin cambiar la malla o los sólidos.

Mercado compone **22 sólidos**: siete locales grandes, seis puestos, dos carros,
dos cajas/barreras bajas, dos barricadas, un contenedor y dos postes. Las formas
están serializadas mediante UrbanObstacle.tscn. El mismo world_navigation.gd
deriva sus huellas, sin geometría de navegación duplicada. Hay calle principal,
aceras, pasos entre puestos, desvío alrededor de una barricada, residuos y señales.
No hay interiores, tiendas, comercio ni otro capítulo narrativo.

Arte técnico provisional: UrbanObstacle, asfalto y escombros SVG ya existentes,
con colores y rótulos de locales ficticios. No se descargó arte ni se declara
definitivo. market_ground.gd solo dibuja superficies/decoración, no colisiones.

Cuatro recogibles: agua ×2, botiquín ×1, comida ×2 y balas de pistola ×24. Tres
contenedores finitos: médico (botiquín ×2, agua ×1), puesto (comida ×3, agua ×2)
y seguridad (balas de pistola ×24, cartuchos ×8). Reutilizan ItemDefinition,
InventoryComponent, LootContainer y WorldPickup. No añaden armas nuevas.

## Población y recompensas

El mismo ZombiePopulation se configura por ZoneDefinition: máximo seis vivos,
presupuesto 18 incluyendo semillas, una reposición por diez segundos con vacantes.
Reutiliza todas las comprobaciones de distancia, campo visual, World y ruta.
Los candidatos que no cumplen se descartan; nunca se fuerza una aparición inválida.

Los ID del mercado son market_zombie_01…18; contenedores y recogibles también
tienen IDs propios. Cada zona conserva sus registros de ProgressionRewards, que
se restauran al volver. No hay recompensas por viajar o cargar ni respawn infinito.
Los nuevos actores usan la misma escena, salud 50, velocidad 105, detección 250,
daño 10 y cooldown 1.5 s, con sus animaciones y audio existentes.

Se mantiene 30 XP por baja y 20 por primer contenedor con contenido. El mercado
añade hasta **600 XP** (18×30 + 3×20), sin nuevas misiones. Con los 790 de la zona
original/capítulo, el contenido completo ofrece **1.390 XP**: nivel 7, 40/400 XP
y seis puntos de habilidad. Los valores no se reequilibraron; este es un máximo
finito que exige esperar reposiciones y eliminar toda la población de ambos mapas.

## Guardado v2 y compatibilidad

Se amplía la infraestructura de Fase 9, sin otro formato o sistema de archivos:
misma ubicación user://saves/, tres ranuras, confirmación, temporal y respaldo.

- version pasa a **2**; map identifica el mapa activo.
- world contiene únicamente el estado del mapa activo, con su estructura anterior.
- zones contiene únicamente registros de mapas visitados **inactivos**, por ID.
- stats contiene bajas y tiempo globales. La suma de bajas locales debe coincidir.
- missions conserva objetivos/premios/radio e incorpora desbloqueos por ID.
- player conserva la estructura de Fase 9, incluida su posición en el mapa activo.

SaveSchema valida cada mundo contra su definición permitida, los IDs y prefijos,
los presupuestos, desbloqueos, duplicados y estadísticas globales. La validación
geométrica usa el mapa correspondiente, incluso si es distinto del que está en
pantalla. No se usa la geometría de la zona actual para validar otra.

SaveMigration valida v1, lo copia en memoria a v2, coloca su reloj/bajas en stats
y deja zones vacío. Si broadcast ya estaba completada, deduce el desbloqueo del
mercado **sin emitir logros ni XP**. Leer no reescribe el archivo original; guardar
después escribe v2 y mantiene el anterior como respaldo. No se admiten versiones
desconocidas. Las ranuras muestran también el nombre del mapa.

La carga mantiene la escena candidata de Fase 9 y prepara en ella el mapa correcto
antes de aplicar los adaptadores. Los viajes, en cambio, no reconstruyen ni
duplican el Player. Reintentar empieza de nuevo en la zona evacuada, con el
mercado bloqueado y ambos estados limpios; no borra archivos de partidas.

## Validación ejecutada

- Suite anterior antes de cambios: **1.369 comprobaciones**, todas aprobadas.
- Regresión final: conserva esas 1.369 y añade **70 de zonas**, **59 de navegación
  del mercado** y **2 + 12 de cierre/reapertura**: **1.512 headless**, cero fallos.
- Prueba gráfica de mercado: **65 comprobaciones**, seis capturas reales de
  fundido, entrada, persecución, ruta, tres perseguidores y plano técnico.
- Ida/regreso y cargas en ventana: **70**; ranuras **114**; regresiones gráficas
  generales **39** y HUD/audio **99**. Todas aprobadas.
- Escritor del mercado PID **18632** terminó antes de que el lector PID **2548**
  recuperara la partida, verificase ambas zonas y regresara a la original.
- Importación y arranque normal de Godot sin nuevos errores/advertencias.

Las pruebas de zonas usan posiciones preparadas y la fixture rica de Fase 9 para
obtener armas/rangos y terminar el capítulo con su radio. Los eventos y E se
simulan; no son una partida manual. La preparación inmoviliza actores, pero se
reactivan antes de viajar. market_navigation_test mantiene IA activa durante
toda la visita: mide desplazamiento y distancia, Walk, ataque/cooldown/audio,
colisión del jugador contra un puesto, desvío alrededor de barricada, disparos
reales y tres perseguidores simultáneos. No presenta enemigos congelados como
evidencia de movimiento.

Se comprueba que Player/audio conservan identidad, que World/enemigos anteriores
se liberan, que no crecen conexiones tras viajes repetidos, y que no se pueden
guardar/cargar, disparar ni interrumpir el fundido con Esc. Las comparaciones
entre procesos usan representación JSON equivalente, sin confundir números
Variant enteros con números decodificados. Cada campo persistente se compara.

Muestra sin capturas, 120 frames, Radeon RX 580: **14.32 ms** TIME_PROCESS medio,
máximo **117 llamadas de dibujo** y **426 nodos**. En esa fase hay seis instancias
de enemigo, una eliminada y tres persiguiendo. No crecen actores en la muestra.
Con capturas de GPU la muestra ronda 36 ms; no se confunden ambos resultados.
No es benchmark de exportación, tiempo exclusivo de CPU ni garantía de 60 FPS.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/zones_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/market_navigation_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/zones_restart_test.gd -- --write
godot --headless --path . --fixed-fps 60 --script res://tests/zones_restart_test.gd -- --read
godot --path . --fixed-fps 60 --script res://tests/market_navigation_test.gd -- --capture
```

## Problemas corregidos y pendientes

La revisión visual detectó World añadido después de los personajes: su suelo
los tapaba. Se restauró World al índice 0 y se repitieron las capturas: jugador
y zombis visibles. Se añadió una aserción de orden de dibujo. También se corrigió
una dependencia circular al intentar consultar el catálogo desde ZoneExit durante
la carga del propio catálogo; el gestor proporciona ahora el nombre en ejecución.
Se corrigieron anotaciones de tipo y la comparación numérica de la fixture IPC.
Las consultas geométricas del test esperan sincronización física tras la pausa.
Las pasadas finales no conservan esos fallos.

Pendiente manual: recorrido completo de ambas zonas a velocidad humana, balance
de suministros/enemigos, lectura a otras resoluciones, mezcla en altavoces, panel
gráfico del depurador y exportación Windows. Arte provisional, sin interiores ni
segundo capítulo. Las pruebas usan user://tests/phase-ten-*, sin tocar partidas
normales. No se crearon commits ni se publicó ningún cambio.

## Archivos

Nuevos: scripts/zones/{zone_definition,zone_catalog,zone_exit,zone_manager}.gd,
scripts/ui/zone_overlay.gd, scripts/world/market_ground.gd y sus .uid;
resources/zones/{Evacuated,Market}.tres; scenes/world/MarketWorld.tscn;
scripts/save/save_migration.gd y .uid; tres pruebas nuevas y sus .uid; este informe;
capturas de mercado, plano y fundido con metadatos .import.

Modificados: Main.tscn (composición), ChapterPoints.tscn (salida transitable),
zombie_population.gd (configuración/IDs por mapa y conexión única),
chapter_controller.gd (reenlace de puntos), player_interaction.gd (tipo de salida),
interface_coordinator.gd/pause_ui.gd (bloqueo durante viaje/nombre del mapa),
world_save_state.gd, mission_save_state.gd, save_schema.gd, save_file_store.gd y
save_coordinator.gd (v2 y restauración por zona); README.md, AGENTS.md,
docs/save_load.md y docs/images/README.md. World.tscn, main.gd, misiones, IA,
armas, salud, RPG, sprites y configuración de resolución conservan su contenido.
