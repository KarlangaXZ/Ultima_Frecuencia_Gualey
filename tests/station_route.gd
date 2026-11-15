extends RefCounted
## Reutiliza el recorrido físico de ambos capítulos; IA aislada por ese driver.
static func capture(driver: SceneTree,label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-thirteen")
	driver.check(driver.root.get_texture().get_image().save_png("res://test-results/phase-thirteen/"+label+".png")==OK,"Captura estación "+label)
static func run(driver: SceneTree) -> void:
	var main: Node=driver.main
	var player: Node=driver.player
	var player_id: int=player.get_instance_id()
	await driver.interact(Vector2(2250,800))
	if main.get_node("ZoneManager").busy:await main.get_node("ZoneManager").transition_finished
	await driver.frames(8)
	driver.check(main.get_node("ZoneManager").current_zone==ZoneCatalog.STATION and player.get_instance_id()==player_id,"E lleva a la Estación con el mismo jugador")
	await capture(driver,"01-station-entry")
	for pair in [["station_water",Vector2(520,930)],["station_canteen",Vector2(600,535)],["station_medical",Vector2(1950,655)],["station_parts",Vector2(1740,1080)]]:
		await driver.interact(pair[1])
		main.get_node("InventoryUI").close_window()
	var xp: int=player.get_node("ProgressionComponent").total_xp()
	await driver.point("StationRadio")
	driver.check(main.get_node("RadioUI").window.visible and main.get_node("ZoneManager").interactions==["station_radio"],"Inspección única, introducción independiente del capítulo 3")
	await capture(driver,"02-station-radio")
	await driver.close_radio()
	driver.check(player.get_node("ProgressionComponent").total_xp()==xp and driver.tracker.definitions.size()==11,"Radio introductoria no otorga XP ni completa misiones")
	var camera: Camera2D=player.get_node("Camera2D")
	var old_zoom:=camera.zoom
	var old_position: Vector2=player.position
	player.position=Vector2(1200,800)
	camera.zoom=Vector2(0.43,0.43)
	camera.reset_smoothing()
	camera.force_update_scroll()
	for ui in ["HUD","ObjectiveHUD"]:main.get_node(ui).hide()
	await driver.frames(4)
	await capture(driver,"03-station-plan")
	for ui in ["HUD","ObjectiveHUD"]:main.get_node(ui).show()
	player.position=old_position
	camera.zoom=old_zoom
	camera.reset_smoothing()
	camera.force_update_scroll()
	await driver.frames(3)
	driver.check(main.get_node("SaveCoordinator").save_slot(3,true).has("ok"),"Guardar Estación recorrida")
	driver.check(main.get_node("SaveCoordinator").load_slot(3).has("ok"),"Restaurar Estación recorrida")
	await driver.frames(4)
	driver.bind_scene()
	main=driver.main
	driver.check(main.get_node("ZoneManager").interactions==["station_radio"] and not main.get_node("World/ChapterPoints/StationRadio").available,"Inspección no se repite al cargar")
	await driver.interact(Vector2(270,800))
	if main.get_node("ZoneManager").busy:await main.get_node("ZoneManager").transition_finished
	await driver.frames(4)
	driver.check(main.get_node("ZoneManager").current_zone==ZoneCatalog.MARKET,"E regresa al Mercado; continúa recorrido hacia Gualey")
