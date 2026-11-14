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
		"chapter": "signal_lost", "map": main.get_node("ZoneManager").current_zone, "player": PlayerSaveState.capture(main.get_node("Player")),
		"zones": main.get_node("ZoneManager").states.duplicate(true), "stats": {"kills": main.kills,"survival_time": main.survival_time},
		"world": WorldSaveState.capture(main), "missions": MissionSaveState.capture(main)}

func save_slot(slot: int, confirmed := false) -> Dictionary:
	if busy or main.restoring or main.get_node("ZoneManager").busy or main.game_ended or main.get_node("Player/HealthComponent").is_dead(): return {"error": "No se puede guardar durante Game Over o una transición."}
	if main.get_node("Missions")._busy or not main.get_node("Population")._initialized: return {"error": "Espera a que termine la actualización del mundo."}
	busy = true
	var result := store.write_slot(slot, capture(slot), confirmed)
	busy = false
	return result

func _autosave() -> void:
	if autosave_enabled and not get_tree().paused and not busy and not main.restoring and not main.game_ended:
		var result := save_slot(0, true)
		if result.has("error"): main.get_node("HUD").show_message("Autoguardado: " + result.error)

func _position_free(point: Array, zone_id: String) -> bool:
	return ZoneCatalog.point_free(zone_id,point)

func load_slot(slot: int) -> Dictionary:
	if busy or main.restoring or main.get_node("ZoneManager").busy: return {"error": "Ya hay una carga o transición en curso."}
	var loaded := store.read_slot(slot)
	if not loaded.has("data"): return loaded
	var data: Dictionary = loaded.data.duplicate(true)
	var relocated := false
	if not _position_free(data.player.position,data.map):
		var safe: Vector2 = ZoneCatalog.definition(data.map).entries.initial
		data.player.position = [safe.x,safe.y]
		relocated = true
	var worlds: Dictionary = data.zones.duplicate(true)
	worlds[data.map] = data.world
	for id in worlds:
		for zombie in worlds[id].zombies:
			if zombie.health > 0 and not _position_free(zombie.position,id): return {"error": "Un enemigo guardado está dentro de un obstáculo. La partida actual se conserva."}
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
	candidate.get_node("ZoneManager").restore_session(data.map,data.zones,data.missions.unlocked_zones)
	PlayerSaveState.restore(candidate.get_node("Player"), data.player)
	MissionSaveState.restore(candidate, data.missions)
	WorldSaveState.restore(candidate, data.world)
	candidate.kills = int(data.stats.kills)
	candidate.survival_time = data.stats.survival_time
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
	if loaded.get("migrated",false): message += " Guardado v1 adaptado a v2."
	if relocated: message += " Posición recuperada en el inicio seguro."
	candidate.get_node("HUD").show_message(message)
	candidate.get_node("ZoneOverlay").show_location(ZoneCatalog.definition(data.map).display_name)
	return {"ok": true, "recovered": loaded.recovered, "relocated": relocated, "migrated": loaded.get("migrated",false)}

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
