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
  configuración reutilizable de armas; la pistola inicial conserva sus parámetros.
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
  La misma biblioteca conserva su ruta y añade walk_down con ocho PNG a 8 FPS.
  Al caminar, la dirección visual usa la velocidad; al parar conserva esa dirección
  hasta mover el mouse. Aim/disparos mantienen su comportamiento independiente.
  Actualización: el reposo conserva ahora la última dirección de marcha aunque
  se mueva el mouse. Idle real en cuatro direcciones; walk real down/up/right.
  Actualización V2: walk_left usa los PNG nuevos player_walk_left_*; walk_right
  conserva los anteriores en walk/legacy_right/. Idle/walk completos en cuatro
  direcciones. Validación: docs/walk_left_v2_validation.md. Mapa anterior:
  docs/player_directions_integration.md. No integrar los PNG con fondo gris.
  Visual combina bibliotecas parciales con el atlas provisional; solo animaciones
  presentes adoptan library_scale/offset y orientación fija salvo configuración.
  No aplicar el pivote frontal a walk/death provisionales ni modificar la física.

## Convenciones y reglas
- Fase 6.1: HUD conserva sus rutas/datos y mide 256 × 172 en reposo; Text oculto,
  SECTOR 04 discreto, Reload solo visible mientras recarga. Inventario: MOCHILA.
  Main/Audio usa GameAudio, AudioCatalog/TechnicalAudio y pools SoundEmitter;
  Zombie/Audio observa salud/cooldown sin cambiar IA. WAV sintéticos originales
  en assets/placeholders/audio/ (generador tools/generate_placeholder_audio.py).
  Sonidos solo por señales semánticas de resultados válidos; no parsear feedback.
  Una descarga de escopeta produce un sonido, no ocho; un contenedor no duplica
  apertura de mochila. Invalid/dry_fire/herida tienen límites solo sonoros, nunca
  alteran cooldown/daño. Lethal solo muerte, no herida adicional. No crear nodos
  por efecto. No reproducir ataque/recarga/vacío del jugador con UI o muerte.
  Headless verifica eventos sin iniciar voces del driver Dummy; probar mezcla real
  con tests/hud_audio_test.gd -- --capture en ventana. Ambiente -30 dB, loop copia
  del banco, pausado/volumen mediante GameAudio. Ver docs/hud_audio_polish.md.
- Fase 6: EquipmentComponent conserva Player/Weapon como pistola inicial activa;
  posee además machete y crea un Weapon por cada arma incorporada desde ItemUse.
  No duplicar instancias ni municiones. Equipment solo posee referencias a estados;
  loaded/reserve/cooldown/reload_remaining siguen en Weapon. Config es inmutable.
  Cambiar cancela recarga sin transferir balas; cooldown continúa incluso inactivo.
  Armas inactivas no atacan ni recargan. died deshabilita todo el arsenal.
  ItemDefinition añade efecto weapon, weapon_config y ammo_type (pistol por defecto).
  Incorporar consume el objeto; munición solo se usa si se posee su arma, aunque
  esté inactiva. No reflejar reservas en InventoryComponent ni cambiar capacidad 12.
  WeaponCombat selecciona hitscan, SpreadCombat o MeleeCombat. cast_hit reutiliza
  el único impacto por rayo; ocho rayos de escopeta consumen un cartucho y emiten
  un solo efecto. Machete consulta cono frontal y visibilidad World, deduplica
  enemigos y nunca dispara shot_fired/destellos. Daño solo via HealthComponent.
  WeaponVisual cambia textura y CharacterVisual.bind_weapon reconecta señales;
  no editar SpriteFrames para adaptar armas. Melee usa idle/walk y arco provisional.
  1/2/3/4 y rueda se bloquean con la mochila; mantener exigencia de soltar shoot.
  ArsenalSupplies.tscn reutiliza LootContainer y Areas 8 fuera de Obstacles.
  Ver docs/arsenal_equipment.md y tests/phase_six_test.gd. No autoriza RPG, crafting,
  comerciantes, persistencia ni multiplayer.
- Fase 5 autoriza inventario, cuatro suministros, tres contenedores finitos,
  hambre y sed. InventoryComponent guarda pilas por instancia; ItemDefinition es
  configuración compartida inmutable en resources/items/. ItemUse aplica efectos
  mediante HealthComponent.heal, SurvivalComponent.restore_need y Weapon.add_reserve.
  La munición en mochila son unidades aún sin transferir: nunca reflejar loaded
  o reserve en el inventario. Usar una pila de balas la retira y añade a reserve;
  no llena el cargador ni cambia la recarga/cadencia.
  Player/Interaction consulta Areas en capa 4 (8), radio 56 px y visibilidad World.
  Supplies está fuera de Obstacles: recogibles y pequeños contenedores son
  transitables y no alteran la malla. WorldPickup reserva la recogida antes de
  emitir señales; InventoryComponent transfiere ambos estados antes de notificar.
  SurvivalComponent empieza 100/100; descenso continuo 1/30 s y 1/20 s, HUD redondea
  hacia arriba. Un solo reloj de daño 2 HP/5 s si alguna necesidad está a cero.
  No dañar dos veces por hambre y sed ni revivir tras died. Main conecta señales.
  InventoryUI usa el tema existente y bloquea movimiento, aim, shoot, reload y E
  mediante Player.controls_blocked; mundo, necesidades y recarga iniciada siguen.
  Exigir soltar shoot tras cerrar para evitar clics accidentales. Muerte cierra
  la ventana; reload_current_scene restaura todos los estados por instancia.
  Ver docs/inventory_survival.md, tests/inventory_component_test.gd y phase_five_test.gd.
- Fase 4.5: World conserva dimensiones, límites, cinco cajas y apariciones. Añade
  23 sólidos urbanos en Obstacles mediante UrbanObstacle.tscn. Sus colisiones
  rectangulares están serializadas; urban_obstacle.gd solo dibuja desde esa huella.
  world_navigation.gd ya incluye todos los hijos de Obstacles: no duplicar geometría
  ni configurar colisiones tardíamente en _ready. ground.gd pinta superficies
  transitables; urban_details.gd dibuja cables aéreos. Ambient es CanvasModulate suave.
  Arte geométrico provisional, sin interiores; no ajustar personajes para acomodarlo.
  Pruebas: tests/urban_world_test.gd; informe: docs/urban_world_integration.md.
- Fase 4.4: Zombie/Visual usa zombie_visual.gd (subclase de CharacterVisual) y
  base/ZombieBaseFrames.tres, 96 PNG técnicos. Attack observa renovaciones del
  cooldown y no produce daño. Death termina dentro del fade existente de 0.45 s.
  No cambiar el controlador visual del protagonista para ajustes del zombi.
  Validación: tests/zombie_visual_test.gd; informe docs/zombie_base_integration.md.
- Fase 4.3: Player/Visual.action_library es PlayerActionAnimations.tres, separado
  de Idle/Walk. Reload lee progreso de Weapon tras reload_changed; no transfiere
  balas. Death se activa por died, no repite y conserva frame final. Shoot corregido
  se activa por shot_fired y usa cooldown/fire_interval reales para sus cuatro
  frames; no modifica el arma ni añade destello. Perfiles left/right corregidos
  solo en SpriteFrames. Ver docs/shoot_final_integration.md.
  Mapa de acciones up/right corregido y límites: docs/phase_4_3_actions.md.
- Escenas PascalCase, scripts snake_case, indentación GDScript con tabuladores.
- Acciones move_up/down/left/right: teclas físicas W/S/A/D.
- Acciones shoot y reload: clic izquierdo y tecla física R. Mantener clic permite
  disparos sucesivos respetando la cadencia; R inicia una única recarga.
- Capa física 1: World; capa 2: Player; capa 3: Zombie. Mantener máscaras explícitas.
  Player y Zombie colisionan con World. Los personajes no se bloquean entre sí.
- Mantener la velocidad diagonal normalizada y usar el motor físico para colisiones.
- Componer sistemas separados; no acumular combate, inventario o IA en player.gd.
- Fase 3 autoriza una pistola, apuntado, disparos, munición, recarga y estadísticas,
  además de los sistemas de fase 2. No añadir más armas, fabricación, progresión RPG, oleadas
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
   `godot --headless --path . --fixed-fps 60 --script res://tests/player_walk_down_test.gd`.
4. Revisar salida y depurador; documentar cualquier prueba que no se pueda ejecutar.
