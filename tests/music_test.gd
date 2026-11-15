extends SceneTree
## --capture usa el driver real y guarda audio del Master y Music, no eventos simulados.
var checks := 0
var failures := 0
var native := false
var recordings: Dictionary = {}
var directory: String
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func wait_seconds(seconds: float) -> void:
	if native:
		var deadline := Time.get_ticks_msec() + roundi(seconds*1000)
		while Time.get_ticks_msec() < deadline: await process_frame
	else:
		for i in range(ceili(seconds*60)): await process_frame
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func sample(label: String, bus: String, duration := 0.8) -> float:
	var index := AudioServer.get_bus_index(bus)
	var effect := AudioEffectRecord.new()
	AudioServer.add_bus_effect(index, effect)
	var position := AudioServer.get_bus_effect_count(index)-1
	effect.set_recording_active(true)
	var maximum_meter := -200.0
	var deadline := Time.get_ticks_msec() + roundi(duration*1000)
	while Time.get_ticks_msec() < deadline:
		await process_frame
		maximum_meter = maxf(maximum_meter, AudioServer.get_bus_peak_volume_left_db(index,0))
	effect.set_recording_active(false)
	var wav := effect.get_recording()
	AudioServer.remove_bus_effect(index, position)
	check(wav != null and wav.get_length() > duration*.6, "Duración real de " + label)
	var peak := 0.0
	var square := 0.0
	for i in range(0, wav.data.size(), 2):
		var value := absf(float(wav.data.decode_s16(i))/32768.0)
		peak = maxf(peak, value)
		square += value*value
	var rms := sqrt(square / (wav.data.size()/2))
	recordings[label] = {"peak":peak,"rms":rms,"seconds":wav.get_length(),"bus":bus,"output_peak_db":maximum_meter}
	check(wav.save_to_wav("res://test-results/phase-fifteen-one/"+label+".wav")==OK,"Guardar captura "+label)
	return rms
func silence_actors(main: Node) -> void:
	for zombie in main.get_node("Zombies").get_children():
		zombie.set_physics_process(false)
		zombie.get_node("Audio").groans_enabled = false
func run() -> void:
	native = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-fifteen-one")
	directory = "user://tests/music-%d-%d" % [OS.get_process_id(), int(Time.get_unix_time_from_system()*1000000)]
	var prefs := root.get_node("AppPreferences")
	var old_path: String = prefs.settings_path
	var old_values: Dictionary = prefs.values.duplicate()
	prefs.settings_path = directory.path_join("preferences.cfg")
	prefs.reset_defaults()
	var music := root.get_node("MusicDirector")
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("Music")) == &"Master", "Music independiente enviado a Master")
	for key in music.PATHS:
		var stream: AudioStreamWAV = music._streams[key]
		check(stream.stereo and stream.mix_rate==22050 and stream.format==AudioStreamWAV.FORMAT_16_BITS and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end==roundi(stream.get_length()*stream.mix_rate),"PCM estéreo y bucle completo: "+key)
	change_scene_to_file("res://scenes/TitleMenu.tscn")
	await frames(4)
	var menu := current_scene
	menu.store.directory = directory
	await wait_seconds(1.5)
	check(music.context=="menu" and music.requested=="menu" and music.get_child_count()==1,"Una voz musical en portada")
	if native:
		check(music.player.playing,"Reproducción nativa de menú")
		check(await sample("menu", "Master")>.001,"Señal musical real en Master")
	menu.show_page("settings")
	check(menu.sliders.has("music"),"Control Música disponible")
	menu.sliders.music.value = 50
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),linear_to_db(.5)),"Slider aplica ganancia musical real")
	if native:
		music.player.seek(4)
		await wait_seconds(.15)
		await sample("music-half", "Master")
		menu.sliders.music.value = 100
		music.player.seek(4)
		await wait_seconds(.15)
		await sample("music-full", "Master")
		var full_meter: float = recordings["music-full"].output_peak_db
		var ratio: float = recordings["music-half"].rms / recordings["music-full"].rms
		check(ratio>.42 and ratio<.58,"Muestras reales: 50% Música reduce amplitud a la mitad")
		prefs.set_value("master",50)
		music.player.seek(4)
		await wait_seconds(.15)
		await sample("master-half", "Master")
		# AudioEffectRecord es pre-fader en su propio bus: para Master usar medidor
		# de salida real, no confundir su WAV pre-fader con la ganancia final.
		var master_meter: float = recordings["master-half"].output_peak_db
		recordings["master-output"]={"full_db":full_meter,"half_db":master_meter}
		check(master_meter-full_meter < -4.5 and master_meter-full_meter > -7.5,"Medidor de salida: Master 50% reduce aproximadamente 6 dB")
		prefs.set_value("master",100)
	menu.sliders.music.value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Música 0% silencia su bus")
	if native:
		await wait_seconds(.15)
		check(await sample("music-muted", "Master")<.00001,"Silencio digital real con Música 0%")
	menu.sliders.music.value = 100
	menu.show_page("home")
	menu._launch(1,true,false)
	for i in range(90):
		await frames(1)
		if current_scene.scene_file_path=="res://scenes/Main.tscn": break
	check(current_scene.scene_file_path=="res://scenes/Main.tscn","Nueva partida desde portada")
	if current_scene.scene_file_path!="res://scenes/Main.tscn":
		push_error(menu.status.text)
		quit(1)
		return
	var main := current_scene
	silence_actors(main)
	await wait_seconds(1.5)
	check(music.context=="gameplay" and music.player.stream==music._streams.gameplay,"Partida usa composición diferente")
	var player_id: int = music.player.get_instance_id()
	var starts: int = music.starts
	var pause_ui := main.get_node("PauseUI")
	var position_before: float = music.player.get_playback_position()
	pause_ui.open_panel()
	await wait_seconds(.4)
	check(paused and is_equal_approx(music.duck_db,-6) and not music.player.stream_paused,"Pausa reduce nivel sin pausar música")
	if native: check(music.player.get_playback_position()>position_before,"La posición avanza durante pausa")
	pause_ui.close_window()
	await wait_seconds(.4)
	check(not paused and is_zero_approx(music.duck_db),"Reanudar recupera volumen")
	check(main.get_node("Radio").play(preload("res://resources/radio/FirstSignal.tres")),"Transmisión real abre radio")
	await wait_seconds(.4)
	check(main.get_node("RadioUI").window.visible and is_equal_approx(music.duck_db,-12),"Radio reduce música por señal de ventana")
	if native:
		main.get_node("Audio/UI").play_event(&"ui_select")
		check(await sample("radio-duck", "Master")>.0001,"Mezcla de radio real")
	while main.get_node("Radio").transmission != null: main.get_node("Radio").advance()
	await wait_seconds(.4)
	check(is_zero_approx(music.duck_db) and not main.get_node("RadioUI").window.visible,"Fin de radio restaura nivel")
	if native:
		check(await sample("gameplay", "Music")>.0001,"Señal real en bus Music")
		# Cruza el final de ambas pistas con el reproductor real, sin reiniciar.
		for key in ["gameplay","menu"]:
			music._start(key)
			music.envelope_db=0
			music.player.seek(music.player.stream.get_length()-.4)
			await sample("loop-"+key,"Music",1.0)
			check(music.player.playing and music.player.get_playback_position()<2,"Bucle nativo cruza final: "+key)
		music._start("gameplay")
		music.envelope_db=0
		starts=music.starts
		# Efectos reales existentes, simultáneos a música/ambiente. No nuevo daño.
		var effect := AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,effect)
		var effect_index := AudioServer.get_bus_effect_count(0)-1
		effect.set_recording_active(true)
		for event in [&"pistol_shot",&"revolver_shot",&"shotgun_shot",&"reload"]:
			main.get_node("Audio/Combat").play_event(event)
			main.get_node("Zombies").get_child(0).get_node("Audio").emitter.play_event(&"zombie_groan")
			await wait_seconds(.6)
		effect.set_recording_active(false)
		var mix := effect.get_recording()
		check(mix.save_to_wav("res://test-results/phase-fifteen-one/gameplay-mix.wav")==OK,"Captura de música, ambiente, armas y zombi")
		AudioServer.remove_bus_effect(0,effect_index)
	# Cargar desde gameplay tampoco reinicia el tema; el candidato no lo toma antes.
	var saves := main.get_node("SaveCoordinator")
	check(saves.load_slot(1).has("ok"),"Carga transaccional conserva música")
	main=current_scene
	silence_actors(main)
	await frames(3)
	check(music.starts==starts and music.player.get_instance_id()==player_id,"Cargar no reinicia ni duplica reproductor")
	var manager := main.get_node("ZoneManager")
	# Fixture: desbloqueo solo en memoria para probar el audio de los cuatro mapas.
	manager.unlocked.assign([ZoneCatalog.MARKET,ZoneCatalog.STATION,ZoneCatalog.PERIMETER])
	for destination in [ZoneCatalog.MARKET,ZoneCatalog.STATION,ZoneCatalog.PERIMETER,ZoneCatalog.STATION,ZoneCatalog.MARKET,ZoneCatalog.HOME]:
		var entry: String = manager.active_definition().connections[destination]
		check(manager.request_travel(destination,entry),"Viaje real a "+destination)
		await manager.transition_finished
		silence_actors(main)
		main.get_node("RadioUI").close_window()
		check(music.starts==starts and music.player.get_instance_id()==player_id and music.duck_target==0,"Viaje conserva música continua sin duplicación")
	# Volver al inicio mediante su confirmación existente.
	main.get_node("PauseUI").open_panel()
	main.get_node("PauseUI")._request_home()
	main.get_node("PauseUI").window.find_children("*","ConfirmationDialog",true,false)[0].get_ok_button().pressed.emit()
	await frames(5)
	await wait_seconds(1.5)
	check(current_scene.name=="TitleMenu" and music.context=="menu" and is_zero_approx(music.duck_db),"Volver al inicio cambia tema y elimina atenuación")
	check(root.find_children("Ambience","AudioStreamPlayer",true,false).is_empty(),"No quedan reproductores de la partida anterior")
	menu=current_scene
	menu.store.directory=directory
	menu._launch(1,false,false)
	await frames(5)
	await wait_seconds(1.5)
	check(current_scene.name=="Main" and music.context=="gameplay","Continuar ranura desde menú inicia tema correcto")
	# Interrupciones rápidas de fundidos: último contexto gana; recursos estables.
	var before_streams: Dictionary = music._streams.duplicate()
	for i in range(20):
		music.enter_menu(current_scene)
		music.enter_gameplay(current_scene)
	await wait_seconds(1.5)
	check(music.context=="gameplay" and music.get_child_count()==1 and music._streams==before_streams,"Cuarenta solicitudes no acumulan voces ni recursos")
	var stale := Node.new()
	root.add_child(stale)
	music.set_mix(stale,true,true)
	check(music.duck_target==0,"Escena ajena/candidato no cambia mezcla activa")
	stale.queue_free()
	prefs.settings_path=old_path
	prefs.values=old_values
	prefs.apply()
	if native:
		var file := FileAccess.open("res://test-results/phase-fifteen-one/audio-metrics.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(recordings,"\t"))
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado música: ",checks," comprobaciones, ",failures," fallos; captura nativa=",native)
	quit(0 if failures==0 else 1)
