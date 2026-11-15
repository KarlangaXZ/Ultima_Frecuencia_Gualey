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
func point(name: String,finish:=true) -> void:
	var main:=current_scene
	await F.interact(self,main,main.get_node("World/ChapterPoints/"+name).position+Vector2(0,30))
	if finish:F.finish_radio(main)
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await ARC.frames(self,8)
	var saves:=current_scene.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-fourteen-restart"
	var args:=OS.get_cmdline_user_args()
	if "--write" in args:
		check(await F.enter(self),"Preparar estación")
		var main:=current_scene
		for z in main.get_node("Zombies").get_children():z.set_physics_process(false)
		for z in main.get_node("Zombies").get_children().slice(0,2):z.health.take_damage(500)
		var inventory: InventoryComponent=main.get_node("Player/InventoryComponent")
		check(inventory.add_item(SaveCatalog.ITEMS.food,inventory.space_for(SaveCatalog.ITEMS.food)),"Llenar mochila de fixture")
		for name in ["Log","Console","Evacuation","Generator","Component","Secondary","Antenna"]:await point(name)
		await point("Link",false)
		main.get_node("Radio").advance()
		main.get_node("RadioUI").close_window()
		check(saves.save_slot(1,true).has("ok"),"Escribir componente, mochila llena y enlace pendiente")
	else:
		var slot:=1 if "--read" in args else 2 if "--final" in args else 3
		var saved: Dictionary=saves.store.read_slot(slot)
		check(saved.has("data") and saves.load_slot(slot).has("ok"),"Cargar en proceso nuevo")
		var main:=current_scene
		var actual: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(slot),"",true,true))
		for key in ["player","world","zones","missions","story","stats","chapter","map"]:
			check(actual[key]==saved.data[key],"Restauración exacta "+key)
		var xp: int=main.get_node("Player/ProgressionComponent").total_xp()
		await ARC.frames(self,4)
		for z in main.get_node("Zombies").get_children():z.set_physics_process(false)
		check(main.get_node("Player/InventoryComponent").occupied_slots()==12 and main.get_node("Missions").progress_of(&"station_power",1)==1,"Componente y mochila llenos persistentes")
		if "--read" in args:
			await point("Link",false)
			check(main.get_node("Radio").index==1,"Reabrir enlace desde índice 1")
			F.finish_radio(main)
			check(main.get_node("Player/ProgressionComponent").total_xp()==xp+65,"Premio pendiente de 65 XP una vez")
			await point("Broadcast",false)
			main.get_node("Radio").advance()
			main.get_node("RadioUI").close_window()
			check(main.get_node("SaveCoordinator").save_slot(2,true).has("ok"),"Guardar última llamada pendiente")
		elif "--final" in args:
			await point("Broadcast",false)
			check(main.get_node("Radio").index==1,"Reabrir última llamada desde índice 1")
			F.finish_radio(main)
			check(main.get_node("Player/ProgressionComponent").total_xp()==xp+90 and MissionSaveState.story(main).perimeter_hint,"Premio final de 90 XP y pista")
			check(main.get_node("SaveCoordinator").save_slot(3,true).has("ok"),"Guardar capítulo completo")
		else:
			check(MissionSaveState.story(main).perimeter_hint and main.get_node("Missions").completed_chapters().size()==3,"Tres capítulos completos sin radio pendiente")
			await point("Broadcast")
			check(main.get_node("Player/ProgressionComponent").total_xp()==xp and main.get_node("Radio").transmission==null,"Reabrir no premia ni reproduce otra vez")
			check(main.get_node("Missions/Rewards")._awarded.size()==11,"Once premios individuales conservados")
	print("Proceso capítulo 3 PID=",OS.get_process_id())
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura capítulo 3: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
