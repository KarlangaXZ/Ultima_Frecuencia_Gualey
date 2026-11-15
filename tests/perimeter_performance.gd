extends "res://tests/performance_phase_11_1.gd"
## Reloj real, mismo instrumento que estación; no usar --fixed-fps ni capturas.
func run() -> void:
	output="res://test-results/performance/perimeter"
	DirAccess.make_dir_recursive_absolute(output)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	process_frame.connect(_sample)
	await fresh()
	await preload("res://tests/perimeter_fixture.gd").complete_station(self)
	var main:=current_scene
	var population:=main.get_node("Population")
	for i in range(2):
		population._physics_process(10.1)
		await preload("res://tests/archetype_fixture.gd").frames(self,3)
	check(population.active_enemies().size()==6,"Control estación estabilizado con seis vivos")
	for z in population.active_enemies():z.set_physics_process(true)
	main.get_node("Player").position=Vector2(320,800)
	main.get_node("Player/Camera2D").reset_smoothing()
	main.get_node("Player/Camera2D").force_update_scroll()
	await measure("station_control")
	check(await preload("res://tests/station_fixture.gd").travel(self,ZoneCatalog.PERIMETER,"from_station"),"Viajar al Perímetro")
	preload("res://tests/station_fixture.gd").finish_radio(main)
	await measure("perimeter_idle")
	main.get_node("Player").position=Vector2(1200,950)
	var starts: Array=[Vector2(1100,930),Vector2(1200,850),Vector2(1320,970),Vector2(1020,1020),Vector2(1190,1060),Vector2(1330,1000)]
	for i in range(6):
		check(ZoneCatalog.point_free(ZoneCatalog.PERIMETER,[starts[i].x,starts[i].y]),"Posición de benchmark fuera de sólidos")
		main.get_node("Zombies").get_child(i).position=starts[i]
	await measure("perimeter_six")
	main.get_node("Player").position=Vector2(1200,1350)
	var stable: Dictionary={}
	var route: Array=[ZoneCatalog.STATION,ZoneCatalog.MARKET,ZoneCatalog.HOME,ZoneCatalog.MARKET,ZoneCatalog.STATION,ZoneCatalog.PERIMETER]
	for i in range(12):
		var dest: String=route[i%route.size()]
		var entry: String=main.get_node("ZoneManager").active_definition().connections[dest]
		check(await preload("res://tests/station_fixture.gd").travel(self,dest,entry),"Transición de benchmark")
		await measure("perimeter_transition_%d"%i,1.5,0.3)
		var state:=snapshot("settled_%d"%i)
		if stable.has(dest):
			var previous: Dictionary=stable[dest]
			check(state.nodes==previous.nodes and state.audio_players==previous.audio_players and state.player_death_connections==previous.player_death_connections and state.resources==previous.resources,"Sin acumulación en benchmark")
		stable[dest]=state
	var result: Dictionary={"scenarios":rows,"snapshots":snapshots,"checks":checks,"failures":failures,
		"environment":{"version":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"debug":OS.is_debug_build(),"window":DisplayServer.window_get_size()}}
	FileAccess.open(output+"/metrics.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado rendimiento Perímetro: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
