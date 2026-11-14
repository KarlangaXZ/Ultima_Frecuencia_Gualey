# Fase 8.1 — diagnóstico de movilidad y población finita

Validación: 14 de noviembre de 2026, Godot 4.7.2 Stable oficial, Windows,
Compatibility, Radeon RX 580. Sin commits, push, plugins ni recursos nuevos de arte.

## Diagnóstico confirmado antes de modificar

No se reprodujo un bloqueo de la IA en Main normal. ZombieA aparece a **400 px**
del jugador, fuera de su detección de **250 px**. Los otros dos también están
fuera de rango. Su física está activa, el árbol no está pausado y permanecen
IDLE según la regla existente. No patrullan ni buscan al jugador a distancia.

Al situar al jugador dentro del rango, ZombieA pasó de (1000,800) a (1000,870):
**70 px**, velocidad **105 px/s**, CHASE y walk_down. Después atacó, restando
10 HP y respetando su intervalo de 1.5 s. Con parámetros originales rodeó la
esquina del colmado, y tres zombis persiguieron simultáneamente. Todo se comprobó
en ventana antes de añadir población, con IA activa durante toda la prueba.

La prueba de fase 8 usa explícitamente set_physics_process(false) para aislar
misiones, igual que otras fixtures visuales. Esa instrucción solo existe en tests;
no se ejecuta al jugar Main. Las capturas de aquella prueba no demostraban
movimiento. **No se editó zombie.gd, Zombie.tscn, navegación ni animaciones.**

Se ejecutó la misma escena configurada como entrada del proyecto mediante Godot
en ventana. Esto comprueba el contenido que arranca F5; no se pulsó F5 manualmente
en el editor ni se presenta la sesión automatizada como una partida humana.

## Población actual

Main/Population, script zombie_population.gd, es el único gestor de nuevas
apariciones. Reutiliza Zombie.tscn y sus animaciones, salud, daño y audio.

- **6 vivos** inicialmente: los tres originales y tres adicionales distribuidos.
- **Máximo 6 vivos**, configurable mediante active_limit (hasta 10).
- **18 apariciones totales por capítulo**, incluyendo los tres originales,
  configurable mediante total_budget (hasta 20, mínimo efectivo: actores existentes).
- Una reposición por **10 segundos** cuando hay vacantes. Estar al máximo reinicia
  la espera. No hay oleadas ni creación infinita. Al agotar el presupuesto no repone.
- Game Over detiene el gestor. Todos los actores, incluidos los dinámicos, dejan
  de perseguir por la señal de muerte del jugador existente. Reintentar reconstruye
  seis actores vivos y el presupuesto completo de 18.

Las posiciones candidatas son un PackedVector2Array exportado. En la configuración
actual los tres adicionales iniciales aparecen en **1600,450; 1960,700; 1800,1250**.
No se aleatoriza sobre el mapa ni se cambia la malla. Cada aparición verifica:

- Distancia al jugador de al menos 320 px.
- Fuera del viewport ampliado 96 px; se pospone si no existe candidato seguro.
- Punto sobre la malla con tolerancia de 2 px y ruta conectada al jugador.
- Consulta física circular de 26 px contra World/Player/Zombie, antes de crear.
- Separación de 96 px respecto a vivos y puntos importantes de misión.

El llenado inicial espera a consultas válidas de navegación/cámara. Durante el
desarrollo se detectó que el primer tick podía no ofrecer rutas utilizables:
se conserva el llenado pendiente hasta encontrar candidatos, sin gastar presupuesto
en fallos. Las reposiciones posteriores respetan su intervalo. Si el jugador está
en una posición no navegable o no queda un punto seguro, la aparición se difiere.

El presupuesto se reserva antes de añadir/notificar; el actor se registra antes
del evento spawned. Los cadáveres conservan el flujo anterior de fade/desactivación
hasta reintentar, así que el número total de actores también queda limitado a 18.
No cambia la colisión de personajes ni se bloquean físicamente entre ellos.

## Integración y XP

Main._register_zombie se usa tanto para originales como para nuevos: asigna
objetivo y conecta el contador de bajas y ProgressionRewards existentes. La señal
zombie_added permite a ChapterController observar también bajas dinámicas,
después de actualizar Main.kills. No se duplican salud, XP ni objetivos.

Se conservan **30 XP por eliminación**, **20 por primer contenedor no vacío** y
**25/50/75 por misiones**. Con 18 bajas, cinco contenedores y las tres misiones:

`18 × 30 + 5 × 20 + 150 = 790 XP`

Máximo del contenido actual: **nivel 5, 90/300 XP, cuatro puntos de habilidad**.
No se modifica la fórmula ni las habilidades. El presupuesto solo se consume al
aparecer; alcanzar toda esa XP requiere esperar reposiciones y abatirlos a todos.
Los suministros, munición, armas, daño y misiones no se reequilibraron silenciosamente.

## Pruebas y evidencia

- **19 suites previas: 1.054 comprobaciones**, todas conservadas y aprobadas.
  Quince scripts que instancian Main ahora usan tests/fixtures/LegacyMain.tscn:
  hereda Main y solo configura Population a tres vivos/tres totales. No se borran
  aserciones ni se desactiva la IA mediante el gestor. Esto mantiene las fixtures
  históricas de combate, UI y presupuesto de 340 XP sin cambiar producción.
- zombie_mobility_test.gd: **22 headless / 25 con capturas**, cero fallos. Instancia
  Main de producción, seis vivos, nunca desactiva la física de enemigos. Comprueba
  IDLE, detección, movimiento medido, reducción de distancia, Walk, colmado, tres
  perseguidores, daño, cooldown y detención por muerte. Las posiciones se preparan
  en la fixture; no es un recorrido manual ni una IA distinta.
- zombie_population_test.gd: **85 headless y 85 en ventana**, cero fallos. Valida
  población inicial, límites durante cada evento, distancia, pantalla, obstáculos,
  misión, demora, agotamiento, XP exacta y reinicio. El agotamiento adelanta el
  reloj del gestor y aplica daño de fixture para probar los 18 casos rápidamente.
- La misma prueba completa las tres misiones con IA activa, abatiendo **dos zombis
  dinámicos mediante Weapon.try_fire** y munición real. Sus posiciones cambian al
  perseguir antes de morir. No congela ningún enemigo; las posiciones del jugador
  se preparan y E se introduce con eventos. Conserva inventario y permite continuar.
- Total automático: **1.161 comprobaciones**, cero fallos. Importación y arranque
  normal también se comprueban; no se inspeccionó el panel gráfico del depurador.

```text
godot --headless --path . --fixed-fps 60 --script res://tests/zombie_mobility_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/zombie_population_test.gd
godot --path . --fixed-fps 60 --script res://tests/zombie_mobility_test.gd -- --capture
godot --path . --fixed-fps 60 --script res://tests/zombie_population_test.gd
```

Tres capturas reales en test-results/population/ muestran persecución, ruta urbana
y persecución simultánea. La última se copia a docs/images/zombie-pursuit.png,
sin cambiar los sprites. test-results/, cachés y herramientas continúan ignorados.
Un error de inferencia de tipo en la nueva prueba se corrigió antes de validar.

## Rendimiento y límites de la medición

Muestra de 120 frames, mismo recorrido con tres perseguidores, audio real y
ventana normal **sin capturas**: TIME_PROCESS medio **14.08 ms con tres actores**
y **13.94 ms con seis**; máximo **122 llamadas de dibujo** en ambos casos,
**390 / 423 nodos** respectivamente. No se observó crecimiento de actores durante
la muestra. La diferencia pequeña no permite afirmar que seis sean más rápidos.

La ejecución que guarda PNG mide aproximadamente **40–41 ms** en esa muestra;
no se mezcla ese dato con la comparación sin capturas. Es monitor de proceso de
Godot, no tiempo exclusivo de CPU, garantía de 60 FPS ni benchmark de exportación
o equipos modestos. La prueba también limita los cadáveres a 18 y valida que
agotado el presupuesto no crezcan los actores. Balance y rendimiento prolongado
requieren una partida manual en el equipo de destino.

## Archivos y pendientes

Nuevos: scripts/enemies/zombie_population.gd y .uid; tests/fixtures/LegacyMain.tscn;
tests/zombie_mobility_test.gd, zombie_population_test.gd y sus .uid; este informe;
docs/images/zombie-pursuit.png con .import.

Modificados: scenes/Main.tscn, scripts/main.gd, scripts/missions/chapter_controller.gd;
solo la ruta de escena de las quince pruebas históricas que cargan Main;
README.md, AGENTS.md, docs/zombie_base_integration.md, docs/missions_radio.md y
docs/images/README.md. Se conservan los cambios no confirmados de la fase 8.

Pendiente manual: partida prolongada con seis enemigos, dificultad de las rutas
de misión, concentración de perseguidores (sin separación avanzada), escucha de
mezcla, otros tamaños de ventana, F5 interactivo/editor, depurador y exportación
Windows. No se declara balance final ni arte definitivo. Sin nuevos tipos,
estadísticas, mapa, armamento ni modificaciones de la campaña.
