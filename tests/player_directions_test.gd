extends SceneTree
## Verifica biblioteca parcial y conservación de la última dirección.
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

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/directions")
	check(root.get_texture().get_image().save_png("res://test-results/directions/" + label + ".png") == OK,
		"Captura " + label)

func run() -> void:
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
	await frames(3)
	var player := current_scene.get_node("Player") as CharacterBody2D
	var sprite := player.get_node("Visual/Sprite") as AnimatedSprite2D
	var library := sprite.sprite_frames
	var sources := {"idle_left": "idle_left", "walk_up": "walk_up", "idle_up": "idle_right", "idle_right": "idle_up", "walk_right": "walk_left", "walk_left": "walk_left"}
	for name: String in sources:
		var count := 4 if name.begins_with("idle") else 8
		check(library.get_frame_count(name) == count and library.get_animation_speed(name) == float(count)
			and library.get_animation_loop(name), "Cantidad, FPS y bucle " + name)
		for index in range(count):
			check(library.get_frame_texture(name, index).resource_path.ends_with("player_%s_%02d.png" % [sources[name], index]),
				"Orden " + name + " " + str(index))
	for direction in ["down", "up", "left", "right"]:
		Input.action_press("move_" + direction)
		await frames(8)
		check(sprite.animation == StringName("walk_" + direction), "Caminar " + direction)
		await capture("walk-" + direction)
		Input.action_release("move_" + direction)
		await frames(3)
		check(sprite.animation == StringName("idle_" + direction), "Detenerse " + direction)
		await capture("idle-" + direction)
	check(library.get_frame_texture("walk_left", 0).resource_path == "res://assets/characters/player/walk/player_walk_left_00.png"
		and library.get_frame_texture("walk_right", 0).resource_path == "res://assets/characters/player/walk/legacy_right/player_walk_left_00.png",
		"Walk izquierdo usa V2 y derecho conserva originales separados")
	check(library.get_frame_count("death_down") == 6, "Muerte técnica integrada")
	print("Resultado direcciones: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
