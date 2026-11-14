extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame
func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
func player_data(main: Node) -> Dictionary:
	var data := PlayerSaveState.capture(main.get_node("Player"))
	data.erase("position")
	return data
func travel(manager: Node, destination: String, entry: String) -> void:
	check(manager.request_travel(destination,entry), "Iniciar viaje a " + destination)
	await manager.transition_finished
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var manager := main.get_node("ZoneManager")
	check(not manager.request_travel(ZoneCatalog.MARKET,"from_gualey"), "Mercado bloqueado")
	var player := main.get_node("Player")
	var player_id: int = player.get_instance_id()
	var audio_id: int = main.get_node("Audio").get_instance_id()
	var saves := main.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-ten-zones-%d" % OS.get_process_id()
	var directory: String = saves.store.directory
	var original := saves.capture(3) as Dictionary
	# Archivo con el formato exacto anterior: sin zonas ni estadísticas globales.
	var legacy := original.duplicate(true)
	legacy.version = 1
	legacy.erase("zones")
	legacy.erase("stats")
	check(SaveSchema.validate(legacy).is_empty(), "v1 anterior sigue siendo válido")
	check(saves.store.write_slot(3,legacy).has("ok"), "Escribir fixture v1")
	var legacy_bytes := FileAccess.get_file_as_string(saves.store.path_for(3))
	var migrated: Dictionary = saves.store.read_slot(3)
	check(migrated.migrated and migrated.data.version == 2 and migrated.data.zones.is_empty(), "Migración explícita v1 → v2")
	check(FileAccess.get_file_as_string(saves.store.path_for(3)) == legacy_bytes, "Leer no sobrescribe archivo v1")
	await preload("res://tests/save_fixture.gd").build(self,main)
	# Terminar el capítulo mediante la radio existente; no se reescriben misiones.
	preload("res://tests/save_fixture.gd").close_windows(main)
	player.position = Vector2(600,680)
	await frames(2)
	main.get_node("Player/Interaction").try_interact()
	main.get_node("RadioUI").close_window()
	main.set_process(true)
	player.set_physics_process(true)
	player.get_node("SurvivalComponent").set_physics_process(true)
	main.get_node("Population").set_physics_process(true)
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(true)
	check(ZoneCatalog.MARKET in manager.unlocked, "Capítulo desbloquea mercado")
	check(main.get_node("World/ChapterPoints/MarketExit").available, "Salida se habilita")
	check(saves.save_slot(1).has("ok"), "Guardar zona 1 con capítulo terminado")
	var completed_v1: Dictionary = saves.capture(3)
	completed_v1.version = 1
	completed_v1.erase("zones")
	completed_v1.erase("stats")
	completed_v1.missions.unlocked_zones = []
	check(saves.store.write_slot(3,completed_v1,true).has("ok"), "v1 completado sin nuevo campo de desbloqueo")
	check(ZoneCatalog.MARKET in saves.store.read_slot(3).data.missions.unlocked_zones, "Migración deduce desbloqueo sin premiar")
	check(not manager.request_travel("unknown","initial") and not manager.request_travel(ZoneCatalog.MARKET,"invalid"), "Destino y entrada desconocidos rechazados")
	check(not main.get_node("World/ChapterPoints/MarketExit").try_activate(player.get_node("Interaction")), "E no viaja desde lejos")
	player.position = Vector2(2090,800)
	await frames(2)
	var before := player_data(main)
	var missions := MissionSaveState.capture(main)
	var old_world: WeakRef = weakref(main.get_node("World"))
	var old_zombie: WeakRef = weakref(main.get_node("Zombies/ZombieC"))
	await key(KEY_E)
	check(manager.busy and paused and player.controls_blocked, "E inicia fundido con pausa y bloqueo")
	check(saves.save_slot(1,true).has("error") and saves.load_slot(1).has("error"), "No guardar/cargar durante transición")
	check(not manager.request_travel(ZoneCatalog.MARKET,"from_gualey"), "No dos viajes")
	Input.action_press("shoot")
	Input.action_press("move_right")
	await key(KEY_ESCAPE)
	check(not main.get_node("PauseUI").window.visible, "Esc no interrumpe fundido")
	check(main.get_children().filter(func(node): return node.name == "Player").size() == 1, "Un solo jugador durante fundido")
	await manager.transition_finished
	Input.action_release("shoot")
	Input.action_release("move_right")
	check(manager.current_zone == ZoneCatalog.MARKET, "Carga mercado")
	check(main.get_node("Player").position == Vector2(320,800), "Entrada segura")
	check(main.get_node("Player").get_instance_id() == player_id and main.get_node("Audio").get_instance_id() == audio_id, "Jugador y audio conservan identidad")
	check(player_data(main) == before, "Salud, necesidades, RPG, pilas, armas y cooldown sin cambios durante viaje")
	check(MissionSaveState.capture(main) == missions, "Misiones y radio globales sin cambios")
	check(old_world.get_ref() == null and old_zombie.get_ref() == null, "Mapa y enemigos anteriores liberados")
	check(main.get_node("Population").active_enemies().size() == 6, "Seis vivos antes de continuar")
	check(manager.states[ZoneCatalog.HOME].population.spawned == 7 and manager.states[ZoneCatalog.HOME].kills == 3, "Presupuesto original guardado aparte")
	await frames(8)
	check(main.get_node("Population").active_enemies().size() == 6, "Población del mercado")
	# Nueva XP e interacción propia, sin reutilizar recibos de la primera zona.
	var xp_before: int = player.get_node("ProgressionComponent").total_xp()
	main.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
	main.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
	check(player.get_node("ProgressionComponent").total_xp() == xp_before + 30 and main.kills == 4, "Baja del mercado entrega treinta XP una vez")
	player.position = Vector2(580,830)
	await frames(2)
	player.get_node("Interaction").try_interact()
	check(SaveCatalog.find(main.get_node("World"),"market_water") == null or SaveCatalog.find(main.get_node("World"),"market_water").claimed, "Agua del mercado recogida")
	player.position = Vector2(530,1215)
	await frames(2)
	player.get_node("Interaction").try_interact()
	var medical: Node = SaveCatalog.find(main.get_node("World"),"market_medical")
	check(player.get_node("Interaction").transfer_from_container(medical,0), "Botiquines transferidos del mercado")
	main.get_node("InventoryUI").close_window()
	var market_world := WorldSaveState.capture(main)
	check(market_world.kills == 1 and market_world.rewarded_containers == ["market_medical"], "Recompensas separadas por zona")
	check(saves.save_slot(2).has("ok"), "Guardar zona 2")
	var market_slot := saves.capture(2) as Dictionary
	check(SaveSchema.validate(market_slot).is_empty() and market_slot.stats.kills == 4, "Guardado v2 con ambas zonas y bajas globales")
	var malformed := market_slot.duplicate(true)
	malformed.zones[ZoneCatalog.MARKET] = malformed.world
	check(not SaveSchema.validate(malformed).is_empty(), "Rechaza mapa activo duplicado en caché")
	malformed = market_slot.duplicate(true)
	malformed.missions.unlocked_zones = []
	check(not SaveSchema.validate(malformed).is_empty(), "Rechaza zona visitada sin desbloquear")
	before = player_data(main)
	await travel(manager,ZoneCatalog.HOME,"from_market")
	check(player_data(main) == before, "Regreso conserva al protagonista")
	check(main.kills == 4 and main.get_node("Population").total_spawned == 7 and main.get_node("Population").active_enemies().size() == 4, "Conserva bajas globales y presupuesto original")
	check(SaveCatalog.find(main.get_node("World"),"pickup_water") == null and SaveCatalog.find(main.get_node("World"),"medical_case").inventory.get_slot(0).is_empty(), "No renacen suministros originales")
	check(manager.states[ZoneCatalog.MARKET].pickups.market_water == false, "Mercado inactivo guarda recogida")
	var home_death_connections: int = player.health.get_signal_connection_list("died").size()
	var home_nodes: int = main.get_node("Zombies").get_child_count()
	# Repetir viajes sin avanzar física: no recarga poblaciones ni duplica señales.
	for index in range(3):
		before = player_data(main)
		await travel(manager,ZoneCatalog.MARKET,"from_gualey")
		check(player_data(main) == before and main.kills == 4, "Ida repetida conserva progreso")
		check(SaveCatalog.find(main.get_node("World"),"market_water") == null and SaveCatalog.find(main.get_node("World"),"market_medical").inventory.get_slot(0).is_empty(), "Mercado conserva recursos agotados")
		check(main.get_node("Population").total_spawned == 6 and main.get_node("Population").active_enemies().size() == 5, "Mercado conserva presupuesto y cadáver")
		await travel(manager,ZoneCatalog.HOME,"from_market")
		check(player.health.get_signal_connection_list("died").size() == home_death_connections and main.get_node("Zombies").get_child_count() == home_nodes, "Sin conexiones ni enemigos huérfanos")
		check(main.get_node("Player").get_instance_id() == player_id and main.get_node("Audio").get_instance_id() == audio_id, "No duplica jugador ni reproductores globales")
	# Cargar directamente el mercado desde la zona inicial.
	check(saves.load_slot(2).has("ok"), "Carga directa de ranura del mercado")
	main = current_scene
	manager = main.get_node("ZoneManager")
	player = main.get_node("Player")
	saves = main.get_node("SaveCoordinator")
	check(manager.current_zone == ZoneCatalog.MARKET and main.kills == 4, "Restaura mapa correcto y contador global")
	check(manager.states.has(ZoneCatalog.HOME) and not manager.states[ZoneCatalog.HOME].pickups.pickup_water, "Restaura zona original inactiva")
	check(main.get_node("Population").total_spawned == 6 and SaveCatalog.find(main.get_node("World"),"market_water") == null, "No duplica población/recogidas al cargar")
	await travel(manager,ZoneCatalog.HOME,"from_market")
	check(main.get_node("Population").total_spawned == 7 and main.kills == 4, "Regresa tras cargar sin perder presupuesto")
	check(saves.load_slot(3).get("migrated",false), "Cargar partida v1 completada")
	main = current_scene
	manager = main.get_node("ZoneManager")
	check(manager.current_zone == ZoneCatalog.HOME and ZoneCatalog.MARKET in manager.unlocked and main.kills == 3, "v1 mantiene progreso y permite salir")
	await frames(8)
	main.get_node("Player/HealthComponent").take_damage(1000)
	check(not manager.request_travel(ZoneCatalog.MARKET,"from_gualey"), "Game Over impide viajes")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("ZoneManager").current_zone == ZoneCatalog.HOME and current_scene.get_node("ZoneManager").states.is_empty() and current_scene.get_node("ZoneManager").unlocked.is_empty(), "Reintentar restaura primera zona y bloqueo")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado zonas: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
