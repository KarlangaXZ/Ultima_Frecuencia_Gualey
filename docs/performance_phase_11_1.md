# Fase 11.1 — rendimiento y estabilidad

Evaluación reproducible, 14 de noviembre de 2026. Sin cambios de gameplay,
balance, IA, renderizador, resolución ni configuración predeterminada del juego.

## Qué significaban los 32,18 ms

La fase 11 promedió 120 lecturas de `Performance.TIME_PROCESS` desde
archetypes_visual_test.gd, ejecutado con `--fixed-fps 60`. La fixture esperaba
physics_frame y process_frame, por lo que no medía cada frame presentado.
El resultado se etiquetó como medio, pero **no era el tiempo medio real de frame**.

En Godot 4.7.2, Main acumula `process_max`, `physics_process_max` y
`navigation_process_max`, publica esos máximos al pasar un segundo y los reinicia.
TIME_PROCESS abarca el tramo process/render, incluida la presentación; no es
tiempo exclusivo de scripts ni suma de todos los componentes de un frame.
Promediar consultas repetidas al monitor mezcla máximos retenidos y no determina
FPS medios o p95. Además, `--fixed-fps` fuerza el reloj y desactiva sincronización
temporal del bucle: sirve para regresión determinista, no para un benchmark real.

Fuentes primarias: [Main de Godot 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L4723),
[publicación de máximos](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L4743),
[monitores y frecuencia de actualización](https://docs.godotengine.org/en/stable/classes/class_performance.html),
[tiempos de viewport](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-viewport-set-measure-render-time).

## Entorno y metodología

- Windows, Godot oficial 4.7.2 ed1daf0bf, ejecutable del editor en modo proyecto
  Debug autónomo mediante `--script`; sin depurador remoto ni editor embebido.
- Ryzen 5 5600G, 12 hilos lógicos; 34.243.321.856 bytes de RAM física
  (31,89 GiB); Radeon RX 580, OpenGL Compatibility 3.3, driver 26.5.2.260413.
- Ventana 1280 × 720 con foco; física 60 Hz. El editor del usuario (PID 19200,
  aproximadamente 1,13 GiB de Working Set al inicio) permaneció abierto.
  No se cerraron aplicaciones del usuario ni se ejecutó otra prueba Godot en paralelo.
- Misma fixture, secuencia, resolución y hardware: VSync original activado sin
  límite; diagnóstico sin VSync; diagnóstico sin VSync con límite de 60 FPS.
  Los cambios de sincronización/límite solo afectan al proceso de prueba.
- Sin `--fixed-fps`, imágenes, grabación ni impresión por frame dentro de muestras.
  Un segundo de calentamiento, tres segundos por escenario normal; dos para
  mercado estable y poscarga; 1,6 para cada transición, incluyendo el fundido.
- Se toma reloj monotónico `Time.get_ticks_usec()` entre process_frame
  consecutivos. FPS = 1000 / media de intervalos; p95 por rango más próximo.
  Son FPS del bucle de aplicación, no FPS de salida física del monitor.
- Render CPU/GPU por viewport y preparación CPU mediante RenderingServer.
  Física/navegación y TIME_PROCESS se conservan **como monitores de máximos
  publicados por segundo**; sus medias de lecturas no son perfiles por paso.
  Se incluyen muestras crudas para evitar interpretarlos como tiempos exclusivos.
- Nodos/objetos/recursos/huérfanos, nodos procesando, enemigos, voces, regiones
  y conexiones died del jugador se capturan por etapa. PowerShell registra
  Working Set, memoria privada y CPU del proceso cada 200 ms.
- Se conservan muestras en RAM: una pequeña subida de memoria del propio
  instrumento es esperable; el diagnóstico ilimitado recoge muchas más muestras
  y no debe usarse como prueba de fuga. Se comparan mapas equivalentes tras
  calentamiento, con número de actores y estado idénticos.

## Escenarios y alcance

home_idle: Main de producción, seis comunes fuera de detección. home_six:
los seis se sitúan cerca del jugador, sin desactivar su IA. market_mixed:
mercado real con tres comunes, dos corredores y un resistente, próximos al jugador.
combat: dispara la pistola real contra esos enemigos, con su cadencia y recarga;
el número de vivos puede bajar por impactos. inventory/character: apertura real
de ambas ventanas, conservando mundo activo.

La fixture cura inmediatamente daño no letal para prolongar las muestras;
no altera estadísticas ni cooldown. Prepara posiciones y eventos de misión para
viajar. No representa una partida humana ni valida balance o puntería manual.

Para estabilidad se reinicia Main antes del recorrido. La misión elimina dos
comunes para desbloquear el mercado: Home conserva cuatro vivos y dos cadáveres,
mercado seis vivos. Se hacen seis transiciones (tres viajes de ida/vuelta),
comparando cada zona consigo misma. Se comprueba que World y un actor anteriores
se han liberado mediante WeakRef, una región activa, sin aumento de nodos,
recursos, voces, huérfanos o conexiones. Un guardado/carga real adicional usa
`user://tests/phase-eleven-one-performance-<PID>`, sin tocar partidas normales.

## Resultados

Comparación de configuración, **sin modificar el juego**. Son pasadas de
la misma fixture; no un antes/después de optimización de código.

| Escenario | FPS VSync | Media ms | p95 ms | FPS sin VSync, cap 60 | Media ms | p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Zona 1, lejos | 35.1 | 28.51 | 32.13 | 60.0 | 16.67 | 16.77 |
| Zona 1, seis cercanos | 34.7 | 28.80 | 32.29 | 60.0 | 16.67 | 16.83 |
| Mercado, mezcla 3/2/1 | 35.3 | 28.32 | 31.99 | 60.0 | 16.67 | 16.85 |
| Combate | 35.0 | 28.57 | 32.60 | 60.2 | 16.62 | 17.16 |
| Inventario | 34.9 | 28.62 | 32.13 | 60.0 | 16.67 | 16.75 |
| Personaje | 35.4 | 28.28 | 32.10 | 60.0 | 16.67 | 16.75 |
| Mercado estable | 36.2 | 27.63 | 32.11 | 60.0 | 16.67 | 16.78 |
| transition_0 | 32.0 | 31.22 | 32.45 | 60.0 | 16.67 | 16.87 |
| transition_1 | 37.9 | 26.39 | 32.03 | 60.0 | 16.67 | 16.87 |
| transition_2 | 31.8 | 31.47 | 32.55 | 60.0 | 16.67 | 16.99 |
| transition_3 | 37.9 | 26.38 | 32.07 | 60.1 | 16.65 | 16.80 |
| transition_4 | 32.3 | 30.92 | 32.18 | 60.5 | 16.53 | 16.82 |
| transition_5 | 32.1 | 31.11 | 32.23 | 60.0 | 16.67 | 16.79 |
| Después de cargar | 32.5 | 30.82 | 32.09 | 60.0 | 16.67 | 16.79 |

La pasada sin límite y sin VSync dio aproximadamente 1.915–2.703 FPS de bucle
según escenario (0,37–0,52 ms medios). Es una comprobación de capacidad, no
una recomendación de consumo ni garantía de presentación visible. La limitación
original no puede atribuirse a la IA solo por el dato de 32,18 ms.

Costes y recursos de la pasada cap 60. Física = promedio de lecturas del monitor
de máximos por segundo; render CPU/GPU = medición de viewport, en ms. Nodos
totales/procesando y vivos se toman al final de cada muestra. WS es la media
de muestras externas agrupadas por etapa, en MiB, no memoria estática de Godot.
El grupo externo incluye preparación hasta que empieza la siguiente muestra;
por ello no se atribuye un pico de memoria a un frame u operación concreta.

| Escenario | Física* ms | Render CPU / GPU ms | WS MiB | Nodos total / procesando | Vivos |
| --- | ---: | ---: | ---: | ---: | ---: |
| Zona 1, lejos | 0.293 | 0.533 / 0.816 | 261.8 | 457 / 38 | 6 |
| Zona 1, seis cercanos | 0.522 | 0.525 / 0.753 | 263.9 | 457 / 38 | 6 |
| Mercado, mezcla 3/2/1 | 0.550 | 0.439 / 0.828 | 265.4 | 426 / 38 | 6 |
| Combate | 0.845 | 0.442 / 0.808 | 274.8 | 426 / 38 | 3 |
| Inventario | 0.252 | 0.608 / 1.131 | 293.4 | 457 / 38 | 6 |
| Personaje | 0.203 | 0.588 / 1.120 | 305.8 | 457 / 38 | 6 |
| Mercado estable | 0.284 | 0.374 / 0.820 | 306.3 | 426 / 38 | 6 |
| Después de cargar | 0.296 | 0.362 / 0.820 | 322.8 | 426 / 38 | 6 |

Los costes anteriores no son sumables: algunos son máximos publicados, otros
mediciones por viewport y otros intervalos con esperas. La preparación de render
CPU ronda 0,005–0,007 ms. Las muestras crudas incluyen navegación y p95/máximos
de todos los canales; navegación no apareció como limitación dominante.

Operaciones síncronas: guardar **11.78 / 12.55 ms** y cargar **33.74 / 32.69 ms**
(VSync / cap 60). La fila después de cargar mide el estado estabilizado y
excluye esos costes, que se cronometran por separado. No equivale a afirmar que
cada carga entra en un presupuesto de 16,7 ms.

### Estabilidad ampliada: 24 transiciones

La repetición independiente con cap 60 aprobó **170 comprobaciones**. Fundidos
completos de 395,41–414,20 ms (incluyen la animación prevista de unos 400 ms);
máximo intervalo entre frames durante transición: **17,27 ms**. No hubo
congelamiento largo en esta muestra; falta valoración humana de suavidad.

| Punto | Nodos | Enemigos vivos / nodos | Recursos | Voces | Conexiones died | Huérfanos |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| settled_0 | 457 | 4 / 6 | 418 | 27 | 21 | 0 |
| settled_1 | 426 | 6 / 6 | 418 | 27 | 21 | 0 |
| settled_16 | 468 | 5 / 7 | 418 | 30 | 22 | 0 |
| settled_22 | 468 | 5 / 7 | 418 | 30 | 22 | 0 |
| settled_23 | 426 | 6 / 6 | 418 | 27 | 21 | 0 |
| final | 426 | 6 / 6 | 418 | 27 | 21 | 0 |

Siempre queda **una región**. Home pasa de cuatro a cinco vivos cuando su
reposición de diez segundos se cumple: un actor legítimo añade 11 nodos, tres
voces y una conexión died. Se descuentan sus propios nodos/conexiones al comparar
zonas equivalentes; no se confunde esta reposición finita con una fuga. Los
418 recursos permanecen constantes. World y actores anteriores ya no existen.

Memoria externa, misma pasada: mercado estable **285,21 MiB WS / 378,56 MiB
privados**; transition_1 **286,32 / 379,66**, transition_13 **287,85 / 381,17**,
transition_19 **287,56 / 380,84**, transition_21 **288,06 / 381,36** y
transition_22 **288,08 / 381,36**. Se aproxima a una meseta en este tramo, sin
crecimiento proporcional a cada cambio de zona. No demuestra ausencia de fugas
a largo plazo. Tras cargar, el grupo externo promedia **319,15 MiB WS / 404,48
MiB privados**; el proceso no devuelve necesariamente toda su reserva al SO.
No se ha aislado el origen exacto de esta reserva ni comprobado cargas repetidas
durante horas; no se declara resuelto un posible crecimiento prolongado.

La memoria estática registrada va de 47,49 MiB en Home a 48,29 MiB al final de
sus visitas, y 48,04 MiB tras cargar. Parte del aumento pertenece al instrumento
que retiene muestras JSON, snapshots y arrays durante toda la prueba.

En esta pasada ampliada: guardar 11,53 ms; cargar 31,39 ms. Logs y CSV de la
pasada final ampliada: `test-results/performance/stability-final/`.

## Diagnóstico y decisiones

La caída observada con VSync desaparece al cambiar únicamente esa opción dentro
del benchmark. El coste medido de render CPU/GPU y física es muy inferior al
intervalo de presentación original. Esto confirma una limitación asociada a
sincronización/presentación en este entorno; no identifica por sí solo el ajuste
del driver, compositor, pantalla o software externo responsable.

No se confirmó un cuello de botella en navegación, seis enemigos, audio o HUD
que justifique reescribirlos. No se cambian algoritmos, frecuencias de IA,
efectos, animaciones, número de actores, geometría o recursos gráficos.
La configuración con VSync desactivado es un diagnóstico reproducible, no una
optimización de scripts ni una mejora publicada del juego. Desactivarlo por
defecto podría introducir tearing; no se cambia project.godot sin comprobarlo
visualmente en una build y pantalla de destino.

Se corrigió la instrumentación: reloj real, métricas separadas, percentiles,
memoria externa, escenarios repetidos y aserciones de liberación. La primera
pasada piloto esperaba seis vivos en Home después de dos bajas de misión;
se corrigió esa expectativa, manteniendo cadáveres y gameplay. También se
corrigió una anotación WeakRef del diagnóstico antes de las pasadas finales.
Los logs piloto se conservan separados y no cuentan como validación aprobada.

## Reproducción

Desde la raíz, PowerShell:

```powershell
./tools/measure_performance.ps1 -Label vsync
./tools/measure_performance.ps1 -Label unlimited -NoVSync
./tools/measure_performance.ps1 -Label capped60 -NoVSync -Cap 60
./tools/measure_performance.ps1 -Label stability -NoVSync -Cap 60 -Cycles 24
```

El runner usa el Godot local de `.tools/godot/`. Para otro equipo adaptar la ruta
del ejecutable. Cada pasada guarda metrics.json con muestras, stdout/stderr y
process-memory.csv en test-results/performance/<Label>/ (ignorado). No ejecutar
pasadas simultáneas. Los labels finales de esta evaluación son `final-vsync`,
`baseline-unlimited` y `diagnostic-cap60`, más `stability-final` (24 transiciones). El ilimitado precede a las aserciones
adicionales de liberación; solo se usa como diagnóstico de capacidad.

## Regresión y archivos

Suite completa repetida: **1.764 comprobaciones headless, cero fallos**, con
movimiento/cámara, navegación de ambas zonas, tres variantes con IA activa,
cuatro armas, daño/cadencia, animaciones/audio, inventario, supervivencia, RPG,
misiones, persistencia v1/v2 y reapertura en procesos separados, viajes, Game
Over y Reintentar. No se modificó ninguna prueba anterior.

Diagnóstico gráfico: 44 comprobaciones en cada pasada comparativa final y 170
en la pasada ampliada final. Sin errores ni advertencias durante estas pruebas.
Importación aprobada. Logs en `test-results/performance/`.

Un primer arranque normal con `--quit-after 180` informó **dos ObjectDB retenidos
al salir**. No volvió a aparecer en la repetición `--verbose --quit-after 180`
ni en `--verbose --quit-after 600`. No se identificó el tipo de objeto de ese
primer cierre; no se declara corregido ni se atribuye a audio sin evidencia.
No hubo huérfanos durante las transiciones. Se conserva como advertencia
intermitente pendiente de reproducir en cierre manual y build exportada.

La primera prueba larga detectó una expectativa errónea del propio instrumento:
restaba un Resource por enemigo repuesto aunque el monitor de recursos
compartidos permanecía constante en 418. Se corrigió el cálculo y se repitieron
las 24 transiciones completas, sin cambiar el sistema de población.

Nuevos: tests/performance_phase_11_1.gd y su UID, tools/measure_performance.ps1,
este informe. README e informe de arquetipos reciben enlaces y la aclaración de
32,18 ms. No se modifican scripts/escenas/Resources funcionales ni project.godot.
Se conservan todos los cambios preexistentes de las fases 10 y 11, sin commits,
push ni plugins.

## Limitaciones y pendientes

No hay plantillas de exportación 4.7.2 instaladas en
%APPDATA%/Godot/export_templates/4.7.2.stable ni preset de exportación en el
repositorio. **No se probó un Windows exportado Debug/Release**, ni se descargaron
binarios o se inventó una prueba de exportación. Es necesaria una comparación
en build exportada con editor cerrado por el usuario, misma pantalla y driver,
seguida de una sesión prolongada y escucha de mezcla.

Las muestras de segundos y doce viajes de ida/vuelta no demuestran ausencia de
fugas durante horas. El muestreo de memoria de 200 ms puede omitir picos breves
de carga. Los FPS observados no garantizan cadencia visible libre de tearing o
stutter; no se declara alcanzado el objetivo de 60 FPS estables en la
configuración predeterminada ni en Windows exportado. No hubo revisión humana
interactiva de todos los recorridos, depurador gráfico o latencia percibida.
