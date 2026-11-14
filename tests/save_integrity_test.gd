extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func write_raw(path: String, raw: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(raw)
	file.close()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await preload("res://tests/save_fixture.gd").frames(self, 8)
	var saves := current_scene.get_node("SaveCoordinator")
	var data: Dictionary = saves.capture(1)
	var store := SaveFileStore.new()
	store.directory = "user://tests/phase-nine-integrity-%d" % OS.get_process_id()
	check(SaveSchema.validate(data, 1).is_empty(), "Snapshot inicial válido")
	check(store.read_slot(1).has("error"), "Ranura vacía")
	check(store.write_slot(1, data).has("ok"), "Primera escritura")
	check(store.read_slot(1).has("data"), "Leer JSON escrito")
	var initial := FileAccess.get_file_as_string(store.path_for(1))
	var changed := data.duplicate(true)
	changed.player.health = 90.0
	check(store.write_slot(1, changed).get("confirmation_required", false), "Confirmar sobrescritura")
	check(FileAccess.get_file_as_string(store.path_for(1)) == initial, "Sin confirmación no modifica")
	check(store.write_slot(1, changed, true).has("ok"), "Sobrescritura confirmada")
	check(store.read_slot(1).data.player.health == 90, "Última versión leída")
	check(store._read(store.path_for(1) + ".bak", 1).data.player.health == 100, "Respaldo previo conservado")
	write_raw(store.path_for(1), "{truncado")
	var recovered := store.read_slot(1)
	check(recovered.has("data") and recovered.recovered and recovered.data.player.health == 100, "Primario corrupto recupera respaldo")
	check(store.write_slot(1, changed, true).has("ok"), "Guardar tras primario corrupto")
	check(store._read(store.path_for(1) + ".bak", 1).data.player.health == 100, "No sustituye respaldo por archivo corrupto")
	DirAccess.remove_absolute(store.path_for(1))
	check(store.read_slot(1).recovered, "Interrupción entre respaldo y commit recuperable")
	write_raw(store.path_for(1) + ".tmp", JSON.stringify(changed))
	check(store.read_slot(1).data.player.health == 100, "Temporal huérfano no se adopta como confirmado")
	write_raw(store.path_for(1) + ".bak", "basura")
	check(store.read_slot(1).has("error"), "Sin archivo recuperable falla sin excepción")
	var slot_two := data.duplicate(true)
	slot_two.slot = 2
	slot_two.version = 999
	write_raw(store.path_for(2), JSON.stringify(slot_two))
	check(store.read_slot(2).error.contains("incompatible"), "Versión incompatible")
	check(store.write_slot(-1, data).has("error") and store.read_slot(99).has("error"), "Ranuras fuera de rango")
	var blocked := SaveFileStore.new()
	blocked.directory = store.directory.path_join("blocked")
	write_raw(blocked.directory, "archivo, no carpeta")
	check(blocked.write_slot(1, data).has("error"), "Error de escritura manejado")
	# Datos no confiables: estructura, tipos, rangos, IDs y coherencia entre sistemas.
	for invalid in [null, [], "partida", 7, {}, {"version": 1}]:
		check(not SaveSchema.validate(invalid).is_empty(), "Rechazar raíz inválida")
	var mutations := [
		func(d): d.player.health = -1,
		func(d): d.player.health = 1000,
		func(d): d.player.position = [0,0],
		func(d): d.player.position = "posición",
		func(d): d.player.inventory = [],
		func(d): d.player.inventory[0] = {"item":"res://scripts/main.gd","quantity":1},
		func(d): d.player.inventory[0] = {"item":"medkit","quantity":99999},
		func(d): d.player.weapons.pistol.reserve = -1,
		func(d): d.player.weapons.pistol.loaded = 13,
		func(d): d.player.weapons["unknown"] = {},
		func(d): d.player.equipped = "shotgun",
		func(d): d.player.skills.vitality = 6,
		func(d): d.player.progression.available_points = 9,
		func(d): d.player.progression.xp = 100,
		func(d): d.player.progression.level = "2",
		func(d): d.player.thirst = true,
		func(d): d.player.penalty_time = 4,
		func(d): d.world.population.spawned = 19,
		func(d): d.world.population.remaining = -0.1,
		func(d): d.world.zombies[0].id = d.world.zombies[1].id,
		func(d): d.world.zombies[0].type = "res://enemy.gd",
		func(d): d.world.zombies[0].health = 51,
		func(d): d.world.kills = 1,
		func(d): d.world.rewarded_containers = ["medical_case"],
		func(d): d.world.pickups.pickup_water = "sí",
		func(d): d.missions.states.signal = 3,
		func(d): d.missions.progress.signal = [99],
		func(d): d.missions.awarded = ["signal"],
		func(d): d.missions.radio = {"transmission":"first", "index":99},
		func(d): d.missions.receipts = ["x","x"],
		func(d): d.missions.totals = {"arbitrary":1},
		func(d): d.map = "other_map",
		func(d): d.slot = 1.5,
		func(d): d.saved_at = "not-a-date",
		func(d): d.saved_at = "2026-02-30T12:00:00Z",
		func(d): d.version = true,
		func(d): d.player.weapons.pistol.reserve = 1.5]
	for mutate in mutations:
		var invalid := data.duplicate(true)
		mutate.call(invalid)
		check(not SaveSchema.validate(invalid).is_empty(), "Rechazar mutación inválida")
	check(SaveSchema.validate(data, 2).contains("ranura"), "Archivo no pertenece a otra ranura")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado integridad guardado: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
