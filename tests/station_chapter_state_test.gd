extends SceneTree
const F:=preload("res://tests/station_fixture.gd")
const ARC:=preload("res://tests/archetype_fixture.gd")
const LEGACY:=preload("res://tests/legacy_save_fixture.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func frames(n:=2) -> void:await ARC.frames(self,n)
func point(name: String, finish:=true) -> void:
	var main:=current_scene
	await F.interact(self,main,main.get_node("World/ChapterPoints/"+name).position+Vector2(0,30))
	if finish:F.finish_radio(main)
func freeze() -> void:
	for z in current_scene.get_node("Zombies").get_children():z.set_physics_process(false)
func sequence() -> void:
	for name in ["Log","Console","Evacuation","Generator","Component","Secondary","Antenna"]:await point(name)
	await point("Link",false)
func run() -> void:
	var content_xp:=0
	for mission in SaveCatalog.MISSIONS:content_xp+=mission.reward_xp
	for zone: ZoneDefinition in ZoneCatalog.DEFINITIONS.values():
		if zone.id==ZoneCatalog.PERIMETER:continue # Presupuesto histórico de fase 14.
		content_xp+=20*zone.container_ids.size()
		for ordinal in range(1,zone.total_budget+1):content_xp+=zone.archetype_for(ordinal).xp_reward
	check(content_xp==2795,"Contenido finito de tres capítulos: 2795 XP configurados")
	var progression:=ProgressionComponent.new()
	root.add_child(progression)
	check(progression.add_xp(content_xp) and progression.level==10 and progression.xp==0 and progression.available_points==9,"Fórmula existente alcanza nivel 10 y nueve puntos; excedente no se almacena")
	check(not progression.add_xp(240) and progression.available_points==9,"El tope no añade puntos ni XP acumulable")
	progression.queue_free()
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var directory: String="user://tests/phase-fourteen-state-%d-%d" % [OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	current_scene.get_node("SaveCoordinator").store.directory=directory
	var old_one: Dictionary=LEGACY.convert(current_scene.get_node("SaveCoordinator").capture(1),1)
	check(not current_scene.get_node("Missions").begin_chapter(ChapterCatalog.STATION),"No salta capítulo 2")
	await F.complete_market(self,current_scene)
	var old_two: Dictionary=LEGACY.convert(current_scene.get_node("SaveCoordinator").capture(1),2)
	var old_three: Dictionary=LEGACY.convert(current_scene.get_node("SaveCoordinator").capture(1),3)
	check(await F.travel(self,ZoneCatalog.STATION,"from_market"),"Entrar para pruebas con IA activa")
	var main:=current_scene
	var player:=main.get_node("Player")
	player.position=Vector2(650,800)
	var actors: Array=[]
	var starts: Array=[Vector2(530,650),Vector2(650,620),Vector2(770,650)]
	for i in range(3):
		var z:=ARC.by_type(main,["base","runner","resistant"][i])
		z.position=starts[i]
		actors.append(z)
	await frames(25)
	for i in range(3):check(actors[i].is_physics_processing() and actors[i].position.distance_to(starts[i])>20 and actors[i].state==1,"Capítulo activo con IA "+String(actors[i].archetype.id))
	var hp: float=player.health.current_health
	await frames(110)
	check(player.health.current_health<hp and not main.game_ended,"Ataques reales durante capítulo 3")
	for z in actors:check(z.attack_interval==1.5 and z.get_node("Audio").emitter.get_child_count()==3,"Cooldown y pool intactos "+String(z.archetype.id))
	# Tras la evidencia de IA, aislar la preparación narrativa de migraciones.
	freeze()
	actors[0].health.take_damage(500)
	actors[1].health.take_damage(500)
	await point("StationRadio",false)
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	var old_four: Dictionary=LEGACY.convert(main.get_node("SaveCoordinator").capture(1),4)
	check(old_four.missions.radio.index==1 and old_four.world.interactions==["station_radio"],"v4 conserva introducción pendiente")
	await point("Log",false)
	check(main.get_node("Radio").index==1 and main.get_node("Radio").transmission==SaveCatalog.TRANSMISSIONS.station_intro and not main.get_node("World/ChapterPoints/Log").available,"Investigar no reemplaza introducción interrumpida")
	for historical in [old_one,old_two,old_three,old_four]:
		var saves:=current_scene.get_node("SaveCoordinator")
		check(SaveSchema.validate(historical,1).is_empty(),"Formato histórico válido v"+str(historical.version))
		check(saves.store.write_slot(1,historical,true).has("ok"),"Escribir formato histórico aislado")
		var bytes:=FileAccess.get_file_as_string(saves.store.path_for(1))
		check(saves.load_slot(1).get("migrated",false),"Migración explícita v"+str(historical.version)+" → v5")
		await frames(4)
		main=current_scene
		freeze()
		var result: Dictionary=main.get_node("SaveCoordinator").capture(1)
		check(result.version==SaveSchema.VERSION and SaveSchema.validate(result).is_empty(),"Reconstrucción en formato actual coherente")
		check(result.player.progression==historical.player.progression and result.missions.awarded==historical.missions.awarded,"Migrar no entrega XP/recompensas")
		check(FileAccess.get_file_as_string(main.get_node("SaveCoordinator").store.path_for(1))==bytes,"Lectura no reescribe histórico")
		if historical.version==4:
			check(main.get_node("Missions").active_chapter==ChapterCatalog.STATION and main.get_node("Missions").active_mission().id==&"station_records","v4 guardado en estación inicia investigación")
			check(result.missions.radio==historical.missions.radio and result.missions.totals.station_kills==2,"Índice y bajas de estación preservados")
	await point("StationRadio")
	check(not main.get_node("World/ChapterPoints/StationRadio").available,"Introducción concluida no se repite")
	check(await F.travel(self,ZoneCatalog.MARKET,"from_station"),"Salir antes de migración inactiva")
	var inactive: Dictionary=LEGACY.convert(main.get_node("SaveCoordinator").capture(1),4)
	var migrated:=SaveMigration.to_current(inactive)
	check(SaveSchema.validate(migrated).is_empty() and migrated.chapter==ChapterCatalog.STATION and migrated.missions.totals.station_kills==2,"v4 con estación inactiva conserva historia e inicia capítulo")
	check(await F.travel(self,ZoneCatalog.STATION,"from_market"),"Volver a investigación")
	freeze()
	await sequence()
	main=current_scene
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	var partial: Dictionary=main.get_node("SaveCoordinator").capture(2)
	check(SaveSchema.validate(partial).is_empty(),"Snapshot de enlace pendiente válido")
	var mutations: Array[Callable]=[
		func(d):d.story.perimeter_hint=true,
		func(d):d.story.started.erase(ChapterCatalog.STATION),
		func(d):d.missions.totals.station_kills=3,
		func(d):d.missions.totals.station_component=0,
		func(d):d.missions.receipts.erase("station_component:station_component"),
		func(d):d.missions.totals.station_final_listen=1,
		func(d):d.missions.awarded.append("station_frequency"),
		func(d):d.missions.radio.index=9,
		func(d):d.missions.radio.transmission="res://untrusted.tres",
		func(d):d.missions.states.station_call=3]
	for mutate in mutations:
		var invalid:=partial.duplicate(true)
		mutate.call(invalid)
		check(not SaveSchema.validate(invalid).is_empty(),"Rechaza narrativa adulterada")
	check(not main.get_node("World/ChapterPoints/StationRadio").available,"No reemplaza transmisión esencial pendiente por introducción")
	await point("Link",false)
	check(main.get_node("Radio").index==1,"Reanuda enlace sin duplicar índice")
	F.finish_radio(main)
	await point("Broadcast",false)
	var before: int=main.get_node("Player/ProgressionComponent").total_xp()
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	check(main.get_node("Missions").state_of(&"station_call")==2,"Cerrar temprano no completa llamada")
	main.get_node("Player/HealthComponent").take_damage(1000)
	check(main.get_node("Player/ProgressionComponent").total_xp()==before and main.get_node("Missions").state_of(&"station_call")==2,"Morir tampoco concede premio final")
	check(main.get_node("SaveCoordinator").save_slot(2,true).has("error"),"Game Over rechaza guardado")
	# Caso histórico agotado: 18 cadáveres existentes, sin revivir/generar amenazas.
	var exhausted:=old_four.duplicate(true)
	exhausted.slot=3
	exhausted.missions.radio={"transmission":"","index":0}
	exhausted.world.zombies=[]
	exhausted.world.rewarded_zombies=[]
	for i in range(1,19):
		var id: String="station_zombie_%02d"%i
		exhausted.world.zombies.append({"id":id,"type":"base","health":0,"cooldown":0,"position":[650,800]})
		exhausted.world.rewarded_zombies.append(id)
	exhausted.world.population.spawned=18
	exhausted.stats.kills+=18-int(exhausted.world.kills)
	exhausted.world.kills=18
	exhausted.missions.totals.kills=exhausted.stats.kills
	check(SaveSchema.validate(exhausted).is_empty(),"v4 agotado exacto válido")
	var saves:=main.get_node("SaveCoordinator")
	var writing: Dictionary=saves.store.write_slot(3,exhausted,true)
	var loading: Dictionary=saves.load_slot(3)
	check(writing.has("ok") and loading.has("ok"),"Migrar estación agotada desde Game Over: "+str(writing)+" / "+str(loading))
	await frames(4)
	main=current_scene
	var xp: int=main.get_node("Player/ProgressionComponent").total_xp()
	await sequence()
	F.finish_radio(main)
	check(main.get_node("Missions").progress_of(&"station_call",0)==2 and main.get_node("Population").active_enemies().is_empty(),"Historia despeja área sin bajas nuevas")
	await point("Broadcast")
	check(main.get_node("Missions").chapter_completed(ChapterCatalog.STATION) and main.get_node("Player/ProgressionComponent").total_xp()==xp+240,"Partida agotada completa 240 XP sin bloqueo")
	check(main.get_node("Zombies").get_child_count()==18 and main.get_node("Population").total_spawned==18 and main.kills==exhausted.stats.kills,"Ningún enemigo/contador/recompensa de baja inventado")
	var snapshot: Dictionary=main.get_node("SaveCoordinator").capture(3)
	check(SaveSchema.validate(snapshot).is_empty() and snapshot.story.perimeter_hint,"Snapshot final agotado válido")
	var stable: Dictionary={}
	for i in range(6):
		var destination: String=ZoneCatalog.MARKET if i%2==0 else ZoneCatalog.STATION
		check(await F.travel(self,destination,"from_station" if i%2==0 else "from_market"),"Viaje tras completar capítulo")
		var all:=main.find_children("*","",true,false)
		var state: Dictionary={"nodes":all.size(),"voices":all.filter(func(n):return n is AudioStreamPlayer or n is AudioStreamPlayer2D).size(),
			"timers":all.filter(func(n):return n is Timer).size(),"signals":main.get_node("Player/HealthComponent").died.get_connections().size(),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)}
		if stable.has(destination):check(stable[destination]==state,"Sin acumulación de recursos, timers, voces o señales")
		stable[destination]=state
		check(main.get_node("Player/ProgressionComponent").total_xp()==xp+240 and main.get_node("Missions/Rewards")._awarded.size()==11,"Viajar no duplica recompensas completas")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado estado capítulo 3: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
