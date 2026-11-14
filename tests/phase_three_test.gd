extends SceneTree
## Integración: arma real, consultas físicas, entrada, HUD y reinicio de Main.
var checks: int = 0
var failures: int = 0
var resolved_shots: int = 0

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

func mouse_at_world(player: Node2D, world_position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = player.get_viewport().get_canvas_transform() * world_position
	motion.global_position = motion.position
	motion.position = player.get_viewport().get_screen_transform() * motion.position
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	Input.flush_buffered_events()

func run() -> void:
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var weapon := player.get_node("Weapon")
	var combat := player.get_node("Combat")
	var hud := main.get_node("HUD")
	var zombies := main.get_node("Zombies").get_children()
	for zombie in zombies:
		zombie.set_physics_process(false)
	combat.shot_resolved.connect(func(_endpoint: Vector2, _hit: bool): resolved_shots += 1)
	check(weapon.loaded == 12 and weapon.reserve == 48, "Pistola inicia 12 / 48")
	check(weapon.config.damage == 25.0 and weapon.config.shot_range == 600.0,
		"Configuración de daño y alcance")
	check(hud.get_node("Panel/Margin/Content/Ammo").text == "Munición: 12 / 48", "HUD muestra munición inicial")
	check(not weapon.start_reload(), "Cargador lleno no permite recarga")
	check(not weapon.try_fire(player.position, Vector2.ZERO) and weapon.loaded == 12,
		"Dirección nula no consume munición")
	# Caja A entre el punto inicial y ZombieA.
	check(weapon.try_fire(player.position, Vector2.RIGHT), "Disparo válido consume una bala")
	check(weapon.loaded == 11 and zombies[0].health.current_health == 50.0,
		"Caja bloquea daño al zombi")
	check(absf(combat.trace_end.x - 736.0) < 1.0 and combat.hit_something,
		"Trazo termina en el impacto con la caja")
	check(not weapon.try_fire(player.position, Vector2.RIGHT) and weapon.loaded == 11,
		"Cadencia rechaza disparo inmediato")
	await frames(10)
	check(not weapon.try_fire(player.position, Vector2.RIGHT), "No dispara antes de 0.3 segundos")
	await frames(10)
	# Línea despejada y dos enemigos alineados: únicamente el primero recibe daño.
	player.position = Vector2(1000, 1200)
	zombies[0].position = Vector2(1150, 1200)
	zombies[1].position = Vector2(1250, 1200)
	zombies[2].position = Vector2(1700, 1300)
	await frames(2)
	check(weapon.try_fire(player.position, Vector2.RIGHT), "Disparo disponible después de cadencia")
	check(zombies[0].health.current_health == 25.0 and zombies[1].health.current_health == 50.0,
		"Impacto causa 25 HP solo al primer enemigo")
	check(combat.trace_end.distance_to(Vector2(1134, 1200)) < 1.0,
		"Dirección y punto de impacto corresponden al rayo")
	await frames(20)
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(zombies[0].state == zombies[0].State.DEAD and main.kills == 1,
		"Dos impactos eliminan zombi de 50 HP y suman una baja")
	zombies[0].health.take_damage(25)
	check(main.kills == 1, "Daño a cadáver no repite eliminación")
	await frames(30)
	check(zombies[0].collision_layer == 0 and zombies[0].get_node("CollisionShape2D").disabled,
		"Cadáver desactiva colisiones")
	check(zombies[0].modulate.a < 0.3, "Efecto provisional de muerte se completa")
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(zombies[1].health.current_health == 25.0, "Cadáver no bloquea disparos al siguiente zombi")
	await frames(20)
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(main.kills == 2 and hud.get_node("Panel/Margin/Content/Stats").text.begins_with("Eliminados: 2"),
		"HUD refleja eliminaciones")
	# Fuera de alcance: el borde del cuerpo también queda más allá de 600 px.
	zombies[2].position = Vector2(1700, 1200)
	await frames(20)
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(zombies[2].health.current_health == 50.0, "No daña fuera del alcance")
	check(combat.trace_end.distance_to(player.position + Vector2(600, 0)) < 1.0 and not combat.hit_something,
		"Trazo sin impacto muestra alcance de 600 px")
	# La próxima entrada dispara mientras WASD mueve al jugador y el mouse apunta arriba.
	await frames(20)
	player.get_node("Camera2D").reset_smoothing()
	await frames(3)
	mouse_at_world(player, player.position + Vector2(0, -200))
	var old_position := player.position
	var old_ammo: int = weapon.loaded
	Input.action_press("move_right")
	Input.action_press("shoot")
	await frames(2)
	Input.action_release("shoot")
	Input.action_release("move_right")
	check(player.position.x > old_position.x and weapon.loaded == old_ammo - 1,
		"Puede disparar mientras se mueve")
	check((combat.trace_end - combat.trace_start).normalized().dot(Vector2.UP) > 0.99,
		"Entrada de mouse determina dirección independientemente de WASD")
	check(absf(player.get_node("Aim").rotation + PI / 2.0) < 0.1,
		"Indicador del arma sigue al mouse")
	# Gastar cargador hasta exactamente 4 y probar la entrada R.
	while weapon.loaded > 4:
		await frames(20)
		weapon.try_fire(player.position, Vector2.DOWN)
	check(weapon.loaded == 4 and weapon.reserve == 48, "Ocho disparos dejan 4 / 48")
	Input.action_press("reload")
	await frames(2)
	Input.action_release("reload")
	check(weapon.reloading and hud.get_node("Panel/Margin/Content/Reload").text == "RECARGANDO...",
		"R inicia recarga y actualiza HUD")
	check(not weapon.start_reload(), "No permite recargas simultáneas")
	check(not weapon.try_fire(player.position, Vector2.RIGHT) and weapon.loaded == 4,
		"No dispara durante recarga")
	await frames(70)
	check(weapon.reloading and weapon.loaded == 4 and weapon.reserve == 48,
		"No transfiere balas antes de 1.5 segundos")
	await frames(22)
	check(not weapon.reloading and weapon.loaded == 12 and weapon.reserve == 40,
		"Recarga parcial transfiere exactamente ocho balas")
	check(hud.get_node("Panel/Margin/Content/Reload").text == ""
		and hud.get_node("Panel/Margin/Content/Ammo").text == "Munición: 12 / 40", "HUD refleja recarga finalizada")
	# Vaciar el cargador real, verificando una resolución por bala válida.
	var before: int = resolved_shots
	for index in range(12):
		await frames(20)
		weapon.try_fire(player.position, Vector2.DOWN)
	await frames(20)
	check(weapon.loaded == 0 and resolved_shots - before == 12, "Doce balas producen exactamente doce disparos")
	check(not weapon.try_fire(player.position, Vector2.DOWN) and resolved_shots - before == 12,
		"Cargador vacío no dispara")
	# Reserva insuficiente: configuración reutilizable de otra instancia del mismo arma.
	var small_weapon := load("res://scripts/weapons/weapon.gd").new() as Node
	var small_config := WeaponConfig.new()
	small_config.initial_reserve = 3
	small_weapon.config = small_config
	root.add_child(small_weapon)
	for index in range(12):
		await frames(20)
		small_weapon.try_fire(Vector2.ZERO, Vector2.RIGHT)
	small_weapon.start_reload()
	await frames(92)
	check(small_weapon.loaded == 3 and small_weapon.reserve == 0, "Reserva limitada transfiere solo tres balas")
	check(not small_weapon.start_reload(), "Sin reserva no permite recarga")
	small_weapon.queue_free()
	check(main.survival_time > 1.0 and not hud.get_node("Panel/Margin/Content/Stats").text.ends_with("00:00"),
		"Tiempo de supervivencia avanza y se muestra")
	# El tercer enemigo también se elimina con el arma original.
	weapon.start_reload()
	await frames(92)
	zombies[2].position = player.position + Vector2(150, 0)
	await frames(2)
	weapon.try_fire(player.position, Vector2.RIGHT)
	await frames(20)
	weapon.try_fire(player.position, Vector2.RIGHT)
	check(main.kills == 3, "Pistola permite eliminar los tres zombis existentes")
	await frames(20)
	check(weapon.start_reload(), "Puede iniciar recarga antes de morir")
	var loaded_at_death: int = weapon.loaded
	var reserve_at_death: int = weapon.reserve
	player.get_node("HealthComponent").take_damage(100)
	await frames(2)
	var frozen_time: float = main.survival_time
	check(hud.game_over.visible and not weapon.enabled and not weapon.reloading,
		"Game Over cancela recarga y deshabilita arma")
	Input.action_press("shoot")
	Input.action_press("reload")
	await frames(100)
	Input.action_release("shoot")
	Input.action_release("reload")
	check(weapon.loaded == loaded_at_death and weapon.reserve == reserve_at_death,
		"Muerte cancela transferencia y bloquea entradas de combate")
	check(not weapon.try_fire(player.position, Vector2.RIGHT) and not weapon.start_reload(),
		"Arma deshabilitada rechaza acciones directas")
	check(main.survival_time == frozen_time, "Tiempo se detiene al morir")
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	main = current_scene
	weapon = main.get_node("Player/Weapon")
	check(main.kills == 0 and main.survival_time < 0.2, "Reintentar reinicia bajas y tiempo")
	check(weapon.loaded == 12 and weapon.reserve == 48 and weapon.enabled and not weapon.reloading,
		"Reintentar restaura arma, munición y recarga")
	check(main.get_node("Player/HealthComponent").current_health == 100.0,
		"Reintentar restaura salud")
	for zombie in main.get_node("Zombies").get_children():
		check(zombie.health.current_health == 50.0 and zombie.collision_layer == 4,
			"Reintentar restaura zombi y colisión de impactos")
	check(InputMap.action_get_events("shoot")[0].button_index == MOUSE_BUTTON_LEFT
		and InputMap.action_get_events("reload")[0].physical_keycode == KEY_R,
		"Acciones configuradas como clic izquierdo y R")
	print("Resultado fase 3: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
