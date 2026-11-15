extends SceneTree
const F := preload("res://tests/evacuation_fixture.gd")
const S := preload("res://tests/station_fixture.gd")
const ARC := preload("res://tests/archetype_fixture.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await ARC.frames(self,8)
	var saves := current_scene.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-sixteen-restart"
	var args := OS.get_cmdline_user_args()
	if "--write" in args:
		check(await F.enter(self),"Preparar capítulo 4")
		var main := current_scene
		var inventory: InventoryComponent=main.get_node("Player/InventoryComponent")
		inventory.add_item(SaveCatalog.ITEMS.food,inventory.space_for(SaveCatalog.ITEMS.food))
		await F.point(self,"Checkpoint")
		check(saves.save_slot(1,true).has("ok"),"Guardar investigación parcial y mochila llena")
	else:
		var slot := 1 if "--read" in args else 2 if "--final" in args else 3
		var saved: Dictionary=saves.store.read_slot(slot)
		check(saved.has("data") and saves.load_slot(slot).has("ok"),"Cargar en proceso independiente")
		var main := current_scene
		var actual: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(slot),"",true,true))
		for key in ["player","world","zones","missions","story","stats","chapter","map"]:
			check(actual[key]==saved.data[key],"Restauración exacta de "+key)
		await ARC.frames(self,4)
		F.freeze(main)
		var xp: int=main.get_node("Player/ProgressionComponent").total_xp()
		if "--read" in args:
			check(main.get_node("Missions").progress_of(&"convoy_access",0)==1 and main.get_node("Player/InventoryComponent").occupied_slots()==12,"Registro parcial y mochila persisten")
			await F.to_final(self)
			main.get_node("Radio").advance()
			main.get_node("RadioUI").close_window()
			check(main.get_node("Player/ProgressionComponent").total_xp()==xp+170,"Tres premios, sin final anticipado")
			check(main.get_node("SaveCoordinator").save_slot(2,true).has("ok"),"Guardar transmisión final índice 1")
		elif "--final" in args:
			await F.point(self,"Comms",false)
			check(main.get_node("Radio").index==1,"Reanudar desde índice 1 en proceso nuevo")
			S.finish_radio(main)
			check(main.get_node("Player/ProgressionComponent").total_xp()==xp+100 and MissionSaveState.story(main).facility_hint,"Premio final único y pista")
			check(main.get_node("SaveCoordinator").save_slot(3,true).has("ok"),"Guardar cuatro capítulos completos")
		else:
			await F.point(self,"RadioLink")
			check(main.get_node("Missions").completed_chapters().size()==4 and main.get_node("Missions/Rewards")._awarded.size()==15,"Quince premios e historial completo")
			check(main.get_node("Radio").transmission==null and main.get_node("Player/ProgressionComponent").total_xp()==xp,"Reabrir no reproduce ni premia")
			check(ZoneCatalog.DEFINITIONS.size()==4 and main.get_node("ZoneManager").states.size()==3,"Solo cuatro mapas persistidos")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Proceso capítulo 4 PID=",OS.get_process_id())
	print("Resultado reapertura capítulo 4: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
