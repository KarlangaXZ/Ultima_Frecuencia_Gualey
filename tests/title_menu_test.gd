extends SceneTree
var checks:=0
var failures:=0
var directory: String
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func frames(n:=3) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/start-menu")
	check(root.get_texture().get_image().save_png("res://test-results/start-menu/"+label+".png")==OK,"Captura "+label)
func click(control: Control) -> void:
	if DisplayServer.get_name()=="headless":
		control.pressed.emit()
		await frames(1)
		return
	var position:=control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=position
		event.global_position=position
		event.pressed=pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(1)
func run() -> void:
	directory="user://tests/start-menu-%d-%d"%[OS.get_process_id(),int(Time.get_unix_time_from_system()*1000000)]
	var prefs:=root.get_node("AppPreferences")
	var prefs_path: String=prefs.settings_path
	var previous: Dictionary=prefs.values.duplicate()
	prefs.settings_path=directory.path_join("preferences.cfg")
	prefs.load_settings()
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/TitleMenu.tscn","F5 inicia en la presentación")
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	await frames()
	var menu:=current_scene
	menu.store.directory=directory
	check(menu.page=="home" and menu.pages.home.visible,"Portada inicial")
	check(root.find_children("*","NavigationRegion2D",true,false).is_empty() and root.find_children("Player","CharacterBody2D",true,false).is_empty(),"Menú sin mundo/jugador/IA activos")
	await capture("01-title")
	await click(menu.start_button)
	check(menu.page=="slots" and menu.slot_rows.size()==3,"Empezar muestra tres ranuras")
	for row in menu.slot_rows:check(row["continue"].disabled,"Ranura vacía no permite continuar")
	menu.show_page("settings")
	menu.sliders.master.value=35
	menu.sliders.effects.value=0
	menu.sliders.ambience.value=70
	menu.sliders.interface.value=55
	check(prefs.values.master==35 and prefs.values.effects==0 and prefs.values.ambience==70 and prefs.values.interface==55,"Cada slider actualiza su canal correcto")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"Cero silencia efectos")
	check(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(0.35)),"Volumen general aplicado a Master")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Interface")),"Silenciar efectos no silencia interfaz")
	await capture("02-settings")
	menu.fullscreen.button_pressed=true
	await frames(2)
	check(prefs.values.fullscreen and (DisplayServer.get_name()=="headless" or DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN),"Selector activa pantalla completa")
	menu.fullscreen.button_pressed=false
	await frames(2)
	check(not prefs.values.fullscreen and (DisplayServer.get_name()=="headless" or DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_WINDOWED),"Selector restaura modo ventana")
	menu._save_settings()
	check(menu.page=="home" and FileAccess.file_exists(prefs.settings_path),"Guardar configuración vuelve al inicio")
	prefs.values.master=100
	check(prefs.load_settings()==OK and prefs.values.master==35 and prefs.values.effects==0,"Preferencias vuelven desde archivo independiente")
	check(not FileAccess.file_exists(directory.path_join("slot_1.json")),"Configuración no crea ni reemplaza partidas")
	# Datos de prueba existentes y válidos, sin escribir ranuras normales.
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main:=current_scene
	await preload("res://tests/save_fixture.gd").build(self,main)
	var saves:=main.get_node("SaveCoordinator")
	saves.store.directory=directory
	check(saves.save_slot(1,true).has("ok"),"Preparar partida rica de prueba")
	var expected: Dictionary=JSON.parse_string(JSON.stringify(saves.capture(1),"",true,true))
	var original_bytes:=FileAccess.get_file_as_string(saves.store.path_for(1))
	var broken:=FileAccess.open(saves.store.path_for(2),FileAccess.WRITE)
	broken.store_string("{truncated")
	broken.close()
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	paused=false
	await frames()
	menu=current_scene
	menu.store.directory=directory
	menu.show_page("slots")
	check(not menu.slot_rows[0]["continue"].disabled and menu.slot_rows[1]["continue"].disabled and menu.slot_rows[2]["continue"].disabled,"Continúa únicamente guardados válidos")
	check(menu.slot_rows[0].label.text.contains("NIVEL") and menu.slot_rows[1].label.text.contains("NO DISPONIBLE"),"Información de ranura y aviso de corrupción")
	await capture("03-slots")
	menu.request_new(1)
	check(menu.confirm.visible and current_scene==menu and FileAccess.get_file_as_string(menu.store.path_for(1))==original_bytes,"Reemplazar ranura exige confirmación y no escribe todavía")
	menu.confirm.get_cancel_button().pressed.emit()
	await frames()
	check(menu.pending_slot==-1 and FileAccess.get_file_as_string(menu.store.path_for(1))==original_bytes,"Cancelar conserva los bytes de la partida")
	# Un JSON válido con enemigo en sólido debe fallar sin retirar la presentación.
	var bad:=expected.duplicate(true)
	bad.slot=2
	for zombie in bad.world.zombies:
		if zombie.health>0:zombie.position=[410,220];break
	check(menu.store.write_slot(2,bad,true).has("ok"),"Preparar geometría inválida con formato válido")
	menu.refresh_slots()
	menu.slot_rows[1]["continue"].pressed.emit()
	await frames(5)
	check(current_scene==menu and not menu.busy and menu.status.text.contains("obstáculo"),"Fallo geométrico de carga mantiene menú utilizable")
	check(root.find_children("*","NavigationRegion2D",true,false).is_empty(),"Fallo libera escena de preparación sin región huérfana")
	menu.slot_rows[0]["continue"].pressed.emit()
	main=current_scene
	check(main.scene_file_path=="res://scenes/Main.tscn" and main.get_node("SaveCoordinator").active_slot==1,"Continuar carga la ranura elegida")
	if main.scene_file_path!="res://scenes/Main.tscn":quit(1);return
	var loaded: Dictionary=JSON.parse_string(JSON.stringify(main.get_node("SaveCoordinator").capture(1),"",true,true))
	for key in ["world","zones","missions","story","stats"]:check(loaded[key]==expected[key],"Continuar conserva "+key)
	check(loaded.player.health==expected.player.health and loaded.player.weapons==expected.player.weapons and loaded.player.inventory==expected.player.inventory and loaded.player.progression==expected.player.progression,"Salud, arsenal, munición, mochila y RPG restaurados")
	check(main.get_node("Player")._require_shoot_release,"Clic de continuar no dispara accidentalmente")
	check(main.get_node("Audio/UI")._players[0].bus==&"Interface" and main.get_node("Audio/Combat")._players[0].bus==&"Effects" and main.get_node("Audio/Ambience").bus==&"Ambience","Pools de audio usan canales configurables")
	await frames(5)
	check(root.find_children("TitleMenu","CanvasLayer",true,false).is_empty() and root.find_children("*","NavigationRegion2D",true,false).size()==1,"Un mundo, menú retirado tras éxito")
	check(FileAccess.get_file_as_string(main.get_node("SaveCoordinator").store.path_for(1))==original_bytes,"Continuar no reescribe el guardado")
	var pause_ui:=main.get_node("PauseUI")
	pause_ui.open_panel()
	check(paused and pause_ui.rows[0].label.text.contains("EN USO"),"Pausa reconoce ranura activa")
	pause_ui._request_home()
	var dialogs: Array=pause_ui.window.find_children("*","ConfirmationDialog",true,false)
	check(dialogs.size()==1 and paused,"Volver al inicio pide confirmar sin reanudar mundo")
	dialogs[0].get_ok_button().pressed.emit()
	await frames(6)
	menu=current_scene
	check(menu.name=="TitleMenu" and not paused and root.find_children("*","NavigationRegion2D",true,false).is_empty(),"Regresa al inicio sin mundo procesando ni pausa residual")
	menu.store.directory=directory
	menu.show_page("slots")
	menu.slot_rows[2]["new"].pressed.emit()
	for i in range(30):
		await frames(1)
		if current_scene.scene_file_path=="res://scenes/Main.tscn":break
	main=current_scene
	check(main.scene_file_path=="res://scenes/Main.tscn" and main.get_node("SaveCoordinator").active_slot==3,"Nueva partida inicia en ranura vacía seleccionada")
	check(main.get_node("SaveCoordinator").store.read_slot(3).has("data") and main.get_node("Population").active_enemies().size()==6,"Partida nueva guardada e inicializada con seis enemigos")
	check(main.get_node("Player/HealthComponent").current_health==100 and main.get_node("Missions").started_chapters==[ChapterCatalog.FIRST],"Nueva partida conserva inicio de gameplay")
	check(FileAccess.get_file_as_string(main.get_node("SaveCoordinator").store.path_for(1))==original_bytes,"Crear en ranura 3 no toca ranura 1")
	check(main.get_node("HUD").visible and not main.get_node("PauseUI").window.visible and not paused,"Juego visible y controles disponibles")
	await capture("04-new-game-palette")
	main.get_node("Player/HealthComponent").take_damage(1000)
	main.get_node("HUD/GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(8)
	check(current_scene.get_node("SaveCoordinator").active_slot==3,"Reintentar conserva la selección de ranura de esta sesión")
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	await frames()
	menu=current_scene
	menu.store.directory=directory
	menu.show_page("slots")
	menu.request_new(1)
	menu.confirm.get_ok_button().pressed.emit()
	for i in range(30):
		await frames(1)
		if current_scene.scene_file_path=="res://scenes/Main.tscn":break
	main=current_scene
	check(main.scene_file_path=="res://scenes/Main.tscn" and main.get_node("SaveCoordinator").active_slot==1,"Confirmar permite empezar de nuevo en ranura ocupada")
	check(FileAccess.get_file_as_string(directory.path_join("slot_1.json.bak"))==original_bytes,"Reemplazo conserva respaldo exacto de la partida anterior")
	check(main.get_node("SaveCoordinator").store.read_slot(3).has("data"),"Reemplazar ranura 1 conserva ranura 3")
	prefs.settings_path=prefs_path
	prefs.values=previous
	prefs.apply()
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado inicio/configuración: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
