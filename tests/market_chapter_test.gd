extends SceneTree
## Recorrido con entrada/física e interacciones reales. IA aislada aquí; prueba
## market_chapter_state_test mantiene IA activa y comprueba persistencia/migración.
var checks := 0
var failures := 0
var walked := 0.0
var main: Node
var player: CharacterBody2D
var tracker: MissionTracker
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func frames(n := 2) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func key(code: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=code
		event.keycode=code
		event.pressed=pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
func close_radio() -> void:
	while main.get_node("Radio").transmission!=null:
		main.get_node("Radio").advance()
	await frames()
func freeze_enemies() -> void:
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
func bind_scene() -> void:
	main=current_scene
	player=main.get_node("Player")
	tracker=main.get_node("Missions")
	freeze_enemies()
	main.zombie_added.connect(func(enemy):enemy.set_physics_process(false))
func walk_to(target: Vector2) -> void:
	var path:=NavigationServer2D.map_get_path(player.get_world_2d().navigation_map,player.position,target,true)
	check(not path.is_empty() and path[-1].distance_to(target)<3,"Ruta conectada "+str(target))
	for waypoint in path:
		var ticks:=0
		while player.position.distance_to(waypoint)>5 and ticks<1000:
			var direction:=player.position.direction_to(waypoint)
			for pair in [["move_right",direction.x],["move_left",-direction.x],["move_down",direction.y],["move_up",-direction.y]]:
				Input.action_press(pair[0],maxf(0,pair[1]))
			var previous:=player.position
			await frames(1)
			walked+=previous.distance_to(player.position)
			ticks+=1
		for action in ["move_up","move_down","move_left","move_right"]: Input.action_release(action)
		await frames(1)
		if ticks>=1000: break
	check(player.position.distance_to(target)<8,"Llegada física "+str(target))
func interact(target: Vector2) -> void:
	await walk_to(target)
	await key(KEY_E)
func point(name: String) -> void:
	var p: MissionPoint=main.get_node("World/ChapterPoints/"+name)
	await interact(p.position+Vector2(0,30))
func shoot(enemy: Node) -> void:
	var candidate:=Vector2.ZERO
	for offset in [Vector2(0,-80),Vector2(-80,0),Vector2(80,0),Vector2(0,80)]:
		var p: Vector2=enemy.position+offset
		if not ZoneCatalog.point_free(main.get_node("ZoneManager").current_zone,[p.x,p.y]): continue
		var ray:=PhysicsRayQueryParameters2D.create(p,enemy.position,1)
		if player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			candidate=p
			break
	check(candidate!=Vector2.ZERO,"Puesto de tiro transitable")
	await walk_to(candidate)
	var count:=ceili(enemy.health.current_health/player.get_node("Weapon").config.damage)
	for i in range(count):
		if player.weapon.loaded==0:
			check(player.weapon.start_reload(),"Recarga real")
			await frames(91)
		check(player.weapon.try_fire(player.position,player.position.direction_to(enemy.position)),"Disparo válido")
		await frames(19)
	check(enemy.health.is_dead(),"Baja real "+String(enemy.archetype.id))
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-twelve")
	check(root.get_texture().get_image().save_png("res://test-results/phase-twelve/"+label+".png")==OK,"Captura "+label)
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	bind_scene()
	check(tracker.definitions.size()==7 and tracker.started_chapters==[ChapterCatalog.FIRST],"Siete misiones, capítulo 2 bloqueado")
	check(not main.get_node("ZoneManager").request_travel(ZoneCatalog.MARKET,"from_gualey"),"Salida inicialmente bloqueada")
	# Capítulo 1 completo: sin eventos de misión sintéticos ni XP añadida.
	await interact(Vector2(560,810))
	await interact(Vector2(650,880))
	await shoot(main.get_node("Zombies/ZombieA"))
	await shoot(main.get_node("Zombies/ZombieB"))
	await interact(Vector2(600,680))
	await close_radio()
	await interact(Vector2(1720,630))
	await close_radio()
	await interact(Vector2(600,680))
	await close_radio()
	check(tracker.chapter_completed(ChapterCatalog.FIRST) and tracker.active_chapter==ChapterCatalog.FIRST,"Capítulo 1 completado sin anticipar capítulo 2")
	await interact(Vector2(2090,800))
	if main.get_node("ZoneManager").busy: await main.get_node("ZoneManager").transition_finished
	await frames(4)
	check(tracker.active_chapter==ChapterCatalog.MARKET and tracker.active_mission().id==&"market_traces","Entrada real inicia Ecos del Mercado")
	var market_points:=main.get_node("World/ChapterPoints")
	for p in market_points.get_children():
		if not p is MissionPoint: continue
		check(ZoneCatalog.point_free(ZoneCatalog.MARKET,[p.position.x,p.position.y]),"Punto fuera de sólidos: "+p.name)
		var path:=NavigationServer2D.map_get_path(player.get_world_2d().navigation_map,player.position,p.position+Vector2(0,30),true)
		check(not path.is_empty() and path[-1].distance_to(p.position+Vector2(0,30))<3,"Punto alcanzable: "+p.name)
	check(not market_points.get_node("Power").available and not market_points.get_node("Repeater").available,"Alimentación/repetidor bloqueados por orden")
	await key(KEY_J)
	check(not main.get_node("ZoneOverlay").banner.visible,"Rótulo de zona no tapa el diario")
	check(main.get_node("MissionUI").body.text.contains("75 XP") and main.get_node("MissionUI").chapter.text.contains("ECOS"),"Diario único con capítulo/recompensas/historial")
	await capture("01-market-journal")
	await key(KEY_J)
	# Recuperaciones y bajas antes de activar las misiones 2 y 3.
	await interact(Vector2(580,890))
	await interact(Vector2(600,960))
	await interact(Vector2(530,1215))
	main.get_node("InventoryUI").close_window()
	var inventory: InventoryComponent=player.get_node("InventoryComponent")
	player.health.take_damage(5)
	player.get_node("SurvivalComponent").thirst=50
	for id in [&"water",&"medkit"]:
		var slot:=preload("res://tests/save_fixture.gd").slot_of(inventory,id)
		check(player.get_node("ItemUse").use_slot(slot),"Consumir recurso recuperado")
		check(tracker._totals.get(StringName("market_"+String(id)),0)>0,"Consumo no borra recuperación")
	await shoot(preload("res://tests/archetype_fixture.gd").by_type(main,"runner"))
	await shoot(preload("res://tests/archetype_fixture.gd").by_type(main,"resistant"))
	check(tracker.state_of(&"market_horde")==0 and tracker._totals.get(&"market_runner_kills",0)==1 and tracker._totals.get(&"market_resistant_kills",0)==1,"Bajas históricas conservadas antes de misión 3")
	await point("Stall")
	await point("Evacuation")
	await point("Record")
	check(tracker.state_of(&"market_traces")==3 and tracker.state_of(&"market_supplies")==3 and tracker.state_of(&"market_horde")==3,"Tres misiones completadas en orden con historial")
	check(main.get_node("RadioUI").message_label.text.contains("Salimos"),"Registro revela evacuación")
	await capture("02-survivor-record")
	await close_radio()
	var saves:=main.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-twelve-walk-%d"%OS.get_process_id()
	check(saves.save_slot(1).has("ok"),"Guardar objetivos históricos y orden")
	var before: int=player.get_node("ProgressionComponent").total_xp()
	check(saves.load_slot(1).has("ok"),"Cargar recorrido sin repetir premios")
	await frames(4)
	bind_scene()
	check(player.get_node("ProgressionComponent").total_xp()==before and tracker.active_mission().id==&"market_frequency","Restauración exacta de misión 4")
	# Alimentación narrativa: no requiere espacio, objeto ni consumo en mochila.
	inventory=player.get_node("InventoryComponent")
	check(inventory.add_item(SaveCatalog.ITEMS.food,inventory.space_for(SaveCatalog.ITEMS.food)) and inventory.occupied_slots()==12,"Mochila realmente llena")
	var slots_before:=SaveCatalog.slots(inventory)
	await point("Comms")
	await close_radio()
	await point("Power")
	await close_radio()
	check(SaveCatalog.slots(inventory)==slots_before,"Alimentación segura con mochila llena")
	await point("Repeater")
	check(tracker.state_of(&"market_frequency")==2 and tracker.progress_of(&"market_frequency",2)==1,"Activar no cobra antes de escuchar")
	main.get_node("RadioUI").close_window()
	check(tracker.progress_of(&"market_frequency",3)==0,"Cerrar temprano no completa transmisión")
	check(main.get_node("SaveCoordinator").save_slot(2).has("ok"),"Guardar repetidor activado y diálogo pendiente")
	check(main.get_node("SaveCoordinator").load_slot(2).has("ok"),"Cargar repetidor pendiente")
	await frames(4)
	bind_scene()
	await point("Repeater")
	main.get_node("Radio").advance()
	check(main.get_node("RadioUI").message_label.text.contains("todavía hay alguien allí"),"Transmisión final de estación")
	await capture("03-station-signal")
	await close_radio()
	check(tracker.chapter_completed(ChapterCatalog.MARKET) and tracker.completed_chapters().size()==2,"Capítulo 2 completado")
	check(main.get_node("HUD/Feedback").text.contains("Capítulo 2 completado") and not main.game_ended,"Final mantiene exploración activa")
	var awarded: Dictionary=main.get_node("Missions/Rewards")._awarded
	var mission_xp:=0
	for mission in tracker.definitions:
		if mission.id in awarded and mission.chapter_id==&"market_echoes":mission_xp+=mission.reward_xp
	check(mission_xp==205 and awarded.size()==7,"205 XP de capítulo 2 una sola vez")
	check(ZoneCatalog.DEFINITIONS.size()==3 and main.get_node("ZoneManager").unlocked==[ZoneCatalog.MARKET,ZoneCatalog.STATION],"Estación desbloqueada, sin misiones de capítulo 3")
	await key(KEY_J)
	await capture("04-chapter-two-complete")
	await key(KEY_J)
	check(main.get_node("SaveCoordinator").save_slot(3).has("ok"),"Final persistente válido")
	before=player.get_node("ProgressionComponent").total_xp()
	check(main.get_node("SaveCoordinator").load_slot(3).has("ok"),"Cargar capítulo completado")
	await frames(4)
	bind_scene()
	check(player.get_node("ProgressionComponent").total_xp()==before and tracker.chapter_completed(ChapterCatalog.MARKET),"Cargar no duplica objetos/XP ni pierde final")
	if "--station" in OS.get_cmdline_user_args():
		await preload("res://tests/station_route.gd").run(self)
	await interact(Vector2(270,800))
	if main.get_node("ZoneManager").busy: await main.get_node("ZoneManager").transition_finished
	check(main.get_node("ZoneManager").current_zone==ZoneCatalog.HOME and tracker.chapter_completed(ChapterCatalog.MARKET),"Regreso real a Gualey conserva capítulos")
	check(walked>7000,"Recorrido físico completo "+str(walked)+" px")
	check(main.get_node("Population").total_spawned<=18 and main.get_node("Population").active_enemies().size()<=6,"Población finita intacta")
	player.health.take_damage(1000)
	check(not tracker.enabled and main.game_ended,"Muerte detiene narrativa")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("Missions").started_chapters==[ChapterCatalog.FIRST] and current_scene.get_node("Missions").active_mission().id==&"signal","Reintentar restaura capítulos")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado recorrido capítulo 2: ",checks," comprobaciones, ",failures," fallos; recorrido=",walked," px")
	quit(0 if failures==0 else 1)
