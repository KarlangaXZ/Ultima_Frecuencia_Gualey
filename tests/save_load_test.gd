extends SceneTree
var checks := 0
var failures := 0
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
func inspect(main: Node) -> void:
	var results: Dictionary = preload("res://tests/save_assertions.gd").inspect(main)
	for message in results: check(results[message], message)
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
	DirAccess.make_dir_recursive_absolute("res://test-results/save")
	check(root.get_texture().get_image().save_png("res://test-results/save/" + label + ".png") == OK, "Captura " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var saves := main.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-nine-smoke-%d" % OS.get_process_id()
	var directory: String = saves.store.directory
	var initial: Dictionary = saves.capture(2)
	check(SaveSchema.validate(initial).is_empty(), "Snapshot inicial válido")
	check(saves.store.write_slot(2, initial).has("ok"), "Segunda ranura independiente")
	await preload("res://tests/save_fixture.gd").build(self, main)
	var player := main.get_node("Player")
	var data: Dictionary = saves.capture(1)
	check(SaveSchema.validate(data).is_empty(), "Snapshot completo válido: " + SaveSchema.validate(data))
	check(player.weapon.reloading, "Fixture con recarga en curso")
	check(saves.save_slot(1).has("ok"), "Guardar partida completa")
	check(not FileAccess.file_exists(saves.store.path_for(0)), "Autoguardado desactivado, manuales independientes")
	check(saves.load_slot(3).has("error") and current_scene == main and player.health.current_health == 43.5, "Cargar vacía conserva partida actual")
	var corrupt := FileAccess.open(saves.store.path_for(3), FileAccess.WRITE)
	corrupt.store_string("{archivo roto")
	corrupt.close()
	check(saves.load_slot(3).has("error") and current_scene == main, "Cargar corrupta no restaura parcialmente")
	var invalid_position := data.duplicate(true)
	invalid_position.slot = 3
	invalid_position.world.zombies[2].position = [570,495]
	check(saves.store.write_slot(3, invalid_position, true).has("ok"), "Fixture estructural válida con enemigo mal situado")
	check(saves.load_slot(3).has("error") and current_scene == main and player.weapon.reloading, "Validación geométrica conserva todos los estados")
	main.get_node("PauseUI").open_panel()
	await frames(2)
	check(paused and main.get_node("PauseUI").window.visible, "Menú de guardado pausa el árbol")
	check(saves.load_slot(3).has("error") and current_scene == main, "Validación geométrica también durante pausa")
	check(root.get_visible_rect().encloses(main.get_node("PauseUI").panel.get_global_rect()), "Panel de ranuras dentro del viewport")
	await capture("01-slots")
	await click(main.get_node("PauseUI").rows[0].save)
	check(main.get_node("PauseUI").pending_slot == 1 and main.get_node("PauseUI").confirm_button.visible, "Confirmación de sobrescritura visible")
	check(root.get_visible_rect().encloses(main.get_node("PauseUI").panel.get_global_rect()), "Confirmación dentro del viewport")
	await capture("02-confirm")
	await click(main.get_node("PauseUI").confirm_button)
	check(FileAccess.file_exists(saves.store.path_for(1) + ".bak"), "Sobrescribir desde UI crea respaldo")
	var result: Dictionary = saves.load_slot(1)
	check(result.has("ok"), "Cargar partida completa: " + str(result))
	check(current_scene != main and not paused, "Commit sustituye escena y retira pausa")
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	check(saves.store.directory == directory, "Directorio de pruebas conservado en nueva escena")
	inspect(main)
	var loaded_data: Dictionary = saves.capture(1)
	check(loaded_data.player.inventory == data.player.inventory, "Índices de pilas conservados")
	check(loaded_data.missions.receipts == data.missions.receipts, "Interacciones únicas conservadas")
	check(not main.get_node("Missions/Rewards").award(SaveCatalog.MISSIONS[0]), "No volver a premiar misión completada")
	check(not main.get_node("Player/ProgressionRewards").zombie_eliminated(SaveCatalog.find(main.get_node("Zombies"),"zombie_01")), "Cadáver cargado no vuelve a premiar")
	check(not main.get_node("Player/ProgressionRewards").container_opened(SaveCatalog.find(main.get_node("World"),"medical_case")), "Contenedor cargado no repite XP")
	# Repetir carga no acumula habilidades ni mezcla nodos/munición.
	check(saves.load_slot(1).has("ok"), "Segunda carga del mismo archivo")
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	inspect(main)
	# Pausa real: IA, necesidades, cadencia, reloj y daño no avanzan.
	await frames(3)
	await key(KEY_ESCAPE)
	check(paused and main.get_node("PauseUI").window.visible, "Esc abre pausa sin otro panel")
	var before: Dictionary = saves.capture(1)
	Input.action_press("shoot")
	Input.action_press("move_right")
	await frames(120)
	var after: Dictionary = saves.capture(1)
	check(before.player == after.player and before.world == after.world and before.missions == after.missions, "Pausa congela partida completa durante 120 frames")
	Input.action_release("move_right")
	await key(KEY_ESCAPE)
	check(not paused and not main.get_node("PauseUI").window.visible, "Esc continúa")
	check(main.get_node("Player").weapon.loaded == 2, "Cerrar pausa con disparo mantenido no dispara")
	Input.action_release("shoot")
	# Cargar una ranura inicial retira inventario, armas, habilidades e historia anteriores.
	check(saves.load_slot(2).has("ok"), "Cargar segunda ranura")
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	player = main.get_node("Player")
	check(player.get_node("Equipment").get_weapons().size() == 2 and player.weapon.config.id == &"pistol", "No arrastra armas de otra partida")
	check(player.get_node("InventoryComponent").occupied_slots() == 0 and player.health.max_health == 100 and player.get_node("ProgressionComponent").level == 1, "No arrastra pilas ni modificadores")
	check(main.kills == 0 and main.get_node("Population").total_spawned == 6 and main.get_node("Population").active_enemies().size() == 6, "No arrastra cadáveres ni presupuesto")
	check(main.get_node("Missions").active_mission().id == &"signal" and SaveCatalog.find(main.get_node("World"),"pickup_water") != null, "No arrastra misiones ni recogidas")
	await frames(8)
	await key(KEY_TAB)
	await key(KEY_ESCAPE)
	check(not paused and not main.get_node("InventoryUI").window.visible, "Esc cierra mochila sin abrir pausa")
	await key(KEY_K)
	await key(KEY_ESCAPE)
	check(not paused and not main.get_node("CharacterUI").window.visible, "Esc cierra personaje sin abrir pausa")
	await key(KEY_J)
	await key(KEY_ESCAPE)
	check(not paused and not main.get_node("MissionUI").window.visible, "Esc cierra misiones sin abrir pausa")
	# IA y navegación siguen activas después de cargar: actor original real.
	player.position = Vector2(1000,980)
	var enemy := main.get_node("Zombies/ZombieA")
	var start: Vector2 = enemy.position
	await frames(40)
	check(enemy.is_physics_processing() and enemy.position.distance_to(start) > 30 and enemy.state == 1, "IA persigue después de reconstruir navegación")
	check(String(enemy.get_node("Visual/Sprite").animation).begins_with("walk_"), "Walk funciona tras carga")
	# La posición del jugador inválida se recupera sin dejarlo dentro de sólidos.
	var fallback := initial.duplicate(true)
	fallback.slot = 3
	fallback.player.position = [570,495]
	check(saves.store.write_slot(3, fallback, true).has("ok"), "Guardar fixture para recuperación de posición")
	var relocated: Dictionary = saves.load_slot(3)
	check(relocated.has("ok") and relocated.relocated and current_scene.get_node("Player").position == Vector2(600,800), "Posición bloqueada recupera inicio seguro")
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	await frames(8)
	main.get_node("Player/HealthComponent").take_damage(1000)
	check(main.get_node("HUD").game_over.visible and saves.save_slot(1, true).has("error"), "Game Over conservado, no guardar muerto")
	await key(KEY_ESCAPE)
	check(paused and main.get_node("PauseUI").window.visible and main.get_node("PauseUI").rows[0].save.disabled, "Game Over permite abrir menú solo para cargar")
	check(saves.load_slot(1).has("ok") and not current_scene.game_ended, "Cargar recupera partida viva desde Game Over")
	main = current_scene
	main.get_node("Player/HealthComponent").take_damage(1000)
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("Player").health.current_health == 100 and current_scene.get_node("Population").total_spawned == 6 and current_scene.kills == 0, "Reintentar sigue iniciando una partida nueva")
	# Soporte opt-in: archivo separado; se ejecuta después de finalizar la misión.
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	saves.store.directory = directory
	saves.autosave_enabled = true
	var manual_before := FileAccess.get_file_as_string(saves.store.path_for(1))
	main.get_node("Player").position = Vector2(600,680)
	await frames(2)
	main.get_node("Player/Interaction").try_interact()
	await frames(2)
	check(saves.store.read_slot(0).has("data"), "Autoguardado opt-in en archivo separado")
	check(FileAccess.get_file_as_string(saves.store.path_for(1)) == manual_before, "Autoguardado no toca ranura manual")
	var automatic_before := FileAccess.get_file_as_string(saves.store.path_for(0))
	main.get_node("Player/HealthComponent").take_damage(1000)
	saves._autosave()
	check(FileAccess.get_file_as_string(saves.store.path_for(0)) == automatic_before, "No autoguardar durante Game Over")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado guardado/carga: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
