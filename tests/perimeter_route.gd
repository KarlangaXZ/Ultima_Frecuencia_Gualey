extends RefCounted
## Extiende el driver físico del capítulo 3 sin duplicar movimiento/entrada.
static func capture(driver: SceneTree,label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-fifteen")
	driver.check(driver.root.get_texture().get_image().save_png("res://test-results/phase-fifteen/"+label+".png")==OK,"Captura Perímetro "+label)
static func run(driver: SceneTree) -> void:
	var main: Node=driver.main
	var player: Node=driver.player
	var player_id: int=player.get_instance_id()
	await driver.interact(Vector2(800,260))
	if main.get_node("ZoneManager").busy:await main.get_node("ZoneManager").transition_finished
	await driver.frames(5)
	driver.check(main.get_node("ZoneManager").current_zone==ZoneCatalog.PERIMETER and player.get_instance_id()==player_id,"E accede al Perímetro con el mismo jugador")
	driver.check(main.get_node("RadioUI").window.visible and main.get_node("ZoneManager").interactions==["perimeter_intro"],"Primera visita presenta introducción única")
	await capture(driver,"01-perimeter-intro")
	main.get_node("Radio").advance()
	main.get_node("RadioUI").close_window()
	driver.check(main.get_node("SaveCoordinator").save_slot(1,true).has("ok"),"Guardar introducción pendiente")
	driver.check(main.get_node("SaveCoordinator").load_slot(1).has("ok"),"Cargar cuarta zona con introducción pendiente")
	await driver.frames(5)
	driver.bind_scene()
	main=driver.main
	player=driver.player
	driver.check(main.get_node("Radio").index==1 and not main.get_node("RadioUI").window.visible,"Carga conserva índice sin abrir ventana")
	await driver.point("Comms")
	driver.check(main.get_node("Radio").index==1,"Comunicaciones reabre introducción sin reiniciarla")
	await driver.close_radio()
	# Mochila llena heredada del recorrido del capítulo 3: usar un consumible real.
	var inventory: InventoryComponent=player.get_node("InventoryComponent")
	var used:=false
	for i in range(inventory.capacity):
		var slot:=inventory.get_slot(i)
		if not slot.is_empty() and slot.item.id==&"food":
			used=player.get_node("ItemUse").use_slot(i)
			break
	driver.check(used,"Uso real de suministro conservado tras viaje")
	await driver.interact(Vector2(940,1010))
	for p in [Vector2(480,890),Vector2(450,1390),Vector2(2100,1230)]:
		await driver.interact(p)
		main.get_node("InventoryUI").close_window()
	for name in ["MedicalInspection","Register","Comms"]:
		await driver.point(name)
		await driver.close_radio()
	driver.check(main.get_node("ZoneManager").interactions.size()==4 and driver.tracker.definitions.size()==11,"Puntos de interés únicos sin nuevas misiones")
	await driver.walk_to(Vector2(1200,950))
	await capture(driver,"02-perimeter-road")
	var camera: Camera2D=player.get_node("Camera2D")
	var old_zoom:=camera.zoom
	var old_position: Vector2=player.position
	player.position=Vector2(1350,800)
	camera.zoom=Vector2(0.43,0.43)
	camera.reset_smoothing()
	camera.force_update_scroll()
	for ui in ["HUD","ObjectiveHUD"]:main.get_node(ui).hide()
	await driver.frames(4)
	await capture(driver,"03-perimeter-plan")
	for ui in ["HUD","ObjectiveHUD"]:main.get_node(ui).show()
	player.position=old_position
	camera.zoom=old_zoom
	camera.reset_smoothing()
	camera.force_update_scroll()
	await driver.frames(3)
	driver.check(main.get_node("SaveCoordinator").save_slot(3,true).has("ok"),"Guardar recorrido e inspecciones del Perímetro")
	driver.check(main.get_node("SaveCoordinator").load_slot(3).has("ok"),"Restaurar recorrido del Perímetro")
	await driver.frames(5)
	driver.bind_scene()
	main=driver.main
	driver.check(main.get_node("ZoneManager").states.size()==3 and main.get_node("ZoneManager").interactions.size()==4 and main.get_node("Radio").transmission==null,"Cuatro mundos y ninguna introducción repetida")
	await driver.interact(Vector2(1200,1370))
	if main.get_node("ZoneManager").busy:await main.get_node("ZoneManager").transition_finished
	await driver.frames(4)
	driver.check(main.get_node("ZoneManager").current_zone==ZoneCatalog.STATION,"E regresa del Perímetro a la Estación")
	# El driver continúa Estación → Mercado → Gualey y camina hasta la salida inicial.
