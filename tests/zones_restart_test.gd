extends SceneTree
## --write y --read se ejecutan en procesos separados, nunca sobre ranuras reales.
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
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var saves := main.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-ten-restart"
	if "--write" in OS.get_cmdline_user_args():
		await preload("res://tests/save_fixture.gd").build(self,main)
		preload("res://tests/save_fixture.gd").close_windows(main)
		var player := main.get_node("Player")
		player.position = Vector2(600,680)
		await frames(2)
		player.get_node("Interaction").try_interact()
		main.get_node("RadioUI").close_window()
		main.set_process(true)
		player.set_physics_process(true)
		player.get_node("SurvivalComponent").set_physics_process(true)
		main.get_node("Population").set_physics_process(true)
		for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(true)
		check(main.get_node("ZoneManager").request_travel(ZoneCatalog.MARKET,"from_gualey"),"Viajar antes de cerrar proceso")
		await main.get_node("ZoneManager").transition_finished
		await frames(3)
		player.position = Vector2(580,830)
		await frames(2)
		player.get_node("Interaction").try_interact()
		main.get_node("Zombies/ZombieA/HealthComponent").take_damage(50)
		check(saves.save_slot(1,true).has("ok"),"Guardar en mercado antes de cerrar")
		print("Escritor de mercado PID=",OS.get_process_id())
	elif "--read" in OS.get_cmdline_user_args():
		var stored: Dictionary = saves.store.read_slot(1)
		check(stored.has("data"),"Archivo del proceso anterior disponible")
		if not stored.has("data"):
			quit(1)
			return
		check(saves.load_slot(1).has("ok"),"Cargar mercado desde proceso nuevo")
		main = current_scene
		var manager := main.get_node("ZoneManager")
		var player := main.get_node("Player")
		# JSON convierte enteros a números Variant; comparar la misma representación.
		var after: Dictionary = JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(1),"",true,true))
		check(manager.current_zone == ZoneCatalog.MARKET,"Mapa correcto tras reapertura")
		check(after.player == stored.data.player,"Protagonista, pilas, habilidades y armas exactos")
		check(after.world == stored.data.world,"Estado activo del mercado exacto")
		check(after.zones == stored.data.zones,"Estado inactivo original exacto")
		check(after.stats == stored.data.stats and after.missions == stored.data.missions,"Estadísticas y misiones globales exactas")
		check(not after.world.pickups.market_water and not after.zones[ZoneCatalog.HOME].pickups.pickup_water,"Recogidas de ambas zonas conservadas")
		check(main.get_node("Zombies").get_child_count() == 6 and main.get_node("Population").active_enemies().size() == 5,"Sin zombis duplicados ni resucitados")
		var id: int = player.get_instance_id()
		check(manager.request_travel(ZoneCatalog.HOME,"from_market"),"Regresar después de reabrir")
		await manager.transition_finished
		check(main.get_node("Population").total_spawned == 7 and main.kills == 4,"Presupuesto original y bajas globales restaurados")
		check(SaveCatalog.find(main.get_node("World"),"pickup_water") == null and player.get_instance_id() == id,"Mantiene recogidas y una instancia de jugador al volver")
		print("Lector de mercado PID=",OS.get_process_id())
	else: check(false,"Falta --write o --read")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura zonas: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
