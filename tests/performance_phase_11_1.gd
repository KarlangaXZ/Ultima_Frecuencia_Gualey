extends SceneTree
## Diagnóstico gráfico con reloj real. Nunca ejecutar con --fixed-fps.
const FIXTURE := preload("res://tests/archetype_fixture.gd")
var rows: Array = []
var snapshots: Array = []
var checks := 0
var failures := 0
var collecting := false
var samples: Array = []
var last_tick := 0
var output := "res://test-results/performance/default"
var combat := false
var shot_index := 0
var transition_ms := 0.0
var cycles := 6
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func wait_seconds(seconds: float) -> void:
	var end := Time.get_ticks_usec() + int(seconds * 1000000)
	while Time.get_ticks_usec() < end: await process_frame
func _sample() -> void:
	var now := Time.get_ticks_usec()
	if collecting and last_tick > 0:
		samples.append([float(now-last_tick)/1000,
			Performance.get_monitor(Performance.TIME_PROCESS)*1000,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,
			Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS)*1000,
			RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()),
			RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),
			RenderingServer.get_frame_setup_time_cpu()])
	last_tick = now
func _physics_combat() -> void:
	if not combat or not is_instance_valid(current_scene): return
	var player := current_scene.get_node("Player")
	var enemies: Array = current_scene.get_node("Population").active_enemies()
	if enemies.is_empty(): return
	var enemy: Node = enemies[shot_index % enemies.size()]
	if player.weapon.try_fire(player.global_position,player.global_position.direction_to(enemy.global_position)):
		shot_index += 1
	elif player.weapon.loaded == 0: player.weapon.start_reload()
func snapshot(label: String) -> Dictionary:
	var main := current_scene
	var all := main.find_children("*","",true,false)
	var audio := 0
	var processing := 0
	var enemy_subtree_nodes := 0
	for enemy in main.get_node("Zombies").get_children():
		enemy_subtree_nodes += 1+enemy.find_children("*","",true,false).size()
	for node in all:
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D: audio += 1
		if node.can_process() and (node.is_processing() or node.is_physics_processing()): processing += 1
	var result := {"label":label,"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"tree_nodes":root.get_child_count()+all.size()+1,"processing_nodes":processing,
		"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"tracked_mib":OS.get_static_memory_usage()/1048576.0,
		"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,
		"alive":main.get_node("Population").active_enemies().size(),"enemy_nodes":main.get_node("Zombies").get_child_count(),
		"audio_players":audio,"regions":main.find_children("*","NavigationRegion2D",true,false).size(),
		"enemy_subtree_nodes":enemy_subtree_nodes,
		"player_death_connections":main.get_node("Player/HealthComponent").died.get_connections().size(),
		"zone":main.get_node("ZoneManager").current_zone,"focus":DisplayServer.window_is_focused()}
	snapshots.append(result)
	return result
func percentile(values: Array, fraction: float) -> float:
	values.sort()
	return values[maxi(0,ceili(values.size()*fraction)-1)]
func measure(label: String, seconds := 3.0, warmup := 1.0) -> void:
	await wait_seconds(warmup)
	samples.clear()
	last_tick = 0
	collecting = true
	FileAccess.open(output+"/stage.txt",FileAccess.WRITE).store_string(label)
	await wait_seconds(seconds)
	collecting = false
	var summary := snapshot(label)
	summary["frames"] = samples.size()
	summary["samples"] = samples.duplicate(true)
	for column in range(7):
		var values: Array = []
		var total := 0.0
		for sample in samples:
			values.append(sample[column])
			total += sample[column]
		var key: String = ["wall","process","physics","navigation","render_cpu","render_gpu","render_setup"][column]
		summary[key+"_mean_ms"] = total/maxi(1,values.size())
		summary[key+"_p95_ms"] = percentile(values,0.95) if not values.is_empty() else 0.0
		summary[key+"_max_ms"] = values.max() if not values.is_empty() else 0.0
	summary["observed_fps"] = 1000.0/maxf(0.001,summary.wall_mean_ms)
	rows.append(summary)
	print("PERF ",label," fps=",snappedf(summary.observed_fps,0.1)," mean=",snappedf(summary.wall_mean_ms,0.01)," p95=",snappedf(summary.wall_p95_ms,0.01)," physics=",snappedf(summary.physics_mean_ms,0.001)," nodes=",summary.nodes)
func travel(destination: String, entry: String) -> void:
	var manager := current_scene.get_node("ZoneManager")
	check(manager.request_travel(destination,entry),"Viaje aceptado " + destination)
	await manager.transition_finished
	await wait_seconds(0.3)
func stage_enemies(all_six := true) -> void:
	var main := current_scene
	var player := main.get_node("Player")
	player.position = Vector2(1000,900)
	var offsets := [Vector2(-110,-120),Vector2(0,-150),Vector2(110,-120),Vector2(-180,40),Vector2(180,40),Vector2(0,180)]
	var index := 0
	for enemy in main.get_node("Zombies").get_children():
		if enemy.health.is_dead(): continue
		if all_six or index < 3: enemy.position = player.position + offsets[index]
		index += 1
func fresh() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await wait_seconds(1.0)
	# Solo fixture: no morir durante muestras largas; no altera daño/configuración.
	current_scene.get_node("Player/HealthComponent").health_changed.connect(func(hp, maximum):
		if hp > 0 and hp < maximum: current_scene.get_node("Player/HealthComponent").heal(maximum-hp))
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--cap="): Engine.max_fps = int(arg.trim_prefix("--cap="))
		if arg.begins_with("--cycles="): cycles = clampi(int(arg.trim_prefix("--cycles=")),6,60)
	DirAccess.make_dir_recursive_absolute(output)
	var no_vsync := "--no-vsync" in OS.get_cmdline_user_args()
	if no_vsync: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	process_frame.connect(_sample)
	physics_frame.connect(_physics_combat)
	await fresh()
	var environment := {"version":Engine.get_version_info(),"debug":OS.is_debug_build(),"cpu":OS.get_processor_name(),
		"cpu_threads":OS.get_processor_count(),"memory":OS.get_memory_info(),"gpu":RenderingServer.get_video_adapter_name(),
		"driver":RenderingServer.get_current_rendering_driver_name(),"window_size":DisplayServer.window_get_size(),
		"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"physics_hz":Engine.physics_ticks_per_second,
		"args":OS.get_cmdline_args(),"pid":OS.get_process_id()}
	await measure("home_idle")
	stage_enemies()
	await measure("home_six")
	await fresh()
	await FIXTURE.enter_market(self,current_scene)
	check(FIXTURE.counts(current_scene)=={"base":3,"runner":2,"resistant":1},"Mezcla mercado")
	stage_enemies()
	await measure("market_mixed")
	combat = true
	await measure("combat",3.0,0.0)
	combat = false
	await fresh()
	current_scene.get_node("InventoryUI").open_inventory()
	await measure("inventory")
	current_scene.get_node("InventoryUI").close_window()
	current_scene.get_node("CharacterUI").open_panel()
	await measure("character")
	current_scene.get_node("CharacterUI").close_window()
	await FIXTURE.enter_market(self,current_scene)
	# Estabilidad: no bajas ni cercanía, ambos mapas con seis vivos.
	await measure("market_settled",2.0)
	var stable_by_zone := {}
	for cycle in range(cycles):
		# Medir también los fundidos; la región y los actores anteriores deben liberarse.
		var destination: String = ZoneCatalog.HOME if cycle % 2 == 0 else ZoneCatalog.MARKET
		var entry := "from_market" if destination == ZoneCatalog.HOME else "from_gualey"
		var manager := current_scene.get_node("ZoneManager")
		var previous_world: WeakRef = weakref(current_scene.get_node("World"))
		var previous_enemy: WeakRef = weakref(current_scene.get_node("Zombies").get_child(0))
		var started := Time.get_ticks_usec()
		manager.transition_finished.connect(func(_ok): transition_ms=(Time.get_ticks_usec()-started)/1000.0,CONNECT_ONE_SHOT)
		check(manager.request_travel(destination,entry),"Transición repetida")
		await measure("transition_%d" % cycle,1.6,0.0)
		check(not manager.busy,"Transición terminada")
		rows[-1]["transition_ms"] = transition_ms
		var state := snapshot("settled_%d" % cycle)
		check(previous_world.get_ref()==null and previous_enemy.get_ref()==null,"Zona y actor anteriores liberados")
		# enter_market elimina dos comunes para completar la misión: sus cadáveres
		# permanecen en Home; no confundirlos con una pérdida de población.
		check(state.regions==1 and state.alive<=6 and state.enemy_nodes==current_scene.get_node("Population").total_spawned and state.enemy_nodes<=18,"Una región/población conservada")
		check(state.audio_players==9+state.enemy_nodes*3,"Pool audio estable")
		check(state.orphans==0,"Sin nodos huérfanos")
		if stable_by_zone.has(destination):
			var previous: Dictionary = stable_by_zone[destination]
			# La reposición puede añadir hasta dos actores por las bajas de misión;
			# descontar SOLO sus nodos y conexiones died legítimos. El monitor de
			# recursos compartidos permanece constante; no descontar por actor.
			check(state.nodes-state.enemy_subtree_nodes==previous.nodes-previous.enemy_subtree_nodes and state.resources==previous.resources and state.player_death_connections-state.enemy_nodes==previous.player_death_connections-previous.enemy_nodes,"Nodos/recursos/señales estables por zona")
		stable_by_zone[destination] = state
	var saves := current_scene.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-eleven-one-performance-"+str(OS.get_process_id())
	var start := Time.get_ticks_usec()
	var saved: Dictionary = saves.save_slot(1,true)
	var save_ms := (Time.get_ticks_usec()-start)/1000.0
	check(saved.has("ok"),"Guardar fixture")
	start = Time.get_ticks_usec()
	var loaded: Dictionary = saves.load_slot(1)
	var load_ms := (Time.get_ticks_usec()-start)/1000.0
	check(loaded.has("ok"),"Cargar fixture")
	await measure("after_save_load",2.0)
	var final_state := snapshot("final")
	check(final_state.regions==1 and final_state.alive==6,"Carga sin duplicación")
	var result := {"environment":environment,"scenarios":rows,"snapshots":snapshots,
		"save_ms":save_ms,"load_ms":load_ms,"checks":checks,"failures":failures}
	FileAccess.open(output+"/metrics.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("Guardado=",save_ms," ms; carga=",load_ms," ms")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado rendimiento: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
