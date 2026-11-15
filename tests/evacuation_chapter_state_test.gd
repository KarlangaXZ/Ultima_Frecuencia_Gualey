extends SceneTree
const F := preload("res://tests/evacuation_fixture.gd")
const S := preload("res://tests/station_fixture.gd")
const ARC := preload("res://tests/archetype_fixture.gd")
const LEGACY := preload("res://tests/legacy_save_fixture.gd")
var checks := 0
var failures := 0
var directory: String
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func frames(n := 2) -> void: await ARC.frames(self,n)
func fresh() -> void:
	paused=false
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	current_scene.get_node("SaveCoordinator").store.directory=directory
func capture(slot := 1) -> Dictionary:
	return current_scene.get_node("SaveCoordinator").capture(slot)
func load_data(data: Dictionary) -> void:
	var saves := current_scene.get_node("SaveCoordinator")
	var problem := SaveSchema.validate(data)
	check(problem.is_empty(),"Fixture válida v%d: %s"%[data.version,problem])
	var result: Dictionary=saves.store.write_slot(data.slot,data,true)
	check(result.has("ok"),"Escribir fixture aislada: "+str(result))
	var bytes := FileAccess.get_file_as_string(saves.store.path_for(data.slot))
	result=saves.load_slot(data.slot)
	check(result.has("ok"),"Restauración transaccional: "+str(result))
	await frames(4)
	F.freeze(current_scene)
	check(FileAccess.get_file_as_string(current_scene.get_node("SaveCoordinator").store.path_for(data.slot))==bytes,"Leer no reescribe bytes originales")
func run() -> void:
	directory="user://tests/phase-sixteen-state-%d-%d"%[OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	await fresh()
	var historical: Array=[]
	for version in range(1,5): historical.append(LEGACY.convert(capture(),version))
	var forged := capture()
	forged.missions.totals.convoy_security=1
	forged.missions.receipts.append("convoy_security:convoy_security")
	check(not SaveSchema.validate(forged).is_empty(),"No aceptar inspecciones en un Perímetro nunca visitado")
	check(not current_scene.get_node("Missions").begin_chapter(ChapterCatalog.CONVOY),"No saltar capítulos anteriores")
	await preload("res://tests/perimeter_fixture.gd").complete_station(self)
	historical.append(LEGACY.convert(capture(),5))
	check(await S.travel(self,ZoneCatalog.PERIMETER,"from_station"),"Entrar después de capítulo 3")
	var main := current_scene
	F.freeze(main)
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	var old_pending := LEGACY.convert(capture(),6)
	historical.append(old_pending)
	S.finish_radio(main)
	for name in ["MedicalInspection","Register"]: await F.point(self,name)
	await F.point(self,"Comms",false)
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	var old_inspected := LEGACY.convert(capture(),6)
	check(await S.travel(self,ZoneCatalog.STATION,"from_perimeter"),"Preparar Perímetro inactivo histórico")
	var old_inactive := LEGACY.convert(capture(),6)
	for old in historical+[old_inspected,old_inactive]:
		await load_data(old)
		var result := capture()
		check(result.version==7 and SaveSchema.validate(result).is_empty(),"Migración v%d → v7 coherente"%old.version)
		check(result.player.progression==old.player.progression and result.player.inventory==old.player.inventory and result.player.weapons==old.player.weapons,"Migrar conserva XP, suministros y armas")
		check(result.missions.awarded==old.missions.awarded,"Migrar no entrega premios")
		check(result.missions.radio==old.missions.radio and not current_scene.get_node("RadioUI").window.visible,"Radio/índice conservados sin reproducción automática")
		if old.version==6:
			check(result.chapter==ChapterCatalog.CONVOY and result.story.started.count(ChapterCatalog.CONVOY)==1,"v6 visitada inicia capítulo único, activa o inactiva")
			check(result.missions.states.convoy_access==2 and result.missions.awarded.size()==11 and not result.story.facility_hint,"Nueva investigación sin premios ni pista anticipada")
		if old==old_pending:
			await F.point(self,"Comms",false)
			check(current_scene.get_node("Radio").index==1 and current_scene.get_node("Radio").transmission==SaveCatalog.PERIMETER_RADIOS.perimeter_intro,"Introducción histórica reabre sin repetirse")
		if old==old_inspected:
			check(result.missions.progress.convoy_access[1]==1 and result.missions.totals.convoy_medical==1,"Inspecciones anteriores reconocidas como evidencia sin XP")
	# Tres arquetipos con IA/ataques reales mientras el capítulo está activo.
	await fresh()
	check(await F.enter(self),"Preparar investigación con IA")
	main=current_scene
	var player := main.get_node("Player")
	player.position=Vector2(1200,950)
	var origins := [Vector2(1100,950),Vector2(1200,780),Vector2(1320,970)]
	var actors: Array=[]
	for i in range(3):
		var z := ARC.by_type(main,["base","runner","resistant"][i])
		z.position=origins[i]
		z.set_physics_process(true)
		actors.append(z)
	await frames(25)
	for i in range(3):
		check(actors[i].position.distance_to(origins[i])>15 and actors[i].state in [1,2],"IA persigue: "+String(actors[i].archetype.id))
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://test-results/phase-sixteen/04-convoy-active-ai.png")==OK,"Captura de IA activa")
	var hp: float=player.health.current_health
	await frames(100)
	check(player.health.current_health<hp and not main.game_ended,"Daño real durante investigación")
	for z in actors:
		check(z.state==2 and z.attack_interval==1.5 and z.get_node("Audio").emitter.get_child_count()==3,"Ataque/cooldown/pool original: "+String(z.archetype.id))
	F.freeze(main)
	for z in actors.slice(0,2): z.health.take_damage(500)
	check(main.get_node("Missions")._totals.get(&"convoy_kills",0)==2 and main.get_node("Missions")._totals.get(&"convoy_security",0)==1,"Bajas reales previas a misión 3 verifican seguridad")
	var known := capture()
	var corruptions: Array[Callable]=[
		func(d):d.story.facility_hint=true,
		func(d):d.missions.totals.convoy_kills=3,
		func(d):d.missions.awarded.append("convoy_route"),
		func(d):d.missions.radio={"transmission":"convoy_final","index":1},
		func(d):d.story.erase("facility_hint"),
		func(d):d.missions.receipts.append("convoy_future:convoy_future"),
		func(d):d.missions.receipts.append("convoy_security:forged"),
		func(d):d.missions.receipts.append("convoy_security:convoy_security"),
		func(d):d.version=6,
		func(d):d.missions.progress.convoy_route=[0,0,0,1]]
	for mutate in corruptions:
		var bad := known.duplicate(true)
		mutate.call(bad)
		check(not SaveSchema.validate(bad).is_empty(),"Rechazo de narrativa incoherente")
	# Repetición de puntos/recompensas y registros con mochila llena.
	var inventory: InventoryComponent=player.get_node("InventoryComponent")
	inventory.add_item(SaveCatalog.ITEMS.food,inventory.space_for(SaveCatalog.ITEMS.food))
	var slots := SaveCatalog.slots(inventory)
	var before: int=player.get_node("ProgressionComponent").total_xp()
	for name in ["Checkpoint","Register","Authorization","BusInspection","EvacuationVehicle","DestinationLog","QuarantineLog"]: await F.point(self,name)
	await F.point(self,"MedicalInspection",false)
	check(main.get_node("Missions").state_of(&"convoy_quarantine")==3,"Última inspección médica activa misión 4")
	main.get_node("RadioUI").close_window()
	await F.point(self,"Comms",false)
	check(main.get_node("Radio").transmission==SaveCatalog.PERIMETER_RADIOS.perimeter_medical and not main.get_node("World/ChapterPoints/Comms").available,"Misión nueva no sobrescribe un registro anterior pendiente")
	S.finish_radio(main)
	for name in ["Comms","TransferOrder"]: await F.point(self,name)
	await F.point(self,"RadioLink",false)
	check(main.get_node("Missions").state_of(&"convoy_quarantine")==3 and "convoy_security:convoy_security" not in main.get_node("Missions")._receipts,"Bajas previas sustituyen inspección sin fingir un recibo")
	check(SaveCatalog.slots(inventory)==slots,"Mochila llena intacta")
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	var pending := capture(2)
	check(pending.missions.states.convoy_route==2 and player.get_node("ProgressionComponent").total_xp()==before+170,"Final interrumpido sin premio")
	player.health.take_damage(1000)
	check(main.game_ended and main.get_node("Radio").transmission==null and not main.get_node("Missions/Rewards")._awarded.has(&"convoy_route"),"Morir durante transmisión no concede premio final")
	await load_data(pending)
	main=current_scene
	check(await S.travel(self,ZoneCatalog.STATION,"from_perimeter"),"Viajar con última transmisión pendiente")
	await load_data(capture(2))
	main=current_scene
	check(main.get_node("ZoneManager").current_zone==ZoneCatalog.STATION and main.get_node("Radio").index==1,"Guardar/cargar fuera del Perímetro conserva diálogo pendiente")
	await F.point(self,"StationRadio",false)
	check(main.get_node("Radio").transmission==SaveCatalog.CONVOY_RADIOS.convoy_final and main.get_node("Radio").index==1 and not main.get_node("World/ChapterPoints/StationRadio").available,"Introducción de otra zona no reemplaza diálogo del convoy")
	check(await S.travel(self,ZoneCatalog.PERIMETER,"from_station"),"Regresar al equipo de radio pendiente")
	F.freeze(main)
	await F.point(self,"TransferOrder",false)
	check(main.get_node("Radio").index==1 and not main.get_node("World/ChapterPoints/TransferOrder").available,"Otra interacción no sobrescribe final pendiente")
	await F.point(self,"Comms",false)
	S.finish_radio(main)
	check(main.get_node("Missions").chapter_completed(ChapterCatalog.CONVOY),"Reanudar y terminar completa capítulo")
	var completed := capture(3)
	for i in range(3):
		await load_data(completed)
		await F.point(self,"RadioLink")
		check(capture(3).missions==completed.missions and capture(3).player.progression==completed.player.progression,"Repetir carga/interacción no duplica XP o registros")
	# v6 con presupuesto totalmente agotado ANTES del capítulo; no crear enemigos.
	var exhausted := old_inspected.duplicate(true)
	exhausted.slot=3
	exhausted.missions.radio={"transmission":"","index":0}
	exhausted.world.zombies=[]
	exhausted.world.rewarded_zombies=[]
	for ordinal in range(1,19):
		var id := "perimeter_zombie_%02d"%ordinal
		var type_id := String(ZoneCatalog.definition(ZoneCatalog.PERIMETER).archetype_for(ordinal).id)
		exhausted.world.zombies.append({"id":id,"type":type_id,"position":[1200,950],"health":0,"cooldown":0})
		exhausted.world.rewarded_zombies.append(id)
	exhausted.stats.kills+=18-int(exhausted.world.kills)
	exhausted.world.kills=18
	exhausted.world.population.spawned=18
	exhausted.missions.totals.kills=exhausted.stats.kills
	await load_data(exhausted)
	main=current_scene
	check(main.get_node("Missions")._totals.get(&"convoy_kills",0)==18 and main.get_node("Population").active_enemies().is_empty(),"Migración reconoce 18 bajas y cero vivos")
	await F.to_final(self)
	S.finish_radio(main)
	check(main.get_node("Missions").chapter_completed(ChapterCatalog.CONVOY) and main.get_node("Zombies").get_child_count()==18 and main.get_node("Population").total_spawned==18,"Capítulo agotado completable sin nuevas apariciones")
	check(SaveSchema.validate(capture()).is_empty(),"Historia agotada válida")
	# El tope existente consume premios narrativos sin inventar puntos/excedente.
	await fresh()
	check(await F.enter(self),"Nueva fixture para nivel máximo")
	main=current_scene
	main.get_node("Player/ProgressionComponent").add_xp(99999)
	await F.to_final(self)
	S.finish_radio(main)
	check(main.get_node("Player/ProgressionComponent").level==10 and main.get_node("Player/ProgressionComponent").xp==0 and main.get_node("Missions/Rewards")._awarded.size()==15,"Nivel máximo conserva cuatro premios sin excedente")
	check(SaveSchema.validate(capture()).is_empty(),"Estado al tope conserva coherencia")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado estado capítulo 4: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
