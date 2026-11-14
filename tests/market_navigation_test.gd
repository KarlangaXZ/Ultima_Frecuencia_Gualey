extends SceneTree
## Física e IA activas durante toda la comprobación del mercado.
var checks := 0
var failures := 0
var capture_fade := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/zones")
	check(root.get_texture().get_image().save_png("res://test-results/zones/" + label + ".png") == OK,"Captura " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var tracker := main.get_node("Missions") as MissionTracker
	main.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
	main.get_node("Zombies/ZombieB/HealthComponent").take_damage(50)
	for event in [&"inspect_radio",&"recovered_medkit",&"recovered_water",&"power_on",&"send_radio"]:
		tracker.record_event(event,"navigation_fixture")
	var manager := main.get_node("ZoneManager")
	var overlay := main.get_node("ZoneOverlay")
	var player := main.get_node("Player") as CharacterBody2D
	check(manager.request_travel(ZoneCatalog.MARKET,"from_gualey"),"Desbloqueo y transición al mercado")
	await overlay.black_reached
	check(overlay.curtain.visible and overlay.curtain.modulate.a > 0.99 and overlay.title.text == "MERCADO ABANDONADO","Fundido negro y nombre de destino")
	await capture("01-transition")
	await manager.transition_finished
	check(overlay.banner.visible and not overlay.curtain.visible and not paused,"Nombre breve al entrar y juego activo")
	# Sincronizar broadphase y mapas del servidor tras retirar la pausa.
	await frames(3)
	check(main.get_node("HUD/Panel").size == Vector2(256,172),"HUD principal conserva tamaño")
	var world := main.get_node("World")
	check(world.get_index() < player.get_index() and world.get_index() < main.get_node("Zombies").get_index(),"Suelo dibujado antes de personajes")
	var map := player.get_world_2d().navigation_map
	var space := player.get_world_2d().direct_space_state
	check(world.get_node("Obstacles").get_child_count() == 22,"Veintidós sólidos urbanos nuevos")
	for obstacle in world.get_node("Obstacles").get_children():
		var nearest := NavigationServer2D.map_get_closest_point(map,obstacle.position)
		var ray := PhysicsRayQueryParameters2D.create(nearest,obstacle.position,1)
		var hit := space.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == obstacle,"Malla y colisión coinciden: " + obstacle.name)
	for destination in [Vector2(530,1215),Vector2(1650,1195),Vector2(2050,975),Vector2(1900,800),Vector2(400,1200),Vector2(240,800)]:
		var path := NavigationServer2D.map_get_path(map,player.position,destination,true)
		check(path.size() > 1 and path[-1].distance_to(destination) < 2,"Ruta transitable " + str(destination))
	for entry in ZoneCatalog.definition(ZoneCatalog.MARKET).entries.values():
		check(ZoneCatalog.point_free(ZoneCatalog.MARKET,[entry.x,entry.y]),"Entrada libre de sólidos")
	for enemy in main.get_node("Population").active_enemies():
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = enemy.get_node("CollisionShape2D").shape
		query.transform = enemy.global_transform
		query.collision_mask = 1
		check(space.intersect_shape(query).is_empty() and enemy.is_physics_processing(),"Aparición válida e IA activa " + enemy.name)
	await capture("02-market")
	var zombie := main.get_node("Zombies/ZombieA")
	player.position = Vector2(900,900)
	var start: Vector2 = zombie.position
	await frames(20)
	check(zombie.state == 1 and zombie.position.distance_to(start) > 25,"Detecta y se desplaza realmente")
	check(zombie.position.distance_to(player.position) < 80 and String(zombie.get_node("Visual/Sprite").animation) == "walk_down","Se acerca con Walk correcto")
	await capture("03-market-chase")
	await frames(35)
	check(zombie.state == 2 and player.health.current_health == 90,"Ataca con daño original")
	var hp: float = player.health.current_health
	await frames(35)
	check(player.health.current_health == hp,"Cooldown de ataque conservado")
	check(zombie.get_node("Audio").emitter.played_counts.get(&"zombie_attack",0) >= 1,"Audio de ataque reutilizado")
	# Colisión contra un puesto: input y move_and_slide existentes.
	player.position = Vector2(750,700)
	Input.action_press("move_up")
	await frames(50)
	Input.action_release("move_up")
	check(player.position.y >= 650 and player.position.y < 660,"El jugador no atraviesa el puesto")
	zombie.position = Vector2(1180,760)
	player.position = Vector2(1180,880)
	await frames(2)
	var ray := PhysicsRayQueryParameters2D.create(zombie.position,player.position,1)
	check(not space.intersect_ray(ray).is_empty(),"Barricada bloquea línea directa")
	start = zombie.position
	await frames(40)
	check(zombie.position.distance_to(start) > 25 and String(zombie.get_node("Visual/Sprite").animation).begins_with("walk_"),"Zombi navega alrededor de barricada")
	await capture("04-market-route")
	await frames(160)
	check(zombie.state == 2 and zombie.position.distance_to(player.position) <= 35,"Rodea barricada y llega a atacar")
	var xp: int = player.get_node("ProgressionComponent").total_xp()
	var ammo: int = player.weapon.loaded
	for index in range(2):
		check(player.weapon.try_fire(player.position,player.position.direction_to(zombie.position)),"Disparo real en mercado")
		await frames(19)
	check(zombie.health.is_dead() and player.weapon.loaded == ammo - 2,"Combate y muerte conservados")
	check(player.get_node("ProgressionComponent").total_xp() == xp + 30 and main.kills == 3,"XP y bajas globales válidas")
	player.health.heal(100)
	player.position = Vector2(900,900)
	var pursuers := [main.get_node("Zombies/ZombieB"),main.get_node("Zombies/ZombieC"),SaveCatalog.find(main.get_node("Zombies"),"market_zombie_04")]
	var starts := [Vector2(800,750),Vector2(900,740),Vector2(1000,750)]
	for index in range(3): pursuers[index].position = starts[index]
	await frames(25)
	for index in range(3): check(pursuers[index].position.distance_to(starts[index]) > 25 and pursuers[index].is_physics_processing(),"Persecución simultánea en mercado")
	await capture("05-market-simultaneous")
	var process_sum := 0.0
	var draw_max := 0.0
	var nodes_max := 0.0
	var enemies_before := main.get_node("Zombies").get_child_count()
	for index in range(120):
		await frames(1)
		process_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
		draw_max = maxf(draw_max,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		nodes_max = maxf(nodes_max,Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	check(main.get_node("Zombies").get_child_count() == enemies_before,"No crecen nodos de enemigos durante muestra")
	print("Mercado 120 frames: TIME_PROCESS medio=",snappedf(process_sum/120,0.01)," ms; draw calls máximo=",draw_max,"; nodos máximo=",nodes_max)
	# Plano técnico solo para documentación; no cambia cámara ni resolución del juego.
	player.position = Vector2(1200,800)
	player.get_node("Camera2D").zoom = Vector2(0.43,0.43)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	main.get_node("HUD").hide()
	main.get_node("ObjectiveHUD").hide()
	await frames(2)
	await capture("06-market-plan")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado navegación mercado: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
