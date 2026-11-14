extends SceneTree
## Escenario real: huellas sólidas, rutas, movimiento, hitscan y capturas opcionales.
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

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/urban")
	check(root.get_texture().get_image().save_png("res://test-results/urban/" + label + ".png") == OK, "Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var world := main.get_node("World")
	var obstacles := world.get_node("Obstacles")
	var camera := player.get_node("Camera2D") as Camera2D
	var space := player.get_world_2d().direct_space_state
	var navigation_map := player.get_world_2d().navigation_map
	check(obstacles.get_child_count() == 28, "Cinco cajas originales y 23 sólidos urbanos")
	check(world.get_node("Ambient").color.r >= 0.9, "Ambiente moderado")
	check(camera.zoom == Vector2.ONE and camera.limit_right == 2400 and camera.limit_bottom == 1600, "Cámara y tamaño originales")
	var bodies: Array[Node] = [player]
	bodies.append_array(main.get_node("Zombies").get_children())
	for body in bodies:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = body.get_node("CollisionShape2D").shape
		query.transform = body.global_transform
		query.collision_mask = 1
		check(space.intersect_shape(query).is_empty(), "Aparición libre: " + body.name)
	# Malla y rayos consultan los 28 cuerpos reales, no una copia del trazado visual.
	for obstacle in obstacles.get_children():
		var shape := obstacle.get_node("CollisionShape2D").shape as RectangleShape2D
		var nearest := NavigationServer2D.map_get_closest_point(navigation_map, obstacle.global_position)
		var half: Vector2 = shape.size * obstacle.scale / 2
		check(nearest.distance_to(obstacle.global_position) >= minf(half.x, half.y) + 17.0,
			"Navegación excluye sólido y margen: " + obstacle.name)
		var ray := PhysicsRayQueryParameters2D.create(nearest, obstacle.global_position, 1)
		var hit := space.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == obstacle, "Rayo bloqueado por " + obstacle.name)
	for target in [Vector2(1000, 350), Vector2(1500, 1300), Vector2(2000, 800), Vector2(330, 900)]:
		var path := NavigationServer2D.map_get_path(navigation_map, player.position, target, true)
		check(path.size() > 1 and path[-1].distance_to(target) < 2, "Zona conectada: " + str(target))
	await capture("01-street")
	# Disparo real bloqueado por el colmado: sin daño detrás de la cubierta sólida.
	var zombie := main.get_node("Zombies/ZombieA")
	for enemy in main.get_node("Zombies").get_children():
		enemy.set_physics_process(false)
	player.position = Vector2(570, 690)
	zombie.position = Vector2(570, 325)
	await frames(2)
	var weapon := player.get_node("Weapon")
	weapon.try_fire(player.position, Vector2.UP)
	check(weapon.loaded == 11 and zombie.health.current_health == 50.0, "Disparo consume una bala sin atravesar edificio")
	check(player.get_node("Combat").trace_end.distance_to(Vector2(570, 610)) < 1, "Impacto sobre huella visual del colmado")
	Input.action_press("move_up")
	await frames(35)
	Input.action_release("move_up")
	check(player.position.y >= 625 and player.position.y <= 627, "Jugador no atraviesa el colmado")
	# IA original rodea la estructura; solo la fixture amplía el radio de detección.
	player.position = Vector2(770, 495)
	zombie.position = Vector2(370, 495)
	zombie.detection_radius = 800
	zombie.repath_time = 0
	zombie.set_physics_process(true)
	var crossed := false
	var crossing_position := Vector2.ZERO
	for index in range(600):
		await frames(1)
		if Rect2(395, 365, 350, 260).has_point(zombie.position):
			crossed = true
			crossing_position = zombie.position
		if zombie.position.distance_to(player.position) <= 36:
			break
	check(not crossed and zombie.position.distance_to(player.position) <= 36,
		"Zombi rodea colmado sin atravesarlo ni atascarse; cruce=" + str(crossing_position) + "; final=" + str(zombie.position))
	await frames(3)
	check(zombie.state == zombie.State.ATTACK and player.get_node("HealthComponent").current_health == 90,
		"Ataque y daño originales al completar la ruta")
	await capture("02-colmado")
	# Nueva instancia: capturas del resto de la zona sin arrastrar fixtures de combate.
	reload_current_scene()
	await frames(5)
	main = current_scene
	player = main.get_node("Player")
	camera = player.get_node("Camera2D")
	check(player.position == Vector2(600, 800) and main.get_node("World/Obstacles").get_child_count() == 28,
		"Reinicio restaura zona y posición original")
	player.position = Vector2(1900, 800)
	camera.reset_smoothing()
	await frames(3)
	await capture("03-east")
	# Vista técnica del plano completo; zoom solo en la prueba, nunca en el juego.
	player.position = Vector2(1200, 800)
	camera.zoom = Vector2(0.43, 0.43)
	camera.reset_smoothing()
	main.get_node("HUD").hide()
	await frames(3)
	await capture("04-plan")
	if DisplayServer.get_name() != "headless":
		main.get_node("HUD").show()
		camera.zoom = Vector2.ONE
		camera.reset_smoothing()
		# Muestra sin espera vertical en esta ventana de prueba, sin tocar project.godot.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await frames(30)
		var node_count := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var process_total := 0.0
		var draw_calls := 0
		for index in range(120):
			await process_frame
			process_total += Performance.get_monitor(Performance.TIME_PROCESS)
			draw_calls = maxi(draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == node_count, "Decoración no acumula nodos durante 120 frames")
		print("Muestra renderizada: monitor TIME_PROCESS medio=", snappedf(process_total / 120.0 * 1000, 0.01),
			" ms; máximo draw calls=", draw_calls, "; nodos=", node_count, ". No es un benchmark de FPS/exportación.")
	print("Resultado zona urbana: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
