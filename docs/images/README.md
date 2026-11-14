# Imágenes del README

Capturas reales y composiciones de recursos del proyecto. No son portadas ni
arte final. No se usaron recursos externos, drafts descartados ni imágenes
conceptuales para representar funcionalidades.

| Archivo | Fuente | Fecha y preparación |
| --- | --- | --- |
| save-slots.png | test-results/save/01-slots.png | 2026-11-14, tres ranuras con partida rica en estado y ranura inicial de fixture |
| zombie-pursuit.png | test-results/population/03-simultaneous.png | 2026-11-14, tres perseguidores con IA activa dentro de población de seis |
| missions.png | test-results/phase-eight/02-missions.png | 2026-11-14, diario con misión 3 activa e historial de las dos primeras |
| radio.png | test-results/phase-eight/01-radio.png | 2026-11-14, primer mensaje textual, sin doblaje |
| gameplay.png | test-results/phase-four/01-overview.png | 2026-11-14, fase 7: zona urbana y HUD con NIV/XP |
| combat.png | test-results/phase-four/02-combat.png | 2026-11-14, fase 7: pistola y HUD actual |
| game-over.png | test-results/phase-four/05-game-over.png | 2026-11-14, fase 7: panel de muerte real |
| character.png | test-results/phase-seven/01-character.png | 2026-11-14, PERSONAJE en nivel 2 con 130 XP útiles y un punto disponible |
| arsenal-shotgun.png | test-results/phase-six/05-shotgun.png | Renovada en fase 6.1, ocho rayos bloqueados por caja |
| arsenal-inventory.png | test-results/phase-six/03-acquisition.png | Renovada en fase 6.1, arma recogida en MOCHILA |
| arsenal-machete.png | test-results/phase-six/02-machete.png | Renovada en fase 6.1, ataque frontal y HUD compacto |
| inventory.png | test-results/phase-five/02-inventory.png | Renovada en fase 6.1, título neutro MOCHILA y 12 espacios |
| loot-container.png | test-results/phase-five/03-container.png | Renovada en fase 6.1, contenido finito de mochila abandonada |
| urban-plan.png | test-results/urban/04-plan.png | 2026-11-13, plano completo, zoom 0.43 y HUD oculto solo en la prueba |
| player-animations.png | PNG down de idle/shoot/reload/death y walk_left V2 | 2026-11-12, composición en orden, escala nativa |
| zombie-base.png | PNG de Idle 00, Walk 02, Attack 03 y Death 05 | Fase 4.4, down/up/left/right del paquete técnico |

Las catorce capturas son PNG 1280 × 720 optimizados sin pérdida. La lámina del
protagonista mide 1024 × 800; la del zombi, 512 × 624. Las fuentes permanecen en
assets/ y los resultados de pruebas en test-results/ (ignorado).

En fase 5 la prueba gráfica general aprobó 39 comprobaciones y produjo cinco
capturas; la de supervivencia aprobó 80 y produjo cuatro. El plano conserva la
captura de fase 4.5 (prueba urbana: 78 comprobaciones). Solo se conservan aquí las
imágenes necesarias para documentación. Las pruebas preparan posiciones y acciones;
no son capturas de una sesión manual. El plano no cambia la cámara del juego.
[Validación y límites](../urban_world_integration.md).
[Inventario y supervivencia](../inventory_survival.md).

Fase 6: regresión gráfica general repetida, 39 comprobaciones y cinco capturas;
arsenal, 107 comprobaciones y seis capturas. Las tres imágenes principales muestran
el HUD de esa fase; sus fuentes se renuevan ahora como se indica en la tabla.
[Pruebas, fuentes y limitaciones del arsenal](../arsenal_equipment.md).

Fase 6.1 renueva ocho capturas existentes para mostrar HUD compacto y MOCHILA:
39 comprobaciones gráficas generales, 80 de inventario y 107 de arsenal, sin fallos.
La prueba nueva de HUD/audio aprueba 99, produce dos PNG adicionales solo en
test-results/ y graba una mezcla WAV real, sin añadir imágenes duplicadas aquí.
[Validación de HUD y audio](../hud_audio_polish.md).

Fase 7 añade PERSONAJE desde una ejecución real de Godot y renueva las tres
capturas principales con NIV/XP. Su prueba gráfica aprueba 90 comprobaciones y
la regresión general, 39. Las bajas/aperturas se preparan por fixtures, no por
una sesión manual. La captura de nivel 2 usa tres bajas y dos contenedores; no
representa niveles altos alcanzables con el contenido actual. El resto de la
galería conserva las capturas históricas de sus fases.
[Recompensas, límites y pruebas](../progression_skills.md).

Fase 8 añade diario y radio desde el recorrido automatizado del capítulo:
126 comprobaciones gráficas, cuatro PNG en resultados, dos seleccionados aquí.
El jugador camina mediante entrada y física reales; enemigos inmóviles en esta
fixture para aislar objetivos. La galería previa conserva sus capturas históricas;
el indicador actual de misión se comprueba en 00-objective.png, solo en resultados.
[Recorrido, recompensas y límites de la validación](../missions_radio.md).

Fase 8.1 añade persecución real, sin congelar enemigos: posiciones preparadas
en Main, física, navegación y animaciones activas. [Movilidad, población y límites](../zombie_population.md).

Fase 9 añade el menú de partidas desde su prueba gráfica: 114 comprobaciones,
dos capturas reales; la confirmación queda solo en resultados para no duplicar
la galería. La fixture prepara objetos/XP/posiciones y refresca el HUD antes de
pausar. [Formato, integridad, reapertura y límites](../save_load.md).
