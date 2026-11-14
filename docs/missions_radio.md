# Fase 8 — misiones, exploración y radio

Capítulo 1: **La señal perdida**. Godot 4.7.2 Stable, Windows, Compatibility.
El protagonista despierta en una zona evacuada, busca una radio junto al colmado
y recibe la petición de una estación desconocida. Recupera suministros, despeja
la zona, alimenta la instalación y envía su primera respuesta. La siguiente
señal queda pendiente de otro capítulo, sin cargar mapas ni terminar la partida.

## Misiones y recompensas

| Misión | Objetivos | XP |
| --- | --- | ---: |
| La señal perdida | E en la radio del colmado | 25 |
| Suministros para sobrevivir | Recuperar botiquín y agua del mundo; dos bajas | 50 |
| Volver al aire | E en el generador, después volver a la radio y transmitir | 75 |

Las definiciones están en resources/missions/. Se encadenan automáticamente en
ese orden; cada misión reserva su estado COMPLETADA antes de notificar. Los
premios se reservan antes de llamar ProgressionComponent.add_xp. Repetir señales,
interactuar de nuevo o reentrar desde un observador no vuelve a cobrar XP.
No se premian misiones incompletas ni eventos después de morir.

Se conservan los **30 XP por baja** y **20 por primer contenedor no vacío**.
Tres zombis y cinco contenedores suman 190 XP; el capítulo aporta otros 150:
**340 XP posibles, nivel 3 con 90/200 XP y dos puntos de habilidad**. Ninguna
fórmula, habilidad, suministro, arma o estadística de supervivencia cambia.
Los 150 XP y todos los objetivos se configuran en recursos.

## Fuentes de verdad

- Bajas: se observa Main.kills después de su conexión eliminated existente. No
  hay otro contador de muertes ni consultas a cadáveres que desaparecen.
- Recogidas: Player/Interaction añade supply_recovered(item, receipt) únicamente
  después del éxito de WorldPickup o de transfer_slot_to desde un contenedor.
  El inventario inicial, add_item directo, consumir, abrir, fallar por capacidad
  o transferir desde lejos no generan un recibo de recuperación válido.
- Los recibos identifican el pickup o el compartimento del contenedor por
  instancia. Estos orígenes son finitos y no se rellenan durante la partida.
  El registro se reserva antes de notificar. No sirve para persistencia futura.
- Los objetivos históricos conservan recogidas reales y bajas anteriores a
  activar la misión 2, evitando que el orden de exploración bloquee la historia.
  El inventario puede consumirse después: no se exige conservar esos objetos.
- Generador y transmisión son pasos no históricos y secuenciales: las
  interacciones adelantadas no se acreditan.

Los contenedores, inventario, interacción física, salud y progresión siguen
siendo los propietarios de sus datos. Los observadores de misión no aplican
daño, transfieren suministros ni fabrican bajas.

## Arquitectura reutilizable

- MissionObjective: clave de evento, descripción, cantidad y carácter histórico.
- MissionDefinition: ID, título, descripción, requisitos, objetivos, recompensa,
  secuencia y autoactivación. Los recursos son inmutables durante la partida.
- MissionTracker: estados LOCKED/AVAILABLE/ACTIVE/COMPLETED, totales observados,
  recibos, progreso acotado y señales changed/mission_completed. Admite objetivos
  configurables, activación explícita y cadenas mediante requisitos. Las
  definiciones deben tener IDs únicos y dependencias existentes sin ciclos.
- MissionRewards: concede únicamente misiones completadas de su biblioteca y
  protege contra duplicados/reentrada. No altera ProgressionRewards anterior.
- ChapterController: adapta los eventos de esta historia al tracker y selecciona
  las transmisiones. Un capítulo futuro puede usar otro adaptador con el mismo
  tracker, recompensas y vistas.
- RadioTransmission / RadioController: emisor, mensajes y avance textual. Las
  tres transmisiones se configuran en resources/radio/, sin audio de voces.
- ChapterWindow: base visual de las dos ventanas nuevas con SurvivalTheme.
  MissionUI representa progreso e historial; RadioUI presenta y avanza mensajes.
- ObjectiveHUD: panel independiente pequeño arriba a la derecha, una misión y
  su primer objetivo pendiente. El HUD principal conserva 256 × 172.

Main.tscn compone los sistemas por partida. Main solo conecta Chapter.bind al
final de su conexión de señales, para que la lectura de bajas vea el valor
actualizado. No hay autoload, plugins ni persistencia. snapshot del tracker
devuelve datos independientes; futuras partidas guardadas necesitarían IDs
estables para las interacciones y una política de restauración.

## Interacciones y presentación

ChapterPoints.tscn agrega dos Areas en World, fuera de Obstacles:

| Punto | Posición | Acceso sugerido |
| --- | --- | --- |
| Radio abandonada | 600, 650 | Acera sur del colmado, al norte del inicio |
| Generador de emergencia | 1720, 600 | Calle este; volver por la misma red de pasos |

Son transitables, capa 8, máscara 0. No cambian colisiones sólidas, navegación,
apariciones ni límites. PlayerInteraction conserva su consulta de 56 px y rayo
World. MissionPoint vuelve a validar el acceso al ejecutar, comprueba estado y
reserva la acción antes de emitir. Las siluetas geométricas de radio/generador
son técnicas provisionales, sustituibles sin cambiar sus áreas.

J abre/cierra **MISIONES**; K, Tab y J sustituyen la ventana anterior. E abre una
transmisión y avanza sus mensajes; el botón también permite avanzar. E al final,
Esc o CERRAR cierran la radio. Cerrar temprano o pasar a otra ventana permite
seguir jugando sin exigir leer toda la transmisión; no revoca el objetivo ya
confirmado. En esta fase no existe archivo ni reproducción del diálogo cerrado.

InterfaceCoordinator deriva el bloqueo de MOCHILA, PERSONAJE, MISIONES y RADIO:
solo una visible, sin desbloqueo transitorio. Se bloquean movimiento, aim,
ataque, nueva recarga, selección de arma y E exterior. El mundo, necesidades y
recargas ya iniciadas siguen. Al cerrar se exige soltar el disparo. Las ventanas
nuevas se cierran al morir y no se reabren con Game Over. ObjectiveHUD se oculta
con ventanas modales o muerte para evitar superposiciones.

La radio es modal únicamente durante sus mensajes breves, cerrables de inmediato;
no hay introducción modal al iniciar ni cinemática. GameAudio reutiliza ui_select
una vez por mensaje, y apertura/cierre existentes para el diario. No se añade
un segundo sonido de apertura a la radio, WAV nuevo, interferencia ficticia ni
doblaje. Las subidas de nivel conservan su sonido propio.

## Reinicio y límites

Reintentar reconstruye las misiones, recibos, recompensas y radio junto a todos
los estados anteriores. Vuelve a estar activa la misión 1, las demás bloqueadas,
sin recuperación registrada, XP cero e interfaces cerradas. Completar el capítulo
deja activos combate, inventario, habilidades y exploración; no activa Game Over.

No hay nuevo mapa, NPC, respawn, arma, guardado ni segundo capítulo. El arte y
aviso electrónico son provisionales. El cierre del texto no es una condición
adicional para cobrar: se premia la interacción válida, como pide la secuencia.

## Validación

Comandos específicos:

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/mission_tracker_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/phase_eight_test.gd
godot --path . --fixed-fps 60 --script res://tests/phase_eight_test.gd -- --capture
```

Validación del 14 de noviembre de 2026:

- Base antes de modificar: las 17 suites anteriores, **905 comprobaciones**, sin
  fallos. La misma suite se conserva íntegra después de la integración.
- MissionTracker: **27 comprobaciones**, cero fallos. Estados, activación explícita,
  claves configurables, históricos, requisitos, secuencia, reentrada, recibos,
  eventos repetidos, muerte y snapshot profundo independiente.
- Integración: **122 comprobaciones headless**, cero fallos. Total de las 19
  suites: **1.054 comprobaciones**, cero fallos.
- Recorrido gráfico: **126 comprobaciones**, cero fallos, cuatro capturas reales:
  objetivo inicial, primera transmisión, diario y cierre del capítulo.
- Regresiones gráficas general **39**, arsenal **107** y HUD/audio **99**:
  todas aprobadas, sin errores/advertencias del motor. Importación y arranque
  normal también correctos; el panel gráfico del depurador no se inspeccionó.

El recorrido principal mueve al jugador por **8.480 px** con Input.action_press,
Input.get_vector y move_and_slide existentes. La ruta procede de la malla real;
no teletransporta entre objetivos. Recoge agua/botiquín con E, dispara cuatro
balas mediante Weapon.try_fire a dos zombis antes de activar la misión 2,
inspecciona la radio, alimenta el generador y regresa a transmitir. Después
elimina al tercer zombi y abre los cinco contenedores para comprobar **340 XP**,
nivel 3 y dos puntos; aprende Vitalidad y continúa antes de probar muerte/reinicio.

Es una **sesión automatizada**, no una partida manual: los tres enemigos se
congelan en esta fixture para aislar navegación/objetivos, el apuntado y disparo
llaman la API existente con direcciones calculadas, y el botón Reintentar se
activa por su señal. Las regresiones anteriores conservan la IA y el combate
con enemigos activos. La comprobación negativa de pared coloca temporalmente
al jugador dentro del colmado, sin su proceso físico, exclusivamente para aislar
el rayo bloqueado; lo restaura antes de seguir el recorrido. La segunda fixture
usa posiciones preparadas para comprobar fallos de capacidad/alcance y transferencias.

J/Tab/K/E/Esc y el botón de avance son eventos de entrada de Godot. Se comprueba
la exclusión de las cuatro ventanas, bloqueo de movimiento/disparo/recarga,
exigencia de soltar el disparo, un sonido por mensaje, generador repetido,
interacciones prematuras o lejanas, pared, inventario directo ignorado,
recuperación desde contenedor, fallos/vacíos, XP posterior a muerte y reinicio.

Durante desarrollo se corrigieron **dos errores de la fixture**, no del gameplay:
un nombre antiguo del contenedor y la recuperación física que expulsaba al
jugador del sólido antes de probar el rayo. La ejecución fallida se detuvo por
su proceso identificado y se repitió correctamente. Se redujo el ancho mínimo
del texto de ObjectiveHUD para incluir los márgenes reales del tema y mantener
el panel dentro de pantalla. No quedan fallos en estas comprobaciones.

test-results/ permanece ignorado; solo las capturas seleccionadas para
documentación se copian a docs/images/.

Pendiente manual: sesión prolongada con IA activa, lectura a otras resoluciones,
revisión auditiva en altavoces, balance/ritmo narrativo, panel gráfico del
depurador y exportación Windows. Las pruebas automáticas no sustituyen estos
controles. Sin commits ni push.

## Archivos

Nuevos: scripts/missions/{mission_objective,mission_definition,mission_tracker,
mission_rewards,chapter_controller}.gd; scripts/radio/{radio_transmission,
radio_controller}.gd; scripts/ui/{chapter_window,mission_ui,radio_ui,objective_hud}.gd;
scripts/world/mission_point.gd; sus .uid; tres recursos resources/missions/ y tres
resources/radio/; scenes/world/ChapterPoints.tscn; dos pruebas y sus .uid; este
informe y capturas de diario/radio con sus metadatos .import.

Modificados: Main.tscn, World.tscn (solo instancia transitable), main.gd,
player_interaction.gd (eventos/rama para MissionPoint), interface_coordinator.gd,
game_audio.gd, project.godot (solo J), README.md, AGENTS.md y docs/images/README.md.
No cambian Player.tscn, player.gd, armas, salud, habilidades, necesidades,
inventario, IA, animaciones, recursos gráficos existentes ni geometría sólida.

## Actualización de fase 8.1

La población actual es de hasta seis vivos y 18 apariciones totales. Se validó
movilidad con IA activa sin editar zombie.gd ni sus parámetros. El presupuesto
completo del capítulo ofrece 790 XP; los resultados anteriores conservan su
fixture histórica de tres enemigos. [Diagnóstico y pruebas actuales](zombie_population.md).
