extends "res://tests/market_chapter_test.gd"
## Recorrido físico con E y move_and_slide; IA aislada aquí, activa en state_test.
const F := preload("res://tests/evacuation_fixture.gd")
var stage := "arranque"
var stage_since := 0
var last_stage := ""
func watchdog() -> void:
	if stage != last_stage:
		last_stage=stage
		stage_since=Time.get_ticks_msec()
		print("RECORRIDO C4: ",stage)
	elif Time.get_ticks_msec()-stage_since>45000:
		push_error("Recorrido detenido en %s; pausa=%s, posición=%s"%[stage,paused,player.position if is_instance_valid(player) else Vector2.ZERO])
		quit(1)
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-sixteen")
	check(root.get_texture().get_image().save_png("res://test-results/phase-sixteen/"+label+".png")==OK,"Captura "+label)
func checked_point(name: String) -> void:
	stage=name
	await point(name)
	await close_radio()
	check(SaveSchema.validate(main.get_node("SaveCoordinator").capture(1)).is_empty(),"Estado coherente tras "+name)
func run() -> void:
	process_frame.connect(watchdog)
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var directory := "user://tests/phase-sixteen-route-%d-%d"%[OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	current_scene.get_node("SaveCoordinator").store.directory=directory
	check(await F.enter(self),"Acceso a Perímetro tras capítulo 3")
	bind_scene()
	var music := root.get_node("MusicDirector")
	var music_id: int=music.player.get_instance_id()
	var starts: int=music.starts
	check(tracker.active_chapter==ChapterCatalog.CONVOY and tracker.definitions.size()==15,"Cuarto capítulo, quince misiones")
	check(tracker.active_mission().id==&"convoy_access" and not main.get_node("World/ChapterPoints/BusInspection").available,"Orden de misiones")
	var inventory: InventoryComponent=player.get_node("InventoryComponent")
	inventory.add_item(SaveCatalog.ITEMS.food,inventory.space_for(SaveCatalog.ITEMS.food))
	var slots := SaveCatalog.slots(inventory)
	check(inventory.occupied_slots()==12,"Mochila llena para toda la investigación")
	var before: int=player.get_node("ProgressionComponent").total_xp()
	await key(KEY_J)
	check(main.get_node("MissionUI").chapter.text.contains("CAPÍTULO 4"),"Diario del convoy")
	await capture("01-convoy-journal")
	stage="cerrar diario"
	await key(KEY_J)
	for name in ["Checkpoint","Register","Authorization"]: await checked_point(name)
	check(tracker.state_of(&"convoy_access")==3 and player.get_node("ProgressionComponent").total_xp()==before+45,"Control de acceso: 45 XP una vez")
	for name in ["BusInspection","EvacuationVehicle","DestinationLog"]: await checked_point(name)
	check(tracker.state_of(&"convoy_stopped")==3 and player.get_node("ProgressionComponent").total_xp()==before+100,"Convoy detenido: 55 XP")
	for name in ["MedicalInspection","QuarantineLog"]: await checked_point(name)
	check(tracker.state_of(&"convoy_quarantine")==2 and tracker._totals.get(&"convoy_kills",0)==0,"Seguridad aún pendiente sin bajas locales")
	await checked_point("SafetyInspection")
	check(tracker.state_of(&"convoy_quarantine")==3 and tracker._totals.get(&"convoy_kills",0)==0,"Alternativa de inspección sin inventar bajas")
	check(player.get_node("ProgressionComponent").total_xp()==before+170,"Cuarentena: 70 XP")
	await checked_point("Comms")
	await checked_point("TransferOrder")
	stage="RadioLink"
	await point("RadioLink")
	await frames(20)
	check(main.get_node("Radio").transmission==SaveCatalog.CONVOY_RADIOS.convoy_final and is_equal_approx(music.duck_db,-12),"Transmisión nueva atenúa música existente")
	await key(KEY_E)
	await capture("02-convoy-last-order")
	stage="guardar/cargar final"
	check(tracker.state_of(&"convoy_route")==2 and player.get_node("ProgressionComponent").total_xp()==before+170,"Abrir/avanzar final no concede 100 XP")
	main.get_node("RadioUI").close_window()
	check(main.get_node("SaveCoordinator").save_slot(1,true).has("ok"),"Guardar última orden pendiente")
	check(main.get_node("SaveCoordinator").load_slot(1).has("ok"),"Cargar investigación pendiente")
	await frames(5)
	bind_scene()
	check(main.get_node("Radio").index==1 and not main.get_node("RadioUI").window.visible,"Índice conservado sin abrir radio automáticamente")
	await point("Comms")
	stage="escuchar final"
	check(main.get_node("Radio").index==1,"Comunicaciones continúa la última transmisión")
	await key(KEY_E)
	check(tracker.state_of(&"convoy_route")==2,"Mostrar el último mensaje aún no completa")
	await key(KEY_E)
	await frames(20)
	check(tracker.chapter_completed(ChapterCatalog.CONVOY) and player.get_node("ProgressionComponent").total_xp()==before+270,"Final correcto: 270 XP totales")
	check(MissionSaveState.story(main).facility_hint and main.get_node("HUD/Feedback").text.contains("Capítulo 4 completado"),"Pista persistente y aviso de capítulo")
	check(SaveCatalog.slots(player.get_node("InventoryComponent"))==slots,"Registros no consumen espacios ni objetos")
	await key(KEY_J)
	check(main.get_node("MissionUI").body.text.contains("NODO CERO"),"Pista final en historial")
	await capture("03-convoy-complete")
	stage="viajes y reinicio"
	await key(KEY_J)
	await point("RadioLink")
	check(main.get_node("Radio").transmission==null and main.get_node("Missions/Rewards")._awarded.size()==15,"No repetir radio final ni premios")
	check(main.get_node("SaveCoordinator").save_slot(2,true).has("ok") and main.get_node("SaveCoordinator").load_slot(2).has("ok"),"Guardar/cargar capítulo completo")
	await frames(5)
	bind_scene()
	for destination in [ZoneCatalog.STATION,ZoneCatalog.MARKET,ZoneCatalog.HOME,ZoneCatalog.MARKET,ZoneCatalog.STATION,ZoneCatalog.PERIMETER]:
		var manager := main.get_node("ZoneManager")
		check(await preload("res://tests/station_fixture.gd").travel(self,destination,manager.active_definition().connections[destination]),"Conexión conservada: "+destination)
		freeze_enemies()
	check(music.player.get_instance_id()==music_id and music.starts==starts and music.context=="gameplay","Música continua sin voces adicionales")
	check(ZoneCatalog.DEFINITIONS.size()==4 and tracker.completed_chapters().size()==4 and not main.game_ended,"Cuatro capítulos, cuatro zonas, exploración continúa")
	check(main.get_node("ZoneManager").active_definition().connections.size()==1,"Ninguna salida a quinta zona")
	player.health.take_damage(1000)
	check(main.game_ended and not tracker.enabled and main.get_node("Radio").transmission==null,"Game Over conserva su bloqueo")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("Missions").started_chapters==[ChapterCatalog.FIRST] and not MissionSaveState.story(current_scene).facility_hint,"Reintentar limpia capítulo y pista")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado recorrido capítulo 4: ",checks," comprobaciones, ",failures," fallos; recorrido=",walked," px")
	quit(0 if failures==0 else 1)
