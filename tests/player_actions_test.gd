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
	DirAccess.make_dir_recursive_absolute("res://test-results/actions")
	check(root.get_texture().get_image().save_png("res://test-results/actions/" + label + ".png") == OK, "Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for direction in ["down", "left", "right", "up"]:
		change_scene_to_file("res://scenes/Main.tscn")
		await frames(4)
		var player := current_scene.get_node("Player")
		var visual := player.get_node("Visual")
		var sprite := visual.get_node("Sprite") as AnimatedSprite2D
		var weapon := player.get_node("Weapon")
		Input.action_press("move_" + direction)
		await frames(2)
		Input.action_release("move_" + direction)
		await frames(2)
		check(sprite.animation == StringName("idle_" + direction), "Idle conservado " + direction)
		check(not sprite.sprite_frames.has_animation("shoot_" + direction), "Shoot rechazado sin doble destello")
		weapon.try_fire(player.position, Vector2.DOWN)
		check(weapon.loaded == 11, "Disparo real intacto")
		check(weapon.start_reload(), "Recarga real inicia")
		await frames(2)
		check(sprite.animation == StringName("reload_" + direction) and sprite.frame == 0, "Inicio visual recarga " + direction)
		await frames(42)
		check(weapon.reloading and weapon.loaded == 11 and sprite.frame >= 2 and sprite.frame <= 3, "Mitad recarga sincronizada")
		await capture("reload-" + direction)
		await frames(48)
		check(not weapon.reloading and weapon.loaded == 12 and weapon.reserve == 47, "Transferencia a 1.5 segundos")
		check(sprite.animation == StringName("idle_" + direction), "Regreso a idle")
		weapon.try_fire(player.position, Vector2.DOWN)
		weapon.start_reload()
		player.health.take_damage(100)
		await frames(2)
		check(visual.dead and not weapon.reloading and not weapon.enabled, "Muerte cancela recarga sin bloqueo visual")
		check(sprite.animation == StringName("death_" + direction) and not sprite.sprite_frames.get_animation_loop(sprite.animation), "Death única " + direction)
		await frames(70)
		check(sprite.frame == 5 and not sprite.is_playing(), "Death conserva último frame")
		await frames(20)
		check(sprite.frame == 5, "Frame final persistente")
		# Solo en la captura se oculta el overlay para inspeccionar el cadáver.
		current_scene.get_node("HUD/GameOver").hide()
		await capture("death-" + direction)
	print("Resultado acciones: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
