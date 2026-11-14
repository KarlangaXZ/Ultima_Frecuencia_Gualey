# Fase 9 — guardado, carga y pausa

**Actualización Fase 11:** [variantes, distribución, XP y persistencia](zombie_archetypes.md).
Los valores de enemigo común y resultados históricos de este informe se conservan;
las variantes actuales se configuran mediante ZombieArchetype.

**Actualización Fase 10:** el formato actual es v2, con dos zonas, estado por mapa
y estadísticas globales. v1 se valida y migra en memoria sin sobrescribirlo al
leer. Este informe conserva la arquitectura/resultados originales; consultar
[zonas y migración v1 → v2](zones_transitions.md) para el estado actual.

Godot 4.7.2 Stable, GDScript, Windows, Compatibility. Validación: 14 de noviembre
de 2026. Guardado local, sin servicios, nube, plugins, commits ni push.

## Uso

**Esc** cierra primero MOCHILA, PERSONAJE, MISIONES o RADIO si están abiertas.
Sin otra ventana abre **PAUSA · PARTIDAS**. Ofrece tres ranuras con nivel,
capítulo, fecha UTC, GUARDAR y CARGAR. Una ranura ocupada exige pulsar
**CONFIRMAR REEMPLAZO**, incluso si su archivo está dañado. Esc/CONTINUAR cierra.

Solo este menú pausa el árbol mediante InterfaceCoordinator. En pausa no avanzan
movimiento, IA, ataques, recargas, cooldowns, necesidades, daño automático, reloj
de partida ni reposiciones. La UI y SaveCoordinator siguen procesándose para
permitir botones. El ambiente se pausa conservando su preferencia anterior.
Las otras ventanas mantienen su regla anterior: mundo activo y controles bloqueados.
Se exige soltar el disparo al cerrar o cargar. Desde Game Over se puede abrir el
menú y cargar, pero guardar queda deshabilitado y se rechaza también en la API.
Reintentar sigue iniciando una partida nueva; no borra las ranuras.

Al abrir el juego comienza el escenario habitual. Esc → CARGAR permite continuar
una partida anterior; no se añade un menú de inicio ni se carga automáticamente.

## Ubicación y archivos

Directorio **user://saves/** de Godot, fuera del repositorio. En esta instalación:

```text
C:/Users/carlo/AppData/Roaming/Godot/app_userdata/Última Frecuencia- Gualey/saves/
  slot_1.json
  slot_2.json
  slot_3.json
```

La ruta exacta depende del usuario y de la configuración de Godot; user:// es la
referencia del código. Cada ranura puede tener .json.bak (versión anterior) y
.json.tmp (escritura pendiente). No copiar estas partidas a Git. Las pruebas
usan exclusivamente **user://tests/phase-nine-***, sin tocar las ranuras normales.
Los resultados de pruebas locales continúan en test-results/, ignorado.

## Formato v1 y datos persistidos

JSON de datos simples; tamaño máximo 2 MiB. Cabecera obligatoria:

```json
{
  "version": 1,
  "slot": 1,
  "saved_at": "2026-11-14T16:00:00Z",
  "chapter": "signal_lost",
  "map": "gualey_sector_04",
  "player": {},
  "world": {},
  "missions": {}
}
```

Los objetos vacíos del ejemplo representan las secciones descritas abajo; no
constituyen por sí solos un archivo válido. No se serializan nodos, instancias,
scripts, escenas ejecutables, rutas de recursos ni referencias de memoria.

| Sección | Datos |
| --- | --- |
| player | Posición, salud actual/base máxima, velocidad base, hambre/sed, periodos base, fracción del reloj de privación, nivel/XP/puntos, cuatro rangos, pilas e índices, armas por ID, equipada, cargador/reserva/cooldown, orientación y apuntado |
| world | Contenido y apertura de cinco contenedores, disponibilidad de cuatro recogibles, enemigos por ID/tipo/posición/salud/cooldown, presupuesto consumido, espera/cursor de población, bajas, tiempo, registros de XP por baja/apertura |
| missions | Estados, objetivos y progreso, totales históricos, recibos únicos, recompensas ya entregadas, transmisión/índice textual y zonas desbloqueadas (vacías en este capítulo) |

Las pilas contienen {item, quantity} o un objeto vacío para cada uno de los 12
espacios. Son IDs de ItemDefinition; los objetos de arma usan weapon_revolver,
weapon_shotgun y weapon_machete, diferentes de los IDs del arsenal. La munición
en mochila sigue separada de loaded/reserve del Weapon correspondiente.

Se conserva el tiempo pendiente de privación para que cargar no reinicie la
penalización por hambre/sed. Salud máxima y demás modificadores se reconstruyen
desde bases/rangos con CharacterStats, sin acumular bonificaciones ni curar.

Recargas, disparos y golpes en curso **no se reejecutan**. La recarga se cancela
sin transferir balas; se conservan cargadores, reservas y cooldown. Las velocidades,
rutas de NavigationAgent, efectos, flashes y menús se reconstruyen, no se guardan.
Un cadáver carga desactivado en su frame final, sin died/eliminated. La IA viva
vuelve a calcular su ruta. No se retrasa ni repite daño por reconstruir una animación.

Radio/generador derivan su disponibilidad del progreso de misión. El recurso de
transmisión se identifica por una clave permitida y conserva su índice, pero su
ventana carga cerrada. Se mantiene la política anterior: un diálogo cerrado no
se reproduce automáticamente ni dispone de archivo de relectura.

## Identidad estable

metadata/persistence_id en las escenas identifica recogibles, contenedores,
puntos de misión y los tres enemigos originales. Los dinámicos reciben
zombie_04…zombie_18 desde el contador de apariciones; los originales son
zombie_01…zombie_03. El ID no depende del orden de hijos ni se obtiene de una ruta
aportada por el JSON. Conservarlo al renombrar nodos o sustituir su presentación.

SaveCatalog registra los objetos, armas y transmisiones permitidos y busca
elementos del mundo por esa metadata. Los recibos de recogida y los registros de
ProgressionRewards usan ahora IDs estables. Solo objetos efímeros de fixtures sin
metadata emplean un ID session: por instancia; no se aceptan como enemigos o
contenedores persistentes en un archivo de partida válido.

No se emiten eventos de logro al reconstruir. Estados y registros se restauran
silenciosamente; después se refrescan HUD y vistas. Las conexiones semánticas se
conservan para acciones futuras. No hay nuevas bajas, sonidos, transferencias ni
XP por cargar. El presupuesto 6 vivos/18 totales y la demora de 10 s continúan
desde el punto guardado, sin duplicar actores ni revivir eliminados.

## Integridad y restauración

SaveSchema comprueba versión, mapa/capítulo conocido, ranura, fecha UTC/calendario,
estructura, tipos, números finitos, rangos y coherencia: puntos/rangos/nivel,
XP por nivel, capacidades de pila/cargador, IDs únicos y permitidos, número de
enemigos, bajas/cadáveres, XP ya marcada, dependencias de misiones, secuencia,
contadores y premios. Rechaza archivos incompatibles; no hay migraciones antiguas
porque esta es la primera versión persistente. No es cifrado ni protección antitrampas.

Escritura: validar → escribir .tmp → flush/cerrar → releer y validar .tmp → mover
primario válido a .bak → renombrar temporal a primario. Un primario dañado nunca
reemplaza un respaldo válido. Si falla el commit se conserva o recupera el
respaldo. Un temporal huérfano no se toma por una operación confirmada.
Al leer se intenta el primario y después .bak; la UI indica recuperación desde
respaldo. Esta estrategia se prueba con archivos truncados e interrupción entre
renombres; no se simula una avería física del disco ni se promete inmunidad a ella.

Cargar valida todo antes de tocar la partida. También consulta geometría World:
si el jugador estaría dentro de un sólido, recupera el inicio seguro y avisa;
un enemigo vivo dentro de un sólido hace rechazar la carga. Una escena nueva de
Main se prepara sin procesar gameplay, sin iniciar población/ambiente ni activar
su región de navegación. Los adaptadores reconstruyen sus estados con audio
silenciado y validan de nuevo el resultado. Solo entonces se retira la escena
anterior, se activa la nueva región, se continúa y se informa del resultado.
Un fallo previo al commit deja intacta la partida actual y su menú.

No se asignan estados a medias sobre los componentes de la escena actual.
Cambiar de ranura usa siempre una escena nueva, eliminando armas, pilas, rangos,
cadáveres, recibos y datos anteriores que no pertenezcan al archivo elegido.

## Arquitectura

- SaveCoordinator: captura estable, carga por escena candidata, validación geométrica,
  confirmación del reemplazo de escena y refresco de presentación.
- SaveSchema: validación de datos puros, sin acceso a archivos o gameplay.
- SaveFileStore: rutas de ranuras, lectura/escritura, temporales y recuperación.
- PlayerSaveState: adaptador de salud, necesidades, estadísticas, inventario y arsenal.
- MissionSaveState: progreso, recibos, premios y radio, sin emitir logros.
- WorldSaveState: suministros, actores, registros de XP y población.
- SaveCatalog: contenido permitido, IDs y conversión de pilas.
- PauseUI: vista de ranuras y confirmación; InterfaceCoordinator sigue siendo el
  único responsable de exclusión de ventanas, bloqueo y pausa.

Los adaptadores acceden a los estados privados por convención de los componentes
existentes como contrato de persistencia v1; no crean otra fuente mutable de
munición, bajas, inventario o XP. Cualquier cambio de esos contratos requiere
actualizar adaptador, esquema, versión/migración y pruebas conjuntamente.

## Autoguardado y compatibilidad futura

Soporte optativo en SaveCoordinator.autosave_enabled, **desactivado por defecto**.
Al habilitarlo por configuración se programa tras completar misiones, fuera de
la actualización del tracker. Usa autosave.json (slot 0), nunca las ranuras 1–3.
Rechaza Game Over, restauración, captura incompleta y pausa. Los errores se
presentan por HUD. La API permite cargar slot 0; el menú actual muestra solo las
tres ranuras manuales. No se añade un control de autoguardado al menú en esta fase.

Futuros mapas/capítulos/tipos deben registrarse por ID junto a escenas confiables
en el código, y ampliar secciones con migraciones explícitas. No aceptar rutas
ejecutables del archivo. Para múltiples mapas, mantener identidad por capítulo/mapa;
versionar los cambios incompatibles y conservar respaldos durante la migración.
No se implementa ese contenido futuro ni persistencia en nube.

## Pruebas y límites

La suite base anterior a los cambios aprobó sus 21 pruebas (1.161 comprobaciones).
Se conservan las regresiones de movimiento, IA, población, armas, inventario,
necesidades, RPG, misiones, HUD/audio y reinicio. Resultado completo:

- **1.161 comprobaciones anteriores**, todas aprobadas.
- **62 de integridad**: rangos/tipos/IDs, archivos vacíos/corruptos/incompatibles,
  confirmación, escritura fallida, respaldo y temporal huérfano.
- **112 de integración**: estado completo, carga repetida sin modificadores extra,
  otra ranura sin residuos, geometría/posición segura, pausa, UI, IA posterior,
  Game Over, Reintentar y autoguardado optativo aislado.
- **1 de escritura + 33 de lectura en procesos separados**. En la pasada final,
  el escritor PID 18180 terminó y el lector PID 19440 recuperó ese archivo.
- Total headless: **1.369 comprobaciones**, cero fallos.
- Prueba gráfica de guardado: **114 comprobaciones**, dos capturas reales del
  menú y su confirmación, con teclado y clics en GUARDAR/CONFIRMAR.
- Regresiones gráficas general **39** y HUD/audio **99**, cero fallos. Arranque
  normal e importación sin errores/advertencias nuevos del motor. La cámara se
  sincroniza con la posición cargada antes de continuar o reponer enemigos.

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/save_integrity_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/save_load_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/save_restart_test.gd -- --write
godot --headless --path . --fixed-fps 60 --script res://tests/save_restart_test.gd -- --read
godot --path . --fixed-fps 60 --script res://tests/save_load_test.gd -- --capture
```

Las dos órdenes restart se ejecutan en procesos separados y una carpeta de
pruebas compartida. La fixture prepara posiciones, daño y XP extra para tener
cuatro habilidades y todas las armas; inmoviliza únicamente los procesos de
actores durante la preparación. Mantiene las colisiones World para probar alcance
y rechazo geométrico. Los actores reconstruidos tienen IA activa: se mide su
desplazamiento y Walk tras cargar. La pausa se comprueba durante 120 frames;
se conserva el conjunto completo de datos sin avances.

Teclado y clics del menú se introducen mediante eventos de Godot. No son capturas
ficticias ni una partida manual. El agotamiento y balance de supervivencia ya
pertenecen a las regresiones; las fixtures no se presentan como rendimiento ni
dificultad natural de la campaña.

Problemas corregidos durante desarrollo: IDs de objetos de arma distintos de
los IDs del arsenal; convertir StringName a texto en la lista de premios; una
fixture que deshabilitaba también colisiones del mundo al desactivar su árbol
(se cambió a detener solo los procesos de preparación). No se cambió la IA para
resolverlos. Las pruebas fallidas se repitieron tras corregir esas causas.

Pendientes manuales: sesión prolongada guardando en combate, cierre desde la UI
del sistema, distintas resoluciones, escucha de mezcla, panel gráfico del
depurador, exportación Windows y fallos físicos de almacenamiento. No se declaran
aprobados. Los archivos normales del jugador no se modificaron por las pruebas.

## Archivos

Nuevos: siete scripts scripts/save/ y sus .uid; scripts/ui/pause_ui.gd y .uid;
save_integrity_test.gd, save_load_test.gd, save_restart_test.gd, save_fixture.gd,
save_assertions.gd en tests/ y sus .uid; este informe; captura del menú con .import.

Modificados: Main.tscn (coordinador/menú, IDs iniciales), main.gd (bandera de
reconstrucción, no iniciar población en candidato), zombie_population.gd (ID y
restauración de su estado), game_audio.gd (no iniciar ambiente al reconstruir),
player_interaction.gd y progression_rewards.gd (recibos estables), loot_container.gd
(apertura), Supplies.tscn, ArsenalSupplies.tscn y ChapterPoints.tscn (metadata),
interface_coordinator.gd (pausa), README.md, AGENTS.md y docs/images/README.md.
Se conserva la normalización previa de project.godot, que ya estaba modificada
al comenzar; esta fase no añade acciones de entrada. Esc reutiliza ui_cancel.
