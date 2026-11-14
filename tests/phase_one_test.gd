extends SceneTree
## Integración real: acciones, física y cámara de la escena principal.

var failures: int = 0

func check(condition: bool, message: String) -> void:
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
	var main := load("res://tests/fixtures/LegacyMain.tscn").instantiate() as Node2D
	root.add_child(main)
	var player := main.get_node("Player") as CharacterBody2D
	var camera := player.get_node("Camera2D") as Camera2D
	await frames(3)
	var directions := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
		Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for direction: Vector2 in directions:
		player.position = Vector2(1200, 800)
		var start := player.position
		if direction.x < 0: Input.action_press("move_left")
		if direction.x > 0: Input.action_press("move_right")
		if direction.y < 0: Input.action_press("move_up")
		if direction.y > 0: Input.action_press("move_down")
		await frames(12)
		check(player.velocity.is_equal_approx(direction.normalized() * player.speed),
			"Velocidad normalizada " + str(direction))
		check((player.position - start).normalized().is_equal_approx(direction.normalized()),
			"Desplazamiento " + str(direction))
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		await frames(2)
	check(player.velocity.is_zero_approx(), "Detención al soltar WASD")
	player.position = Vector2(600, 800)
	Input.action_press("move_right")
	await frames(90)
	check(player.position.x <= 721.0 and player.position.x >= 718.0,
		"Obstáculo bloquea al jugador")
	Input.action_release("move_right")
	player.position = Vector2(80, 800)
	Input.action_press("move_left")
	await frames(45)
	check(player.position.x >= 39.0 and player.position.x <= 41.0,
		"Límite del escenario bloquea al jugador")
	Input.action_release("move_left")
	player.position = Vector2(1200, 800)
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	camera.reset_smoothing()
	await frames(3)
	check(camera.is_current(), "Cámara activa")
	check(camera.get_screen_center_position().distance_to(player.global_position) < 2.0,
		"Cámara sigue al jugador")
	main.queue_free()
	await process_frame
	print("Resultado: ", failures, " fallos")
	quit(0 if failures == 0 else 1)
