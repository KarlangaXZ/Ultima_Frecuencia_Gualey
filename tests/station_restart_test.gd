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
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await ARC.frames(self,8)
	var saves:=current_scene.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-thirteen-restart"
	if "--write" in OS.get_cmdline_user_args():
		check(await F.enter(self),"Acceder a estación antes de escribir")
		var main:=current_scene
		await F.interact(self,main,Vector2(520,930))
		await F.interact(self,main,Vector2(1420,470))
		main.get_node("Radio").advance()
		main.get_node("RadioUI").close_window()
		ARC.by_type(main,"resistant").health.take_damage(12.5)
		ARC.by_type(main,"runner").health.take_damage(500)
		check(saves.save_slot(1,true).has("ok"),"Guardar tres zonas/intro pendiente/tipos/heridas")
		print("Escritor Estación PID=",OS.get_process_id())
	elif "--read" in OS.get_cmdline_user_args():
		var loaded: Dictionary=saves.store.read_slot(1)
		check(loaded.has("data") and saves.load_slot(1).has("ok"),"Cargar Estación en otro proceso")
		var main:=current_scene
		var after: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(1),"",true,true))
		check(after.map==ZoneCatalog.STATION and after.world==loaded.data.world and after.zones==loaded.data.zones and after.zones.size()==2,"Tres estados de mundo exactos")
		check(after.player==loaded.data.player and after.missions==loaded.data.missions and after.story==loaded.data.story and after.stats==loaded.data.stats,"Jugador/RPG/arsenal/narrativa/bajas intactos")
		check(after.world.interactions==["station_radio"] and main.get_node("Radio").index==1,"Inspección e índice de intro conservados")
		check(ARC.by_type(main,"resistant").health.current_health==87.5 and ARC.by_type(main,"runner").health.is_dead(),"Herida/cadáver sin recompensa duplicada")
		check(main.get_node("Zombies").get_child_count()==6 and main.find_children("*","NavigationRegion2D",true,false).size()==1,"Una región, seis actores y cinco vivos")
		print("Lector Estación PID=",OS.get_process_id())
	else:check(false,"Falta --write o --read")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura estación: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
