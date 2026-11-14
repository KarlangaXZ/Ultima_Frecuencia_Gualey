extends SceneTree
var checks: int = 0
var failures: int = 0
var shots: int = 0
var flashes: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
	await frames(4)
	var player := current_scene.get_node("Player")
	var visual := player.get_node("Visual")
	var sprite := visual.get_node("Sprite") as AnimatedSprite2D
	var weapon := player.get_node("Weapon")
	var combat := player.get_node("Combat")
	weapon.shot_fired.connect(func(_a, _b, _c, _d): shots += 1)
	combat.visual_shot.connect(func(_a, _b, _c): flashes += 1)
	var directions := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}
	for name: String in directions:
		if DisplayServer.get_name() != "headless":
			player.get_viewport().warp_mouse(player.get_viewport().get_canvas_transform() * (player.position + directions[name] * 200.0))
		await frames(20)
		var loaded: int = weapon.loaded
		check(weapon.try_fire(player.position, directions[name]), "Tiro válido " + name)
		check(sprite.animation == StringName("shoot_" + name) and sprite.frame == 0, "Inicio de Shoot " + name)
		check(not weapon.try_fire(player.position, directions[name]) and weapon.loaded == loaded - 1, "Cooldown conserva bala")
		await frames(8)
		check(String(sprite.animation).begins_with("shoot") and sprite.frame >= 1, "Avance antes de 0.3 s")
		if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://test-results/shoot")
			check(root.get_texture().get_image().save_png("res://test-results/shoot/" + name + ".png") == OK, "Captura " + name)
		await frames(12)
		check(not visual.shooting_visual and String(sprite.animation).begins_with("idle"), "Fin Shoot a 0.3 s")
	check(shots == 4 and flashes == 4, "Una señal de efecto existente por tiro real")
	# Disparo con mouse/input real de Godot mientras se mueve perpendicularmente.
	player.get_node("Camera2D").reset_smoothing()
	await frames(2)
	var motion := InputEventMouseMotion.new()
	if DisplayServer.get_name() != "headless":
		player.get_viewport().warp_mouse(player.get_viewport().get_canvas_transform() * (player.position + Vector2(0, -200)))
	motion.position = player.get_viewport().get_screen_transform() * (player.get_viewport().get_canvas_transform() * (player.position + Vector2(0, -200)))
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	var start: Vector2 = player.position
	Input.action_press("move_right")
	Input.action_press("shoot")
	await frames(3)
	Input.action_release("shoot")
	check(player.position.x > start.x and sprite.animation == &"shoot_up", "Shoot sigue mouse sin detener movimiento")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://test-results/shoot/moving.png") == OK, "Captura en movimiento")
	await frames(20)
	check(sprite.animation == &"walk_right", "Shoot vuelve a caminata actual")
	Input.action_release("move_right")
	await frames(3)
	check(sprite.animation == &"idle_right", "Luego vuelve a idle correcto")
	weapon.try_fire(player.position, Vector2.UP)
	Input.action_press("move_down")
	await frames(3)
	Input.action_release("move_down")
	await frames(20)
	check(sprite.animation == &"idle_down", "Pararse durante Shoot conserva última dirección de movimiento")
	weapon.try_fire(player.position, Vector2.LEFT)
	weapon.start_reload()
	await frames(2)
	check(not visual.shooting_visual and String(sprite.animation).begins_with("reload"), "Reload interrumpe Shoot")
	check(not weapon.try_fire(player.position, Vector2.LEFT), "No dispara recargando")
	player.health.take_damage(100)
	await frames(2)
	check(not visual.shooting_visual and String(sprite.animation).begins_with("death"), "Death tiene prioridad")
	check(not weapon.try_fire(player.position, Vector2.LEFT), "No dispara muerto")
	print("Resultado Shoot: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
