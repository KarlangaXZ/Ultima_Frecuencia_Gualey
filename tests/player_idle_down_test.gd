extends SceneTree
## Verifica sustitución parcial por arte real y retorno al atlas existente.
var failures: int = 0
var checks: int = 0

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
	await frames(3)
	var player := current_scene.get_node("Player") as CharacterBody2D
	var visual := player.get_node("Visual")
	var sprite := visual.get_node("Sprite") as AnimatedSprite2D
	# Mantener Aim hacia abajo para observar específicamente idle_down.
	player.set_physics_process(false)
	player.get_node("Aim").rotation = PI / 2.0 + 0.2
	await frames(2)
	var library := sprite.sprite_frames
	check(library.get_animation_names().size() == 16, "Sustitución conserva las 16 animaciones")
	check(library.get_frame_count("idle_down") == 4 and library.get_animation_speed("idle_down") == 4.0
		and library.get_animation_loop("idle_down"), "Idle real: cuatro fotogramas, 4 FPS, bucle")
	for index in range(4):
		var texture := library.get_frame_texture("idle_down", index)
		check(texture.resource_path.ends_with("player_idle_down_%02d.png" % index)
			and texture.get_size() == Vector2(128, 128), "PNG real en orden: " + str(index))
	check(sprite.animation == &"idle_down" and visual.rotation == 0.0,
		"Reposo hacia abajo usa arte real sin rotación del mouse")
	check(sprite.scale == Vector2(0.4, 0.4) and sprite.offset == Vector2(0, -56),
		"Escala y pivote visual ajustados sin tocar el cuerpo")
	var frame_before := sprite.frame
	await frames(16)
	check(sprite.frame != frame_before, "La animación real avanza en ejecución")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://test-results/idle-down")
		check(root.get_texture().get_image().save_png("res://test-results/idle-down/in-game.png") == OK,
			"Captura del protagonista real en Main")
	player.velocity = Vector2(240, 0)
	await frames(2)
	check(sprite.animation == &"walk_right" and sprite.sprite_frames.get_frame_texture("walk_right", 0) is AtlasTexture,
		"Caminar a la derecha conserva los fotogramas provisionales")
	check(sprite.scale == Vector2(0.85, 0.85) and sprite.offset == Vector2.ZERO,
		"Salir de idle real restaura escala y pivote provisionales")
	player.velocity = Vector2.ZERO
	player.get_node("Aim").rotation = 0.0
	await frames(2)
	check(sprite.animation == &"idle_right" and library.get_frame_count("idle_right") == 2,
		"Las otras direcciones de reposo siguen provisionales")
	player.health.take_damage(100)
	await frames(2)
	check(sprite.animation == &"death_right" and sprite.scale == Vector2(0.85, 0.85),
		"Muerte conserva animación y transformaciones anteriores")
	print("Resultado idle_down: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
