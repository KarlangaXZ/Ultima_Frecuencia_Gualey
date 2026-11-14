extends SceneTree
## Recorrido mediante Input y física real; enemigos inmóviles solo en esta fixture.
var checks := 0
var failures := 0
var walked := 0.0
var completed_events := 0
var receipt := ""

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
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func walk_to(player: CharacterBody2D, target: Vector2) -> void:
	print("Ruta: ", player.position, " → ", target)
	var path := NavigationServer2D.map_get_path(player.get_world_2d().navigation_map, player.position, target, true)
	check(path.size() > 0 and path[-1].distance_to(target) < 3, "Destino conectado " + str(target))
	for waypoint in path:
		var ticks := 0
		while player.position.distance_to(waypoint) > 5 and ticks < 900:
			var direction := player.position.direction_to(waypoint)
			Input.action_press("move_right", maxf(0, direction.x))
			Input.action_press("move_left", maxf(0, -direction.x))
			Input.action_press("move_down", maxf(0, direction.y))
			Input.action_press("move_up", maxf(0, -direction.y))
			var previous := player.position
			await frames(1)
			walked += previous.distance_to(player.position)
			ticks += 1
		for action in ["move_up", "move_down", "move_left", "move_right"]: Input.action_release(action)
		await frames(1)
		if ticks >= 900: break
	check(player.position.distance_to(target) < 8, "Llegada física " + str(target))

func shoot_enemy(player: Node, zombie: Node, from: Vector2) -> void:
	await walk_to(player, from)
	var ammo: int = player.weapon.loaded
	for index in range(2):
		check(player.weapon.try_fire(player.position, player.position.direction_to(zombie.position)), "Disparo real")
		await frames(19)
	check(zombie.health.is_dead() and player.weapon.loaded == ammo - 2, "Baja real con dos balas")

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-eight")
	check(root.get_texture().get_image().save_png("res://test-results/phase-eight/" + label + ".png") == OK, "Captura " + label)

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	point = root.get_screen_transform() * point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var interaction := player.get_node("Interaction")
	var tracker := main.get_node("Missions") as MissionTracker
	var rewards := main.get_node("Missions/Rewards")
	var progression := player.get_node("ProgressionComponent") as ProgressionComponent
	var journal := main.get_node("MissionUI")
	var radio_ui := main.get_node("RadioUI")
	var radio := main.get_node("Radio")
	var inventory_ui := main.get_node("InventoryUI")
	var character := main.get_node("CharacterUI")
	var radio_point := main.get_node("World/ChapterPoints/Radio") as MissionPoint
	var generator := main.get_node("World/ChapterPoints/Generator") as MissionPoint
	var audio := main.get_node("Audio")
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
	tracker.mission_completed.connect(func(mission: MissionDefinition):
		completed_events += 1
		check(not rewards.award(mission), "Recompensa ya reservada antes de otros observadores"))
	interaction.supply_recovered.connect(func(_item: ItemDefinition, token: String): receipt = token)
	check(tracker.definitions.size() == 3 and tracker.active_mission().id == &"signal", "Tres misiones, inicio correcto")
	check(progression.total_xp() == 0 and main.kills == 0, "XP y bajas iniciales intactas")
	check(InputMap.action_get_events("missions")[0].physical_keycode == KEY_J, "J físico")
	check(main.get_node("World/Obstacles").get_child_count() == 28 and main.get_node("Zombies").get_child_count() == 3, "Mundo y enemigos conservados")
	check(main.get_node("HUD/Panel").size == Vector2(256,172), "HUD principal no crece")
	var objective_panel := main.get_node("ObjectiveHUD/Panel") as Control
	check(root.get_visible_rect().encloses(objective_panel.get_global_rect()) and objective_panel.size.x <= 340 and objective_panel.size.y <= 128, "Objetivo discreto dentro de pantalla: " + str(objective_panel.get_global_rect()))
	check(main.get_node("ObjectiveHUD").objective_label.text.contains("colmado"), "Pista inicial visible")
	await capture("00-objective")
	check(not radio_point.try_activate(interaction) and progression.total_xp() == 0, "Radio fuera de alcance rechazada")
	check(not rewards.award(tracker.definitions[0]), "Sin XP para misión incompleta")
	for point in [radio_point, generator]:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = CircleShape2D.new()
		query.shape.radius = 30
		query.transform = Transform2D(0, point.position)
		query.collision_mask = 1
		check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Punto fuera de sólidos: " + point.name)
		check(point.collision_layer == 8 and point.collision_mask == 0, "Punto transitable")
	# Añadir inventario por API no es una recogida del mundo.
	inventory.add_item(preload("res://resources/items/Medkit.tres"), 1)
	check(tracker.progress_of(&"supplies", 0) == 0, "Inventario inicial/sintético no cuenta")
	await key(KEY_J)
	check(journal.window.visible and player.controls_blocked, "J abre diario y bloquea controles")
	check(journal.body.text.contains("25 XP") and journal.body.text.contains("BLOQUEADA"), "Diario describe recompensas y estados")
	var position_before := player.position
	var loaded: int = player.weapon.loaded
	Input.action_press("move_right")
	Input.action_press("shoot")
	Input.action_press("reload")
	await frames(12)
	check(player.position == position_before and player.weapon.loaded == loaded and not player.weapon.reloading, "Diario bloquea movimiento/disparo/recarga")
	Input.action_release("move_right")
	Input.action_release("reload")
	await key(KEY_K)
	check(character.window.visible and not journal.window.visible and player.controls_blocked, "K sustituye diario")
	await key(KEY_TAB)
	check(inventory_ui.window.visible and not character.window.visible and player.controls_blocked, "Tab sustituye personaje")
	await key(KEY_J)
	check(journal.window.visible and not inventory_ui.window.visible, "J sustituye mochila")
	await key(KEY_J)
	await frames(20)
	check(not player.controls_blocked and player.weapon.loaded == loaded, "Cerrar requiere soltar disparo")
	Input.action_release("shoot")
	await frames(2)
	# Recogidas reales anteriores a activar la misión 2.
	await walk_to(player, Vector2(560,810))
	await key(KEY_E)
	check(inventory.count_item(&"water") == 2 and not receipt.is_empty(), "Agua real recogida con E")
	check(not tracker.record_event(&"recovered_water", receipt), "Recibo de recogida no se duplica")
	await walk_to(player, Vector2(650,880))
	await key(KEY_E)
	check(inventory.count_item(&"medkit") == 2, "Botiquín real recogido")
	await shoot_enemy(player, main.get_node("Zombies/ZombieA"), Vector2(1000,700))
	await shoot_enemy(player, main.get_node("Zombies/ZombieB"), Vector2(1650,800))
	check(main.kills == 2 and progression.total_xp() == 60, "Bajas anteriores conservan sus 30 XP")
	check(tracker.state_of(&"supplies") == MissionTracker.State.LOCKED, "Cadena aún bloqueada")
	await walk_to(player, Vector2(1720,630))
	check(not generator.try_activate(interaction) and not generator.available, "Generador cercano en estado inválido rechazado")
	# Pared del colmado: dentro de 56 px, pero sin visibilidad.
	var saved := player.position
	player.set_physics_process(false)
	player.position = Vector2(600,600)
	await frames(2)
	check(not radio_point.try_activate(interaction), "World bloquea interacción con radio")
	player.position = saved
	player.set_physics_process(true)
	await frames(2)
	await walk_to(player, Vector2(600,680))
	check(interaction.can_access(radio_point), "Radio accesible a pie")
	var cues: int = audio.ui.played_counts.get(&"ui_select", 0)
	await key(KEY_E)
	check(radio_ui.window.visible and player.controls_blocked, "Transmisión modal abierta")
	check(radio_ui.message_label.text.contains("¿Hay alguien") and radio.index == 0, "Primer mensaje textual")
	check(audio.ui.played_counts.get(&"ui_select", 0) == cues + 1, "Un sonido por mensaje")
	check(completed_events == 2 and tracker.active_mission().id == &"broadcast", "Históricos completan misión 2 al activarse")
	check(tracker.progress_of(&"supplies", 0) == 1 and tracker.progress_of(&"supplies", 1) == 1 and tracker.progress_of(&"supplies", 2) == 2, "Objetivos históricos exactos")
	check(progression.total_xp() == 135 and progression.level == 2 and progression.xp == 35, "XP acumulada: bajas 60 + misiones 75")
	await capture("01-radio")
	await click(radio_ui.next_button)
	check(radio.index == 1 and radio_ui.message_label.text.contains("Recupera"), "E avanza sin reactivar mundo")
	check(player.weapon.loaded == 8, "Clic de diálogo no dispara")
	await key(KEY_ESCAPE)
	check(not radio_ui.window.visible and not player.controls_blocked, "Esc cierra radio")
	check(not radio_point.try_activate(interaction), "No transmitir antes de alimentar")
	await key(KEY_J)
	check(journal.body.text.contains("HISTORIAL") and journal.body.text.contains("Volver al aire"), "Diario muestra historial y misión activa")
	await capture("02-missions")
	await key(KEY_ESCAPE)
	await walk_to(player, Vector2(1720,630))
	await key(KEY_E)
	check(tracker.progress_of(&"broadcast", 0) == 1 and radio_ui.window.visible, "E activa generador y avisa")
	await key(KEY_E)
	check(not radio_ui.window.visible and not generator.try_activate(interaction), "Cierre de mensaje único; generador no se repite")
	await walk_to(player, Vector2(600,680))
	await key(KEY_E)
	check(tracker.state_of(&"broadcast") == MissionTracker.State.COMPLETED and completed_events == 3, "Tres misiones completadas en orden")
	check(progression.total_xp() == 210, "150 XP de misiones más 60 de bajas")
	await key(KEY_E)
	check(radio_ui.message_label.text.contains("CAPÍTULO COMPLETADO"), "Cierre narrativo del capítulo")
	await capture("03-chapter-complete")
	await key(KEY_E)
	check(not main.game_ended and not player.controls_blocked and not main.get_node("HUD").game_over.visible, "Fin permite continuar, sin Game Over")
	for mission in tracker.definitions: check(not rewards.award(mission), "No repetir premio " + String(mission.id))
	await key(KEY_E)
	check(progression.total_xp() == 210 and completed_events == 3, "Interacción repetida no farmea XP")
	# Completar presupuesto del mapa con las fuentes anteriores intactas.
	await shoot_enemy(player, main.get_node("Zombies/ZombieC"), Vector2(800,1150))
	for path in ["Supplies/SupplyCrate", "Supplies/MedicalCase", "Supplies/Backpack", "ArsenalSupplies/RevolverCase", "ArsenalSupplies/ShotgunCase"]:
		var container := main.get_node("World/" + path) as LootContainer
		await walk_to(player, container.position + Vector2(0,35))
		await key(KEY_E)
		check(inventory_ui.window.visible and inventory_ui.container == container, "Contenedor real " + path)
		await key(KEY_ESCAPE)
	check(progression.total_xp() == 340 and progression.level == 3 and progression.xp == 90 and progression.available_points == 2, "190 XP previos + 150 misiones = 340, nivel 3")
	check(player.get_node("SkillsComponent").upgrade(&"vitality") and player.health.max_health == 105, "Habilidades funcionan tras capítulo")
	check(main.kills == 3 and walked > 5000, "Recorrido físico completo y tres bajas existentes")
	check(player.get_node("SurvivalComponent").hunger_seconds_per_point == 30 and inventory.capacity == 12, "Supervivencia e inventario intactos")
	await key(KEY_J)
	check(journal.body.text.contains("CAPÍTULO COMPLETADO") and journal.body.text.contains("75 XP"), "Historial completo y cierre")
	player.health.take_damage(1000)
	check(not journal.window.visible and not radio_ui.window.visible and main.get_node("HUD").game_over.visible, "Muerte cierra nuevas ventanas")
	check(not tracker.enabled and not radio.enabled and not tracker.record_event(&"inspect_radio", "afterdeath"), "Muerte bloquea misión/radio")
	await key(KEY_J)
	check(not journal.window.visible and not radio.play(preload("res://resources/radio/FirstSignal.tres")), "No abrir tras Game Over")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	main = current_scene
	tracker = main.get_node("Missions")
	player = main.get_node("Player")
	check(tracker.active_mission().id == &"signal" and tracker.state_of(&"supplies") == MissionTracker.State.LOCKED, "Reintentar reinicia cadena")
	check(tracker.progress_of(&"supplies", 2) == 0 and player.get_node("ProgressionComponent").total_xp() == 0 and main.kills == 0, "Históricos, XP y bajas reiniciados")
	check(player.get_node("InventoryComponent").occupied_slots() == 0 and player.health.max_health == 100 and player.weapon.loaded == 12, "Inventario/salud/arma reiniciados")
	check(not main.get_node("MissionUI").window.visible and not main.get_node("RadioUI").window.visible and main.get_node("Radio").transmission == null, "Ventanas y transmisión reiniciadas")
	# Segunda fixture: recursos por contenedor y exclusión de eventos fallidos.
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
	interaction = player.get_node("Interaction")
	inventory = player.get_node("InventoryComponent")
	radio_ui = main.get_node("RadioUI")
	journal = main.get_node("MissionUI")
	inventory_ui = main.get_node("InventoryUI")
	character = main.get_node("CharacterUI")
	var food := preload("res://resources/items/Food.tres")
	inventory.add_item(food, food.max_stack * inventory.capacity)
	player.position = Vector2(560,810)
	await frames(2)
	await key(KEY_E)
	check(not main.get_node("World/Supplies/Water").claimed and tracker.progress_of(&"supplies", 1) == 0, "Recogida fallida no acredita agua")
	for index in range(inventory.capacity):
		var slot := inventory.get_slot(index)
		if not slot.is_empty(): inventory.remove_from_slot(index, slot.quantity)
	player.position = Vector2(600,680)
	await frames(2)
	await key(KEY_E)
	check(radio_ui.window.visible and tracker.active_mission().id == &"supplies", "Radio inicia segunda misión sin suministros iniciales")
	await key(KEY_J)
	check(journal.window.visible and not radio_ui.window.visible and player.controls_blocked, "Diario sustituye radio")
	await key(KEY_K)
	check(character.window.visible and not journal.window.visible and player.controls_blocked, "Personaje sustituye diario")
	await key(KEY_TAB)
	check(inventory_ui.window.visible and not character.window.visible and player.controls_blocked, "Mochila sustituye personaje")
	await key(KEY_ESCAPE)
	var medical := main.get_node("World/Supplies/MedicalCase") as LootContainer
	check(not interaction.transfer_from_container(medical, 0), "Transferencia lejana no cuenta")
	player.position = Vector2(770,685)
	await frames(2)
	await key(KEY_E)
	check(tracker.progress_of(&"supplies", 0) == 0 and tracker.progress_of(&"supplies", 1) == 0, "Abrir contenedor no recupera objetos")
	check(not interaction.transfer_from_container(medical, -1), "Compartimento inválido no cuenta")
	check(interaction.transfer_from_container(medical, 0) and tracker.progress_of(&"supplies", 0) == 1, "Botiquín transferido acredita objetivo")
	check(not interaction.transfer_from_container(medical, 0) and tracker.progress_of(&"supplies", 0) == 1, "Compartimento vacío no repite objetivo")
	check(interaction.transfer_from_container(medical, 1) and tracker.progress_of(&"supplies", 1) == 1, "Agua transferida acredita objetivo")
	check(tracker.state_of(&"supplies") == MissionTracker.State.ACTIVE and tracker.progress_of(&"supplies", 2) == 0, "Sin bajas no completar misión ni cobrar 50")
	check(player.get_node("ProgressionComponent").total_xp() == 45, "Solo 25 de misión y 20 del contenedor")
	player.health.take_damage(1000)
	main.get_node("Zombies/ZombieA/HealthComponent").take_damage(100)
	check(not tracker.record_event(&"kills", "dead-start") and tracker.state_of(&"supplies") == MissionTracker.State.ACTIVE, "Muerte bloquea nuevos objetivos")
	check(player.get_node("ProgressionComponent").total_xp() == 45, "Sin premios tras muerte")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Recorrido automatizado: ", snappedf(walked,1), " px; 3 misiones; 150 XP de misiones; 340 XP totales")
	print("Resultado fase 8: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
