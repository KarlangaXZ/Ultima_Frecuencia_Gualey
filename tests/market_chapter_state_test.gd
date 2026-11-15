extends SceneTree
const FIXTURE:=preload("res://tests/archetype_fixture.gd")
const LEGACY:=preload("res://tests/legacy_save_fixture.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func frames(n:=2) -> void: await FIXTURE.frames(self,n)
func interaction(name: String) -> void:
	var main:=current_scene
	for ui in ["RadioUI","InventoryUI"]:main.get_node(ui).close_window()
	var point: Node=main.get_node("World/ChapterPoints/"+name)
	main.get_node("Player").position=point.position+Vector2(0,30)
	await frames()
	main.get_node("Player/Interaction").try_interact()
	await frames()
func finish_radio() -> void:
	var radio:=current_scene.get_node("Radio")
	while radio.transmission!=null:radio.advance()
	await frames()
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main:=current_scene
	var saves:=main.get_node("SaveCoordinator")
	var directory: String="user://tests/phase-twelve-state-%d"%OS.get_process_id()
	saves.store.directory=directory
	var legacy_one: Dictionary=LEGACY.convert(saves.capture(3),1)
	check(saves.store.write_slot(3,legacy_one).has("ok"),"v1 exacto anterior")
	await FIXTURE.enter_market(self,main)
	var tracker: MissionTracker=main.get_node("Missions")
	var player:=main.get_node("Player")
	check(tracker.active_mission().id==&"market_traces" and main.get_node("Population").active_enemies().size()==6,"Capítulo 2 con población real")
	# Física de los tres tipos activa mientras las misiones están en curso.
	player.position=Vector2(1000,900)
	var actors: Array=[]
	var origins: Array=[]
	for pair in [["base",Vector2(900,750)],["runner",Vector2(1000,750)],["resistant",Vector2(1100,750)]]:
		var actor:=FIXTURE.by_type(main,pair[0])
		actor.position=pair[1]
		actors.append(actor)
		origins.append(pair[1])
	await frames(25)
	for i in range(3):
		check(actors[i].is_physics_processing() and actors[i].position.distance_to(origins[i])>25 and actors[i].state==1,"IA activa "+String(actors[i].archetype.id))
	check(tracker._totals.get(&"market_runner_seen",0)==1,"Identificación por persecución real")
	await frames(90)
	check(player.health.current_health<100 and not main.game_ended,"Ataques reales durante narrativa")
	for actor in actors:
		check(actor.get_node("Audio").emitter.get_child_count()==3 and actor.attack_interval==1.5,"Pool/cadencia intactos")
	# Guardado parcial: sin manipular estados del tracker.
	FIXTURE.by_type(main,"runner").health.take_damage(500)
	FIXTURE.by_type(main,"resistant").health.take_damage(500)
	var current: Dictionary=saves.capture(1)
	check(SaveSchema.validate(current).is_empty(),"Snapshot narrativo y arquetipos coherentes")
	var old_two: Dictionary=LEGACY.convert(current,2)
	old_two.slot=2
	var writing: Dictionary=saves.store.write_slot(2,old_two)
	check(writing.has("ok"),"v2 del Mercado anterior a capítulos: "+str(writing)+" / "+SaveSchema.validate(SaveMigration.to_current(old_two)))
	if not writing.has("ok"): quit(1);return
	var bytes_before:=FileAccess.get_file_as_string(saves.store.path_for(2))
	var xp_before: int=player.get_node("ProgressionComponent").total_xp()
	check(saves.load_slot(2).get("migrated",false),"v2 inicia capítulo compatible")
	await frames(3)
	main=current_scene
	saves=main.get_node("SaveCoordinator")
	tracker=main.get_node("Missions")
	check(FileAccess.get_file_as_string(saves.store.path_for(2))==bytes_before,"Migración no reescribe archivo original")
	check(tracker.active_mission().id==&"market_traces" and tracker._totals.get(&"market_runner_kills",0)==1 and tracker._totals.get(&"market_resistant_kills",0)==1,"Reconstruye bajas tipadas previas")
	check(main.get_node("Player/ProgressionComponent").total_xp()==xp_before and main.get_node("Missions/Rewards")._awarded.size()==3,"Cargar no concede nuevas recompensas")
	var mutations: Array[Callable]=[
		func(d):d.story.started="market_echoes",
		func(d):d.story.completed=["signal_lost","signal_lost"],
		func(d):d.story.station_hint=true,
		func(d):d.chapter="unknown",
		func(d):d.story.legacy_waivers=["res://scene"],
		func(d):d.missions.totals.market_runner_kills=9,
		func(d):d.missions.states.market_frequency=2,
		func(d):d.story.started=["market_echoes"],
		func(d):d.missions.totals.market_listen=1]
	for mutate in mutations:
		var invalid: Dictionary=saves.capture(1)
		mutate.call(invalid)
		check(not SaveSchema.validate(invalid).is_empty(),"Rechaza estado narrativo inválido")
	check(saves.load_slot(3).get("migrated",false),"Migración v1 conservada")
	await frames(3)
	check(current_scene.get_node("Missions").started_chapters==[ChapterCatalog.FIRST],"v1 sin visitar mercado no adelanta capítulo")
	# Guardado histórico extremo: mercado agotado, todos comunes de Fase 10,
	# suministros ya consumidos. No hay enemigos legítimos que puedan reponerse.
	var exhausted:=old_two.duplicate(true)
	exhausted.player.progression={"level":5,"xp":70,"available_points":4}
	exhausted.world.zombies=[]
	exhausted.world.rewarded_zombies=[]
	for i in range(1,19):
		var id: String="market_zombie_%02d"%i
		exhausted.world.zombies.append({"id":id,"type":"base","health":0,"cooldown":0,"position":[900,800]})
		exhausted.world.rewarded_zombies.append(id)
	exhausted.world.population.spawned=18
	exhausted.world.kills=18
	exhausted.stats.kills=20
	exhausted.missions.totals.kills=20
	exhausted.world.pickups.market_water=false
	exhausted.world.pickups.market_medkit=false
	exhausted.world.containers.market_medical.opened=true
	exhausted.world.rewarded_containers=["market_medical"]
	var store:=SaveFileStore.new()
	store.directory=directory
	writing=store.write_slot(2,exhausted,true)
	check(writing.has("ok"),"Fixture v2 agotada válida: "+str(writing)+" / "+SaveSchema.validate(SaveMigration.to_current(exhausted)))
	if not writing.has("ok"):quit(1);return
	check(current_scene.get_node("SaveCoordinator").load_slot(2).has("ok"),"Carga mercado legado agotado")
	await frames(3)
	main=current_scene
	tracker=main.get_node("Missions")
	check(tracker.legacy_waivers==["runner","resistant"] and main.get_node("Population").total_spawned==18 and main.kills==20,"Compatibilidad explícita sin inventar bajas ni enemigos")
	check(tracker._totals.get(&"market_water",0)==1 and tracker._totals.get(&"market_medkit",0)==1 and tracker._totals.get(&"market_container",0)==1,"Reconoce recuperaciones agotadas/consumidas del mundo anterior")
	check(main.get_node("Player/ProgressionComponent").total_xp()==770,"Migración mantiene XP exacta")
	for name in ["Stall","Evacuation","Record"]:await interaction(name)
	await finish_radio()
	check(tracker.active_mission().id==&"market_frequency","Ninguna misión imposible por presupuesto legado")
	check(main.get_node("Player/ProgressionComponent").total_xp()==900,"Solo 30+40+60 XP de misiones nuevas")
	check(main.get_node("MissionUI").body.text.contains("No son bajas nuevas"),"Diario explica reconocimiento legado")
	for name in ["Comms","Power"]:
		await interaction(name)
		await finish_radio()
	await interaction("Repeater")
	var radio:=main.get_node("Radio")
	radio.advance()
	check(radio.index==1 and tracker.progress_of(&"market_frequency",3)==0,"Último mensaje pendiente sin recompensa anticipada")
	check(main.get_node("SaveCoordinator").save_slot(1,true).has("ok"),"Guarda índice de transmisión e interacciones")
	check(main.get_node("SaveCoordinator").save_slot(3,true).has("ok"),"Fixture de muerte con transmisión pendiente")
	check(main.get_node("SaveCoordinator").load_slot(1).has("ok"),"Carga diálogo parcial v3")
	await frames(3)
	main=current_scene
	tracker=main.get_node("Missions")
	check(main.get_node("Radio").index==1 and tracker.progress_of(&"market_frequency",2)==1,"Índice/activación restaurados")
	await interaction("Repeater")
	check(main.get_node("Radio").index==1,"Reabrir continúa desde el mensaje guardado")
	await finish_radio()
	check(tracker.chapter_completed(ChapterCatalog.MARKET) and main.get_node("Player/ProgressionComponent").total_xp()==975,"Final legado cobra 75 una sola vez")
	var xp: int=main.get_node("Player/ProgressionComponent").total_xp()
	check(not main.get_node("Missions/Rewards").award(tracker.definitions[-1]),"Recompensa final duplicada rechazada")
	for i in range(4):main.get_node("Population")._physics_process(60.0)
	check(main.get_node("Zombies").get_child_count()==18 and main.get_node("Population").active_enemies().is_empty(),"No crea enemigos para compensar legado")
	check(main.get_node("SaveCoordinator").save_slot(1,true).has("ok"),"Final legado guardable")
	var connections: int=main.get_node("Player/HealthComponent").died.get_connections().size()
	for destination in [ZoneCatalog.HOME,ZoneCatalog.MARKET,ZoneCatalog.HOME,ZoneCatalog.MARKET]:
		var manager:=main.get_node("ZoneManager")
		check(manager.request_travel(destination,"from_market" if destination==ZoneCatalog.HOME else "from_gualey"),"Viaje con capítulos completos")
		await manager.transition_finished
	check(main.get_node("Player/HealthComponent").died.get_connections().size()==connections and main.get_node("Player/ProgressionComponent").total_xp()==xp,"Viajes no acumulan señales ni XP")
	check(main.get_node("SaveCoordinator").load_slot(3).has("ok"),"Restaurar antes de escuchar para probar muerte")
	await frames(3)
	main=current_scene
	tracker=main.get_node("Missions")
	xp=main.get_node("Player/ProgressionComponent").total_xp()
	main.get_node("Player/HealthComponent").take_damage(1000)
	main.get_node("Radio").advance()
	check(not tracker.enabled and not tracker.chapter_completed(ChapterCatalog.MARKET) and main.get_node("Player/ProgressionComponent").total_xp()==xp,"Muerte bloquea transmisión pendiente/premios")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado estado capítulo 2: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
