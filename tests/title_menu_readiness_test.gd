extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func run() -> void:
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	for i in range(3):
		await physics_frame
		await process_frame
	var menu := current_scene
	var directory := "user://tests/phase-sixteen-readiness-%d-%d"%[OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	menu.store.directory=directory
	var count := [0]
	var safe := [true]
	# Simular ocho frames sin región publicada, solo en esta prueba.
	var gate := func():
		var candidate := root.get_node_or_null("LaunchPreparation")
		if candidate!=null:
			count[0]+=1
			safe[0]=safe[0] and candidate.survival_time==0 and candidate.get_node("Player/HealthComponent").current_health==100
			candidate.get_node("World/Navigation").enabled=count[0]>=8
	physics_frame.connect(gate)
	menu._launch(1,true,false)
	for i in range(90):
		await physics_frame
		await process_frame
		if current_scene.scene_file_path=="res://scenes/Main.tscn": break
	physics_frame.disconnect(gate)
	check(count[0]>=8,"La preparación esperó más de cuatro frames")
	check(safe[0],"La espera no simula tiempo ni daño de gameplay")
	check(current_scene.scene_file_path=="res://scenes/Main.tscn","Navegación tardía permite iniciar sin cambiar la población")
	if current_scene.scene_file_path=="res://scenes/Main.tscn":
		var main := current_scene
		check(main.get_node("Population").active_enemies().size()==6 and main.get_node("Population")._initialized,"Seis enemigos antes del commit")
		check(main.get_node("SaveCoordinator").store.read_slot(1).has("data"),"Guardar únicamente estado inicializado")
		check(main.get_node("Missions").started_chapters==[ChapterCatalog.FIRST] and not main.restoring,"Partida inicial sin capítulos anticipados")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado preparación de inicio: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
