# Última Frecuencia: Gualey — guía para agentes

## Entorno
- Motor objetivo: Godot 4.7.2 Stable, GDScript, Windows.
- Nombre visible oficial: Última Frecuencia: Gualey. No renombrar rutas internas
  para aplicar branding. `deadzone` del InputMap es un parámetro de Godot, no marca.
- Abrir `project.godot`; ejecutar `scenes/Main.tscn` con F6 o el proyecto con F5.
- Resolución base 1280 × 720, stretch canvas_items, renderizador Compatibility.

## Arquitectura
- `scenes/Main.tscn`: composición de escenario, jugador e interfaz.
- `scenes/player/Player.tscn`: CharacterBody2D, colisión circular y cámara hija.
- `scripts/player/player.gd`: locomoción con Input.get_vector y move_and_slide,
  lectura de entrada de combate y orientación hacia el mouse; delega en Weapon.
- `scenes/world/World.tscn`: escenario 2400 × 1600, límites y obstáculos estáticos.
- `scenes/world/Obstacle.tscn`: obstáculo reutilizable con visual y colisión.
- `scripts/world/ground.gd`: dibujo provisional del suelo.
- `interfaces/`: interfaces en CanvasLayer, independientes del mundo.
- `resources/`: recursos compartidos futuros; sin dependencias externas.
- `tests/`: validaciones de integración ejecutables en Godot sin plugins.
- `scripts/components/health_component.gd`: salud compartida, señales health_changed y died.
- `scenes/enemies/Zombie.tscn`, `scripts/enemies/zombie.gd`: IA IDLE/CHASE/ATTACK/DEAD,
  NavigationAgent2D y cooldown por enemigo. Parámetros editables en inspector.
- `scripts/world/world_navigation.gd`: NavigationRegion2D genera malla al iniciar desde
  las colisiones de las cajas, margen de 20 px para cuerpos de radio 16 px.
- `scripts/main.gd`: conecta salud, HUD, objetivos de zombis y recarga de partida.
- `scripts/ui/hud.gd`: presentación de salud y Game Over; emite retry_requested.
- `scripts/weapons/weapon_config.gd`, `resources/weapons/BasicPistol.tres`:
  configuración reutilizable de la única arma actual.
- `scripts/weapons/weapon.gd`: estado por instancia de munición, cadencia y recarga;
  emite ammo_changed, reload_changed y shot_fired. No hace consultas físicas.
- `scripts/combat/hitscan_combat.gd`: un rayo World/Zombie, daño mediante
  HealthComponent y trazo provisional anclado al mundo.
- Main también coordina tiempo de supervivencia y bajas mediante eliminated.
- Fase 4 añade `assets/` para arte provisional modular (ver `assets/README.md`).
- Fase 4.1 separa `assets/placeholders/` del arte final en las carpetas modulares.
  El generador solo escribe placeholders. Visual acepta animation_library (SpriteFrames)
  final o sheet temporal; Ground y Effects exponen texturas sustituibles en inspector.
- `scripts/visuals/character_visual.gd`: capa desacoplada, observa el actor y salud;
  genera SpriteFrames para idle/walk/attack/death y cuatro direcciones con atlas
  cenital rotado. No lee entrada directamente ni modifica gameplay.
- `scripts/visuals/combat_effects.gd`: escucha visual_shot del Combat; destello y
  partículas opcionales con duración limitada. Combat sigue resolviendo el único rayo.
- `assets/ui/SurvivalTheme.tres`: tema del HUD y Game Over existentes.
- Fase 4.2: Player usa idle/PlayerIdleDown.tres con cuatro PNG reales a 4 FPS.
  Visual combina bibliotecas parciales con el atlas provisional; solo animaciones
  presentes adoptan library_scale/offset y orientación fija salvo configuración.
  No aplicar el pivote frontal a walk/death provisionales ni modificar la física.

## Convenciones y reglas
- Escenas PascalCase, scripts snake_case, indentación GDScript con tabuladores.
- Acciones move_up/down/left/right: teclas físicas W/S/A/D.
- Acciones shoot y reload: clic izquierdo y tecla física R. Mantener clic permite
  disparos sucesivos respetando la cadencia; R inicia una única recarga.
- Capa física 1: World; capa 2: Player; capa 3: Zombie. Mantener máscaras explícitas.
  Player y Zombie colisionan con World. Los personajes no se bloquean entre sí.
- Mantener la velocidad diagonal normalizada y usar el motor físico para colisiones.
- Componer sistemas separados; no acumular combate, inventario o IA en player.gd.
- Fase 3 autoriza una pistola, apuntado, disparos, munición, recarga y estadísticas,
  además de los sistemas de fase 2. No añadir más armas, inventario, oleadas
  ni aparición infinita de enemigos sin nueva solicitud.
- No modificar WeaponConfig durante una partida: los recursos pueden compartirse;
  el estado mutable de cada arma pertenece exclusivamente a su nodo Weapon.
- Fase 4 es visual: no cambiar estadísticas, navegación, cámara, daño ni tiempos
  para ajustar animaciones. Mantener el contrato de los atlas en assets/README.md.
- Efectos/animaciones no producen eventos de daño. Solo reaccionan a estado/señales.
- Conservar `.svg.import` (metadatos de importación), nunca `.godot/imported/`.
- Los disparos se resuelven desde el centro del jugador (evita disparar al otro
  lado de una pared con el cañón), máscara World | Zombie (5), un impacto máximo.
- La señal died deshabilita el arma y cancela recarga sin transferir munición.
- El zombi emite eliminated una sola vez desde died. Cadáveres quedan desactivados,
  con colisiones diferidas deshabilitadas y efecto de desvanecimiento; se restauran
  con reload_current_scene. No duplicar lógica de salud ni de bajas.
- La cadencia pertenece al atacante; la salud no impone invulnerabilidad global.
  Cada zombi puede causar 10 HP cada 1.5 s; varios zombis tienen intervalos propios.
- No permitir ataques a través de World ni perseguir personajes muertos.
- No duplicar la geometría de cajas en la navegación; derivarla de sus colisiones.
- Si cambian formas de obstáculos o tamaño de mundo, adaptar world_navigation.gd.
- Preservar funcionalidades existentes y evitar plugins innecesarios.
- No versionar `.godot/`, binarios, credenciales ni resultados de pruebas.
- Sí versionar archivos `.uid` generados por Godot para scripts.

## Validación
1. `godot --headless --path . --editor --import` para importar y comprobar scripts.
2. `godot --headless --path . --script res://tests/phase_one_test.gd`.
   `godot --headless --path . --fixed-fps 60 --script res://tests/phase_two_test.gd`.
   `godot --headless --path . --fixed-fps 60 --script res://tests/phase_three_test.gd`.
   `godot --headless --path . --fixed-fps 60 --script res://tests/phase_four_test.gd`.
   Para capturas reales: `godot --path . --fixed-fps 60 --script res://tests/phase_four_test.gd -- --capture`.
   Guarda PNG en `test-results/phase-four/` (ignorado); inspeccionarlos visualmente.
3. `godot --path .` para comprobar imagen y WASD en ventana.
   `godot --headless --path . --fixed-fps 60 --script res://tests/player_idle_down_test.gd`.
4. Revisar salida y depurador; documentar cualquier prueba que no se pueda ejecutar.
