extends SceneTree
var checks: int = 0
var failures: int = 0

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
	DirAccess.make_dir_recursive_absolute("res://test-results/zombie")
	check(root.get_texture().get_image().save_png("res://test-results/zombie/" + label + ".png") == OK, "Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var directions := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}
	for direction: String in directions:
		change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
		await frames(5)
		var main := current_scene
		var player := main.get_node("Player")
		var zombie := main.get_node("Zombies/ZombieA")
		var visual := zombie.get_node("Visual")
		var sprite := visual.get_node("Sprite") as AnimatedSprite2D
		check(sprite.animation == &"idle_down", "Idle inicial sin detección")
		for state_name in ["idle", "walk", "attack", "death"]:
			var animation: String = state_name + "_" + direction
			var expected := 4 if state_name == "idle" else (8 if state_name == "walk" else 6)
			check(sprite.sprite_frames.get_frame_count(animation) == expected, "Frames " + animation)
			check(sprite.sprite_frames.get_animation_loop(animation) == (state_name in ["idle", "walk"]), "Bucle " + animation)
		player.position = Vector2(1200, 800)
		zombie.position = player.position - directions[direction] * 160.0
		await frames(10)
		check(zombie.state == zombie.State.CHASE and sprite.animation == StringName("walk_" + direction), "Detecta y camina " + direction)
		check(visual.rotation == 0.0 and sprite.scale == Vector2(0.85, 0.85), "Arte orientado sin rotación cenital")
		await capture("walk-" + direction)
		zombie.position = player.position - directions[direction] * 34.0
		zombie.cooldown = 0.0
		await frames(3)
		check(sprite.animation == StringName("attack_" + direction) and player.health.current_health == 90.0, "Ataque visual y 10 HP reales")
		check(sprite.frame <= 1, "Ataque inicia en primer frame")
		await frames(40)
		check(player.health.current_health == 90.0 and sprite.frame >= 2, "Visual avanza sin daño adicional")
		await capture("attack-" + direction)
		await frames(50)
		check(player.health.current_health == 80.0 and sprite.frame <= 1, "Cooldown real reinicia ataque a 1.5 s")
		zombie.health.take_damage(25)
		check(zombie.health.current_health == 25.0 and not visual.dead, "Salud previa conservada")
		zombie.health.take_damage(25)
		await frames(30)
		check(sprite.animation == StringName("death_" + direction) and sprite.frame == 5 and not sprite.is_playing(), "Muerte única termina " + direction)
		check(zombie.collision_layer == 0 and main.kills == 1 and is_equal_approx(zombie.modulate.a, 0.25), "Desactivación, baja y fade originales")
		zombie.health.take_damage(50)
		await frames(4)
		check(main.kills == 1 and sprite.frame == 5, "Muerte no se repite")
		await capture("death-" + direction)
	print("Resultado zombi visual: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
