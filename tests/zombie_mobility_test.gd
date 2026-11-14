extends SceneTree
## Main normal, IA activa durante toda la prueba. No desactiva enemigos.
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
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/population")
	check(root.get_texture().get_image().save_png("res://test-results/population/" + label + ".png") == OK, "Captura " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var legacy := "--legacy" in OS.get_cmdline_user_args()
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn" if legacy else "res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var zombie := main.get_node("Zombies/ZombieA") as CharacterBody2D
	var start := zombie.position
	check(main.get_node("Population").active_enemies().size() == (3 if legacy else 6), "Población esperada para esta escena")
	print("Inicio normal: distancia=", start.distance_to(player.position), " detección=", zombie.detection_radius, " física=", zombie.is_physics_processing())
	await frames(30)
	check(zombie.is_physics_processing() and zombie.state == 0 and zombie.position == start, "Idle fuera de detección, no IA desactivada")
	player.position = Vector2(1000,980)
	await frames(40)
	check(zombie.state == 1 and zombie.position.distance_to(start) > 30, "Detecta y se desplaza con IA real")
	check(zombie.position.distance_to(player.position) < 130, "Distancia disminuye")
	check(String(zombie.get_node("Visual/Sprite").animation) == "walk_down", "Walk down real")
	print("Persecución normal: ", start, " → ", zombie.position, " velocidad=", zombie.velocity)
	await capture("01-chase")
	await frames(65)
	check(zombie.state == 2 and player.health.current_health == 90, "Ataque real: diez HP")
	var health: float = player.health.current_health
	await frames(45)
	check(player.health.current_health == health, "Cooldown 1.5 s conservado")
	await frames(50)
	check(player.health.current_health < health, "Segundo ataque real")
	# Rodear esquina del colmado, parámetros de IA originales.
	zombie.position = Vector2(760,550)
	player.position = Vector2(680,650)
	var ray := PhysicsRayQueryParameters2D.create(zombie.position, player.position, 1)
	check(not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(), "Colmado bloquea línea directa")
	start = zombie.position
	await frames(40)
	check(zombie.position.distance_to(start) > 30 and zombie.state == 1, "Ruta activa alrededor del colmado")
	check(zombie.agent.get_current_navigation_path().size() > 0, "NavigationAgent posee ruta")
	await capture("02-urban-route")
	await frames(80)
	check(zombie.state == 2 and zombie.position.distance_to(player.position) <= 35, "Rodea sólido urbano y llega a atacar")
	# Tres actores activos, sin radios ampliados ni velocidades alteradas.
	player.position = Vector2(1000,900)
	var positions := [Vector2(1000,750), Vector2(900,700), Vector2(1100,700)]
	var enemies: Array[Node] = [zombie, main.get_node("Zombies/ZombieB"), main.get_node("Zombies/ZombieC")]
	for index in range(3): enemies[index].position = positions[index]
	await frames(35)
	for index in range(3):
		check(enemies[index].is_physics_processing() and enemies[index].position.distance_to(positions[index]) > 25, "Persecución simultánea: " + enemies[index].name)
		check(String(enemies[index].get_node("Visual/Sprite").animation).begins_with("walk_"), "Walk en perseguidor " + enemies[index].name)
	await capture("03-simultaneous")
	var sample_sum := 0.0
	var max_draws := 0.0
	var max_nodes := 0.0
	var initial_nodes := main.get_node("Zombies").get_child_count()
	for index in range(120):
		await frames(1)
		sample_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		max_draws = maxf(max_draws, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		max_nodes = maxf(max_nodes, Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	check(main.get_node("Zombies").get_child_count() == initial_nodes, "Muestra sin crecimiento de enemigos")
	print("Muestra 120 frames: TIME_PROCESS medio=", snappedf(sample_sum / 120,0.01), " ms; draw calls máximo=", max_draws, "; nodos máximo=", max_nodes)
	player.health.take_damage(1000)
	var stopped := enemies.map(func(enemy): return enemy.position)
	await frames(30)
	for index in range(3): check(enemies[index].position == stopped[index] and enemies[index].target == null, "Game Over detiene perseguidor")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado movilidad IA activa: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
