extends SceneTree
var checks := 0
var failures := 0
var flashes := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	point = root.get_screen_transform() * point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func wheel() -> void:
	var point := Vector2(1100, 600)
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = root.get_screen_transform() * point
		event.button_index = MOUSE_BUTTON_WHEEL_DOWN
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func aim(player: CharacterBody2D, direction: Vector2) -> void:
	player.get_node("Camera2D").reset_smoothing()
	await frames(2)
	var point := root.get_canvas_transform() * (player.position + direction * 200)
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_screen_transform() * point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await frames(2)

func slot_for(inventory: InventoryComponent, id: StringName) -> int:
	for index in range(inventory.capacity):
		var slot := inventory.get_slot(index)
		if not slot.is_empty() and slot.item.id == id: return index
	return -1

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-six")
	check(root.get_texture().get_image().save_png("res://test-results/phase-six/" + label + ".png") == OK, "Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://tests/fixtures/LegacyMain.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var equipment := player.get_node("Equipment") as EquipmentComponent
	var pistol := player.get_node("Weapon")
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var item_user := player.get_node("ItemUse")
	var ui := main.get_node("InventoryUI")
	var hud := main.get_node("HUD")
	var combat := player.get_node("Combat")
	var melee := player.get_node("MeleeCombat")
	var sprite := player.get_node("Visual/Sprite") as AnimatedSprite2D
	var a := main.get_node("Zombies/ZombieA")
	var b := main.get_node("Zombies/ZombieB")
	var c := main.get_node("Zombies/ZombieC")
	for enemy in [a, b, c]: enemy.set_physics_process(false)
	combat.visual_shot.connect(func(_o, _e, _k): flashes += 1)
	check(equipment.active_weapon == pistol and player.weapon == pistol, "Pistola inicial sigue siendo Player/Weapon")
	check(pistol.loaded == 12 and pistol.reserve == 48 and pistol.config.damage == 25 and pistol.config.fire_interval == 0.3, "Configuración original intacta")
	check(equipment.owns(&"machete") and not equipment.owns(&"revolver") and not equipment.owns(&"shotgun"), "Solo machete y pistola iniciales")
	check(not equipment.switch_to(&"revolver") and not equipment.switch_to(&"shotgun") and not equipment.switch_to(&"unknown"), "Armas no obtenidas no seleccionables")
	check(inventory.capacity == 12 and inventory.occupied_slots() == 0, "Mismo inventario vacío de doce espacios")
	for source in main.get_node("World/ArsenalSupplies").get_children():
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = source.get_node("CollisionShape2D").shape
		query.transform = source.global_transform
		query.collision_mask = 1
		check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Contenedor de arsenal fuera de sólidos: " + source.name)
	check(hud.get_node("Panel/Margin/Content/WeaponRow/Name").text == "Pistola básica", "HUD inicial identifica pistola")
	await capture("01-initial")
	await key(KEY_1)
	var machete := equipment.active_weapon
	check(machete.config.id == &"machete" and machete.config.damage == 30 and machete.config.shot_range == 55 and machete.config.fire_interval == 0.65, "Tecla 1 y configuración de machete")
	check(machete.loaded == 0 and machete.reserve == 0 and not machete.start_reload() and not machete.add_reserve(1), "Machete no utiliza munición")
	check(hud.get_node("Panel/Margin/Content/Ammo").text == "CUERPO A CUERPO", "HUD cuerpo a cuerpo")
	player.position = Vector2(1200, 800)
	a.position = Vector2(1240, 800)
	b.position = Vector2(1256, 800)
	c.position = Vector2(1160, 800)
	# Dos formas del mismo enemigo no permiten dos impactos en el mismo ataque.
	var extra_shape := CollisionShape2D.new()
	extra_shape.shape = a.get_node("CollisionShape2D").shape.duplicate()
	a.add_child(extra_shape)
	await frames(2)
	await aim(player, Vector2.RIGHT)
	check(machete.try_fire(player.position, Vector2.RIGHT), "Ataque frontal válido")
	check(a.health.current_health == 20 and melee.hit_count == 1, "Un impacto de 30 por enemigo, incluso con dos formas")
	check(b.health.current_health == 50 and c.health.current_health == 50, "Fuera de alcance y detrás no reciben daño")
	check(flashes == 0 and not player.get_node("Visual").shooting_visual, "Machete sin Shoot ni destellos de arma de fuego")
	check(not machete.try_fire(player.position, Vector2.RIGHT), "Intervalo de machete impide repetición inmediata")
	await capture("02-machete")
	await key(KEY_2)
	await key(KEY_1)
	check(not machete.try_fire(player.position, Vector2.RIGHT), "Cambiar ida/vuelta no reinicia cooldown")
	check(pistol.loaded == 12 and pistol.reserve == 48, "Machete y cambios no gastan pistola")
	await frames(40)
	# Poste real de 12 px entre dos cuerpos válidos, ambos dentro de 55 px.
	player.position = Vector2(1004, 350)
	a.position = Vector2(1055, 350)
	await frames(2)
	check(machete.try_fire(player.position, Vector2.RIGHT) and a.health.current_health == 20 and melee.hit_count == 0, "Poste World bloquea machete a corta distancia")
	await frames(40)
	player.position = Vector2(1200, 800)
	a.position = Vector2(1240, 800)
	b.position = Vector2(1255, 800)
	await frames(2)
	check(machete.try_fire(player.position, Vector2.RIGHT) and b.health.current_health == 20, "Límite inclusivo de 55 px")
	check(a.health.is_dead() and main.kills == 1 and melee.hit_count == 2, "Varios enemigos frontales y una sola baja por muerte")
	await frames(30)
	check(a.get_node("Visual/Sprite").frame == 5 and a.collision_layer == 0, "Death de zombi y desactivación conservadas")
	# Restablecer escena para probar adquisición y armas de fuego sobre enemigos vivos.
	reload_current_scene()
	await frames(5)
	main = current_scene
	player = main.get_node("Player")
	equipment = player.get_node("Equipment")
	pistol = player.get_node("Weapon")
	inventory = player.get_node("InventoryComponent")
	item_user = player.get_node("ItemUse")
	ui = main.get_node("InventoryUI")
	hud = main.get_node("HUD")
	combat = player.get_node("Combat")
	sprite = player.get_node("Visual/Sprite")
	a = main.get_node("Zombies/ZombieA")
	b = main.get_node("Zombies/ZombieB")
	c = main.get_node("Zombies/ZombieC")
	for enemy in [a, b, c]: enemy.set_physics_process(false)
	flashes = 0
	combat.visual_shot.connect(func(_o, _e, _k): flashes += 1)
	var r_ammo := load("res://resources/items/RevolverAmmo.tres") as ItemDefinition
	inventory.add_item(r_ammo, 4)
	check(not item_user.use_slot(0) and inventory.count_item(r_ammo.id) == 4 and pistol.reserve == 48, "Sin revólver no consumir ni desviar su munición")
	var interaction := player.get_node("Interaction")
	var r_case := main.get_node("World/ArsenalSupplies/RevolverCase") as LootContainer
	player.position = r_case.position - Vector2(0, 35)
	await frames(2)
	await key(KEY_E)
	check(ui.container == r_case and ui.window.visible, "E abre contenedor reutilizado de revólver")
	check(interaction.transfer_from_container(r_case, 0) and interaction.transfer_from_container(r_case, 1), "Arma y munición pasan por inventario")
	check(not equipment.owns(&"revolver") and r_case.inventory.occupied_slots() == 0, "No se equipa al recoger; contenedor finito")
	ui._select(slot_for(inventory, &"weapon_revolver"))
	check(ui.content.get_node("Body/Details/Use").text == "INCORPORAR AL ARSENAL", "UI distingue incorporación de arma")
	await capture("03-acquisition")
	check(not interaction.transfer_from_container(r_case, 0), "No duplicar arma desde contenedor vacío")
	await click(ui.content.get_node("Body/Details/Use"))
	var revolver := equipment.get_weapon(&"revolver")
	check(equipment.owns(&"revolver") and inventory.count_item(&"weapon_revolver") == 0 and revolver.loaded == 0 and revolver.reserve == 0, "Incorporación consume arma, sin balas gratuitas")
	check(item_user.use_slot(slot_for(inventory, r_ammo.id)) and revolver.reserve == 16 and pistol.reserve == 48, "Reserva de revólver separada")
	inventory.add_item(load("res://resources/items/Revolver.tres"), 1)
	check(not item_user.use_slot(slot_for(inventory, &"weapon_revolver")) and not equipment.obtain(revolver.config), "No incorporar una segunda instancia de arma poseída")
	check(inventory.count_item(&"weapon_revolver") == 1, "Rechazo de duplicado conserva objeto")
	await key(KEY_TAB)
	await key(KEY_3)
	check(player.weapon == revolver and revolver.config.capacity == 6 and revolver.config.fire_interval == 0.55 and revolver.config.reload_duration == 2.1, "Tecla 3 y configuración revólver")
	check(not revolver.try_fire(player.position, Vector2.RIGHT) and revolver.start_reload(), "Revólver vacío requiere recarga")
	await frames(120)
	check(revolver.reloading and revolver.loaded == 0, "No completar antes de 2.1 segundos")
	await frames(8)
	check(revolver.loaded == 6 and revolver.reserve == 10, "Recarga de seis balas desde reserva propia")
	player.position = Vector2(1200, 800)
	a.position = Vector2(1240, 800)
	b.position = Vector2(1700, 800)
	c.position = Vector2(2000, 800)
	player.get_node("Camera2D").reset_smoothing()
	await frames(2)
	await aim(player, Vector2.RIGHT)
	check(revolver.try_fire(player.position, Vector2.RIGHT) and a.health.current_health == 5, "Revólver aplica 45 HP reales")
	check(sprite.animation == &"shoot_right" and player.get_node("Visual").weapon == revolver, "Shoot existente observa arma activa")
	check(not revolver.try_fire(player.position, Vector2.RIGHT) and revolver.loaded == 5, "Cadencia evita duplicar disparos")
	await capture("04-revolver")
	await frames(35)
	check(revolver.try_fire(player.position, Vector2.RIGHT) and a.health.is_dead() and main.kills == 1, "Segundo tiro válido y conteo de baja")
	check(flashes == 2, "Un destello por disparo de revólver")
	check(revolver.start_reload(), "Recarga parcial iniciada")
	await frames(30)
	await key(KEY_2)
	check(not revolver.reloading and revolver.loaded == 4 and revolver.reserve == 10, "Cambiar cancela recarga sin transferencia")
	await frames(140)
	check(revolver.loaded == 4 and revolver.reserve == 10 and not pistol.reloading, "No existe recarga fantasma en segundo plano")
	check(not revolver.try_fire(player.position, Vector2.RIGHT), "Arma inactiva no puede disparar directamente")
	await key(KEY_3)
	check(revolver.start_reload(), "Se puede volver a recargar al seleccionar")
	await frames(128)
	check(revolver.loaded == 6 and revolver.reserve == 8, "Total de balas conservado tras cambiar y recargar")
	var s_case := main.get_node("World/ArsenalSupplies/ShotgunCase") as LootContainer
	player.position = s_case.position - Vector2(0, 35)
	await frames(2)
	await key(KEY_E)
	check(ui.container == s_case and interaction.transfer_from_container(s_case, 0) and interaction.transfer_from_container(s_case, 1), "Punto de suministro entrega escopeta y cartuchos")
	check(not item_user.use_slot(slot_for(inventory, &"shotgun_ammo")), "No gastar cartuchos sin escopeta")
	check(item_user.use_slot(slot_for(inventory, &"weapon_shotgun")) and equipment.owns(&"shotgun"), "Escopeta incorporada desde inventario")
	check(item_user.use_slot(slot_for(inventory, &"shotgun_ammo")), "Cartuchos transferidos al arma correcta")
	await key(KEY_TAB)
	await key(KEY_4)
	var shotgun := equipment.active_weapon
	check(shotgun.config.id == &"shotgun" and shotgun.reserve == 8 and shotgun.loaded == 0, "Tecla 4 y reserva independiente")
	check(shotgun.config.pellet_count == 8 and shotgun.config.damage == 8 and shotgun.config.fire_interval == 0.9 and shotgun.config.reload_duration == 2.4, "Configuración de escopeta")
	check(shotgun.start_reload(), "Recarga de escopeta iniciada")
	await frames(140)
	check(shotgun.reloading and shotgun.loaded == 0, "No recargar antes de 2.4 segundos")
	await frames(6)
	check(shotgun.loaded == 6 and shotgun.reserve == 2, "Escopeta carga seis cartuchos")
	# Nueva instancia de objetivo, ya que a murió por revólver. Solo fixture de daño.
	var target := load("res://scenes/enemies/Zombie.tscn").instantiate() as CharacterBody2D
	main.get_node("Zombies").add_child(target)
	target.set_physics_process(false)
	target.eliminated.connect(main._on_eliminated)
	target.health.max_health = 500
	target.health.current_health = 500
	player.position = Vector2(1200, 800)
	target.position = Vector2(1240, 800)
	player.get_node("Camera2D").reset_smoothing()
	await frames(2)
	flashes = 0
	check(shotgun.try_fire(player.position, Vector2.RIGHT), "Descarga válida de escopeta")
	check(player.get_node("SpreadCombat").endpoints.size() == 8 and shotgun.loaded == 5, "Ocho trazas consumen un cartucho")
	check(target.health.current_health == 436, "Ocho impactos de 8 HP a corta distancia")
	check(flashes == 1 and sprite.animation == &"shoot_right", "Un solo destello y Shoot existente para toda la descarga")
	check(not shotgun.try_fire(player.position, Vector2.RIGHT), "Cadencia de escopeta rechaza repetición")
	await frames(56)
	player.position = Vector2(600, 800)
	target.position = Vector2(1000, 800)
	await frames(2)
	await aim(player, Vector2.RIGHT)
	flashes = 0
	check(shotgun.try_fire(player.position, Vector2.RIGHT), "Descarga contra caja World")
	check(target.health.current_health == 436 and flashes == 1, "Los ocho perdigones son bloqueados sin daño detrás")
	for endpoint in player.get_node("SpreadCombat").endpoints:
		check(absf(endpoint.x - 736) < 0.1, "Impacto en cara física de CrateA")
	await capture("05-shotgun")
	await frames(56)
	player.position = Vector2(1200, 1200)
	target.position = Vector2(1580, 1200)
	await frames(2)
	await aim(player, Vector2.RIGHT)
	check(shotgun.try_fire(player.position, Vector2.RIGHT) and target.health.current_health == 436, "Alcance limitado: objetivo a 380 px no recibe daño")
	for endpoint in player.get_node("SpreadCombat").endpoints:
		check(absf(endpoint.distance_to(player.position) - shotgun.config.shot_range) < 0.1, "Alcance físico por perdigón")
	check(pistol.loaded == 12 and pistol.reserve == 48 and revolver.loaded == 6 and revolver.reserve == 8, "Ninguna descarga consume otros tipos de balas")
	check(hud.get_node("Panel/Margin/Content/WeaponRow/Name").text == "Escopeta" and not hud.get_node("Panel/Margin/Content/Arsenal").text.contains("—"), "HUD activo e indicadores de propiedad")
	await capture("06-arsenal")
	await frames(56)
	player.position = Vector2(1200, 800)
	target.position = Vector2(1240, 800)
	target.health.current_health = 50
	await frames(2)
	check(shotgun.try_fire(player.position, Vector2.RIGHT) and target.health.is_dead() and main.kills == 2, "Descarga letal emite una sola baja aunque sobren perdigones")
	await frames(30)
	check(target.get_node("Visual/Sprite").frame == 5 and target.collision_layer == 0, "Death y desactivación también con escopeta")
	await wheel()
	check(equipment.active_weapon.config.id == &"machete", "Rueda recorre armas disponibles y vuelve al inicio")
	await key(KEY_4)
	ui.open_inventory()
	var loaded_before: int = shotgun.loaded
	await key(KEY_1)
	await wheel()
	check(equipment.active_weapon == shotgun, "Inventario bloquea teclas y rueda de cambio")
	Input.action_press("shoot")
	await frames(60)
	check(shotgun.loaded == loaded_before, "Inventario bloquea disparo")
	await key(KEY_TAB)
	await frames(60)
	check(shotgun.loaded == loaded_before, "Cerrar con disparo mantenido exige soltar")
	Input.action_release("shoot")
	await frames(2)
	var movement_start: Vector2 = player.position
	Input.action_press("move_down")
	Input.action_press("shoot")
	await frames(3)
	Input.action_release("move_down")
	Input.action_release("shoot")
	check(shotgun.loaded == loaded_before - 1 and player.position.y > movement_start.y and String(sprite.animation).begins_with("shoot_"), "Input dispara arma activa y reutiliza Shoot durante movimiento")
	loaded_before = shotgun.loaded
	var before_init: int = equipment.get_child_count()
	equipment.initialize(pistol)
	check(equipment.get_child_count() == before_init and shotgun.loaded == loaded_before, "Inicialización repetida no duplica arsenal ni restablece balas")
	check(shotgun.start_reload(), "Recarga activa antes de Game Over")
	player.health.take_damage(1000)
	check(hud.game_over.visible and not shotgun.reloading, "Game Over cancela recarga activa")
	for id in equipment.ORDER:
		var weapon := equipment.get_weapon(id)
		check(not weapon.enabled and not weapon.try_fire(player.position, Vector2.RIGHT) and not weapon.start_reload(), "Todas las armas bloqueadas tras muerte: " + String(id))
	check(not equipment.switch_to(&"machete"), "No cambiar tras Game Over")
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	player = current_scene.get_node("Player")
	equipment = player.get_node("Equipment")
	check(equipment.active_weapon == player.get_node("Weapon") and equipment.owns(&"machete") and not equipment.owns(&"revolver") and not equipment.owns(&"shotgun"), "Reintentar restaura propiedad inicial y pistola activa")
	check(player.weapon.loaded == 12 and player.weapon.reserve == 48 and player.get_node("InventoryComponent").occupied_slots() == 0, "Reinicio restaura munición y mochila")
	check(current_scene.get_node("World/ArsenalSupplies/RevolverCase/InventoryComponent").count_item(&"weapon_revolver") == 1, "Reinicio restaura arma del contenedor")
	var survival := player.get_node("SurvivalComponent") as SurvivalComponent
	check(survival.hunger_seconds_per_point == 30 and survival.thirst_seconds_per_point == 20 and survival.penalty_damage == 2 and survival.penalty_interval == 5, "Parámetros de supervivencia intactos")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado fase 6: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
