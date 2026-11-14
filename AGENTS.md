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
- Fase 11: ZombieArchetype configura Common/Runner/Resistant en resources/enemies/;
  Resource inmutable, valores por instancia aplicados en _enter_tree antes de hijos.
  Conservar una sola IA/escena y flujo de salud/daño/muerte. XP 30/45/60 por tipo,
  deduplicada por ID. No producir daño desde visual/audio ni duplicar bajas.
  ZoneDefinition.enemy_weights: Home solo base; Market 60/30/10. ZombieArchetypes
  reparte cuotas por ordinal (primeros seis 3/2/1, total18 11/5/2). Mantener un
  generador, seis vivos, presupuesto18 e intervalo10s. No convertir tipos guardados.
  JSON v2 mantiene type con catálogo seguro base/runner/resistant y HP por tipo;
  v1 solo base. Conservar identidad, heridas, cadáveres y presupuesto por zona.
  Visual conserva pivote/escala, walk usa velocidad real/105; tintes/aros técnicos.
  Audio conserva tres voces por enemigo, pitch/ganancia por instancia sin editar
  bancos compartidos. Ver docs/zombie_archetypes.md y tests/archetypes_*_test.gd.
- Fase 10 autoriza dos zonas: ZoneDefinition/ZoneCatalog en resources/zones/ y
  Main/ZoneManager. Gualey conserva World.tscn; MarketWorld.tscn reutiliza UrbanObstacle
  y world_navigation, sin cambiar IA/armas/RPG. E en ZoneExit usa la interacción
  existente; mercado se desbloquea con broadcast. Viajar conserva el MISMO Player,
  componentes y audio global; cambiar solo World y actores de Zombies. Mantener
  World en índice 0 para no tapar personajes. Reenlazar puntos de ChapterController.
  InterfaceCoordinator controla pausa de transición; ZoneOverlay procesa fundidos
  durante pausa. Bloquear viaje concurrente, Esc, guardar/cargar y combate hasta
  terminar. No avanzar relojes ni daño durante fundido; exigir soltar shoot al volver.
  Cada zona conserva su WorldSaveState inactivo como datos, nunca nodos procesando.
  Población 6/18/10s por definición; prefijo market_zombie_ evita colisiones de IDs.
  Bajas/tiempo globales siguen en Main; bajas locales derivan de cadáveres del mapa.
  Save v2 mantiene world activo, zones inactivos y stats globales; no duplicar mapa
  activo en caché. SaveMigration adapta v1 en memoria, sin reescribir al leer ni
  volver a premiar; broadcast completada deduce desbloqueo. Catálogo confiable,
  validación y rutas de archivo de Fase 9 se reutilizan. No aceptar escenas del JSON.
  Tests nuevos usan user://tests/phase-ten-*; no tocar partidas normales. Máximo
  actual de contenido completo: 1.390 XP, nivel 7, seis puntos. Ver docs/zones_transitions.md.
- Fase 9 autoriza persistencia local: SaveCoordinator/SaveSchema/SaveFileStore y
  adaptadores PlayerSaveState, MissionSaveState, WorldSaveState en scripts/save/.
  user://saves/slot_1..3.json, v1, JSON puro, catálogo de IDs confiables; nunca
  cargar rutas/scripts/recursos procedentes del JSON. Confirmar sobrescritura.
  Temporal validado → respaldo → commit; recuperar .bak, ignorar .tmp huérfano.
  Validar estructura, rangos y coherencia completa antes de reconstruir candidato.
  Reemplazar Main solo tras validar ese candidato: sin población/ambiente/region
  activos durante preparación ni eventos de recompensa. No restaurar sobre la
  partida actual a medias. Cargar cancela recarga sin mover balas, conserva cooldown.
  Recalcular modificadores desde bases/rangos; no acumular ni curar al restaurar.
  metadata/persistence_id identifica mundo y semillas; dinámicos zombie_04..18.
  Conservar IDs al renombrar nodos. Recibos/XP usan IDs estables, no instance_id
  persistido. Adapta formato/esquema/versión y pruebas si cambian estados internos.
  Esc cierra primero las otras cuatro ventanas y después abre PauseUI. Solo
  InterfaceCoordinator controla tree.paused y bloqueo. PauseUI/SaveCoordinator
  procesan mientras pausa; el mundo y temporizadores se congelan. Game Over deja
  cargar, rechaza guardar. Reintentar no borra ranuras. Exigir soltar shoot al volver.
  Autoguardado opt-in desactivado por defecto, slot 0/archivo separado, diferido
  tras misiones; no ejecutar durante muerte, pausa, restauración o estado incompleto.
  Tests escriben solo user://tests/phase-nine-*, nunca las partidas del jugador.
  Ver docs/save_load.md y save_integrity_test/save_load_test/save_restart_test.gd.
- Fase 8.1 autoriza población limitada: Main/Population (zombie_population.gd),
  6 vivos, presupuesto 18 incluyendo los tres originales, reposición 1/10 s.
  Único gestor: valida malla/ruta, círculo World/Player/Zombie, distancia 320,
  cámara +96 px, separación 96 de vivos y misión. Posponer si no hay punto seguro.
  Reservar presupuesto y registro antes de notificar spawned. Game Over detiene;
  Reintentar restaura seis y presupuesto. Cadáveres conservados: máximo 18 nodos.
  Main._register_zombie conecta objetivo/bajas/XP, emite zombie_added; Chapter
  observa también nuevos enemigos después del contador existente. No duplicar XP.
  IA original intacta: detección 250, inicio más cercano 400 px, Idle esperado.
  No confundir fixtures congeladas con partida normal. No ampliar detección ni
  reescribir IA para justificar movimiento. Movilidad real usa Main de producción.
  LegacyMain.tscn hereda Main y configura 3/3 solo para fixtures históricas;
  no detectar tests desde scripts de juego ni desactivar IA de producción.
  Presupuesto completo: 790 XP, nivel 5, cuatro puntos. Ver docs/zombie_population.md
  y tests/zombie_mobility_test.gd / zombie_population_test.gd.
- Fase 8 autoriza tres misiones y radio textual, sin nuevos mapas/armas/zombis.
  MissionDefinition/MissionObjective son configuración inmutable en resources/missions/;
  MissionTracker conserva estados/progreso/recibos por instancia. MissionRewards
  reserva IDs antes de add_xp (25/50/75), sin cambiar los 30/20 XP anteriores.
  ChapterController adapta La señal perdida: observa Main.kills después de su
  actualización, y supply_recovered(item, receipt) solo tras recogida/transferencia
  válida. No contar inventario inicial, apertura sola, fallo o consumo como recogida.
  Recibos por pickup o compartimento finito; no reponerlos durante la partida.
  Recogidas/bajas anteriores cuentan; generador/transmisión exigen estado y orden.
  World/ChapterPoints contiene Areas transitables, capa 8/máscara 0, fuera de
  Obstacles. Reutilizar alcance 56 y rayo World de Player/Interaction, sin otro
  sistema de entrada. No cambiar sólidos, malla ni apariciones para esta historia.
  J abre MISIONES; E avanza RADIO. InterfaceCoordinator es la única fuente del
  bloqueo y exclusión de las cuatro ventanas. Mundo activo y soltar shoot al cerrar.
  ObjectiveHUD independiente; HUD principal mantiene 256×172. RadioController usa
  RadioTransmission configurable y un aviso ui_select por mensaje, sin voces nuevas.
  Muerte bloquea progreso/radio y cierra ventanas; Reintentar restaura todo.
  Completar no termina la partida. Mapa + capítulo: 340 XP, nivel 3, dos puntos.
  Ver docs/missions_radio.md y mission_tracker_test.gd / phase_eight_test.gd.
- Fase 7 autoriza XP/niveles y cuatro habilidades por partida. ProgressionComponent
  conserva nivel/XP actual/puntos; ProgressionRewards concede 30 por zombi y 20
  por primer contenedor con suministros, deduplicando instance_id antes de notificar.
  No añadir XP pasiva por tiempo sin definir tasa. El mapa ofrece 190 XP (nivel 2);
  el máximo 10 queda probado para contenido futuro. Fase 8 autoriza misiones y Fase 8.1 reposición finita.
  SkillsComponent guarda rangos 0..5 y consume puntos con bloqueo de reentrada.
  CharacterStats calcula desde bases: Health.base_max_health + 5/rango (sin curar),
  Player.speed * (1 + .03/rango), recarga * (1 - .04/rango), consumo * (1 - .05/rango).
  No modificar recursos WeaponConfig ni intervalos base de supervivencia. Weapon
  mantiene reload_duration_current; cambios de factor conservan progreso y Visual
  usa esa duración real. Armas nuevas heredan el factor; machete queda excluido.
  K abre PERSONAJE. InterfaceCoordinator gestiona exclusión con InventoryUI y es
  la única conexión de ventanas al bloqueo de Player; no desbloquear al cerrar una
  ventana si otra sigue visible. Death cierra ventanas y bloquea XP/compras. HUD
  usa la línea Sector para NIV/XP sin agrandar panel. Se reutilizan sonidos de UI.
  Snapshots son datos independientes, sin persistencia; Reintentar restaura todo.
  Ver docs/progression_skills.md, progression_component_test.gd y phase_seven_test.gd.
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
