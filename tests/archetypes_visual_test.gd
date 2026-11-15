extends SceneTree
const FIXTURE := preload("res://tests/archetype_fixture.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/archetypes")
	check(root.get_texture().get_image().save_png("res://test-results/archetypes/" + label + ".png") == OK,"Captura " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if "--no-vsync" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	change_scene_to_file("res://scenes/Main.tscn")
	await FIXTURE.frames(self,8)
	var main := current_scene
	var player := main.get_node("Player")
	player.position = Vector2(1000,980)
	await FIXTURE.frames(self,25)
	check(main.get_node("Zombies/ZombieA").velocity.length() > 100 and main.get_node("Population").active_enemies().size() == 6,"Gualey con IA activa y seis comunes")
	check(main.get_node("Population").active_enemies().all(func(e): return e.archetype.id == &"base"),"Sin variantes añadidas a la zona inicial")
	await capture("01-home-common")
	await FIXTURE.enter_market(self,main)
	check(FIXTURE.counts(main) == {"base":3,"runner":2,"resistant":1},"Mercado utiliza las tres variantes")
	player.position = Vector2(900,900)
	var actors := [FIXTURE.by_type(main,"base"),FIXTURE.by_type(main,"runner"),FIXTURE.by_type(main,"resistant")]
	var starts := [Vector2(800,740),Vector2(900,740),Vector2(1000,740)]
	for index in range(3): actors[index].position = starts[index]
	await FIXTURE.frames(self,25)
	for index in range(3):
		var actor: Node = actors[index]
		check(actor.is_physics_processing() and actor.position.distance_to(starts[index]) > 25 and actor.state == 1,"Variante persigue realmente: " + String(actor.archetype.id))
		check(String(actor.get_node("Visual/Sprite").animation).begins_with("walk_") and is_equal_approx(actor.get_node("Visual/Sprite").speed_scale,actor.speed/105.0),"Animación consistente con movimiento")
		check(actor.get_node("Visual/Sprite").offset == Vector2(0,-46) and actor.get_node("CollisionShape2D").shape.radius == 16,"Pivote y colisión conservados")
	check(actors[1].get_node("Visual/Sprite").modulate != Color.WHITE and actors[2].get_node("Visual/Sprite").modulate != actors[1].get_node("Visual/Sprite").modulate,"Tintas moderadas distinguibles")
	await capture("02-market-variants")
	await FIXTURE.frames(self,50)
	var sum := 0.0
	var draws := 0.0
	var nodes := 0.0
	for index in range(120):
		await FIXTURE.frames(self,1)
		sum += Performance.get_monitor(Performance.TIME_PROCESS)*1000
		draws = maxf(draws,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		nodes = maxf(nodes,Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var damage := 0.0
	for actor in actors:
		var emitter: SoundEmitter = actor.get_node("Audio").emitter
		var attacks: int = emitter.played_counts.get(&"zombie_attack",0)
		check(attacks > 0 and attacks <= 3 and emitter.get_child_count() == 3,"Ataques y voces acotados por enemigo")
		damage += attacks * actor.attack_damage
	check(player.health.current_health == 100-damage and not main.game_ended,"Audio por golpe válido, sin daño duplicado")
	check(main.get_node("Population").active_enemies().size() == 6 and main.get_node("Zombies").get_child_count() == 6,"Seis vivos sin crecimiento durante muestra")
	print("Variantes 120 frames: TIME_PROCESS medio=",snappedf(sum/120,0.01)," ms; draw calls máximo=",draws,"; nodos máximo=",nodes,"; foco=",DisplayServer.window_is_focused())
	await capture("03-market-attacks")
	player.health.take_damage(1000)
	await FIXTURE.frames(self,2)
	check(main.get_node("Population").active_enemies().all(func(e): return e.target == null and e.velocity == Vector2.ZERO),"Game Over detiene todas las variantes")
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await FIXTURE.frames(self,8)
	check(current_scene.get_node("ZoneManager").current_zone == ZoneCatalog.HOME and FIXTURE.counts(current_scene) == {"base":6,"runner":0,"resistant":0},"Reintentar conserva comienzo moderado")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado visual variantes: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
