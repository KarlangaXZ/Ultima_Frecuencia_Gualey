extends SceneTree
var checks := 0
var failures := 0
var level_events := 0
var last_points := 0
var reentry_succeeded := false
var reward_reentry := false

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	point = root.get_screen_transform() * point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-seven")
	check(root.get_texture().get_image().save_png("res://test-results/phase-seven/" + label + ".png") == OK, "Captura " + label)

func _on_level(_level: int, points: int) -> void:
	level_events += 1
	last_points = points

func run_initial_checks(player: Node) -> void:
	var progression := player.get_node("ProgressionComponent") as ProgressionComponent
	var skills := player.get_node("SkillsComponent") as SkillsComponent
	check(progression.level == 1 and progression.xp == 0 and progression.available_points == 0, "Nivel, XP y puntos iniciales")
	check(skills.definitions.size() == 4 and skills.snapshot().values().all(func(rank): return rank == 0), "Cuatro habilidades sin rangos")
	check(player.health.max_health == 100 and player.health.current_health == 100 and player.speed == 240 and player.effective_speed() == 240, "Salud y velocidad base")
	check(player.get_node("SurvivalComponent").consumption_multiplier == 1 and player.weapon.reload_multiplier == 1, "Sin bonificaciones iniciales")
	check(player.get_node("InventoryComponent").capacity == 12 and player.get_node("InventoryComponent").occupied_slots() == 0, "Inventario inicial intacto")
	check(player.weapon.loaded == 12 and player.weapon.reserve == 48 and not player.get_node("Equipment").owns(&"revolver"), "Arsenal inicial intacto")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player")
	var progression := player.get_node("ProgressionComponent") as ProgressionComponent
	var skills := player.get_node("SkillsComponent") as SkillsComponent
	var rewards := player.get_node("ProgressionRewards")
	var stats := player.get_node("Stats")
	var character := main.get_node("CharacterUI")
	var inventory_ui := main.get_node("InventoryUI")
	var hud := main.get_node("HUD")
	var audio := main.get_node("Audio")
	var equipment := player.get_node("Equipment") as EquipmentComponent
	var health := player.get_node("HealthComponent") as HealthComponent
	var survival := player.get_node("SurvivalComponent") as SurvivalComponent
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var pistol := player.get_node("Weapon")
	var actor_a := main.get_node("Zombies/ZombieA")
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
	progression.leveled_up.connect(_on_level)
	run_initial_checks(player)
	check(InputMap.action_get_events("character")[0].physical_keycode == KEY_K, "K físico sin conflicto")
	check(hud.get_node("Panel").size.x <= 260 and hud.get_node("Panel").size.y <= 185, "HUD compacto no crece")
	check(hud.get_node("Panel/Margin/Content/Sector").text.contains("NIV 1"), "HUD muestra nivel real")
	check(not rewards.zombie_eliminated(actor_a) and progression.xp == 0, "No premiar un enemigo vivo")
	var empty := load("res://scenes/items/LootContainer.tscn").instantiate() as LootContainer
	main.add_child(empty)
	check(not rewards.container_opened(empty) and progression.xp == 0, "Contenedor vacío no otorga XP")
	empty.queue_free()
	var supply := main.get_node("World/Supplies/SupplyCrate") as LootContainer
	player.position = supply.position - Vector2(0, 35)
	await frames(2)
	var on_reward := func(): reward_reentry = rewards.container_opened(supply)
	progression.changed.connect(on_reward)
	await key(KEY_E)
	progression.changed.disconnect(on_reward)
	check(progression.xp == 20 and inventory_ui.container == supply, "Primera apertura real entrega veinte XP")
	check(not reward_reentry and progression.xp == 20, "Reentrada en señal de XP no duplica premio")
	check(not rewards.container_opened(supply) and progression.xp == 20, "Notificación repetida no duplica premio")
	await key(KEY_TAB)
	await key(KEY_E)
	check(progression.xp == 20, "Reabrir contenedor no permite farmear XP")
	actor_a.health.take_damage(50)
	actor_a.health.take_damage(50)
	check(main.kills == 1 and progression.xp == 50, "Una baja, treinta XP, daño posterior ignorado")
	check(not rewards.zombie_eliminated(actor_a) and progression.xp == 50, "Premio de zombi repetido rechazado")
	main.get_node("Zombies/ZombieB/HealthComponent").take_damage(50)
	var cue_before: int = audio.ui.played_counts.get(&"pickup_supply", 0)
	main.get_node("Zombies/ZombieC/HealthComponent").take_damage(50)
	check(main.kills == 3 and progression.level == 2 and progression.xp == 10 and progression.available_points == 1, "Tres bajas y contenedor cruzan primer nivel")
	check(level_events == 1 and last_points == 1 and audio.ui.played_counts.get(&"pickup_supply", 0) == cue_before + 1, "Una notificación y un sonido por subida")
	check(hud.get_node("Feedback").text.contains("Nivel 2"), "Notificación discreta de nivel")
	inventory_ui.close_window()
	var medical := main.get_node("World/Supplies/MedicalCase") as LootContainer
	player.position = medical.position - Vector2(0, 35)
	await frames(2)
	await key(KEY_E)
	check(progression.xp == 30, "Otro contenedor tiene premio propio")
	await key(KEY_K)
	check(character.window.visible and not inventory_ui.window.visible and player.controls_blocked, "K abre personaje y cierra mochila sin desbloqueo")
	check(character.content.get_node("Summary").text.contains("Nivel 2") and character.content.get_node("XPBar").value == 30, "Panel refleja XP real")
	check(character.content.get_node("Body/Skills").get_child_count() == 4, "Cuatro filas de habilidades")
	var panel := character.window.get_node("Center/Panel") as Control
	check(Rect2(Vector2.ZERO, character.window.size).encloses(panel.get_global_rect()), "Panel completo dentro de 1280 × 720")
	await capture("01-character")
	print("Etapa: panel inicial validado")
	await click(character._rows[&"vitality"].button)
	check(skills.rank_of(&"vitality") == 1 and progression.available_points == 0, "Botón gasta un punto en un rango")
	check(health.max_health == 105 and health.current_health == 100 and health.base_max_health == 100, "Vitalidad aumenta máximo sin curación gratuita")
	check(not skills.upgrade(&"vitality") and skills.rank_of(&"vitality") == 1, "Sin puntos no repetir asignación")
	var start: Vector2 = player.position
	Input.action_press("shoot")
	Input.action_press("move_down")
	Input.action_press("reload")
	await frames(25)
	await key(KEY_E)
	check(player.position == start and pistol.loaded == 12 and not pistol.reloading and character.window.visible, "PERSONAJE bloquea movimiento, combate, R y E")
	Input.action_release("move_down")
	Input.action_release("reload")
	await key(KEY_TAB)
	check(inventory_ui.window.visible and not character.window.visible and player.controls_blocked, "Tab pasa a mochila manteniendo bloqueo")
	await key(KEY_K)
	check(character.window.visible and not inventory_ui.window.visible and player.controls_blocked, "K regresa a personaje manteniendo bloqueo")
	await key(KEY_ESCAPE)
	check(not character.window.visible and not inventory_ui.window.visible and not player.controls_blocked, "Escape cierra y libera solo al no quedar ventanas")
	await frames(20)
	check(pistol.loaded == 12, "Cerrar con clic sostenido no dispara")
	Input.action_release("shoot")
	await frames(2)
	Input.action_press("shoot")
	await frames(1)
	Input.action_release("shoot")
	check(pistol.loaded == 11, "Combate regresa tras soltar y pulsar")
	await frames(20)
	# Fixture de gran recompensa: no añade enemigos, misiones ni respawn al mundo.
	progression.add_xp(100000)
	print("Etapa: progresión al máximo")
	check(progression.level == 10 and progression.available_points == 8 and progression.xp == 0, "Recompensa multinivel hasta máximo, descontando punto ya gastado")
	check(level_events == 2 and last_points == 8, "Multinivel genera una sola notificación con ocho puntos")
	var on_points := func(): reentry_succeeded = skills.upgrade(&"agility")
	progression.changed.connect(on_points)
	check(skills.upgrade(&"vitality"), "Compra protegida frente a reentrada")
	progression.changed.disconnect(on_points)
	check(not reentry_succeeded and skills.rank_of(&"agility") == 0 and progression.available_points == 7, "Una señal no gasta el mismo punto dos veces")
	for index in range(3): check(skills.upgrade(&"vitality"), "Rango de vitalidad " + str(index + 3))
	check(skills.rank_of(&"vitality") == 5 and health.max_health == 125 and health.current_health == 100, "Máximo cinco rangos, límite de salud correcto")
	check(not skills.upgrade(&"vitality") and progression.available_points == 4, "Sexto rango rechazado incluso con puntos")
	check(not skills.upgrade(&"missing"), "Habilidad desconocida rechazada")
	for index in range(20):
		stats.refresh()
		character.refresh()
	check(health.max_health == 125 and health.base_max_health == 100 and progression.available_points == 4, "Refrescos no acumulan bonus ni gastan puntos")
	check(skills.upgrade(&"agility") and is_equal_approx(player.effective_speed(), 247.2) and player.speed == 240, "Agilidad sobre velocidad base inmutable")
	player.position = Vector2(1200, 800)
	Input.action_press("move_down")
	Input.action_press("move_left")
	await frames(8)
	check(is_equal_approx(player.velocity.length(), 247.2), "Diagonal normalizada conserva velocidad efectiva")
	Input.action_release("move_down")
	Input.action_release("move_left")
	await frames(2)
	pistol.try_fire(player.position, Vector2.UP)
	check(pistol.start_reload(), "Recarga base iniciada antes de aprender manejo")
	print("Etapa: recargas mejoradas")
	await frames(30)
	var fraction: float = pistol.reload_remaining / pistol.reload_duration_current
	var reload_cues: int = audio.combat.played_counts.get(&"reload", 0)
	check(skills.upgrade(&"handling") and is_equal_approx(pistol.reload_duration_current, 1.44), "Primer rango reduce recarga cuatro por ciento")
	check(is_equal_approx(pistol.reload_remaining / pistol.reload_duration_current, fraction), "Recarga en curso conserva progreso")
	check(skills.upgrade(&"handling") and is_equal_approx(pistol.reload_duration_current, 1.38), "Dos rangos reducen ocho por ciento de la base")
	check(pistol.config.reload_duration == 1.5 and audio.combat.played_counts.get(&"reload", 0) == reload_cues, "Recurso compartido y sonido no se reinician")
	await frames(2)
	var sprite := player.get_node("Visual/Sprite") as AnimatedSprite2D
	var expected := int((1.0 - pistol.reload_remaining / pistol.reload_duration_current) * 6)
	check(String(sprite.animation).begins_with("reload_") and absi(sprite.frame - expected) <= 1, "Animación de recarga usa duración efectiva")
	await frames(60)
	check(not pistol.reloading and pistol.loaded == 12 and pistol.reserve == 46, "Recarga mejorada transfiere munición una sola vez")
	equipment.obtain(preload("res://resources/weapons/Revolver.tres"))
	equipment.obtain(preload("res://resources/weapons/Shotgun.tres"))
	var revolver := equipment.get_weapon(&"revolver")
	var shotgun := equipment.get_weapon(&"shotgun")
	check(is_equal_approx(revolver.effective_reload_duration(), 1.932) and is_equal_approx(shotgun.effective_reload_duration(), 2.208), "Armas obtenidas después heredan manejo")
	for index in range(10):
		equipment.switch_to(&"revolver")
		equipment.switch_to(&"pistol")
		stats.refresh()
	check(is_equal_approx(pistol.effective_reload_duration(), 1.38) and health.max_health == 125 and is_equal_approx(player.effective_speed(), 247.2), "Cambios de arma no acumulan modificadores")
	check(equipment.get_weapon(&"machete").reload_multiplier == 1, "Machete no recibe modificador de recarga")
	equipment.switch_to(&"revolver")
	revolver.add_reserve(6)
	revolver.start_reload()
	await frames(113)
	check(revolver.reloading, "Revólver respeta duración efectiva antes del final")
	await frames(5)
	check(revolver.loaded == 6 and revolver.reserve == 0 and revolver.config.reload_duration == 2.1, "Recarga de revólver correcta sin cambiar config")
	equipment.switch_to(&"shotgun")
	shotgun.add_reserve(6)
	shotgun.start_reload()
	await frames(129)
	check(shotgun.reloading, "Escopeta respeta duración efectiva antes del final")
	await frames(5)
	check(shotgun.loaded == 6 and shotgun.reserve == 0 and shotgun.config.reload_duration == 2.4, "Recarga de escopeta y recursos intactos")
	check(skills.upgrade(&"survival") and is_equal_approx(survival.consumption_multiplier, 0.95), "Supervivencia reduce consumo cinco por ciento")
	survival.set_physics_process(false)
	survival.hunger = 100
	survival.thirst = 100
	survival.advance(60)
	check(is_equal_approx(survival.hunger, 98.1) and is_equal_approx(survival.thirst, 97.15), "Descenso proporcional en reloj de supervivencia real")
	check(survival.hunger_seconds_per_point == 30 and survival.thirst_seconds_per_point == 20 and survival.penalty_damage == 2, "Bases de supervivencia y penalización conservadas")
	check(progression.available_points == 0 and not skills.upgrade(&"agility"), "Nueve puntos totales gastados sin sobrepasar saldo")
	health.take_damage(20)
	inventory.add_item(preload("res://resources/items/Medkit.tres"), 2)
	check(player.get_node("ItemUse").use_slot(0) and health.current_health == 120, "Botiquín reutiliza salud con máximo mejorado")
	check(player.get_node("ItemUse").use_slot(0) and health.current_health == 125, "Curación limitada a máximo mejorado")
	character.open_panel()
	await frames(2)
	check(character.content.get_node("Summary").text.contains("MÁXIMO") and character.content.get_node("XPBar").value == 1, "Nivel máximo no divide por cero en UI")
	check(character.content.get_node("Body/Stats/Values").text.contains("247.2") and character.content.get_node("Body/Stats/Values").text.contains("95 %"), "Estadísticas del panel son efectivas")
	await capture("02-skills")
	print("Etapa: panel de habilidades validado")
	var ranks := skills.snapshot()
	ranks.vitality = 999
	check(skills.rank_of(&"vitality") == 5, "Snapshot de rangos no muta componente")
	health.take_damage(1000)
	check(hud.game_over.visible and not character.window.visible and not inventory_ui.window.visible, "Game Over cierra ambas interfaces")
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	player = current_scene.get_node("Player")
	run_initial_checks(player)
	progression = player.get_node("ProgressionComponent")
	skills = player.get_node("SkillsComponent")
	rewards = player.get_node("ProgressionRewards")
	character = current_scene.get_node("CharacterUI")
	progression.add_xp(100)
	character.open_panel()
	player.health.take_damage(1000)
	check(progression.available_points == 1 and not skills.upgrade(&"vitality"), "Muerte impide gastar incluso con puntos disponibles")
	check(not progression.add_xp(1000) and progression.level == 2 and progression.xp == 0, "XP bloqueada tras Game Over")
	current_scene.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
	check(progression.xp == 0 and not rewards.container_opened(current_scene.get_node("World/Supplies/SupplyCrate")), "Ni bajas ni contenedores premian después de muerte")
	await key(KEY_K)
	check(not character.window.visible, "No abrir PERSONAJE tras Game Over")
	current_scene.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	player = current_scene.get_node("Player")
	run_initial_checks(player)
	check(player.get_node("ProgressionRewards").container_opened(current_scene.get_node("World/Supplies/SupplyCrate"))
		and player.get_node("ProgressionComponent").xp == 20, "Reintentar restaura también el registro de premios")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado fase 7: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
