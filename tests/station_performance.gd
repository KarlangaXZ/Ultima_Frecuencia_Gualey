extends "res://tests/performance_phase_11_1.gd"
## Misma instrumentación/ventana/VSync; preparación narrativa fuera de muestras.
func run() -> void:
	output="res://test-results/performance/station"
	DirAccess.make_dir_recursive_absolute(output)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	process_frame.connect(_sample)
	await fresh()
	await preload("res://tests/station_fixture.gd").complete_market(self,current_scene)
	# La preparación elimina dos variantes. Reponer fuera de la muestra para
	# comparar seis vivos estables y no confundir reposición legítima con fuga.
	var population:=current_scene.get_node("Population")
	for i in range(2):
		population._physics_process(10.1)
		await preload("res://tests/archetype_fixture.gd").frames(self,3)
	check(population.active_enemies().size()==6,"Mercado estabilizado con seis vivos")
	await measure("market_control")
	check(await preload("res://tests/station_fixture.gd").travel(self,ZoneCatalog.STATION,"from_market"),"Viajar a estación para medir")
	await measure("station_idle")
	var player:=current_scene.get_node("Player")
	player.position=Vector2(650,800)
	var starts: Array=[Vector2(500,650),Vector2(650,620),Vector2(800,650),Vector2(480,850),Vector2(820,850),Vector2(650,980)]
	var index:=0
	for enemy in current_scene.get_node("Zombies").get_children():
		enemy.position=starts[index]
		index+=1
	await measure("station_six")
	player.position=Vector2(320,800)
	var stable: Dictionary={}
	for i in range(6):
		var destination: String=ZoneCatalog.MARKET if i%2==0 else ZoneCatalog.STATION
		check(await preload("res://tests/station_fixture.gd").travel(self,destination,"from_station" if i%2==0 else "from_market"),"Transición de benchmark")
		await measure("station_transition_%d"%i,1.5,0.3)
		var state:=snapshot("settled_%d"%i)
		if stable.has(destination):
			var previous: Dictionary=stable[destination]
			check(state.nodes==previous.nodes and state.audio_players==previous.audio_players and state.player_death_connections==previous.player_death_connections,"Sin acumulaciones en benchmark")
		stable[destination]=state
	var result: Dictionary={"scenarios":rows,"snapshots":snapshots,"checks":checks,"failures":failures,
		"environment":{"version":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"debug":OS.is_debug_build(),"window":DisplayServer.window_get_size()}}
	FileAccess.open(output+"/metrics.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado rendimiento estación: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
