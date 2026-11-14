extends SceneTree
var checks := 0
var failures := 0
var spawn_events := 0
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
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var player := main.get_node("Player")
	var population := main.get_node("Population")
	var progression := player.get_node("ProgressionComponent") as ProgressionComponent
	print("Población inicial: ", population.total_spawned, " vivos=", population.active_enemies().size(), " límite=", population.active_limit, " presupuesto=", population.total_budget)
	for enemy in population.active_enemies(): print(enemy.name, " ", enemy.position)
	check(population.active_limit == 6 and population.total_budget == 18 and population.total_spawned == 6, "Producción: seis vivos, presupuesto dieciocho")
	check(population.active_enemies().size() == 6 and main.get_node("Zombies").get_child_count() == 6, "Población inicial sin duplicados")
	for zombie in population.active_enemies():
		check(zombie.is_physics_processing() and zombie.target == player and zombie.health.current_health == 50, "IA real conectada " + zombie.name)
		if String(zombie.name).begins_with("Population"):
			var screen: Vector2 = zombie.get_canvas_transform() * zombie.global_position
			check(not root.get_visible_rect().grow(96).has_point(screen), "Inicio adicional fuera de pantalla")
	check(not population.is_valid_spawn(player.position) and not population.is_valid_spawn(Vector2(570,495)), "No sobre jugador ni colmado")
	check(not population.is_valid_spawn(main.get_node("World/ChapterPoints/Generator").position), "No sobre misión")
	population.spawned.connect(func(zombie: CharacterBody2D):
		spawn_events += 1
		check(population.active_enemies().size() <= 6 and population.total_spawned <= 18, "Límites reservados al notificar")
		check(zombie.is_physics_processing() and zombie.target == player, "Nuevo actor conectado por Main")
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = zombie.get_node("CollisionShape2D").shape
		query.transform = zombie.global_transform
		query.collision_mask = 1
		check(zombie.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Aparición sin World")
		check(not root.get_visible_rect().grow(96).has_point(zombie.get_canvas_transform() * zombie.position), "Reposición fuera de cámara"))
	var first: Node = population.active_enemies()[0]
	first.health.take_damage(50)
	first.health.take_damage(50)
	check(main.kills == 1 and progression.total_xp() == 30, "Una baja y treinta XP")
	population._physics_process(0.1)
	check(population.active_enemies().size() == 5 and population.total_spawned == 6, "No reemplaza inmediatamente")
	population._physics_process(10.0)
	check(population.active_enemies().size() == 6 and population.total_spawned == 7, "Una reposición después del intervalo")
	# Reloj adelantado solo en esta fixture para agotar presupuesto finito.
	while population.total_spawned < population.total_budget:
		population.active_enemies()[0].health.take_damage(50)
		population._physics_process(10.1)
		await frames(2)
	for zombie in population.active_enemies(): zombie.health.take_damage(50)
	await frames(2)
	for index in range(30): population._physics_process(60.0)
	check(population.total_spawned == 18 and population.active_enemies().is_empty(), "Presupuesto agotado, no infinito")
	check(main.kills == 18 and progression.total_xp() == 540 and spawn_events == 12, "Dieciocho bajas, XP única y doce reposiciones")
	check(main.get_node("Zombies").get_child_count() == 18, "Cadáveres conservados, nodos acotados al presupuesto")
	var tracker := main.get_node("Missions") as MissionTracker
	player.position = Vector2(600,680)
	await frames(2)
	await key(KEY_E)
	await key(KEY_E)
	await key(KEY_E)
	player.position = Vector2(560,810)
	await frames(2)
	await key(KEY_E)
	player.position = Vector2(650,880)
	await frames(2)
	await key(KEY_E)
	check(tracker.state_of(&"supplies") == MissionTracker.State.COMPLETED, "Bajas de toda la población sirven a misión")
	player.position = Vector2(1720,630)
	await frames(2)
	await key(KEY_E)
	await key(KEY_E)
	player.position = Vector2(600,680)
	await frames(2)
	await key(KEY_E)
	await key(KEY_E)
	await key(KEY_E)
	check(tracker.state_of(&"broadcast") == MissionTracker.State.COMPLETED and progression.total_xp() == 690, "Campaña intacta: 540 bajas + 150 misiones")
	for path in ["Supplies/SupplyCrate", "Supplies/MedicalCase", "Supplies/Backpack", "ArsenalSupplies/RevolverCase", "ArsenalSupplies/ShotgunCase"]:
		var container := main.get_node("World/" + path)
		player.position = container.position + Vector2(0,35)
		await frames(2)
		await key(KEY_E)
		await key(KEY_ESCAPE)
	check(progression.total_xp() == 790 and progression.level == 5 and progression.xp == 90 and progression.available_points == 4, "XP máxima: 790, nivel cinco y cuatro puntos")
	player.health.take_damage(1000)
	check(not population.running, "Game Over detiene gestor")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	main = current_scene
	player = main.get_node("Player")
	population = main.get_node("Population")
	check(population.total_spawned == 6 and population.active_enemies().size() == 6 and population.running, "Reintentar restaura población y presupuesto")
	check(main.kills == 0 and player.get_node("ProgressionComponent").total_xp() == 0, "Reinicio restaura bajas y XP")
	# Capítulo con enemigos vivos y activos: dos nuevos enemigos abatidos por pistola.
	player.position = Vector2(600,680)
	await frames(2)
	await key(KEY_E)
	await key(KEY_E)
	await key(KEY_E)
	for point in [Vector2(560,810), Vector2(650,880)]:
		player.position = point
		await frames(2)
		await key(KEY_E)
	var new_enemies: Array = population.active_enemies().filter(func(z): return String(z.name).begins_with("Population"))
	for index in range(2):
		var enemy: Node = new_enemies[index]
		player.position = enemy.position + Vector2(0,100)
		await frames(2)
		var start: Vector2 = enemy.position
		for shot in range(2):
			check(player.weapon.try_fire(player.position, player.position.direction_to(enemy.position)), "Tiro válido contra enemigo dinámico")
			await frames(19)
		check(enemy.health.is_dead() and enemy.position.distance_to(start) > 5, "Enemigo nuevo persigue y muere por combate real")
	check(main.kills == 2 and main.get_node("Missions").state_of(&"supplies") == MissionTracker.State.COMPLETED, "Dos dinámicos completan misión de bajas")
	player.position = Vector2(1720,630)
	await frames(2)
	await key(KEY_E)
	await key(KEY_E)
	player.position = Vector2(600,680)
	await frames(2)
	await key(KEY_E)
	await key(KEY_E)
	await key(KEY_E)
	check(main.get_node("Missions").state_of(&"broadcast") == MissionTracker.State.COMPLETED and not main.game_ended, "Capítulo completado con IA activa y sin Game Over")
	check(player.get_node("InventoryComponent").count_item(&"water") == 2 and player.weapon.loaded == 8, "Inventario y munición conservados")
	check(population.active_enemies().all(func(z): return z.is_physics_processing()), "No se congeló IA para completar misiones")
	player.health.take_damage(1000)
	var count_before: int = population.total_spawned
	for index in range(20): population._physics_process(60.0)
	await frames(2)
	check(not population.running and population.total_spawned == count_before, "Sin reposiciones durante Game Over con presupuesto restante")
	check(population.active_enemies().all(func(z): return z.target == null and z.velocity == Vector2.ZERO), "Todos los supervivientes dejan de perseguir")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado población: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
