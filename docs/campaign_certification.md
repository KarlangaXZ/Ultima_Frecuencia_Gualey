# Fase 17 — certificación de campaña y preparación Windows

Validación técnica local del 15 de noviembre de 2026, Godot 4.7.2 Stable,
Windows, GDScript, Compatibility, 1280 × 720. Se conservan cuatro capítulos,
quince misiones, cuatro zonas, tres arquetipos, cuatro armas y guardado v7.
No se añadió contenido, música, balance o interfaces.

**Alcance:** campaña funcional desde el proyecto y paquete PCK verificados.
**Límite:** no hay ejecutable Windows independiente certificado; faltan sus
plantillas exactas. La escucha musical subjetiva y la partida humana siguen
pendientes. La campaña automatizada no se presenta como una sesión humana.

## Recorrido principal sin preparación artificial

`tests/campaign_certification_test.gd` parte de TitleMenu, elige una ranura
aislada y crea una partida normal. Usa Input/move_and_slide y E para navegar
y activar elementos físicos, sin reposicionar al jugador o enemigos, asignar
salud/XP, inyectar misiones, llenar mochilas ni desactivar IA/población.
Las transiciones utilizan las salidas existentes. Los checkpoints guardan/cargan
la misma posición y comparan exactamente sus seis secciones de estado.

Un bot defensivo llama las mismas APIs de Weapon, ItemUse y Equipment empleadas
por el juego: daño físico real, munición finita, cadencia, recarga, consumibles y
cambio de arma válidos. No simula apuntado manual humano ni decide por un jugador.
Puede disparar preventivamente desde el alcance real del arma; esto no certifica
que el balance sea cómodo o justo para una persona.

Recorrido completado:

1. Inicio, ranura 1 y Gualey: La señal perdida, recogidas y bajas reales.
2. Arsenal recuperado de sus contenedores: enfrentamientos con machete, revólver,
   escopeta y pistola. Habilidad comprada con XP ganada.
3. Mercado: Ecos del Mercado, corredor/resistente, suministros y transmisión.
4. Estación: Voces en la oscuridad, dos bajas locales, registros, energía y radio.
5. Perímetro: El último convoy y transmisión final completa.
6. Quince premios únicos, cuatro capítulos y cuatro mundos persistidos; guardar
   y cargar el resultado sin terminar la exploración.

El recorrido mide **35.419,96 píxeles**, con IA activa durante todo el trayecto.
La pasada en ventana registró **78 ataques**, **9 recargas** y **6 usos de objetos**;
recibió daño real (100 → 90 HP) sin alterar estadísticas. Hambre y sed avanzaron
por el reloj normal. La duración de juego registrada fue 186,83 s. Se ejecutó
con fixed-fps para regresión: esas cifras no se usan como benchmark de FPS.

## Pruebas y cobertura

| Prueba ejecutada | Resultado |
| --- | --- |
| Línea base previa completa, 63 procesos/modos | 3.105 comprobaciones, 0 fallos |
| Campaña continua con IA activa, headless | 198 comprobaciones, 0 fallos |
| Misma campaña en ventana, doce capturas | 210 comprobaciones, 0 fallos |
| Contrato de exportación: radios, misiones, zonas, botín y geometría | 48 comparaciones exactas, 0 diferencias finales |
| PCK aislado: inicio, ranuras, guardado/carga y partida de campaña | 32 headless / 34 en ventana, 0 fallos |

Las filas son ejecuciones separadas y sus alcances se solapan; no representan
usuarios o sesiones humanas independientes. Los intentos fallidos se conservan
para diagnóstico y no se suman como comprobaciones aprobadas.

La base vuelve a ejecutar todos los tests funcionales de las fases anteriores:
IA/persecución/rutas/ataques/colisiones, muerte/bajas/XP, límites 6/18/10 s y
apariciones fuera de cámara, cuatro armas, recarga/cambio, inventario, hambre/sed,
habilidades, Game Over y Reintentar. Incluye tres ranuras, confirmación de
reemplazo, respaldo, recuperación entre procesos, v1–v6 migrados a v7, v7 nativo,
enemigos/suministros, cuatro zonas, diálogos pendientes y premios únicos.

Las pruebas unitarias y fixtures históricas permanecen separadas del recorrido
principal. Algunas preparan capítulos o estados agotados, congelan enemigos o
simulan condiciones extremas; no se presentan como juego real. Ninguna prueba
escribe en `user://saves/` ni guarda las preferencias normales del jugador.
La campaña usa `user://tests/phase-seventeen-campaign-*`; el PCK usa su propio
directorio de pruebas y lee el checkpoint de campaña, sin modificarlo.

## Interfaces y audio

Se capturan presentación, ranuras, configuración, HUD, MOCHILA, PERSONAJE,
MISIONES, RADIO, PAUSA y finales de capítulo a 1280 × 720. Las transiciones
mantienen el mismo jugador y la música. La revisión de imágenes se documenta
al cerrar la validación; no se rehace el diseño.

El audio conserva Music → Master, Effects, Ambience e Interface, dos composiciones
y una voz musical. El PCK emite señal real tanto en menú como en gameplay.
Las comprobaciones de volumen, silencio, fundidos, radio/pausa y clipping se
ejecutan además con los tests musicales existentes. **La calidad musical subjetiva
sigue pendiente de escucha humana**, independientemente de los resultados técnicos.

## Defectos reproducidos y corrección mínima

1. **Dependencias omitidas al seleccionar recursos para exportación.** El PCK
   aislado no encontraba SVG usados por scripts. El preset final exporta los
   recursos del proyecto, excluyendo tests, documentación, herramientas y material
   de referencia identificado; no se cambió ningún asset.
2. **Pérdida de datos en conversión textual → binaria.** En el PCK desaparecían
   cantidades de contenedores y mensajes de radio. También se observaron huellas
   de obstáculos instanciados distintas de las fuentes en Gualey/Mercado; eso
   impedía cargar enemigos situados correctamente en el proyecto original.
   El contrato de datos y geometría reprodujo las diferencias fuera del directorio
   fuente. La única corrección final de configuración es
   `editor/export/convert_text_resources_to_binary=false` en project.godot.
   No se modifican cantidades, colisiones, scripts de gameplay o historia.

El caso de los arrays coincide con la
[incidencia reportada para Packed*Array en Godot 4.7.2](https://github.com/godotengine/godot/issues/124452).
La diferencia de geometría es un resultado local del contrato, sin atribuirle
una causa interna adicional no demostrada. El formato de exportación se controla
mediante la [opción oficial de ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-editor-export-convert-text-resources-to-binary).
Tras conservar textos, las 48 comparaciones coinciden y la partida fuente carga
en el PCK. Se descartaron los cambios experimentales a inicializadores: sus dos
scripts quedaron idénticos a los que había al comenzar la fase.

Los primeros probes también detectaron un error metodológico: ejecutar el PCK
con `--path .` permitía resolver archivos del proyecto fuente. La prueba final
usa `--path builds/windows`, sin proyecto fuente allí, y exige que los tests estén
ausentes del paquete. Los probes son scripts externos y no se distribuyen.

## Exportación Windows

Se creó `export_presets.cfg`, preset **Windows Desktop**, arquitectura x86_64,
sin firma, salida local `builds/windows/UltimaFrecuenciaGualey.exe`. Sin credenciales
ni cambios de VSync. Excluye `tests/`, `docs/`, `tools/`, `.tools/`, resultados,
plantillas y referencias gráficas no usadas. Los guardados permanecen en user://;
ninguna partida personal forma parte del paquete.

La exportación debug se intentó y falla únicamente por plantillas ausentes:

```text
C:/Users/carlo/AppData/Roaming/Godot/export_templates/4.7.2.stable/windows_debug_x86_64.exe
C:/Users/carlo/AppData/Roaming/Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe
```

El directorio local export_templates/ tampoco contenía archivos aprovechables.
No se descargó ni instaló ningún componente. Hace falta instalar, con autorización,
las plantillas correspondientes exactamente a 4.7.2.stable y repetir exportación
debug/release, arranque, nueva partida, carga y audio desde el ejecutable final.
**Esas pruebas de ejecutable no se declaran realizadas.**

Se generó `builds/windows/UltimaFrecuenciaGualey.pck` y se probó con el motor
ya instalado, sin recursos fuente de respaldo. Esto valida contenido y lógica
empaquetada, **no sustituye una compilación Windows independiente**. El PCK y
todos los resultados están ignorados por Git; no se publicaron ni distribuyeron.

## Reproducción

```powershell
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script res://tests/campaign_certification_test.gd
godot --path . --fixed-fps 60 --script res://tests/campaign_certification_test.gd -- --capture
godot --headless --path . --script res://tests/export_contract_probe.gd -- --write
godot --headless --path . --export-pack "Windows Desktop" builds/windows/UltimaFrecuenciaGualey.pck
$pack = (Resolve-Path builds/windows/UltimaFrecuenciaGualey.pck).Path
$contract = (Resolve-Path tests/export_contract_probe.gd).Path
$probe = (Resolve-Path tests/pack_certification_probe.gd).Path
godot --headless --path builds/windows --main-pack $pack --script $contract
godot --path builds/windows --main-pack $pack --script $probe
```

Generar primero el informe de campaña y contrato fuente. Las rutas de los probes
se resuelven desde su propia ubicación. La suite base completa y modos usados
están registrados en `test-results/phase-seventeen/baseline.txt`.

## Estabilidad y rendimiento

Resultados de dos pasadas comparables y revisión de StringName: pendientes de
incorporar al concluir las mediciones. Se reutiliza perimeter_performance.gd y
su instrumento de reloj monotónico, con doce transiciones por pasada. Esta
preparación de rendimiento usa fixtures narrativas y curación de prueba para
sostener la carga; es independiente del recorrido principal sin simulaciones.
Las métricas de física son lecturas de máximos publicados por segundo, no tiempos
medios por paso. No se modifica VSync ni se mide con fixed-fps o capturas.

## Capturas y revisión humana

Capturas seleccionadas y pendientes de incorporación tras revisión visual.

Quedan pendientes una partida humana completa, balance bajo presión, comodidad
del apuntado y hotkeys, claridad narrativa sin coordenadas, otras resoluciones,
escucha musical/mezcla en distintos dispositivos, sesiones largas de memoria,
revisión interactiva del panel del depurador y ejecutable Windows/exportación.
El arte y varios sonidos/animaciones siguen siendo provisionales.

## Archivos de esta continuación

Se preservó íntegramente el trabajo pendiente de fase 16. Cambios de fase 17:
preset Windows nuevo, configuración de conversión de exportación, recorrido
integral, dos probes externos y sus UID, este informe, actualización mínima de
README/documentación y capturas seleccionadas. No hay commits ni push.
