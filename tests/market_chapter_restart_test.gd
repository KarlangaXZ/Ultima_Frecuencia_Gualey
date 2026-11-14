extends SceneTree
const FIXTURE:=preload("res://tests/archetype_fixture.gd")
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
	await FIXTURE.frames(self,8)
	var saves:=current_scene.get_node("SaveCoordinator")
	saves.store.directory="user://tests/phase-twelve-restart"
	if "--write" in OS.get_cmdline_user_args():
		await FIXTURE.enter_market(self,current_scene)
		var main:=current_scene
		for name in ["Stall","Evacuation"]:
			var point: Node=main.get_node("World/ChapterPoints/"+name)
			await preload("res://tests/save_fixture.gd").interact_at(self,main,point.position+Vector2(0,30))
		await preload("res://tests/save_fixture.gd").interact_at(self,main,Vector2(580,890))
		FIXTURE.by_type(main,"runner").health.take_damage(500)
		check(saves.save_slot(1,true).has("ok"),"Guardar capítulo 2 parcial antes de cerrar")
		print("Escritor capítulo 2 PID=",OS.get_process_id())
	elif "--read" in OS.get_cmdline_user_args():
		var loaded: Dictionary=saves.store.read_slot(1)
		check(loaded.has("data") and saves.load_slot(1).has("ok"),"Reabrir capítulo en proceso distinto")
		var after: Dictionary=JSON.parse_string(JSON.stringify(current_scene.get_node("SaveCoordinator").capture(1),"",true,true))
		check(after.chapter==loaded.data.chapter and after.story==loaded.data.story and after.missions==loaded.data.missions,"Capítulos, interacciones, premios y diálogo exactos")
		check(after.world==loaded.data.world and after.zones==loaded.data.zones and after.player==loaded.data.player,"Mundo/suministros/arsenal/XP conservados")
		var tracker: MissionTracker=current_scene.get_node("Missions")
		check(tracker.progress_of(&"market_traces",0)==1 and tracker.progress_of(&"market_traces",1)==1 and tracker.progress_of(&"market_traces",2)==0,"Interacciones pendientes sin completar misión al cargar")
		check(tracker._totals.get(&"market_water",0)==1 and tracker._totals.get(&"market_runner_kills",0)==1,"Recogida y baja histórica conservadas")
		print("Lector capítulo 2 PID=",OS.get_process_id())
	else:check(false,"Falta --write o --read")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado reapertura capítulo 2: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
