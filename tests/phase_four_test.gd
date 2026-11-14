extends SceneTree
## Estados visuales con gameplay real. -- --capture guarda PNG al renderizar.
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
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-four")
	# Las capturas son resultados, no recursos del juego para importar/exportar.
	var marker := FileAccess.open("res://test-results/.gdignore", FileAccess.WRITE)
	if marker != null:
		marker.close()
	var path := "res://test-results/phase-four/" + label + ".png"
	var error := root.get_texture().get_image().save_png(path)
	check(error == OK, "Captura renderizada " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var visual := player.get_node("Visual")
	var sprite := visual.get_node("Sprite") as AnimatedSprite2D
	var weapon := player.get_node("Weapon")
	var effects := player.get_node("Combat/Effects")
	var hud := main.get_node("HUD")
	var zombie := main.get_node("Zombies/ZombieA")
	var zombie_visual := zombie.get_node("Visual")
	var zombie_sprite := zombie_visual.get_node("Sprite") as AnimatedSprite2D
	check(sprite.sprite_frames.get_animation_names().size() == 24, "Jugador incluye Shoot y conserva estados")
	for direction in ["down", "up", "left", "right"]:
		check(sprite.sprite_frames.has_animation("idle_" + direction)
			and sprite.sprite_frames.has_animation("walk_" + direction), "Reposo y marcha disponibles: " + direction)
	check(String(sprite.animation).begins_with("idle"), "Jugador quieto reproduce idle")
	check(String(zombie_sprite.animation).begins_with("idle"), "Zombi quieto reproduce idle")
	var first_frame := sprite.frame
	await frames(35)
	check(sprite.frame != first_frame, "Idle avanza fotogramas distintos")
	check(main.get_node("World/Obstacles/CrateA/Visual").texture.get_size() == Vector2(128, 96),
		"Arte de caja coincide con huella de colisión")
	check(hud.bar.get_theme_stylebox("fill") is StyleBoxFlat, "Barra usa estilo visible del tema")
	await capture("01-overview")
	Input.action_press("move_down")
	await frames(12)
	check(String(sprite.animation).begins_with("walk"), "WASD activa walk")
	var walk_frame := sprite.frame
	await frames(7)
	check(sprite.frame != walk_frame, "Walk cambia fotogramas")
	Input.action_release("move_down")
	await frames(2)
	check(String(sprite.animation).begins_with("idle"), "Soltar movimiento vuelve a idle")
	# Llevar al jugador cerca del zombi en zona libre de cajas.
	player.position = Vector2(1120, 800)
	await frames(8)
	check(String(zombie_sprite.animation).begins_with("walk"), "CHASE reproduce marcha de zombi")
	# Aislar el ataque y el destello para observarlos dentro del mismo paso físico.
	zombie.position = player.position + Vector2(34, 0)
	zombie.cooldown = 0.0
	await frames(2)
	check(String(zombie_sprite.animation).begins_with("attack"), "ATTACK reproduce animación de ataque")
	check(visual.flash_remaining > 0.0 and hud.get_node("DamageFlash").color.a > 0.0,
		"Daño al jugador activa sprite y overlay sin alterar salud")
	check(player.health.current_health == 90.0 and hud.bar.value == 90.0, "Daño conserva valor real de 10 HP")
	zombie.set_physics_process(false)
	# Disparo con daño real a zombi y efecto de impacto orgánico.
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(effects.last_impact_kind == "zombie" and effects.particles.size() == 8,
		"Impacto en zombi genera feedback moderado")
	check(effects.flash_time > 0.0, "Disparo genera destello")
	check(zombie_visual.flash_remaining > 0.0 and zombie.health.current_health == 25.0,
		"Hit de zombi activa feedback conservando 25 HP de daño")
	await capture("02-combat")
	await frames(20)
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(zombie_visual.dead and String(zombie_sprite.animation).begins_with("death"),
		"Muerte activa animación no repetida")
	check(not zombie_sprite.sprite_frames.get_animation_loop(zombie_sprite.animation), "Death no está en bucle")
	await frames(30)
	check(zombie_sprite.frame == 5 and zombie.collision_layer == 0 and main.kills == 1,
		"Death finaliza con enemigo desactivado y una sola baja")
	await capture("03-death")
	# Impacto en escenario; conservar hit por rayo, sin lógica en efectos.
	player.position = Vector2(600, 800)
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(effects.last_impact_kind == "world", "Pared genera chispas diferenciadas")
	await frames(22)
	check(effects.particles.is_empty() and effects.flash_time == 0.0, "Efectos temporales se limpian")
	effects.effects_enabled = false
	var ammo_before: int = weapon.loaded
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(weapon.loaded == ammo_before - 1 and effects.particles.is_empty(),
		"Desactivar efectos mantiene disparo y munición")
	weapon.start_reload()
	check(hud.get_node("Panel/Margin/Content/Reload").text == "RECARGANDO...", "Aviso de recarga conserva datos")
	await capture("04-reload")
	player.health.take_damage(1000)
	check(visual.dead and String(sprite.animation).begins_with("death"), "Jugador muerto reproduce death")
	check(not player.get_node("Aim").visible, "Arma visual se oculta al morir")
	await frames(65)
	check(sprite.frame == 5 and hud.game_over.visible, "Death termina y Game Over sigue operativo")
	check(hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").get_global_rect().size.y >= 48,
		"Reintentar conserva objetivo visible grande")
	await capture("05-game-over")
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	main = current_scene
	check(not main.get_node("Player/Visual").dead and main.get_node("Player/Aim").visible,
		"Reintentar restaura presentación del jugador")
	check(not main.get_node("HUD/GameOver").visible and main.get_node("HUD/DamageFlash").color.a == 0.0,
		"Reinicio limpia overlays")
	check(main.get_node("Player/Combat/Effects").particles.is_empty(), "Reinicio limpia efectos")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado fase 4: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
