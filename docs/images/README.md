# Imágenes del README

Actualización fase 4.4: zombie-base.png compone fotogramas reales del paquete
técnico (Idle 00, Walk 02, Attack 03, Death 05), en down/up/left/right.
No sustituye el arte fuente ni representa arte definitivo. Se añade a las cuatro
imágenes iniciales descritas abajo.

No son portadas ni arte nuevo. Son capturas y una composición de recursos reales
del proyecto, preparadas para documentación el 12 de noviembre de 2026.

| Archivo | Fuente | Preparación |
| --- | --- | --- |
| gameplay.png | test-results/phase-four/01-overview.png | Captura actual de Main |
| combat.png | test-results/phase-four/02-combat.png | Combate/impacto y salud |
| game-over.png | test-results/phase-four/05-game-over.png | Panel de muerte real |
| player-animations.png | PNG down de idle/shoot/reload/death y walk_left V2 | Composición en orden, escala nativa |

Las capturas se generaron ejecutando la prueba phase_four_test.gd con renderizado
OpenGL real y --capture: 39 comprobaciones aprobadas. La prueba coloca personajes
y activa acciones para inspección. La lámina usa las fuentes actuales referenciadas
en SpriteFrames: 4, 8, 4, 6 y 6 frames respectivamente. No se usaron drafts,
sprites descartados, recursos externos ni imágenes generadas para esta página.

PNG optimizados sin pérdida de detalle; capturas de 1280 × 720 y lámina de
1024 × 800. Solo estas cuatro imágenes se distribuyen con la documentación.
Los originales permanecen intactos en assets/ y test-results/. La caminata V2 se
eligió frente a las previsualizaciones históricas con restos de bordes o fondos.

Validación documental: 17 rutas relativas comprobadas en el README principal y
7 enlaces del historial, todos existentes; cuatro imágenes sin duplicados y tres
tablas renderizadas con soporte GFM. Vista previa local revisada en un navegador
headless, con ancho similar a GitHub y sin desbordamiento horizontal. No se publicó
en GitHub ni se verificó una página remota. Solo se modificó documentación.
