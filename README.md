# Última Frecuencia: Gualey — Fase 4.1

Shoot corregido integrado en cuatro direcciones: [validación final](docs/shoot_final_integration.md).
16 hashes correctos, sin destellos incrustados; 307 comprobaciones aprobadas.
Los avisos históricos sobre Shoot rechazado quedan superados por este paquete.

Fase 4.3: [Reload y Death integrados en cuatro direcciones](docs/phase_4_3_actions.md).
64 hashes verificados; 48 PNG técnicos provisionales aceptados. Shoot permanece
pendiente por destello incrustado y orientación/poses incorrectas; se conserva
el disparo anterior. 278 comprobaciones aprobadas, sin cambios de gameplay.

Actualización walk_left V2: [integración completada y validación](docs/walk_left_v2_validation.md).
Idle y walk tienen arte en las cuatro direcciones; V2 pasó 230 comprobaciones.
Los avisos anteriores sobre walk_left pendiente son históricos y quedan superados
por esta revisión. Walk_right conserva sus imágenes originales en legacy_right/.

Revisión final de walk_left (12/11/2026): [defectos pendientes por fotograma](docs/walk_left_final_validation.md).
Los PNG presentes aún conservan fondo gris/halos; no se activó la secuencia final.

Estado actual de direcciones: [informe de integración](docs/player_directions_integration.md).
Idle real en cuatro direcciones y walk real en down/up/right; walk_left sigue
provisional hasta recibir PNG sin restos de fondo. Asignaciones corregidas con
autorización del usuario; gameplay conservado.

Auditoría de recursos del protagonista: [informe técnico](docs/player_animation_audit.md).
4 fotogramas finales aprovechables de 112 objetivo; 108 pendientes.
Las referencias de `draft/` no se integraron. El juego conserva idle_down activo.

Prototipo 2D top-down para Godot **4.7.2 Stable**, GDScript y Windows.

Nombre oficial visible: **Última Frecuencia: Gualey**. El historial de fases
inferior describe la evolución del mismo proyecto; las rutas gráficas de fase 4
se reorganizaron en fase 4.1 (ver el apartado final y `assets/README.md`).

## Ejecutar

Importar `project.godot` en Godot y pulsar **F5**.
Moverse con **WASD**; las combinaciones permiten movimiento diagonal.
El jugador verde se detiene ante las cajas marrones y el perímetro.
La cámara lo sigue dentro del escenario de 2400 × 1600.
Ventana base: 1280 × 720, redimensionable mediante canvas_items.

También se puede ejecutar `godot --path .` si Godot está en PATH.
El motor portable utilizado para validar está en `.tools/godot/`, excluido de Git.
No se ha exportado un ejecutable independiente; se ejecuta con Godot.

## Archivos

- `project.godot`: configuración, acciones WASD, capas y escena inicial.
- `scenes/Main.tscn`: composición principal.
- `scenes/player/Player.tscn`: jugador y cámara.
- `scenes/world/World.tscn`, `Obstacle.tscn`: suelo, cajas y límites.
- `scripts/player/player.gd`: movimiento físico normalizado.
- `scripts/world/ground.gd`: dibujo del suelo.
- `interfaces/HUD.tscn`: instrucciones en pantalla.
- `resources/README.md`: espacio para recursos futuros.
- `tests/phase_one_test.gd`: integración física automatizada.
- `AGENTS.md`: arquitectura y reglas para cambios futuros.
- `.gitignore`: exclusión de cachés, herramientas, binarios y resultados.
- Los `.gd.uid` generados por Godot se conservan como metadatos de identidad.

## Validación realizada — 11 de noviembre de 2026

Motor: `4.7.2.stable.official.ed1daf0bf`.

1. Importación con `--headless --path . --editor --import`: correcta.
2. `--headless --path . --script res://tests/phase_one_test.gd`:
   **21 comprobaciones aprobadas, 0 fallos**. Comprueba ocho direcciones,
   velocidad normalizada, detención, colisión con caja y borde, cámara activa
   y centro de cámara siguiendo al jugador. Inyecta acciones de entrada;
   no sustituye una prueba manual de teclado físico.
3. Escena principal con renderizado OpenGL Compatibility y `--quit-after 180`:
   ejecutada, código de salida 0, sin errores ni advertencias en la salida.
   No se realizó inspección visual ni prueba manual de WASD.
4. Git ya existía; se conservó. `.godot/` y `.tools/` se verificaron como ignorados.

La primera importación restringida emitió errores por no poder escribir la
configuración global de Godot en AppData. Se repitió con permisos y terminó
sin errores. No se observaron errores de scripts o ejecución en las pruebas
finales; no se inspeccionó el panel gráfico del depurador.

La fase 1 no incluía combate, inventario, enemigos ni IA.

## Fase 2: zombis y salud

- Tres zombis rojos independientes, alejados del punto inicial y fuera de cajas.
- Estados IDLE, CHASE, ATTACK y DEAD. Detección de 250 px, alcance de ataque
  de 35 px, daño de 10 HP y un intervalo de 1.5 s por zombi. Velocidad de 105 px/s.
  Todos estos valores y sus 50 HP máximos se configuran en el inspector del zombi.
- Navegación mediante NavigationAgent2D y una malla calculada desde las cajas
  existentes al iniciar. Margen de navegación de 20 px para radio físico de 16 px.
  No hay daño a través de obstáculos. Fuera del radio de detección vuelven a IDLE.
- HealthComponent reutilizado por jugador (100 HP) y zombis (50 HP), con señales
  de cambio y muerte. La cadencia corresponde a cada atacante: varios zombis
  pueden atacar con sus propios intervalos, sin invulnerabilidad global.
- HUD original ampliado con barra y valor numérico; al morir aparece HAS MUERTO
  y REINTENTAR. El jugador deja de moverse y los enemigos dejan de interactuar
  con él. Reintentar recarga Main y restablece todos los personajes.
- WASD, cámara, resolución y colisiones de la fase 1 se conservan.
- Los personajes colisionan con World; no se bloquean físicamente entre sí.
- Sin armas, ataques del jugador, munición, inventario ni plugins externos.

### Archivos nuevos en fase 2

- `scripts/components/health_component.gd`: salud reutilizable.
- `scenes/enemies/Zombie.tscn`, `scripts/enemies/zombie.gd`: enemigo e IA.
- `scripts/world/world_navigation.gd`: malla derivada de las colisiones de cajas.
- `scripts/main.gd`: coordinación y reinicio.
- `scripts/ui/hud.gd`: presentación y señal del botón.
- `tests/phase_two_test.gd`: pruebas de integración.
- Metadatos `.gd.uid` correspondientes, generados por Godot.

### Archivos modificados en fase 2

`project.godot`, `scenes/Main.tscn`, `scenes/player/Player.tscn`,
`scripts/player/player.gd`, `scenes/world/World.tscn`, `interfaces/HUD.tscn`,
`AGENTS.md` y este `README.md`. No se realizaron commits.

### Probar la fase 2

1. Abrir `project.godot` en Godot 4.7.2 y pulsar F5.
2. Desde (600, 800), rodear la primera caja por arriba o abajo para acercarse
   al zombi situado en (1000, 800). Se activa al estar a 250 px.
3. Detenerse junto al zombi: resta 10 HP cada 1.5 s. Comprobar barra y número.
4. Tras perder 100 HP, comprobar HAS MUERTO, bloqueo de WASD y enemigos quietos.
5. Pulsar REINTENTAR: salud 100/100, tres zombis y posiciones iniciales.

Pruebas automatizadas (sustituir `godot` por la ruta del ejecutable si no está en PATH):

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/phase_one_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/phase_two_test.gd
godot --path . --quit-after 180
```

### Resultados de fase 2 — 11 de noviembre de 2026

- Importación en 4.7.2 correcta tras permitir escritura de configuración en AppData.
- Regresión fase 1: **21 comprobaciones, 0 fallos**.
- Integración fase 2: **42 comprobaciones, 0 fallos**: aparición válida, IDLE,
  detección, persecución, retorno a IDLE, ruta alrededor de caja sin atravesarla,
  daño y cadencia, reentrada en alcance sin eludir cooldown, bloqueo de ataque
  a través de caja, señales, HUD, muerte por diez ataques, inmovilidad, enemigos
  sin objetivo muerto, DEAD con objetivo vivo, reinicio mediante señal real
  del botón y restauración de todos los personajes.
- Arranque con renderizado OpenGL Compatibility comprobado en Radeon RX 580.
- Inspección visual realizada del escenario, jugador, zombi y HUD inicial 100/100.
- Pendiente: recorrido manual con WASD, observación visual de daño y Game Over,
  clic real en Reintentar e inspección del panel gráfico del depurador.
  Las comprobaciones automáticas inyectan acciones y la señal pressed del botón.
- No se observaron errores de scripts, física o navegación en las pruebas finales.
  La ejecución restringida inicial volvió a mostrar errores de configuración de
  AppData; la importación con permisos terminó limpia. Un intento de guardar
  un log en una carpeta inexistente falló; se repitió el arranque sin ese argumento.

La navegación actual deriva rectángulos de las cajas estáticas existentes;
si se añaden otros tipos de geometría o cambia el perímetro, hay que adaptar
`world_navigation.gd`. No se han añadido recursos externos ni cachés a Git.

## Fase 3: pistola, combate y estadísticas

Controles: **WASD** para moverse, **mouse** para apuntar, **clic izquierdo**
para disparar y **R** para recargar. Mantener el clic repite disparos a la
cadencia configurada. Movimiento y apuntado son independientes.

La Pistola básica comienza con **12 balas y 48 de reserva**, daño **25 HP**,
cadencia **0.3 s**, recarga **1.5 s** y alcance **600 px**. Se configura desde
`resources/weapons/BasicPistol.tres` en el inspector. La configuración se comparte;
la munición y temporizadores pertenecen a cada instancia del arma.

Cada disparo consume una bala, consulta un único rayo y se detiene en el primer
obstáculo o zombi. Un trazo amarillo muestra la dirección y recorrido; el punto
final naranja indica impacto y el amarillo indica fin del alcance. Se origina
en el centro del jugador para impedir que el cañón atraviese cajas al disparar.

No se dispara durante recarga, sin munición o tras morir. R no hace nada si el
cargador está lleno, falta reserva o ya se está recargando. Solo se transfieren
las balas necesarias: **4 / 48 → 12 / 40**. Al morir se cancela la recarga sin
transferencia, se bloquea el arma y se detiene el reloj de supervivencia.

Dos impactos eliminan un zombi de 50 HP. Se reutiliza HealthComponent; DEAD
detiene su IA, emite una sola eliminación y desactiva sus colisiones de forma
diferida. Su representación se oscurece y desvanece hasta quedar como cadáver
inerte, sin bloquear al jugador ni disparos posteriores. No se crean enemigos
nuevos: la partida conserva los tres originales.

El HUD existente conserva salud e instrucciones y añade munición, RECARGANDO...,
bajas y tiempo en minutos:segundos. Reintentar restablece arma, cargador, reserva,
salud, zombis, posiciones, bajas y reloj. No hay inventario, armas adicionales,
oleadas, plugins ni recursos gráficos externos.

### Archivos creados en fase 3

- `scripts/weapons/weapon_config.gd`: recurso de configuración reutilizable.
- `resources/weapons/BasicPistol.tres`: parámetros de la pistola.
- `scripts/weapons/weapon.gd`: munición, cadencia, recarga y señales.
- `scripts/combat/hitscan_combat.gd`: impactos, daño y efecto de disparo.
- `tests/phase_three_test.gd`: integración del combate.
- Archivos `.gd.uid` correspondientes generados por Godot.

### Archivos modificados en fase 3

- `scripts/player/player.gd`: entrada de combate, apuntado y bloqueo por muerte.
- `scenes/player/Player.tscn`: Weapon, Combat e indicador provisional del cañón.
- `scripts/enemies/zombie.gd`: señal de baja, desactivación y efecto de muerte.
- `scripts/main.gd`: señales del arma, bajas y tiempo de supervivencia.
- `scripts/ui/hud.gd`, `interfaces/HUD.tscn`: controles, munición y estadísticas.
- `project.godot`: acciones shoot y reload; resolución y cámara conservadas.
- `AGENTS.md`, `README.md`: arquitectura y documentación ampliadas.

### Prueba automática de fase 3

```text
godot --headless --path . --fixed-fps 60 --script res://tests/phase_three_test.gd
```

Ejecutar también las dos pruebas anteriores y la importación indicadas arriba.
La prueba de fase 3 usa rayos físicos reales, entradas simuladas para WASD,
disparo y recarga, y un evento de mouse transformado a coordenadas de pantalla.
El reinicio se activa mediante la señal pressed del botón real.

### Recorrido manual recomendado

1. Abrir `project.godot`, F5; verificar salud 100/100, munición 12/48 y cero bajas.
2. Apuntar al primer zombi desde el punto inicial: la caja bloquea las balas.
3. Rodear la caja y acertar dos disparos: debe sumar una baja y detener al zombi.
4. Disparar en movimiento; gastar munición y pulsar R para comprobar el aviso
   de recarga y la transferencia correcta. Vaciar el cargador para comprobar bloqueo.
5. Eliminar los tres zombis y comprobar bajas y tiempo. Para comprobar muerte,
   reiniciar con F5 y dejar que un zombi ataque sin eliminarlo.
6. Morir durante una recarga: no debe transferir balas ni permitir más disparos.
7. Pulsar REINTENTAR y comprobar que todos los valores vuelven a los iniciales.

### Resultados de fase 3 — 11 de noviembre de 2026

- Importación final en Godot `4.7.2.stable.official.ed1daf0bf`: correcta.
- Fase 1: **21 comprobaciones aprobadas**; fase 2: **42 aprobadas**.
- Fase 3: **49 comprobaciones aprobadas, 0 fallos**. Total: **112**.
  Se comprobaron daño único, bloqueo por caja, alcance, cadencia, disparo en
  movimiento, dirección de mouse, cargador vacío, recarga y reserva insuficiente,
  cancelación por muerte, eliminación de los tres zombis, cadáveres sin colisión,
  HUD, reloj detenido al morir y restauración completa con Reintentar.
- Arranque final real con `--path . --quit-after 180`: salida 0, OpenGL
  Compatibility sobre Radeon RX 580, sin errores ni advertencias en la salida.
- Inspección visual: HUD de fase 3 legible con salud, munición, bajas, reloj,
  controles, escenario y representación del arma. La herramienta de control
  detectó actividad del usuario durante la comprobación de entrada; no se da
  por aprobada la prueba de clic/R mediante esa sesión.
- Pendiente: recorrido manual completo de combate, revisión visual del trazo,
  impactos, recarga y muerte, clic real en Reintentar y panel gráfico del depurador.
  La presencia y actualización de esos estados sí se comprobaron automáticamente.
- Los primeros intentos de la prueba nueva detectaron una ubicación de alcance
  que cruzaba otra caja y coordenadas de mouse simuladas sin conversión a pantalla
  ni vaciado de eventos. Se corrigió el montaje de prueba; no fue necesario cambiar
  el apuntado del juego para resolverlos. La ejecución final no registra fallos.
- Pruebas anteriores conservadas sin modificaciones. No se realizaron commits.

## Fase 4: integración visual

La presentación ahora representa un depósito urbano evacuado: asfalto agrietado,
señalización desgastada, desagües, papeles y cajas de suministros. Los obstáculos
mantienen sus huellas, posiciones, escalas y colisiones originales. Los restos
del suelo son planos y transitables; no se introdujeron barreras invisibles.

Jugador y zombis usan AnimatedSprite2D con atlas SVG temporales de 12 fotogramas.
La capa visual reproduce idle, walk y death; el zombi también reproduce attack.
Existen nombres de animación para cuatro direcciones, reutilizando el atlas cenital
rotado. El jugador se orienta hacia Aim, independientemente del movimiento WASD.
La muerte no se repite y los cadáveres conservan su desactivación de fase 3.

Los disparos añaden destello, chispas contra obstáculos y partículas rojizas
moderadas contra zombis. Recibir daño produce un flash breve del personaje y,
para el jugador, un overlay tenue. Los efectos son opcionales y solo reaccionan
a eventos: no intervienen en impactos, daño, munición ni cadencias.

El mismo HUD recibe un tema oscuro de alto contraste, salud verde, munición más
grande, estadísticas e indicador ámbar de recarga. Las instrucciones pasan al
pie de pantalla. Game Over conserva la jerarquía de nodos y el botón funcional,
con panel central, título destacado y botón grande con foco de teclado.

### Recursos temporales e integración

Todos los recursos gráficos son **provisionales y originales**, identificados
como `temp_*`, organizados en `assets/characters/`, `environment/tilesets/`,
`environment/props/`, `environment/decals/`, `effects/`, `weapons/` y `ui/`.
No se añadieron dependencias ni descargas. El contrato de sustitución, tamaños,
orden de frames y opciones de efectos se explica en `assets/README.md`.
`tools/generate_placeholder_art.py` permite regenerar los SVG; no es necesario
ejecutarlo ni instalar Python para jugar.

### Archivos creados en fase 4

- Ocho SVG `temp_*` y `assets/ui/SurvivalTheme.tres`, con sus `.svg.import`.
- `assets/README.md`: inventario y reglas para reemplazar el arte.
- `tools/generate_placeholder_art.py`: generador reproducible sin dependencias.
- `scripts/visuals/character_visual.gd`: reproducción de animaciones y flash de daño.
- `scripts/visuals/combat_effects.gd`: destello y partículas opcionales.
- `tests/phase_four_test.gd`: pruebas de estados visuales y capturas.
- Metadatos `.gd.uid` correspondientes.

### Archivos modificados en fase 4

- `scenes/player/Player.tscn`, `scenes/enemies/Zombie.tscn`: sprites animados;
  sin cambios en cuerpos físicos ni cámara.
- `scenes/world/Obstacle.tscn`, `scripts/world/ground.gd`: arte del escenario.
- `scripts/enemies/zombie.gd`: retirada de referencias a Body/Eyes reemplazados;
  conserva IA, desactivación, señal de baja y duración del desvanecimiento.
- `scripts/combat/hitscan_combat.gd`: emite visual_shot con tipo de impacto;
  conserva el rayo, daño y señal anterior shot_resolved.
- `interfaces/HUD.tscn`, `scripts/ui/hud.gd`: tema, jerarquía visual y flash de daño.
- `AGENTS.md`: arquitectura de la nueva capa visual. `README.md`: documentación.

Player, Weapon, HealthComponent, Main, navegación, configuración de arma,
resolución y acciones de entrada no requirieron cambios de lógica en esta fase.
Las tres pruebas anteriores permanecen intactas. No se realizaron commits.

### Validación de fase 4 — 11 de noviembre de 2026

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/phase_four_test.gd
godot --path . --fixed-fps 60 --script res://tests/phase_four_test.gd -- --capture
```

- Importación de SVG, scripts y escenas correcta en Godot 4.7.2.
- Regresión: fase 1 **21**, fase 2 **42**, fase 3 **49**, todas aprobadas.
- Fase 4 sin renderizado: **34 comprobaciones aprobadas, 0 fallos**.
  Verifica estados/fotogramas, daño real y feedback, muerte y colisiones, efectos
  opcionales y limpieza, HUD y restauración de la presentación al reiniciar.
- Total de comprobaciones distintas: **146**, sin fallos.
- Prueba con renderizado OpenGL real: repite las 34 y comprueba cinco PNG;
  **39 comprobaciones aprobadas**. Capturas en `test-results/phase-four/`,
  excluidas de Git. No se suman las 34 repetidas al total anterior.
- Se inspeccionaron las cinco capturas: escenario/HUD inicial, impacto con
  destello y feedback de daño, cadáver, aviso RECARGANDO... y Game Over centrado.
  Sin errores ni advertencias de Godot en las ejecuciones de validación.
- Pendiente: recorrido manual completo con teclado/mouse, valoración del movimiento
  de las animaciones en tiempo real, clic físico en Reintentar y revisión del panel
  gráfico del depurador. Las pruebas usan entradas simuladas y la señal del botón.
- El alias Python de Windows no estaba disponible; el generador se ejecutó con
  el Python incluido en el entorno de trabajo. No afecta al funcionamiento del juego.

## Fase 4.1: nombre oficial y preparación para arte final

El título de proyecto/ventana y el HUD ahora muestran **Última Frecuencia: Gualey**.
El HUD divide el título en dos líneas para mantener la legibilidad en su panel.
Se actualizaron las cabeceras de documentación. No había pantalla introductoria
independiente ni nombre anterior en Game Over; conserva HAS MUERTO y REINTENTAR.

Los ocho SVG provisionales y sus metadatos se trasladaron a
`assets/placeholders/`, conservando la organización modular y actualizando
las referencias. El generador solo escribe en esta carpeta. Las carpetas
`assets/characters/`, `environment/`, `weapons/`, `effects/` y `ui/` quedan
preparadas para arte final, con instrucciones por módulo. El tema compartido
`assets/ui/SurvivalTheme.tres` conserva su ruta. **No se añadió arte final aún.**

El inspector permite sustituir texturas de personajes, suelo, restos, obstáculos,
pistola y destello. Visual admite además una biblioteca `animation_library`
de tipo SpriteFrames, manteniendo el sheet provisional como alternativa.
Contratos de animación, pivotes, tamaños y puntos de asignación:
**`assets/README.md`**. Cambiar arte no debe cambiar colisiones ni estadísticas.

No se renombraron Main, Player, Zombie, nodos, scripts, señales ni clases.
No queda un identificador propio de marca pendiente de migrar en el código.
El parámetro `deadzone` del InputMap pertenece a Godot y se conserva.
Los registros y capturas locales de fases anteriores pueden contener la marca
anterior; son resultados históricos ignorados por Git, no textos activos.

Archivos modificados: `project.godot`, `interfaces/HUD.tscn`, referencias de
`Player.tscn`, `Zombie.tscn`, `Obstacle.tscn`, `ground.gd`, `combat_effects.gd`,
`character_visual.gd`, generador, README, AGENTS y guía de recursos.
Archivos creados: guías de placeholders y de cada destino de arte final.
Recursos movidos: los ocho SVG temporales y sus `.import`.
No se modificaron lógica de combate, salud, IA, navegación, cámara ni resolución.
No se realizaron commits.

Validación de fase 4.1: importación correcta en Godot 4.7.2 y las **146
comprobaciones existentes aprobadas** (21 + 42 + 49 + 34). La ejecución con
renderizado repitió las 34 visuales y guardó cinco capturas: 39 comprobaciones
aprobadas. Se revisaron las capturas del HUD renombrado y Game Over: el nuevo
título cabe sin recortes y los controles conservan su presentación. No se
observaron errores de Godot. El recorrido manual y la revisión del panel gráfico
del depurador siguen pendientes. La biblioteca opcional para arte final queda
preparada, sin arte final incorporado ni validación artística de ese material.

## Fase 4.2: primera animación real del protagonista

Se integraron los PNG suministrados `player_idle_down_00.png` a `_03.png` en
`assets/characters/player/idle/`. Cada imagen es RGBA de 128 × 128 con alfa 0–255.
La silueta conserva la base en y=122; límites por frame (x0,y0,x1,y1):
(31,6,97,122), (32,7,96,122), (32,9,95,122), (32,6,96,122).
El pequeño cambio superior corresponde al reposo; no se recortaron ni editaron
las imágenes originales. El spritesheet suministrado se conserva como referencia.

`PlayerIdleDown.tres` utiliza los cuatro PNG en orden, bucle a **4 FPS**.
Player/Visual combina esta biblioteca parcial con sus animaciones anteriores:
solo sustituye idle_down, sin eliminar ni generar recursos gráficos provisionales.
La animación real se activa en reposo cuando Aim apunta hacia el sector inferior;
otras direcciones, marcha y muerte mantienen el atlas anterior.

El arte frontal permanece sin rotación, con escala visual 0.4 y offset (0,-56),
alineando los pies con el cuerpo físico. Durante ese idle se aproxima el dibujo
de la pistola a la mano; al salir se restauran escala, pivote y arma provisionales.
Aim, raycast, colisión, cámara, input, salud, IA y valores de combate no cambiaron.
La diferencia de estilo entre idle real y las animaciones pendientes es temporal.

Creado: recurso SpriteFrames, prueba `tests/player_idle_down_test.gd` y metadatos
de importación de los PNG. Modificados: Player.tscn, character_visual.gd y guías
README/AGENTS/recursos. No se generó arte nuevo ni se realizaron commits.

Validación: importación correcta en Godot 4.7.2; **146 comprobaciones anteriores
y 13 nuevas aprobadas** (159 distintas). La nueva prueba también se ejecutó con
renderizado OpenGL real y guardó captura en `test-results/idle-down/in-game.png`:
14 comprobaciones incluyendo guardado de imagen. Se inspeccionó la captura en
Main y la hoja suministrada. Las pruebas verifican avance de frames, orden de PNG,
4 FPS, pivote y retorno a los estados provisionales. No se detectaron errores.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/player_idle_down_test.gd
godot --path . --fixed-fps 60 --script res://tests/player_idle_down_test.gd -- --capture
```

Pendiente: valoración manual del ciclo en tiempo real y transiciones de estilo,
recorrido con mouse/teclado e inspección del panel gráfico del depurador.

## Fase 4.2: integración de walk_down

Integrados los ocho PNG existentes de `assets/characters/player/walk/`, orden
00–07, en la biblioteca `idle/PlayerIdleDown.tres`, conservando esa ruta para no
romper referencias. walk_down reproduce a **8 FPS en bucle**, idle_down conserva
sus cuatro frames y 4 FPS. No se sobrescribieron ni retocaron imágenes.

Verificación: ocho RGBA 128 × 128 con alfa 0–255 y hashes distintos. La silueta
ocupa x=36–91 aproximadamente, y=7–122 a 16–122 según pose: centro próximo a
x=64 y la misma base y=122 de idle. La escala visual 0.4 y offset (0,-56) actuales
permiten alternar sin cambiar tamaño del nodo físico. El ancho de walk es menor
por la pose de brazos. Se observa un halo claro en algunos bordes de segmentación;
su limpieza artística queda pendiente, sin editar los originales en esta fase.
La hoja fuente y el spritesheet se conservan como referencias y no se reproducen.

El controlador visual ahora usa la velocidad al caminar, de modo que S activa
walk_down aunque el mouse apunte a otro lado. Al detenerse conserva la dirección
de marcha y vuelve a idle_down; mover el mouse en reposo vuelve a orientar el
cuerpo según el apuntado. El apuntado real del arma permanece independiente.
Izquierda, derecha y arriba conservan el atlas provisional. No se modificaron
movimiento, velocidad, colisiones, cámara, salud, armas, IA ni HUD.

Modificados: PlayerIdleDown.tres, character_visual.gd y documentación. La prueba
existente de idle conserva su cobertura de fallback comprobando walk_right en
lugar de walk_down, que ya tiene arte real. Creada player_walk_down_test.gd y sus
metadatos; metadatos de importación de los PNG. Player.tscn no requirió cambios.

Validación: **178 comprobaciones aprobadas, 0 fallos**: fases 1–4 (146), idle (13)
y walk (19). Ejecución real con OpenGL: 22 comprobaciones, incluyendo tres capturas
en `test-results/walk-down/`, inspeccionadas para comparar reposo, caminata y
retorno a reposo. Sin errores de Godot en las pruebas. Sigue pendiente revisar
manualmente fluidez, último→primer frame, halo de bordes y panel del depurador.
No se generaron placeholders ni commits.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/player_walk_down_test.gd
godot --path . --fixed-fps 60 --script res://tests/player_walk_down_test.gd -- --capture
```
