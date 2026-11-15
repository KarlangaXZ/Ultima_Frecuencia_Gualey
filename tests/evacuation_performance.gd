extends "res://tests/performance_phase_11_1.gd"
## Comparación equivalente antes/después, sin fixed-fps ni capturas paralelas.
func run() -> void:
	output = "res://test-results/phase-sixteen/performance-after"
	if "--before" in OS.get_cmdline_user_args(): output = "res://test-results/phase-sixteen/performance-before"
	DirAccess.make_dir_recursive_absolute(output)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	process_frame.connect(_sample)
	await fresh()
	check(await preload("res://tests/perimeter_fixture.gd").enter(self),"Preparar Perímetro")
	var main := current_scene
	preload("res://tests/station_fixture.gd").finish_radio(main)
	await measure("perimeter_idle",4,1)
	main.get_node("Player").position = Vector2(1200,950)
	var starts := [Vector2(1100,930),Vector2(1200,850),Vector2(1320,970),Vector2(1020,1020),Vector2(1190,1060),Vector2(1330,1000)]
	for i in range(6): main.get_node("Zombies").get_child(i).position=starts[i]
	await measure("perimeter_six",4,1)
	main.get_node("Player").position=Vector2(1200,1350)
	var stable := snapshot("before_trips")
	for i in range(6):
		var destination := ZoneCatalog.STATION if i%2==0 else ZoneCatalog.PERIMETER
		var entry: String = main.get_node("ZoneManager").active_definition().connections[destination]
		check(await preload("res://tests/station_fixture.gd").travel(self,destination,entry),"Viaje medido")
		preload("res://tests/station_fixture.gd").finish_radio(main)
		await measure("trip_%d"%i,1.0,.3)
	var settled := snapshot("after_trips")
	check(settled.nodes==stable.nodes and settled.audio_players==stable.audio_players and settled.resources==stable.resources and settled.player_death_connections==stable.player_death_connections,"Nodos, recursos, voces y señales estables")
	var result := {"scenarios":rows,"snapshots":snapshots,"checks":checks,"failures":failures,
		"environment":{"version":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"debug":OS.is_debug_build(),"window":DisplayServer.window_get_size()}}
	FileAccess.open(output+"/metrics.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado rendimiento capítulo 4: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
