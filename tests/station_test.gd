extends SceneTree
const F:=preload("res://tests/station_fixture.gd")
const ARC:=preload("res://tests/archetype_fixture.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func frames(n:=2) -> void:await ARC.frames(self,n)
func stable_player(player: Node) -> Dictionary:
	var data:=PlayerSaveState.capture(player)
	for key in ["position","aim","facing"]:data.erase(key)
	return data
func counts(main: Node) -> Dictionary:
	var all:=main.find_children("*","",true,false)
	var audio:=0
	for node in all:
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D:audio+=1
	return {"nodes":all.size(),"audio":audio,"signals":main.get_node("Player/HealthComponent").died.get_connections().size(),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)}
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main:=current_scene
	var manager:=main.get_node("ZoneManager")
	check(ZoneCatalog.DEFINITIONS.size()==4 and not manager.request_travel(ZoneCatalog.STATION,"from_market"),"Cuatro zonas, Estación bloqueada inicialmente")
	await ARC.enter_market(self,main)
	check(not main.get_node("World/ChapterPoints/StationExit").available,"Salida cerrada antes de finalizar capítulo 2")
	# Volver a inicio para preparar los capítulos con la misma fixture semántica.
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	main=current_scene
	await F.complete_market(self,main)
	manager=main.get_node("ZoneManager")
	check(main.get_node("Missions").chapter_completed(ChapterCatalog.MARKET) and ZoneCatalog.STATION in manager.unlocked and main.get_node("World/ChapterPoints/StationExit").available,"Final de transmisión desbloquea Estación")
	var saves:=main.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-thirteen-map-%d-%d" % [OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	var directory: String=saves.store.directory
	var legacy: Dictionary=preload("res://tests/legacy_save_fixture.gd").convert(saves.capture(3),3)
	check(saves.store.write_slot(3,legacy).has("ok"),"Guardado v3 anterior exacto")
	var old_bytes:=FileAccess.get_file_as_string(saves.store.path_for(3))
	var before_xp: int=main.get_node("Player/ProgressionComponent").total_xp()
	check(saves.load_slot(3).get("migrated",false),"Migración v3 → v4 explícita")
	await frames(4)
	main=current_scene
	manager=main.get_node("ZoneManager")
	saves=main.get_node("SaveCoordinator")
	check(ZoneCatalog.STATION in manager.unlocked and main.get_node("Player/ProgressionComponent").total_xp()==before_xp and FileAccess.get_file_as_string(saves.store.path_for(3))==old_bytes,"Partida completada recibe salida sin XP ni reescritura")
	check(await F.travel(self,ZoneCatalog.HOME,"from_market"),"Regreso previo a Gualey")
	check(not manager.request_travel(ZoneCatalog.STATION,"from_market"),"No teletransporta Gualey → Estación sin conexión")
	check(await F.travel(self,ZoneCatalog.MARKET,"from_gualey"),"Conexión Gualey → Mercado conservada")
	var player:=main.get_node("Player")
	player.get_node("Equipment").obtain(SaveCatalog.WEAPONS.revolver)
	player.get_node("Equipment").obtain(SaveCatalog.WEAPONS.shotgun)
	player.get_node("SkillsComponent").upgrade(&"survival")
	var player_id: int=player.get_instance_id()
	var hud_id: int=main.get_node("HUD").get_instance_id()
	var before:=stable_player(player)
	var old_world: WeakRef=weakref(main.get_node("World"))
	check(manager.request_travel(ZoneCatalog.STATION,"from_market"),"Mercado → Estación aceptado")
	check(not manager.request_travel(ZoneCatalog.HOME,"from_market") and paused,"No transiciones simultáneas; mundo pausado")
	await manager.transition_finished
	check(stable_player(player)==before and player.get_instance_id()==player_id and main.get_node("HUD").get_instance_id()==hud_id,"Conserva salud/necesidades/RPG/habilidades/inventario/cuatro armas")
	await frames(5)
	check(old_world.get_ref()==null and main.find_children("*","NavigationRegion2D",true,false).size()==1,"Mapa anterior liberado y una región")
	check(main.get_node("World").get_index()==0 and main.get_node("World/Obstacles").get_child_count()==26,"Orden visual y 26 estructuras técnicas")
	var zone: ZoneDefinition=manager.active_definition()
	check(zone.id==ZoneCatalog.STATION and zone.enemy_weights=={"base":40,"runner":40,"resistant":20},"Definición de estación configurable")
	check(ARC.counts(main)=={"base":3,"runner":2,"resistant":1} and main.get_node("Population").active_enemies().size()==6,"Mezcla inicial y seis vivos")
	for id in ZoneCatalog.DEFINITIONS:
		for p: Vector2 in ZoneCatalog.definition(id).entries.values():check(ZoneCatalog.point_free(id,[p.x,p.y]),"Entrada segura "+id+str(p))
	for container in main.get_node("World/Supplies").get_children():
		var p: Vector2=container.position
		check(ZoneCatalog.point_free(ZoneCatalog.STATION,[p.x,p.y]),"Suministro fuera de sólidos "+container.name)
	for p in [Vector2(320,800),Vector2(1420,470),Vector2(600,535),Vector2(1950,655),Vector2(1740,1080),Vector2(900,1280),Vector2(1500,800)]:
		var path:=NavigationServer2D.map_get_path(player.get_world_2d().navigation_map,player.position,p,true)
		check(not path.is_empty() and path[-1].distance_to(p)<3,"Ruta conectada "+str(p))
	# IA original con un obstáculo real del área técnica, sin desactivarla.
	var common:=ARC.by_type(main,"base")
	player.position=Vector2(1105,380)
	common.position=Vector2(955,380)
	await frames(2)
	check(not common._can_reach_target(),"Rack bloquea el rayo World")
	var deviation:=0.0
	for i in range(240):
		await frames(1)
		deviation=maxf(deviation,absf(common.position.y-380))
	check(deviation>60 and common.position.distance_to(player.position)<=36 and common.state==2,"Persigue, rodea rack y ataca con IA activa")
	var hp: float=player.health.current_health
	player.position=Vector2(1420,800)
	var actors: Array=[]
	var positions: Array=[Vector2(1280,750),Vector2(1420,600),Vector2(1580,780)]
	for i in range(3):
		var actor:=ARC.by_type(main,["base","runner","resistant"][i])
		actor.position=positions[i]
		actors.append(actor)
	await frames(25)
	for i in range(3):
		check(actors[i].is_physics_processing() and actors[i].position.distance_to(positions[i])>25,"IA activa "+String(actors[i].archetype.id))
		check(String(actors[i].get_node("Visual/Sprite").animation).begins_with("walk_"),"Walk en estación "+String(actors[i].archetype.id))
	await frames(100)
	check(player.health.current_health<hp and not main.game_ended,"Ataques reales sin Game Over artificial")
	for actor in actors:check(actor.get_node("Audio").emitter.get_child_count()==3 and actor.attack_interval==1.5,"Voces/cadencia sin cambios")
	player.position=Vector2(320,800)
	# Recuperar posiciones originales: sigue IA activa, lejos de las entradas.
	for enemy in main.get_node("Zombies").get_children():enemy.position=Vector2(1800,1300)+Vector2(enemy.get_index()*45,0)
	await frames(4)
	for p in [Vector2(520,930),Vector2(600,535),Vector2(1950,655),Vector2(1740,1080)]:
		await F.interact(self,main,p)
		main.get_node("InventoryUI").close_window()
	var radio_point:=main.get_node("World/ChapterPoints/StationRadio")
	var xp: int=player.get_node("ProgressionComponent").total_xp()
	await F.interact(self,main,radio_point.position+Vector2(0,30))
	main.get_node("RadioUI").close_window()
	check(manager.interactions==["station_radio"] and main.get_node("Missions").definitions.size()==15,"Interacción reservada; introducción independiente del capítulo 3")
	check(player.get_node("ProgressionComponent").total_xp()==xp,"Introducción sin XP")
	check(saves.save_slot(1).has("ok"),"Guardar estación con diálogo pendiente")
	check(saves.load_slot(1).has("ok"),"Cargar estación activa")
	await frames(4)
	main=current_scene
	player=main.get_node("Player")
	manager=main.get_node("ZoneManager")
	saves=main.get_node("SaveCoordinator")
	await F.interact(self,main,Vector2(1420,470))
	check(main.get_node("Radio").index==0 and main.get_node("RadioUI").window.visible,"Reabrir diálogo pendiente sin repetir inspección")
	F.finish_radio(main)
	check(not main.get_node("World/ChapterPoints/StationRadio").available and manager.interactions.size()==1,"Radio completada no se repite")
	ARC.by_type(main,"resistant").health.take_damage(12.5)
	ARC.by_type(main,"runner").health.take_damage(500)
	check(saves.save_slot(1,true).has("ok"),"Guardar heridas, cadáver y recursos")
	var expected:=saves.capture(1) as Dictionary
	check(expected.version==SaveSchema.VERSION and expected.zones.size()==2 and expected.world.interactions==["station_radio"],"Tres estados independientes en formato actual")
	for mutate: Callable in [func(d):d.world.interactions=["station_radio","station_radio"],func(d):d.world.interactions=["arbitrary"],func(d):d.missions.unlocked_zones=[ZoneCatalog.MARKET],func(d):d.zones.erase(ZoneCatalog.MARKET),func(d):d.stats.kills=55]:
		var invalid:=expected.duplicate(true)
		mutate.call(invalid)
		check(not SaveSchema.validate(invalid).is_empty(),"Rechaza estación/registro incoherente")
	var settled: Dictionary={}
	for destination in [ZoneCatalog.MARKET,ZoneCatalog.HOME,ZoneCatalog.MARKET,ZoneCatalog.STATION,ZoneCatalog.MARKET,ZoneCatalog.STATION]:
		var entry: String="from_market" if destination in [ZoneCatalog.HOME,ZoneCatalog.STATION] else "from_station" if manager.current_zone==ZoneCatalog.STATION else "from_gualey"
		var previous_world: WeakRef=weakref(main.get_node("World"))
		check(await F.travel(self,destination,entry),"Viaje repetido "+destination)
		check(previous_world.get_ref()==null and main.find_children("*","NavigationRegion2D",true,false).size()==1,"Sin zona/region antigua activa")
		var current:=counts(main)
		if settled.has(destination):check(current==settled[destination],"Sin acumulación de nodos/voces/señales/recursos en "+destination)
		settled[destination]=current
	check(manager.interactions==["station_radio"] and ARC.by_type(main,"resistant").health.current_health==87.5 and ARC.by_type(main,"runner").health.is_dead(),"Visitas conservan radio/heridas/bajas")
	check(saves.load_slot(1).has("ok"),"Cargar todos los estados tras visitas")
	await frames(4)
	main=current_scene
	player=main.get_node("Player")
	check(main.get_node("ZoneManager").current_zone==ZoneCatalog.STATION and not SaveCatalog.find(main.get_node("World"),"station_water"),"Mapa y recogida restaurados sin duplicación")
	var population:=main.get_node("Population")
	player.position=Vector2(320,800)
	var rewards_before: int=player.get_node("ProgressionComponent").total_xp()
	var remaining_xp:=0
	for enemy in population.active_enemies():remaining_xp+=enemy.archetype.xp_reward
	for ordinal in range(population.total_spawned+1,19):remaining_xp+=ZoneCatalog.definition(ZoneCatalog.STATION).archetype_for(ordinal).xp_reward
	population.spawned.connect(func(enemy):
		check(population.active_enemies().size()<=6 and population.total_spawned<=18,"Límite al aparecer")
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=enemy.get_node("CollisionShape2D").shape
		query.transform=enemy.global_transform
		query.collision_mask=1
		check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(),"Cuerpo aparece libre de colisiones World")
		check(not root.get_visible_rect().grow(96).has_point(enemy.get_canvas_transform()*enemy.position),"Aparece fuera de cámara")
		check(ZoneCatalog.point_free(ZoneCatalog.STATION,[enemy.position.x,enemy.position.y]),"Aparición fuera de sólidos"))
	while population.total_spawned<18:
		population.active_enemies()[0].health.take_damage(500)
		population._physics_process(10.1)
		await frames(2)
	for enemy in population.active_enemies():enemy.health.take_damage(500)
	check(ARC.counts(main)=={"base":7,"runner":7,"resistant":4},"Presupuesto completo 7/7/4")
	check(player.get_node("ProgressionComponent").total_xp()==rewards_before+remaining_xp,"XP por arquetipos, sin premio de entrada/radio")
	for i in range(3):population._physics_process(60)
	check(population.total_spawned==18 and population.active_enemies().is_empty(),"Presupuesto finito, sin enemigos invisibles adicionales")
	check(main.get_node("SaveCoordinator").save_slot(2).has("ok"),"Guardar población agotada de Estación sin cambiar fórmula RPG")
	player.health.take_damage(1000)
	check(main.game_ended and not population.running,"Game Over detiene población")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("ZoneManager").current_zone==ZoneCatalog.HOME and current_scene.get_node("ZoneManager").unlocked.is_empty(),"Reintentar vuelve al inicio sin desbloqueos")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado estación: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
