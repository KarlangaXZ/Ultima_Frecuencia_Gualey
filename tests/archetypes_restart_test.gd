extends SceneTree
const FIXTURE := preload("res://tests/archetype_fixture.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await FIXTURE.frames(self,8)
	var saves := current_scene.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-eleven-restart"
	if "--write" in OS.get_cmdline_user_args():
		await FIXTURE.enter_market(self,current_scene)
		FIXTURE.by_type(current_scene,"resistant").health.take_damage(12.5)
		FIXTURE.by_type(current_scene,"runner").health.take_damage(500)
		check(saves.save_slot(1,true).has("ok"),"Guardar variantes antes de cerrar")
		print("Escritor de variantes PID=",OS.get_process_id())
	elif "--read" in OS.get_cmdline_user_args():
		var expected: Dictionary = saves.store.read_slot(1)
		check(expected.has("data") and saves.load_slot(1).has("ok"),"Cargar variantes en otro proceso")
		var main := current_scene
		var after: Dictionary = JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(1),"",true,true))
		check(after.world == expected.data.world and after.zones == expected.data.zones,"Tipos, ID, salud y ambas zonas exactos")
		check(after.player == expected.data.player and after.stats == expected.data.stats and after.missions == expected.data.missions,"Protagonista y progreso intactos")
		check(FIXTURE.by_type(main,"resistant").health.current_health == 87.5 and FIXTURE.by_type(main,"runner").health.is_dead(),"Resistente herido y corredor eliminado conservados")
		check(main.get_node("Zombies").get_child_count() == 6 and main.get_node("Population").active_enemies().size() == 5,"No duplica población ni resucita al cargar")
		print("Lector de variantes PID=",OS.get_process_id())
	else: check(false,"Falta --write o --read")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura arquetipos: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
