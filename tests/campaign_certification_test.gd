extends "res://tests/market_chapter_test.gd"
## Campaña desde TitleMenu sin fixtures, teletransportes, daño/XP artificiales,
## cambios de población ni IA desactivada. Bot usa APIs de acciones reales.
var stage := "inicio"
var started := 0
var last_progress := 0
var actions := {"shots":0,"reloads":0,"items":0}
var directory: String
var armed := false
func bind_scene() -> void:
	main=current_scene
	player=main.get_node("Player")
	tracker=main.get_node("Missions")
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://test-results/phase-seventeen/"+label+".png")==OK,"Captura "+label)
func use(id: StringName) -> bool:
	var inventory: InventoryComponent=player.get_node("InventoryComponent")
	for i in range(inventory.capacity):
		var slot:=inventory.get_slot(i)
		if not slot.is_empty() and slot.item.id==id:
			if player.get_node("ItemUse").use_slot(i): actions.items+=1;return true
	return false
func bot() -> void:
	if not armed or not is_instance_valid(player) or not is_instance_valid(main):return
	if main.game_ended:
		push_error("Campaña fallida por muerte en "+stage)
		quit(1)
		return
	if Time.get_ticks_msec()-last_progress>180000:
		push_error("Campaña sin progreso: "+stage)
		quit(1)
	if player.controls_blocked or paused:return
	if player.health.current_health<60: use(&"medkit")
	var survival:=player.get_node("SurvivalComponent")
	if survival.thirst<70:use(&"water")
	if survival.hunger<70:use(&"food")
	var equipment:=player.get_node("Equipment")
	var weapon: Node=player.weapon
	if weapon.config.weapon_type!="melee" and weapon.reserve<12:use(StringName(String(weapon.config.ammo_type)+"_ammo"))
	if weapon.config.weapon_type!="melee" and weapon.loaded==0:
		if weapon.reserve>0:
			if weapon.start_reload():actions.reloads+=1
		else: equipment.switch_to(&"machete")
	weapon=player.weapon
	var target: Node
	var closest:=minf(570,weapon.config.shot_range)
	for zombie in main.get_node("Population").active_enemies():
		var distance:=player.position.distance_to(zombie.position)
		if distance>=closest:continue
		var ray:=PhysicsRayQueryParameters2D.create(player.position,zombie.position,1)
		if not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
		target=zombie
		closest=distance
	if target!=null and weapon.try_fire(player.position,player.position.direction_to(target.position)):actions.shots+=1
func mark(value: String) -> void:
	stage=value
	last_progress=Time.get_ticks_msec()
	print("CAMPAÑA: ",value," · recorrido=",snappedf(walked,.1)," · HP=",player.health.current_health if is_instance_valid(player) else 0)
func loot(position: Vector2) -> void:
	await interact(position+Vector2(0,30))
	var ui:=main.get_node("InventoryUI")
	if ui.window.visible and is_instance_valid(ui.container):
		var container: LootContainer=ui.container
		for i in range(container.inventory.capacity):
			if not container.inventory.get_slot(i).is_empty(): player.get_node("Interaction").transfer_from_container(container,i)
		ui.close_window()
	for id in [&"weapon_revolver",&"weapon_shotgun",&"pistol_ammo",&"revolver_ammo",&"shotgun_ammo"]:use(id)
func hunt(type: StringName = &"") -> void:
	var target: Node
	# Si la población está reponiéndose, esperar su reloj real, sin forzar spawns.
	if main.get_node("Population").active_enemies().is_empty() and main.get_node("Population").total_spawned<18:
		await frames(620)
	for zombie in main.get_node("Population").active_enemies():
		if type==&"" or zombie.archetype.id==type:target=zombie;break
	check(target!=null,"Amenaza real disponible: "+String(type))
	if target==null:return
	var id:=SaveCatalog.id_of(target)
	for i in range(12):
		if not is_instance_valid(target) or target.health.is_dead():break
		var point: Vector2=target.position
		await walk_to(point)
		await frames(65)
	check(target.health.is_dead(),"Baja real: "+id)
func mission_point(name: String) -> void:
	await point(name)
	await close_radio()
	check(not main.game_ended,"Interacción con IA activa: "+name)
func travel(position: Vector2, destination: String) -> void:
	await interact(position)
	if main.get_node("ZoneManager").busy:await main.get_node("ZoneManager").transition_finished
	await frames(5)
	check(main.get_node("ZoneManager").current_zone==destination,"Viaje mediante salida real a "+destination)
	await close_radio()
func checkpoint(slot: int) -> void:
	await key(KEY_J)
	await capture("chapter-%d"%tracker.completed_chapters().size())
	await key(KEY_J)
	var saves:=main.get_node("SaveCoordinator")
	check(saves.save_slot(slot,true).has("ok"),"Guardar checkpoint "+str(slot))
	var expected: Dictionary=JSON.parse_string(JSON.stringify(saves.capture(slot),"",true,true))
	armed=false
	check(saves.load_slot(slot).has("ok"),"Cargar checkpoint "+str(slot))
	bind_scene()
	var actual: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(slot),"",true,true))
	for key in ["player","world","zones","missions","story","stats"]:check(actual[key]==expected[key],"Restauración exacta "+key)
	armed=true
	await frames(5)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-seventeen")
	started=Time.get_ticks_msec()
	last_progress=started
	directory="user://tests/phase-seventeen-campaign-%d-%d"%[OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	await frames(4)
	var menu:=current_scene
	menu.store.directory=directory
	await capture("01-title")
	menu.show_page("settings")
	await capture("00-settings")
	menu.show_page("slots")
	await capture("02-slots")
	menu._launch(1,true,false)
	for i in range(90):
		await frames(1)
		if current_scene.scene_file_path=="res://scenes/Main.tscn":break
	check(current_scene.scene_file_path=="res://scenes/Main.tscn","Nueva partida desde ranura 1")
	if current_scene.scene_file_path!="res://scenes/Main.tscn":quit(1);return
	bind_scene()
	physics_frame.connect(bot)
	armed=true
	mark("Gualey")
	await interact(Vector2(560,810))
	await interact(Vector2(650,880))
	while main.kills<2:await hunt()
	for p in [Vector2(600,680),Vector2(1720,630),Vector2(600,680)]:
		await interact(p)
		await close_radio()
	check(tracker.chapter_completed(ChapterCatalog.FIRST),"Tres misiones de La señal perdida")
	await loot(Vector2(770,650))
	await loot(Vector2(1560,1230))
	await loot(Vector2(1960,880))
	check(player.get_node("Equipment").get_weapons().size()==4,"Arsenal adquirido desde contenedores reales")
	for id in [&"machete",&"revolver",&"shotgun",&"pistol"]:
		player.get_node("Equipment").switch_to(id)
		check(player.weapon.config.id==id,"Cambio real de arma: "+String(id))
		await hunt()
	await key(KEY_K)
	await capture("03-character")
	await key(KEY_K)
	check(player.get_node("SkillsComponent").upgrade(&"vitality"),"Habilidad comprada con XP ganada")
	main.get_node("InventoryUI").open_inventory()
	await capture("inventory")
	main.get_node("InventoryUI").close_window()
	main.get_node("PauseUI").open_panel()
	await capture("pause")
	main.get_node("PauseUI").close_window()
	await checkpoint(1)
	await travel(Vector2(2090,800),ZoneCatalog.MARKET)
	mark("Mercado")
	for p in [Vector2(580,890),Vector2(600,960)]:await interact(p)
	await loot(Vector2(530,1180))
	for type in [&"runner",&"resistant"]:
		if tracker._totals.get(StringName("market_"+String(type)+"_kills"),0)==0:await hunt(type)
	for name in ["Stall","Evacuation","Record","Comms","Power","Repeater"]:await mission_point(name)
	check(tracker.chapter_completed(ChapterCatalog.MARKET),"Cuatro misiones de Ecos del Mercado")
	await loot(Vector2(2050,940))
	await checkpoint(2)
	await travel(Vector2(2250,800),ZoneCatalog.STATION)
	mark("Estación")
	while tracker._totals.get(&"station_kills",0)<2:await hunt()
	for name in ["StationRadio","Log","Console","Evacuation","Generator","Component","Secondary","Antenna","Link","Broadcast"]:await mission_point(name)
	check(tracker.chapter_completed(ChapterCatalog.STATION),"Cuatro misiones de Voces en la oscuridad")
	await checkpoint(3)
	await travel(Vector2(800,260),ZoneCatalog.PERIMETER)
	mark("Perímetro")
	await loot(Vector2(480,860))
	for name in ["Checkpoint","Register","Authorization","BusInspection","EvacuationVehicle","DestinationLog","MedicalInspection","QuarantineLog","SafetyInspection","Comms","TransferOrder"]:await mission_point(name)
	await point("RadioLink")
	check(tracker.state_of(&"convoy_route")==2,"Última transmisión todavía pendiente")
	await capture("04-final-radio")
	await close_radio()
	check(tracker.completed_chapters().size()==4 and main.get_node("Missions/Rewards")._awarded.size()==15,"Cuatro capítulos y quince premios completados desde cero")
	await key(KEY_J)
	await capture("05-campaign-complete")
	await key(KEY_J)
	await checkpoint(3)
	for z in main.get_node("Population").active_enemies():check(z.is_physics_processing(),"IA continúa activa al completar campaña")
	check(main.get_node("ZoneManager").states.size()==3 and ZoneCatalog.DEFINITIONS.size()==4,"Cuatro mundos persistidos")
	var result: Dictionary={"checks":checks,"failures":failures,"walked_pixels":walked,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0,"game_seconds":main.survival_time,"actions":actions,"directory":directory,"final":main.get_node("SaveCoordinator").capture(3),"method":"Real movement, interaction, finite loot, combat and AI; no fixtures or actor/state repositioning"}
	FileAccess.open("res://test-results/phase-seventeen/campaign.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	armed=false
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado campaña integral: ",checks," comprobaciones, ",failures," fallos; recorrido=",walked," px")
	quit(0 if failures==0 else 1)
