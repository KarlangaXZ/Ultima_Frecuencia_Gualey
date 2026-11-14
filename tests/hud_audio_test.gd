extends SceneTree
## Eventos y regresión de presentación; --capture genera PNG y mezcla WAV real.
var checks := 0
var failures := 0
var recorder: AudioEffectRecord
var effect_index := -1

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func count(emitter: SoundEmitter, id: StringName) -> int:
	return emitter.played_counts.get(id, 0)

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/hud-audio")
	check(root.get_texture().get_image().save_png("res://test-results/hud-audio/" + label + ".png") == OK, "Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player")
	var ui := main.get_node("InventoryUI")
	var hud := main.get_node("HUD")
	var audio := main.get_node("Audio")
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var interaction := player.get_node("Interaction")
	var equipment := player.get_node("Equipment") as EquipmentComponent
	var actor_a := main.get_node("Zombies/ZombieA")
	var actor_b := main.get_node("Zombies/ZombieB")
	var actor_c := main.get_node("Zombies/ZombieC")
	for actor in [actor_a, actor_b, actor_c]:
		actor.set_physics_process(false)
		actor.get_node("Audio").groans_enabled = false
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		recorder = AudioEffectRecord.new()
		recorder.format = AudioStreamWAV.FORMAT_16_BITS
		effect_index = AudioServer.get_bus_effect_count(0)
		AudioServer.add_bus_effect(0, recorder)
		recorder.set_recording_active(true)
	var panel := hud.get_node("Panel") as Control
	check(panel.size.x <= 260 and panel.size.y <= 185, "HUD compacto, máximo 260 × 185")
	check(panel.size.x * panel.size.y < 330 * 365 * 0.4, "Menos de 40% del área anterior")
	print("HUD medido: ", panel.size, "; referencia anterior 330 × 365")
	check(not hud.get_node("Panel/Margin/Content/Text").is_visible_in_tree(), "Título fuera del HUD persistente")
	for path in ["HealthBar", "HealthValue", "Ammo", "WeaponRow", "Arsenal", "Stats", "Needs"]:
		check(hud.get_node("Panel/Margin/Content/" + path).is_visible_in_tree(), "Dato visible: " + path)
	check(ui.content.get_node("Header/Title").text == "MOCHILA", "Inventario sin branding repetido")
	check(ProjectSettings.get_setting("application/config/name") == "Última Frecuencia: Gualey", "Nombre oficial conserva branding general")
	await capture("01-compact-hud")
	var bank := audio.ui.bank as AudioCatalog
	check(bank.sounds.size() == 20, "Diecinueve efectos y un ambiente")
	for id in bank.sounds:
		var stream := bank.sounds[id] as AudioStreamWAV
		check(stream != null and stream.mix_rate == 22050 and not stream.stereo and stream.data.size() > 0, "WAV válido: " + String(id))
		check(stream.get_length() > 0 and stream.get_length() <= (8.1 if id == &"ambience" else 0.71), "Duración acotada: " + String(id))
	check(audio.ambience.stream != bank.sounds[&"ambience"] and audio.ambience.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"Ambiente en copia con loop sin modificar banco")
	check(audio.ambience.stream.loop_end == 176400 and audio.ambience.volume_db == -30, "Loop de ocho segundos y volumen sutil")
	audio.set_ambience_paused(true)
	check(audio.ambience_paused and (DisplayServer.get_name() == "headless" or audio.ambience.stream_paused), "Ambiente pausable")
	audio.set_ambience_volume(-35)
	check(audio.ambience.volume_db == -35, "Volumen ambiental ajustable")
	audio.set_ambience_volume(-30)
	audio.set_ambience_paused(false)
	ui.open_inventory()
	ui.open_inventory()
	check(count(audio.ui, &"inventory_open") == 1, "Abrir inventario no duplica notificación repetida")
	ui._select(0)
	check(count(audio.ui, &"ui_select") == 1, "Selección reproduce un clic")
	await capture("02-inventory")
	ui.close_window()
	ui.close_window()
	check(count(audio.ui, &"inventory_close") == 1, "Cerrar una sola vez")
	var crate := main.get_node("World/Supplies/SupplyCrate") as LootContainer
	player.position = crate.position - Vector2(0, 35)
	await frames(2)
	interaction.try_interact()
	check(ui.container == crate and count(audio.ui, &"container_open") == 1 and count(audio.ui, &"inventory_open") == 1,
		"Abrir contenedor emite solo su sonido, sin apertura doble")
	check(interaction.transfer_from_container(crate, 0) and count(audio.ui, &"pickup_ammo") == 1, "Transferir munición reproduce un sonido")
	check(interaction.transfer_from_container(crate, 1) and count(audio.ui, &"pickup_supply") == 1, "Transferir comida reproduce recogida")
	check(not interaction.transfer_from_container(crate, 0) and count(audio.ui, &"invalid") == 1, "Acción inválida suave")
	ui.close_window()
	player.position = Vector2(560, 805)
	await frames(2)
	interaction.try_interact()
	interaction.try_interact()
	check(count(audio.ui, &"pickup_supply") == 2 and inventory.count_item(&"water") == 2, "Recogida real una vez, sin duplicación sonora")
	player.get_node("SurvivalComponent").restore_need("hunger", 100)
	# Agua sí produce beneficio por el descenso real transcurrido desde el arranque.
	var water_slot := -1
	for index in range(12):
		var slot := inventory.get_slot(index)
		if not slot.is_empty() and slot.item.id == &"water": water_slot = index
	check(player.get_node("ItemUse").use_slot(water_slot) and count(audio.ui, &"item_use") == 1, "Consumo válido reproduce un sonido")
	var pistol := player.get_node("Weapon")
	player.position = Vector2(600, 800)
	check(pistol.try_fire(player.position, Vector2.UP) and count(audio.combat, &"pistol_shot") == 1, "Disparo válido de pistola")
	check(not pistol.try_fire(player.position, Vector2.UP) and count(audio.combat, &"pistol_shot") == 1, "Cooldown no produce disparos sonoros falsos")
	check(pistol.start_reload() and count(audio.combat, &"reload") == 1, "Una recarga, un sonido inicial")
	check(not pistol.start_reload() and count(audio.combat, &"reload") == 1, "Reintento de recarga no duplica")
	await frames(2)
	check(panel.size.x <= 260 and panel.size.y <= 205 and hud.get_node("Panel/Margin/Content/Reload").visible,
		"Recarga visible sin recuperar el bloque grande del HUD")
	ui.open_inventory()
	Input.action_press("shoot")
	Input.action_press("reload")
	await frames(100)
	Input.action_release("reload")
	check(pistol.loaded == 12 and count(audio.combat, &"pistol_shot") == 1 and count(audio.combat, &"reload") == 1,
		"Inventario no inicia combate ni audio; recarga previa termina silenciosamente")
	ui.close_window()
	await frames(20)
	check(count(audio.combat, &"pistol_shot") == 1, "Cerrar con clic sostenido no emite disparo")
	Input.action_release("shoot")
	await frames(2)
	# Las otras armas reutilizan los eventos del arsenal, no los ocho impactos.
	check(equipment.obtain(preload("res://resources/weapons/Revolver.tres")), "Preparar revólver poseído")
	equipment.switch_to(&"revolver")
	var revolver := equipment.active_weapon
	for index in range(20): revolver.try_fire(player.position, Vector2.UP)
	check(count(audio.combat, &"dry_fire") == 1 and revolver.cooldown == 0, "Clic vacío limitado solo en presentación, sin tocar cooldown")
	await frames(20)
	revolver.try_fire(player.position, Vector2.UP)
	check(count(audio.combat, &"dry_fire") == 2, "Clic vacío vuelve tras su intervalo sonoro")
	revolver.add_reserve(6)
	revolver.start_reload()
	await frames(128)
	check(revolver.try_fire(player.position, Vector2.UP) and count(audio.combat, &"revolver_shot") == 1, "Revólver con su efecto propio")
	equipment.obtain(preload("res://resources/weapons/Shotgun.tres"))
	equipment.switch_to(&"shotgun")
	var shotgun := equipment.active_weapon
	shotgun.add_reserve(6)
	shotgun.start_reload()
	await frames(146)
	check(shotgun.try_fire(player.position, Vector2.RIGHT) and player.get_node("SpreadCombat").endpoints.size() == 8,
		"Descarga física de ocho rayos")
	check(count(audio.combat, &"shotgun_shot") == 1, "Escopeta emite un disparo, no ocho sonidos")
	equipment.switch_to(&"machete")
	actor_a.position = player.position + Vector2(40, 0)
	await frames(2)
	var machete := equipment.active_weapon
	check(machete.try_fire(player.position, Vector2.RIGHT) and count(audio.combat, &"machete_swing") == 1
		and count(audio.combat, &"machete_hit") == 1, "Machete: movimiento e impacto solo si golpea")
	check(count(audio.combat, &"pistol_shot") == 1, "Machete no reproduce arma de fuego")
	var zombie_audio := actor_a.get_node("Audio")
	check(count(zombie_audio.emitter, &"zombie_hurt") == 1, "Daño válido de zombi reproduce reacción")
	for index in range(10): actor_a.health.take_damage(1)
	check(count(zombie_audio.emitter, &"zombie_hurt") == 1, "Daños simultáneos no apilan gemidos")
	await frames(8)
	actor_a.health.take_damage(1)
	check(count(zombie_audio.emitter, &"zombie_hurt") == 2, "Nuevo daño tras intervalo sonoro")
	actor_a.health.take_damage(100)
	actor_a.health.take_damage(100)
	check(count(zombie_audio.emitter, &"zombie_death") == 1 and count(zombie_audio.emitter, &"zombie_hurt") == 2,
		"Daño letal emite muerte una vez, sin duplicar herida")
	await frames(40)
	machete.try_fire(player.position, Vector2.LEFT)
	check(count(audio.combat, &"machete_swing") == 2 and count(audio.combat, &"machete_hit") == 1, "Golpe al aire sin impacto ficticio")
	actor_b.get_node("Audio").groans_enabled = true
	actor_b.get_node("Audio")._groan_remaining = 0
	await frames(2)
	check(count(actor_b.get_node("Audio").emitter, &"zombie_groan") == 1, "Gemido ambiental de zombi")
	actor_c.position = player.position + Vector2(0, 34)
	actor_c.cooldown = 0
	actor_c.set_physics_process(true)
	await frames(2)
	check(count(actor_c.get_node("Audio").emitter, &"zombie_attack") == 1 and player.health.current_health == 90,
		"Sonido de ataque corresponde al cooldown y daño reales")
	await frames(20)
	check(count(actor_c.get_node("Audio").emitter, &"zombie_attack") == 1, "Sin sonidos de ataque entre cooldowns")
	actor_c.set_physics_process(false)
	# Pool y mute son independientes de las cantidades y de los sistemas de juego.
	var probe := SoundEmitter.new()
	probe.volume_db = -60
	probe.max_voices = 2
	main.add_child(probe)
	var nodes := probe.get_child_count()
	for index in range(100): probe.play_event(&"ui_select")
	check(probe.get_child_count() == nodes and nodes == 2, "Cien eventos no crean nodos nuevos")
	probe.enabled = false
	check(not probe.play_event(&"pistol_shot") and not probe.play_event(&"unknown"), "Mute y clave desconocida no reproducen")
	probe.queue_free()
	await frames(5)
	if recorder != null:
		recorder.set_recording_active(false)
		var recording: AudioStreamWAV = recorder.get_recording()
		check(recording != null and recording.get_length() > 0.2, "Mezcla real del bus Master capturada")
		var has_signal := false
		for byte in recording.data:
			if byte != 0:
				has_signal = true
				break
		check(has_signal, "La mezcla contiene muestras no nulas, no solo eventos")
		DirAccess.make_dir_recursive_absolute("res://test-results/hud-audio")
		check(recording.save_to_wav("res://test-results/hud-audio/mix.wav") == OK, "WAV de mezcla guardado")
		AudioServer.remove_bus_effect(0, effect_index)
	var old_audio: WeakRef = weakref(audio)
	player.health.take_damage(1000)
	var before: int = count(audio.combat, &"machete_swing")
	check(not machete.try_fire(player.position, Vector2.UP) and count(audio.combat, &"machete_swing") == before,
		"Game Over bloquea audio de combate igual que el ataque")
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	check(old_audio.get_ref() == null and current_scene.get_node("Audio") != null, "Reintentar libera audio anterior sin duplicar ambiente")
	check(current_scene.get_node("Audio").ui.played_counts.is_empty(), "Reinicio limpia estado de presentación")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado HUD/audio: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
