extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func run() -> void:
	var prefs:=root.get_node("AppPreferences")
	prefs.settings_path="user://tests/start-menu-preferences/preferences.cfg"
	if "--write" in OS.get_cmdline_user_args():
		prefs.reset_defaults()
		for pair in [["master",47],["effects",21],["ambience",0],["interface",65],["music",38]]:prefs.set_value(pair[0],pair[1])
		check(prefs.save_settings()==OK,"Guardar preferencias aisladas")
	else:
		check(prefs.load_settings()==OK,"Cargar preferencias en otro proceso")
		check(prefs.values.master==47 and prefs.values.effects==21 and prefs.values.ambience==0 and prefs.values.interface==65,"Los cuatro volúmenes persisten")
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")),"Ambiente silenciado al reabrir")
		check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")),linear_to_db(0.21)),"Ganancia real restaurada")
		check(prefs.values.music==38 and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),linear_to_db(0.38)),"Música persiste y restaura su bus real")
		var config:=ConfigFile.new()
		config.set_value("preferences","master",999)
		config.set_value("preferences","effects",-20)
		config.set_value("preferences","ambience","invalid")
		config.set_value("preferences","fullscreen","invalid")
		prefs.settings_path="user://tests/start-menu-preferences/invalid.cfg"
		check(config.save(prefs.settings_path)==OK and prefs.load_settings()==OK,"Lectura segura de valores ajenos a los rangos")
		check(prefs.values.master==100 and prefs.values.effects==0 and prefs.values.ambience==100 and not prefs.values.fullscreen,"Limitar valores; ignorar tipos inválidos")
		check(prefs.values.music==100,"Configuración anterior sin Música usa el valor predeterminado")
		if DisplayServer.get_name()=="headless":
			prefs.set_value("fullscreen",true)
			check(prefs.save_settings()==OK and prefs.load_settings()==OK and prefs.values.fullscreen,"Pantalla completa persiste como preferencia")
	print("Proceso preferencias PID=",OS.get_process_id())
	print("Resultado reapertura preferencias: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
