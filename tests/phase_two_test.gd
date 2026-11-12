extends SceneTree
## Integración sobre Main real: navegación, daño, HUD, muerte y botón de reinicio.
var failures: int = 0
var checks: int = 0
var death_signals: int = 0
var health_signals: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var health := player.get_node("HealthComponent") as HealthComponent
	var hud := main.get_node("HUD")
	var zombies := main.get_node("Zombies").get_children()
	check(zombies.size() == 3, "Tres zombis iniciales")
	check(health.current_health == 100.0, "Jugador inicia con 100 HP")
	for zombie in zombies:
		check(zombie.health.current_health == 50.0, "Zombi inicia con 50 HP")
		check(zombie.state == zombie.State.IDLE, "Zombi fuera de detección permanece IDLE")
		var shape_query := PhysicsShapeQueryParameters2D.new()
		shape_query.shape = zombie.get_node("CollisionShape2D").shape
		shape_query.transform = zombie.global_transform
		shape_query.collision_mask = 1
		check(player.get_world_2d().direct_space_state.intersect_shape(shape_query).is_empty(),
			"Aparición fuera de obstáculos")
	await frames(100)
	check(health.current_health == 100.0, "Sin daño al comenzar")
	var zombie = zombies[0]
	for other in [zombies[1], zombies[2]]:
		other.set_physics_process(false)
	player.position = Vector2(1200, 800)
	var initial: float = zombie.position.distance_to(player.position)
	await frames(30)
	check(zombie.state == zombie.State.CHASE, "Detecta dentro de 250 px y cambia a CHASE")
	check(zombie.position.distance_to(player.position) < initial - 20.0, "Persigue físicamente al jugador")
	player.position = Vector2(2200, 1400)
	await frames(3)
	check(zombie.state == zombie.State.IDLE and zombie.velocity == Vector2.ZERO,
		"Sale del radio y deja de perseguir")
	# Ruta al otro lado de CrateA: un movimiento directo quedaría bloqueado.
	zombie.position = Vector2(900, 800)
	zombie.repath_time = 0.0
	zombie.detection_radius = 800.0
	player.position = Vector2(700, 800)
	var crossed_obstacle := false
	for index in range(300):
		await frames(1)
		if zombie.position.x > 720 and zombie.position.x < 880 and absf(zombie.position.y - 800) < 63:
			crossed_obstacle = true
	check(not crossed_obstacle, "Ruta no atraviesa caja ni su margen físico")
	check(zombie.position.distance_to(player.position) <= 36.0, "Rodea caja y alcanza destino sin atascarse")
	# Aísla la cadencia usando un jugador y zombi separados de las cajas.
	zombie.set_physics_process(false)
	player.position = Vector2(1200, 800)
	zombie.position = Vector2(1234, 800)
	zombie.cooldown = 0.0
	# La ruta anterior pudo causar daño; comenzar esta parte con salud intacta.
	health.current_health = 100.0
	hud.update_health(100.0, 100.0)
	health.health_changed.connect(func(_current: float, _maximum: float): health_signals += 1)
	health.died.connect(func(): death_signals += 1)
	zombie.set_physics_process(true)
	await frames(2)
	check(zombie.state == zombie.State.ATTACK, "Entra en ATTACK a 35 px")
	check(health.current_health == 90.0, "Ataque resta exactamente 10 HP")
	check(hud.bar.value == 90.0 and hud.value_label.text == "90 / 100", "HUD actualiza barra y número")
	await frames(70)
	check(health.current_health == 90.0, "No repite ataque antes de 1.5 segundos")
	await frames(22)
	check(health.current_health == 80.0, "Nuevo ataque después de 1.5 segundos")
	check(health_signals == 2, "Señal de salud por cada ataque")
	# Salir y volver no debe reiniciar el intervalo.
	player.position = Vector2(1300, 800)
	await frames(2)
	player.position = zombie.position + Vector2(34, 0)
	await frames(2)
	check(health.current_health == 80.0, "Reentrar en alcance respeta cooldown")
	# Tampoco puede atacar a través de una caja con distancia muy aumentada.
	zombie.position = Vector2(900, 800)
	player.position = Vector2(700, 800)
	zombie.attack_distance = 300.0
	zombie.cooldown = 0.0
	await frames(2)
	check(health.current_health == 80.0 and zombie.state == zombie.State.CHASE,
		"Obstáculo bloquea ataque aunque esté en alcance")
	zombie.attack_distance = 35.0
	health.take_damage(-10)
	check(health.current_health == 80.0, "Daño negativo no cura")
	zombie.position = Vector2(1234, 800)
	player.position = Vector2(1200, 800)
	zombie.cooldown = 0.0
	await frames(640)
	check(health_signals == 10, "Diez ataques completan la muerte del jugador")
	check(health.current_health == 0.0 and death_signals == 1, "Salud limitada a cero y señal de muerte única")
	check(hud.game_over.visible and hud.bar.value == 0.0, "Game Over visible y barra en cero")
	var death_position := player.position
	Input.action_press("move_right")
	await frames(100)
	Input.action_release("move_right")
	check(player.position == death_position and player.velocity == Vector2.ZERO,
		"Jugador muerto no responde a movimiento")
	check(zombie.target == null and zombie.state == zombie.State.IDLE,
		"Enemigos dejan de perseguir y atacar al jugador muerto")
	health.take_damage(10)
	check(death_signals == 1, "Daño posterior no repite muerte")
	# Salud compartida también desactiva al zombi.
	zombie.health.take_damage(50)
	await frames(2)
	check(zombie.state == zombie.State.DEAD and zombie.velocity == Vector2.ZERO,
		"Zombi con 0 HP permanece DEAD e inmóvil")
	var old_id := main.get_instance_id()
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	main = current_scene
	check(main.get_instance_id() != old_id, "Botón Reintentar recarga Main")
	check(main.get_node("Player").position == Vector2(600, 800), "Reinicio restablece posición del jugador")
	check(main.get_node("Player/HealthComponent").current_health == 100.0,
		"Reinicio restablece salud a 100")
	check(not main.get_node("HUD/GameOver").visible, "Reinicio oculta Game Over")
	var expected := [Vector2(1000, 800), Vector2(1650, 700), Vector2(800, 1250)]
	for index in range(3):
		var fresh = main.get_node("Zombies").get_child(index)
		check(fresh.position == expected[index] and fresh.health.current_health == 50.0
			and fresh.state == fresh.State.IDLE, "Reinicio restablece zombi " + str(index))
	var dead_zombie = main.get_node("Zombies").get_child(0)
	var dead_position: Vector2 = dead_zombie.position
	main.get_node("Player").position = dead_position + Vector2(34, 0)
	dead_zombie.health.take_damage(500)
	await frames(100)
	check(dead_zombie.health.current_health == 0.0 and dead_zombie.state == dead_zombie.State.DEAD
		and dead_zombie.position == dead_position, "Daño excesivo limita salud y detiene zombi con objetivo vivo")
	check(main.get_node("Player/HealthComponent").current_health == 100.0,
		"Zombi muerto no ataca al jugador vivo")
	print("Resultado fase 2: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
