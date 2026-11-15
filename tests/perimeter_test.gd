extends SceneTree
const F:=preload("res://tests/station_fixture.gd")
const P:=preload("res://tests/perimeter_fixture.gd")
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
func stable_player(player: Node) -> Dictionary:
	var d:=PlayerSaveState.capture(player)
	for key in ["position","aim","facing"]:d.erase(key)
	return d
func counts(main: Node) -> Dictionary:
	var all:=main.find_children("*","",true,false)
	return {"nodes":all.size(),"audio":all.filter(func(n):return n is AudioStreamPlayer or n is AudioStreamPlayer2D).size(),"timers":all.filter(func(n):return n is Timer).size(),"signals":main.get_node("Player/HealthComponent").died.get_connections().size(),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)}
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-fifteen")
	check(root.get_texture().get_image().save_png("res://test-results/phase-fifteen/"+label+".png")==OK,"Captura IA "+label)
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	check(ZoneCatalog.DEFINITIONS.size()==4 and not current_scene.get_node("ZoneManager").request_travel(ZoneCatalog.PERIMETER,"from_station"),"Cuatro zonas; no acceso inicial")
	await F.enter(self)
	var main:=current_scene
	check(not main.get_node("World/ChapterPoints/PerimeterExit").available and not main.get_node("ZoneManager").request_travel(ZoneCatalog.PERIMETER,"from_station"),"Bloqueado durante capítulo 3")
	# Completar el capítulo por interacciones, conservando su último diálogo pendiente.
	for z in main.get_node("Zombies").get_children():z.set_physics_process(false)
	for z in main.get_node("Zombies").get_children().slice(0,2):z.health.take_damage(500)
	for name in ["Log","Console","Evacuation","Generator","Component","Secondary","Antenna","Link","Broadcast"]:
		await F.interact(self,main,main.get_node("World/ChapterPoints/"+name).position+Vector2(0,30))
		if name!="Broadcast":F.finish_radio(main)
	main.get_node("RadioUI").close_window()
	check(not main.get_node("World/ChapterPoints/PerimeterExit").available,"Última llamada cerrada no desbloquea")
	F.finish_radio(main)
	check(main.get_node("World/ChapterPoints/PerimeterExit").available and main.get_node("Missions").completed_chapters().size()==3,"Terminar mensaje autoriza Perímetro")
	var saves:=main.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-fifteen-map-%d-%d" % [OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	var legacy: Dictionary=LEGACY.convert(saves.capture(3),5)
	check(SaveSchema.validate(legacy).is_empty() and ZoneCatalog.PERIMETER not in legacy.missions.unlocked_zones,"v5 anterior completado exacto")
	check(saves.store.write_slot(3,legacy,true).has("ok"),"Guardar v5 aislado")
	var bytes:=FileAccess.get_file_as_string(saves.store.path_for(3))
	var xp: int=main.get_node("Player/ProgressionComponent").total_xp()
	check(saves.load_slot(3).get("migrated",false),"Migrar v5 → v6")
	await frames(4)
	main=current_scene
	saves=main.get_node("SaveCoordinator")
	check(main.get_node("World/ChapterPoints/PerimeterExit").available and main.get_node("Player/ProgressionComponent").total_xp()==xp and FileAccess.get_file_as_string(saves.store.path_for(3))==bytes,"v5 obtiene acceso sin XP/recompensas/reescritura")
	var player:=main.get_node("Player")
	player.get_node("Equipment").obtain(SaveCatalog.WEAPONS.revolver)
	player.get_node("Equipment").obtain(SaveCatalog.WEAPONS.shotgun)
	player.get_node("SkillsComponent").upgrade(&"survival")
	var before:=stable_player(player)
	var player_id: int=player.get_instance_id()
	var hud_id: int=main.get_node("HUD").get_instance_id()
	var old_world: WeakRef=weakref(main.get_node("World"))
	var manager:=main.get_node("ZoneManager")
	check(manager.request_travel(ZoneCatalog.PERIMETER,"from_station"),"Estación → Perímetro")
	check(not manager.request_travel(ZoneCatalog.HOME,"initial") and paused and saves.save_slot(1,true).has("error"),"Transición única; pausa y bloqueo de guardado")
	await manager.transition_finished
	check(stable_player(player)==before and player.get_instance_id()==player_id and main.get_node("HUD").get_instance_id()==hud_id,"Mismo Player/HUD; salud/necesidades/XP/habilidades/mochila/armas/munición intactas")
	check(main.get_node("RadioUI").window.visible and player.controls_blocked and manager.interactions==["perimeter_intro"],"Introducción automática reservada tras fundido; controles bloqueados")
	main.get_node("RadioUI").close_window()
	await frames(4)
	check(old_world.get_ref()==null and main.get_node("World").get_index()==0 and main.find_children("*","NavigationRegion2D",true,false).size()==1,"Mapa previo liberado; una región; suelo detrás de actores")
	check(ARC.counts(main)=={"base":2,"runner":2,"resistant":2} and main.get_node("Population").active_enemies().size()==6,"Mezcla inicial 2/2/2 y seis vivos")
	for id in ZoneCatalog.DEFINITIONS:
		for p: Vector2 in ZoneCatalog.definition(id).entries.values():check(ZoneCatalog.point_free(id,[p.x,p.y]),"Entrada segura "+id+str(p))
	for node in main.get_node("World/Supplies").get_children()+main.get_node("World/ChapterPoints").get_children():
		var p: Vector2=node.position
		check(ZoneCatalog.point_free(ZoneCatalog.PERIMETER,[p.x,p.y]),"Punto fuera de sólidos "+node.name)
		var path:=NavigationServer2D.map_get_path(player.get_world_2d().navigation_map,player.position,p,true)
		check(not path.is_empty() and path[-1].distance_to(p)<3,"Punto accesible "+node.name)
	# IA activa: corredor lateral rodea un autobús sin ver a través de él.
	var common:=ARC.by_type(main,"base")
	player.position=Vector2(1255,780)
	common.position=Vector2(1045,780)
	await frames()
	check(not common._can_reach_target(),"Autobús bloquea rayo de ataque")
	var deviation:=0.0
	for i in range(320):
		await frames(1)
		deviation=maxf(deviation,absf(common.position.y-780))
	check(deviation>65 and common.position.distance_to(player.position)<=36,"IA rodea extremo del autobús dentro del radio original de detección")
	player.position=Vector2(1200,950)
	var actors: Array=[]
	var origins: Array=[Vector2(1100,950),Vector2(1200,780),Vector2(1320,970)]
	for i in range(3):
		var z:=ARC.by_type(main,["base","runner","resistant"][i])
		z.position=origins[i]
		actors.append(z)
	await frames(25)
	for i in range(3):
		check(actors[i].is_physics_processing() and actors[i].position.distance_to(origins[i])>15 and actors[i].state in [1,2],"IA camina "+String(actors[i].archetype.id))
		check(String(actors[i].get_node("Visual/Sprite").animation).begins_with("walk_"),"Animación Walk real "+String(actors[i].archetype.id))
	await capture("05-perimeter-active-ai")
	var hp: float=player.health.current_health
	await frames(100)
	check(player.health.current_health<hp and not main.game_ended,"Ataques reales de variantes")
	for z in actors:
		check(z.attack_interval==1.5 and z.get_node("Audio").emitter.get_child_count()==3,"Cooldown y pool intactos")
		check(z.state==2 and String(z.get_node("Visual/Sprite").animation).begins_with("attack_"),"Animación Attack real "+String(z.archetype.id))
	# Colisión del jugador con el lateral del autobús, sin modificar velocidad.
	player.position=Vector2(1255,650)
	Input.action_press("move_left")
	await frames(30)
	Input.action_release("move_left")
	check(player.position.x>=1235,"Autobús impide atravesar su huella")
	# Aislar preparación de persistencia después de probar IA/navegación activa.
	for z in main.get_node("Zombies").get_children():z.set_physics_process(false)
	ARC.by_type(main,"resistant").health.take_damage(12.5)
	ARC.by_type(main,"runner").health.take_damage(500)
	for p in [Vector2(940,1010),Vector2(480,890),Vector2(450,1390),Vector2(2100,1230)]:
		await F.interact(self,main,p)
		main.get_node("InventoryUI").close_window()
	F.finish_radio(main)
	for name in ["MedicalInspection","Register","Comms"]:
		await F.interact(self,main,main.get_node("World/ChapterPoints/"+name).position+Vector2(0,30))
		F.finish_radio(main)
	check(manager.interactions.size()==4 and main.get_node("Missions").definitions.size()==15,"Cuatro inspecciones únicas, con las quince misiones del catálogo actual")
	check(saves.save_slot(1,true).has("ok"),"Guardar dentro del Perímetro")
	var saved: Dictionary=saves.capture(1)
	check(saved.zones.size()==3 and saved.version==SaveSchema.VERSION and not saved.world.pickups.perimeter_water,"Cuatro mundos y recogida persistentes")
	var mutations: Array[Callable]=[
		func(d):d.missions.unlocked_zones.erase(ZoneCatalog.PERIMETER),
		func(d):d.zones.erase(ZoneCatalog.STATION),
		func(d):d.world.interactions.append("perimeter_intro"),
		func(d):d.world.interactions.append("unknown"),
		func(d):d.stats.kills=73,
		func(d):d.version=5,
		func(d):d.missions.radio={"transmission":"perimeter_intro","index":10}]
	for mutate in mutations:
		var invalid:=saved.duplicate(true)
		mutate.call(invalid)
		check(not SaveSchema.validate(invalid).is_empty(),"Rechaza Perímetro incoherente")
	var stable: Dictionary={}
	for dest in [ZoneCatalog.STATION,ZoneCatalog.MARKET,ZoneCatalog.HOME,ZoneCatalog.MARKET,ZoneCatalog.STATION,ZoneCatalog.PERIMETER,ZoneCatalog.STATION,ZoneCatalog.PERIMETER,ZoneCatalog.STATION,ZoneCatalog.PERIMETER]:
		var source: String=manager.current_zone
		var entry: String=ZoneCatalog.definition(source).connections[dest]
		before=stable_player(player)
		var old: WeakRef=weakref(main.get_node("World"))
		check(manager.request_travel(dest,entry),"Conexión "+source+" → "+dest)
		await manager.transition_finished
		check(stable_player(player)==before,"Viajar conserva personaje mientras el mundo está congelado")
		await frames(4)
		check(old.get_ref()==null,"Libera mapa previo tras sincronización")
		var state:=counts(main)
		if stable.has(dest):check(state==stable[dest],"Sin acumulación de recursos/nodos/voces/timers/señales")
		stable[dest]=state
	check(manager.interactions.size()==4 and ARC.by_type(main,"resistant").health.current_health==87.5 and ARC.by_type(main,"runner").health.is_dead(),"Retorno conserva interacciones, heridas y cadáveres")
	check(saves.load_slot(1).has("ok"),"Cargar cuarta zona")
	await frames(4)
	main=current_scene
	check(main.get_node("ZoneManager").current_zone==ZoneCatalog.PERIMETER and main.get_node("ZoneManager").states.size()==3 and not main.get_node("RadioUI").window.visible,"Carga conserva cuatro zonas, sin introducción repetida")
	var population:=main.get_node("Population")
	main.get_node("Player").position=Vector2(1200,1350)
	var total_before: int=population.total_spawned
	for z in population.active_enemies():z.health.take_damage(500)
	for i in range(20):
		population._physics_process(10.1)
		await frames(2)
		for z in population.active_enemies():
			check(ZoneCatalog.point_free(ZoneCatalog.PERIMETER,[z.position.x,z.position.y]) and z.position.distance_to(main.get_node("Player").position)>=315,"Reposición segura y alejada")
			z.health.take_damage(500)
		if population.total_spawned==18:break
	check(population.total_spawned==18 and population.active_enemies().is_empty() and total_before==6,"Presupuesto finito completo, sin bloqueo por nuevos puntos")
	check(ARC.counts(main)=={"base":6,"runner":7,"resistant":5},"Distribución completa por ordinal: "+str(ARC.counts(main)))
	main.get_node("Player/HealthComponent").take_damage(1000)
	check(main.game_ended and not main.get_node("ZoneManager").request_travel(ZoneCatalog.STATION,"from_perimeter"),"Game Over impide viaje")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("ZoneManager").current_zone==ZoneCatalog.HOME and current_scene.get_node("ZoneManager").unlocked.is_empty(),"Reintentar restaura inicio sin desbloqueos")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado Perímetro: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
