extends SceneTree
var checks: int = 0
var failures: int = 0

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

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/walk-down")
	check(root.get_texture().get_image().save_png("res://test-results/walk-down/" + label + ".png") == OK,
		"Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(3)
	var player := current_scene.get_node("Player") as CharacterBody2D
	var visual := player.get_node("Visual")
	var sprite := visual.get_node("Sprite") as AnimatedSprite2D
	var library := sprite.sprite_frames
	check(library.get_animation_speed("walk_down") == 8.0 and library.get_animation_loop("walk_down")
		and library.get_frame_count("walk_down") == 8, "Walk real: ocho frames, 8 FPS, bucle")
	for index in range(8):
		check(library.get_frame_texture("walk_down", index).resource_path.ends_with("player_walk_down_%02d.png" % index),
			"Frame walk en orden " + str(index))
	# Se bloquea solo el apuntado automático para aislar su independencia visual.
	player.set_physics_process(false)
	player.get_node("Aim").rotation = PI / 2.0
	await frames(2)
	check(sprite.animation == &"idle_down", "Idle real antes de caminar")
	await capture("01-idle")
	# Restaurar física real: entrada WASD y cámara originales.
	player.set_physics_process(true)
	var start := player.position
	Input.action_press("move_down")
	await frames(12)
	check(player.position.y > start.y and player.velocity == Vector2(0, 240), "WASD abajo conserva movimiento original")
	check(sprite.animation == &"walk_down" and visual.rotation == 0.0, "Movimiento abajo elige walk_down independientemente del mouse")
	check(sprite.scale == Vector2(0.4, 0.4) and sprite.offset == Vector2(0, -56), "Walk e idle comparten escala y pivote")
	var previous_frame := sprite.frame
	await frames(8)
	check(sprite.frame != previous_frame, "Walk avanza fotogramas")
	await capture("02-walk")
	Input.action_release("move_down")
	await frames(5)
	check(sprite.animation == &"idle_down", "Al detenerse vuelve a idle_down")
	await capture("03-idle-return")
	player.set_physics_process(false)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		player.velocity = direction * 240.0
		await frames(2)
		var texture := library.get_frame_texture(sprite.animation, 0)
		var valid: bool = texture is AtlasTexture
		if direction == Vector2.UP:
			valid = texture.resource_path.ends_with("player_walk_up_00.png")
		elif direction == Vector2.RIGHT:
			valid = texture.resource_path.ends_with("player_walk_left_00.png")
		check(valid,
			"Otra dirección usa recurso disponible " + str(direction))
	player.velocity = Vector2.ZERO
	player.health.take_damage(100)
	await frames(2)
	check(String(sprite.animation).begins_with("death"), "Muerte conserva presentación anterior")
	print("Resultado walk_down: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
