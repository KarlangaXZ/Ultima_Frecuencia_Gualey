extends SceneTree
## Ejecutar -- --write y, en OTRO proceso, -- --read.
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
	await preload("res://tests/save_fixture.gd").frames(self,8)
	var saves := current_scene.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-nine-restart"
	if "--write" in OS.get_cmdline_user_args():
		await preload("res://tests/save_fixture.gd").build(self,current_scene)
		check(saves.save_slot(1,true).has("ok"), "Escribir antes de cerrar proceso")
		print("Escritor PID=", OS.get_process_id(), " · ", ProjectSettings.globalize_path(saves.store.path_for(1)))
	elif "--read" in OS.get_cmdline_user_args():
		check(saves.load_slot(1).has("ok"), "Cargar archivo de otro proceso")
		var results: Dictionary = preload("res://tests/save_assertions.gd").inspect(current_scene)
		for message in results: check(results[message], "Tras reapertura: " + message)
		print("Lector PID=", OS.get_process_id())
	else: check(false, "Falta --write o --read")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
