extends SceneTree
const P:=preload("res://tests/perimeter_fixture.gd")
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
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await ARC.frames(self,8)
	var saves:=current_scene.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-fifteen-restart"
	if "--write" in OS.get_cmdline_user_args():
		check(await P.enter(self),"Preparar cuarta zona")
		var main:=current_scene
		main.get_node("Radio").advance()
		main.get_node("RadioUI").close_window()
		ARC.by_type(main,"resistant").health.take_damage(12.5)
		ARC.by_type(main,"runner").health.take_damage(500)
		await F.interact(self,main,Vector2(940,1010))
		await F.interact(self,main,Vector2(480,890))
		var medical:=SaveCatalog.find(main.get_node("World"),"perimeter_medical_case")
		check(main.get_node("Player/Interaction").transfer_from_container(medical,0),"Transferir botiquines realmente")
		main.get_node("InventoryUI").close_window()
		main.get_node("Player/Equipment").obtain(SaveCatalog.WEAPONS.revolver)
		main.get_node("Player/Equipment").obtain(SaveCatalog.WEAPONS.shotgun)
		check(saves.save_slot(1,true).has("ok"),"Guardar cuatro zonas, botín, herida/cadáver y radio pendiente")
	else:
		var saved: Dictionary=saves.store.read_slot(1)
		check(saved.has("data") and saves.load_slot(1).has("ok"),"Leer en otro proceso")
		var main:=current_scene
		var actual: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(1),"",true,true))
		for key in ["player","world","zones","missions","story","stats","chapter","map"]:check(actual[key]==saved.data[key],"Restauración exacta "+key)
		check(actual.map==ZoneCatalog.PERIMETER and actual.zones.size()==3,"Cuatro mundos, mapa activo sin duplicar")
		check(actual.world.interactions==["perimeter_intro"] and main.get_node("Radio").index==1 and not main.get_node("RadioUI").window.visible,"Introducción pendiente sin repetición automática")
		check(ARC.by_type(main,"resistant").health.current_health==87.5 and ARC.by_type(main,"runner").health.is_dead(),"Herida y cadáver intactos")
		check(not actual.world.pickups.perimeter_water and actual.world.containers.perimeter_medical_case.slots[0].is_empty(),"No repone agua/botiquines")
		await ARC.frames(self,4)
		await F.interact(self,main,Vector2(1700,1050))
		check(main.get_node("Radio").index==1,"Equipo reanuda segundo mensaje")
		F.finish_radio(main)
		var xp: int=main.get_node("Player/ProgressionComponent").total_xp()
		for pair in [[ZoneCatalog.STATION,"from_perimeter"],[ZoneCatalog.MARKET,"from_station"],[ZoneCatalog.HOME,"from_market"],[ZoneCatalog.MARKET,"from_gualey"],[ZoneCatalog.STATION,"from_market"],[ZoneCatalog.PERIMETER,"from_station"]]:
			check(await F.travel(self,pair[0],pair[1]),"Viaje tras reapertura "+pair[0])
		check(main.get_node("Player/ProgressionComponent").total_xp()==xp and main.get_node("Radio").transmission==null and not main.get_node("RadioUI").window.visible,"Regreso no repite introducción ni premios")
	print("Proceso Perímetro PID=",OS.get_process_id())
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura Perímetro: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
