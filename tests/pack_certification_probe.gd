extends SceneTree
## Se ejecuta como script externo con --main-pack; no se incluye en el PCK.
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames(n:=5) -> void:
	for i in range(n):await physics_frame;await process_frame
func signal_peak(bus: String) -> float:
	var peak:=-200.0
	var until:=Time.get_ticks_msec()+1600
	while Time.get_ticks_msec()<until:
		await process_frame
		peak=maxf(peak,AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index(bus),0))
	return peak
func run() -> void:
	check(not ResourceLoader.exists("res://tests/phase_one_test.gd"),"Pruebas excluidas del paquete")
	check(not FileAccess.file_exists("res://docs/campaign_certification.md"),"Documentación excluida del paquete")
	for path in ["res://scenes/TitleMenu.tscn","res://scenes/Main.tscn","res://scenes/world/World.tscn","res://scenes/world/MarketWorld.tscn","res://scenes/world/StationWorld.tscn","res://scenes/world/PerimeterWorld.tscn","res://assets/music/menu_last_frequency.wav","res://assets/music/gameplay_streets.wav"]:
		check(ResourceLoader.exists(path) and load(path)!=null,"Recurso de producción incluido: "+path)
	var prefs:=root.get_node("AppPreferences")
	prefs.settings_path="user://tests/phase-seventeen-pack-%d/preferences.cfg"%OS.get_process_id()
	prefs.reset_defaults()
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	await frames()
	var menu:=current_scene
	var directory: String="user://tests/phase-seventeen-pack-%d"%OS.get_process_id()
	menu.store.directory=directory
	check(menu.slot_rows.size()==3,"Tres ranuras desde PCK")
	var music:=root.get_node("MusicDirector")
	if DisplayServer.get_name()!="headless":check(await signal_peak("Music")> -100,"Señal real de menú desde recursos empaquetados")
	menu._launch(1,true,false)
	for i in range(90):
		await frames(1)
		if current_scene.scene_file_path=="res://scenes/Main.tscn":break
	check(current_scene.scene_file_path=="res://scenes/Main.tscn","Nueva partida desde PCK")
	if current_scene.scene_file_path!="res://scenes/Main.tscn":quit(1);return
	var main:=current_scene
	check(main.get_node("Missions").definitions.size()==15,"Quince misiones empaquetadas")
	check(main.get_node("Population").active_enemies().size()==6,"Población inicial empaquetada")
	for slot in range(1,4):check(main.get_node("SaveCoordinator").save_slot(slot,true).has("ok"),"Guardar ranura empaquetada "+str(slot))
	var old: Dictionary=main.get_node("SaveCoordinator").capture(2)
	for z in old.world.zombies:
		if not main.get_node("SaveCoordinator")._position_free(z.position,old.map):print("PCK geometría: ",z)
	var load_result: Dictionary=main.get_node("SaveCoordinator").load_slot(2)
	check(load_result.has("ok"),"Carga transaccional en PCK: "+str(load_result))
	main=current_scene
	var actual: Dictionary=main.get_node("SaveCoordinator").capture(2)
	for key in ["player","world","zones","missions","story","stats"]:check(actual[key]==old[key],"PCK conserva "+key)
	if DisplayServer.get_name()!="headless":check(await signal_peak("Music")> -100 and music.context=="gameplay","Señal real de gameplay desde PCK")
	check(main.get_node("SaveCoordinator").store.directory==directory,"Partidas aisladas, fuera del paquete")
	var report_path: String=get_script().resource_path.get_base_dir().get_base_dir().path_join("test-results/phase-seventeen/campaign.json")
	var campaign: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(report_path))
	main.get_node("SaveCoordinator").store.directory=campaign.directory
	var source_saved: Dictionary=main.get_node("SaveCoordinator").store.read_slot(3)
	check(main.get_node("SaveCoordinator").load_slot(3).has("ok"),"Partida v7 de campaña fuente carga desde PCK")
	main=current_scene
	var full: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(3),"",true,true))
	for key in ["player","world","zones","missions","story","stats"]:check(full[key]==source_saved.data[key],"Campaña fuente → PCK conserva "+key)
	main.get_parent().remove_child(main)
	main.free()
	music.player.stop()
	music.player.stream=null
	if DisplayServer.get_name()!="headless":
		var until:=Time.get_ticks_msec()+100
		while Time.get_ticks_msec()<until:await process_frame
	print("Resultado paquete local: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
