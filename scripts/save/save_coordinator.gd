extends Node
## Captura estable y reemplazo de escena tras validar/construir por completo.
var store := SaveFileStore.new()
var busy := false
@export var autosave_enabled := false
@onready var main: Node = get_parent()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main.get_node("Missions").mission_completed.connect(func(_mission: MissionDefinition):
		if autosave_enabled: call_deferred("_autosave"))

func capture(slot: int) -> Dictionary:
	return {"version": SaveSchema.VERSION, "slot": slot, "saved_at": Time.get_datetime_string_from_system(true) + "Z",
		"chapter": "signal_lost", "map": "gualey_sector_04", "player": PlayerSaveState.capture(main.get_node("Player")),
		"world": WorldSaveState.capture(main), "missions": MissionSaveState.capture(main)}

func save_slot(slot: int, confirmed := false) -> Dictionary:
	if busy or main.restoring or main.game_ended or main.get_node("Player/HealthComponent").is_dead(): return {"error": "No se puede guardar durante Game Over o una transición."}
	if main.get_node("Missions")._busy or not main.get_node("Population")._initialized: return {"error": "Espera a que termine la actualización del mundo."}
	busy = true
	var result := store.write_slot(slot, capture(slot), confirmed)
	busy = false
	return result

func _autosave() -> void:
	if autosave_enabled and not get_tree().paused and not busy and not main.restoring and not main.game_ended:
		var result := save_slot(0, true)
		if result.has("error"): main.get_node("HUD").show_message("Autoguardado: " + result.error)

func _position_free(point: Array) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	query.shape = circle
	query.transform = Transform2D(0, Vector2(point[0], point[1]))
	query.collision_mask = 1
	return main.get_node("Player").get_world_2d().direct_space_state.intersect_shape(query).is_empty()

func load_slot(slot: int) -> Dictionary:
	if busy or main.restoring: return {"error": "Ya hay una carga en curso."}
	var loaded := store.read_slot(slot)
	if not loaded.has("data"): return loaded
	var data: Dictionary = loaded.data.duplicate(true)
	var relocated := false
	if not _position_free(data.player.position):
		data.player.position = [600.0, 800.0]
		relocated = true
	for zombie in data.world.zombies:
		if zombie.health > 0 and not _position_free(zombie.position): return {"error": "Un enemigo guardado está dentro de un obstáculo. La partida actual se conserva."}
	busy = true
	var tree := get_tree()
	var candidate := load("res://scenes/Main.tscn").instantiate() as Node2D
	candidate.restoring = true
	candidate.process_mode = Node.PROCESS_MODE_DISABLED
	candidate.hide()
	# Evitar dos regiones superpuestas mientras se prepara la escena nueva.
	candidate.get_node("World/Navigation").enabled = false
	tree.root.add_child(candidate)
	_set_audio(candidate, false)
	PlayerSaveState.restore(candidate.get_node("Player"), data.player)
	MissionSaveState.restore(candidate, data.missions)
	WorldSaveState.restore(candidate, data.world)
	candidate.get_node("SaveCoordinator").store.directory = store.directory
	candidate.get_node("SaveCoordinator").autosave_enabled = autosave_enabled
	_refresh_presentation(candidate)
	# Solo datos permitidos y reconstruidos; no se ejecuta ninguna ruta del JSON.
	var check_data: Dictionary = candidate.get_node("SaveCoordinator").capture(slot)
	var problem := SaveSchema.validate(check_data, slot)
	if not problem.is_empty():
		tree.root.remove_child(candidate)
		candidate.queue_free()
		busy = false
		return {"error": "No se pudo reconstruir la partida: " + problem}
	# Punto de confirmación: la escena anterior permanece intacta hasta aquí.
	main.get_parent().remove_child(main)
	main.queue_free()
	tree.current_scene = candidate
	candidate.restoring = false
	candidate.process_mode = Node.PROCESS_MODE_INHERIT
	candidate.get_node("World/Navigation").enabled = true
	candidate.show()
	tree.paused = false
	candidate.get_node("Player/Camera2D").reset_smoothing()
	candidate.get_node("Player/Camera2D").force_update_scroll()
	_set_audio(candidate, true)
	var audio: Node = candidate.get_node("Audio")
	if audio.ambience_enabled and DisplayServer.get_name() != "headless": audio.ambience.play()
	var message := "Partida cargada desde respaldo." if loaded.recovered else "Partida cargada."
	if relocated: message += " Posición recuperada en el inicio seguro."
	candidate.get_node("HUD").show_message(message)
	return {"ok": true, "recovered": loaded.recovered, "relocated": relocated}

func _set_audio(root: Node, enabled: bool) -> void:
	if root is SoundEmitter: root.enabled = enabled
	for child in root.get_children(): _set_audio(child, enabled)

func _refresh_presentation(scene: Node) -> void:
	var player: Node = scene.get_node("Player")
	var hud: Node = scene.get_node("HUD")
	hud.previous_health = player.health.current_health
	hud.update_health(player.health.current_health, player.health.max_health)
	hud.update_stats(scene.kills, scene.survival_time)
	scene._update_equipment(player.weapon)
	scene._update_progression()
	scene._update_needs(player.get_node("SurvivalComponent").hunger, player.get_node("SurvivalComponent").thirst)
	scene.get_node("InventoryUI").refresh()
	scene.get_node("ObjectiveHUD").show()
