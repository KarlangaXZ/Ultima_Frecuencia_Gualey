extends Node
## Preferencias locales independientes de las partidas. No contiene estado de juego.
const DEFAULTS: Dictionary={"master":100.0,"effects":100.0,"ambience":100.0,"interface":100.0,"music":100.0,"fullscreen":false}
const BUSES: Dictionary={"master":"Master","effects":"Effects","ambience":"Ambience","interface":"Interface","music":"Music"}
var settings_path: String="user://settings.cfg"
var values: Dictionary=DEFAULTS.duplicate()
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for bus: String in ["Effects","Ambience","Interface","Music"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
			AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
	load_settings()
func load_settings() -> Error:
	values=DEFAULTS.duplicate()
	var config:=ConfigFile.new()
	var error:=config.load(settings_path)
	if error==OK:
		for key in DEFAULTS:
			var value: Variant=config.get_value("preferences",key,DEFAULTS[key])
			if key=="fullscreen":
				if value is bool:values[key]=value
			elif typeof(value) in [TYPE_FLOAT,TYPE_INT] and is_finite(float(value)):
				values[key]=clampf(float(value),0,100)
	apply()
	return OK if error==ERR_FILE_NOT_FOUND else error
func set_value(key: String,value: Variant) -> void:
	if key=="fullscreen" and value is bool:values[key]=value
	elif key in BUSES and typeof(value) in [TYPE_FLOAT,TYPE_INT] and is_finite(float(value)):
		values[key]=clampf(float(value),0,100)
	apply()
func apply() -> void:
	for key in BUSES:
		var index:=AudioServer.get_bus_index(BUSES[key])
		if index<0:continue
		var gain: float=values[key]/100.0
		AudioServer.set_bus_mute(index,gain<=0)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(gain,0.0001)))
	if DisplayServer.get_name()!="headless":
		var mode:=DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode()!=mode:DisplayServer.window_set_mode(mode)
func save_settings() -> Error:
	var directory:=ProjectSettings.globalize_path(settings_path.get_base_dir())
	var error:=DirAccess.make_dir_recursive_absolute(directory)
	if error!=OK:return error
	var config:=ConfigFile.new()
	for key in DEFAULTS:config.set_value("preferences",key,values[key])
	return config.save(settings_path)
func reset_defaults() -> void:
	values=DEFAULTS.duplicate()
	apply()
