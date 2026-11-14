# Fase 4.5 — primera zona urbana de Gualey

Validación: **13 de noviembre de 2026**, Godot 4.7.2 Stable oficial, Windows,
Compatibility/OpenGL. Composición técnica provisional, sin arte final nuevo.

## Resultado y alcance

World conserva sus 2400 × 1600, los límites, las cinco cajas originales y las
apariciones del jugador y los tres zombis. No cambian Main, Player, cámara, IA,
salud, armas, daño, HUD, animaciones ni configuración del juego.

Se añaden 23 obstáculos sólidos: 12 edificios (viviendas, colmado, taller,
ferretería y botica), tres carros, dos contenedores con bolsas dentro de su huella,
dos barricadas y cuatro postes. Total: **28 sólidos**, además del perímetro.
Las aceras y bordillos bajos son transitables; los edificios no tienen interiores
accesibles. Los cables son aéreos. Las señales son pintura y letreros sin
interacción. No se reproducen calles ni negocios reales.

## Arquitectura y ampliación

- `scenes/world/World.tscn`: composición declarativa, formas de colisión,
  decoración y CanvasModulate (0.92, 0.94, 0.91). HUD conserva su CanvasLayer.
- `scenes/world/UrbanObstacle.tscn`: escena reutilizable StaticBody2D con
  CollisionShape2D rectangular. Las instancias sobrescriben su forma en World.
- `scripts/world/urban_obstacle.gd`: dibuja edificios/props cenitales desde el
  tamaño de esa colisión. No crea ni cambia física. Apariencia, color y letrero
  se configuran por instancia.
- `scripts/world/ground.gd`: conserva texturas sustituibles de asfalto y restos;
  compone aceras, cruce, marcas, manchas y rótulo de evacuación. Sin colisiones.
- `scripts/world/urban_details.gd`: cables estáticos. Sus extremos deben seguir
  alineados con los postes al moverlos.
- `scripts/world/world_navigation.gd`: **sin modificaciones**. Recorre todos los
  hijos de Obstacles y deriva rectángulos con su transformación. Los nuevos
  cuerpos usan la misma región y el margen original de 20 px.

Serializar las formas antes del horneado, sin asignarlas tarde en `_ready`:
Navigation puede hornear antes de que ese hermano esté listo. Ampliar mediante
instancias en Obstacles, comprobando accesos, apariciones y rutas. Formas no
rectangulares requieren adaptar el generador, sin copiar contornos manualmente.
La arquitectura existente no necesita TileMapLayer ni otro renderizador/región.

## Recursos provisionales y sustituciones

Se reutilizan sin sobrescribir estos SVG originales:

- `assets/placeholders/environment/tilesets/temp_asphalt.svg`.
- `assets/placeholders/environment/props/temp_supply_crate.svg`.
- `assets/placeholders/environment/decals/temp_debris.svg`.

`assets/environment/` no contiene imágenes urbanas finales; solo documentación.
Los nuevos dibujos son geometría de Godot, sin paquetes ficticios, descargas ni
generación de imágenes por IA. No hay PNG urbanos nuevos con fondos incrustados.

Pendiente de arte: pavimento y aceras menos repetitivos, techos/fachadas cenitales,
tanques, carros, contenedores, bolsas, barricadas, postes, señalética, grietas y
manchas específicas. Guardar texturas en environment/tilesets, props y decals;
sustituir solo presentación, respetando huellas, posiciones y pasos transitables.
Las cajas militares grandes se conservan por compatibilidad. El subtítulo del
HUD sigue diciendo «DEPÓSITO EVACUADO»: no se modificó esa interfaz en esta fase.

## Pruebas automáticas

Importación con `--headless --path . --editor --import`: correcta, sin errores
ni advertencias en la validación final.

| Prueba | Comprobaciones | Fallos |
| --- | ---: | ---: |
| phase_one_test.gd | 21 | 0 |
| phase_two_test.gd | 42 | 0 |
| phase_three_test.gd | 49 | 0 |
| phase_four_test.gd | 34 | 0 |
| player_idle_down_test.gd | 13 | 0 |
| player_walk_down_test.gd | 19 | 0 |
| player_directions_test.gd | 52 | 0 |
| player_actions_test.gd | 48 | 0 |
| player_shoot_test.gd | 29 | 0 |
| zombie_visual_test.gd | 76 | 0 |
| urban_world_test.gd | 73 | 0 |
| **Total sin renderizado** | **456** | **0** |

La prueba urbana comprueba cuatro apariciones libres, exclusión de los 28 sólidos
de la malla con margen, rayos bloqueados por cada uno, cuatro sectores conectados,
colisión del jugador contra el colmado y un disparo que consume una bala sin dañar
al zombi tras el edificio. La IA original rodea el colmado y ataca al llegar:
exactamente 10 HP. Reiniciar restaura la zona. El radio ampliado de esa ruta solo
pertenece a la instancia de prueba. Su comprobación de contorno usa 1 px de
tolerancia en la huella expandida por el radio del cuerpo.

La regresión conserva los criterios anteriores: ocho direcciones, cámara, ruta
alrededor de CrateA, ataques bloqueados por World, cadencia, munición, recarga,
animaciones, bajas, muerte, Game Over y Reintentar.

## Pruebas gráficas y capturas

```text
godot --path . --fixed-fps 60 --script res://tests/phase_four_test.gd -- --capture
godot --path . --fixed-fps 60 --script res://tests/urban_world_test.gd -- --capture
```

La prueba gráfica general aprobó **39 comprobaciones**, cero fallos, cinco PNG en
`test-results/phase-four/`. La urbana aprobó **78 comprobaciones**, cero fallos,
cuatro PNG en `test-results/urban/`: calle inicial, ataque junto al colmado,
sector este y plano. Capturas reales inspeccionadas: actores y HUD visibles,
señales legibles y suelo/techos separados; sin halos urbanos nuevos observados.

El plano usa zoom 0.43 y HUD oculto solo en la prueba. El juego conserva cámara
y resolución originales. README renueva gameplay.png, combat.png y game-over.png
desde la prueba general; urban-plan.png procede del plano. Son PNG 1280 × 720
optimizados sin pérdida. No se modifican los recursos fuente.

Radeon RX 580, muestra de 120 frames a escala normal y sin VSync solo en la
ventana de prueba: monitor TIME_PROCESS medio **14.97 ms**, máximo **79 llamadas
de dibujo**, **128 nodos** sin crecimiento. No es tiempo exclusivo de CPU ni un
benchmark de FPS/exportación/equipos de gama baja. La decoración es estática,
sin luces dinámicas ni acumulación de nodos.

## Pendientes manuales y limitaciones

Sesión prolongada de exploración y combate, recorrido manual de todos los pasos,
revisión artística de densidad/perspectiva y rendimiento con VSync en el equipo
de destino. No se inspeccionó interactivamente el panel gráfico del depurador;
las ejecuciones finales no emitieron errores ni advertencias. No se probó una
exportación Windows. No hay fallos funcionales pendientes detectados en las
pruebas ejecutadas. No se crearon commits ni se publicaron cambios.

## Archivos de esta fase

Nuevos: `scenes/world/UrbanObstacle.tscn`, `scripts/world/urban_obstacle.gd`,
`scripts/world/urban_details.gd`, `tests/urban_world_test.gd`, sus tres `.uid`,
este informe y `docs/images/urban-plan.png` con su metadato `.import`.

Modificados: `scenes/world/World.tscn`, `scripts/world/ground.gd`, `AGENTS.md`,
`README.md`, `assets/README.md`, `assets/environment/props/README.md`,
`docs/images/README.md` y las tres capturas existentes de juego en docs/images.
Resultados y herramientas locales permanecen ignorados por Git.
