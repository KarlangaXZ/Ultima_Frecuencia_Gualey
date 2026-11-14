extends SceneTree
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func tap(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E if action == "interact" else (KEY_ESCAPE if action == "ui_cancel" else KEY_TAB)
		event.keycode = event.physical_keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	if DisplayServer.get_name() != "headless": root.warp_mouse(point)
	point = root.get_screen_transform() * point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)

func clear_inventory(inventory: InventoryComponent) -> void:
	for index in range(inventory.capacity):
		var slot := inventory.get_slot(index)
		if not slot.is_empty(): inventory.remove_from_slot(index, slot.quantity)

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/phase-five")
	check(root.get_texture().get_image().save_png("res://test-results/phase-five/" + label + ".png") == OK, "Captura " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(5)
	var main := current_scene
	var player := main.get_node("Player") as CharacterBody2D
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var survival := player.get_node("SurvivalComponent") as SurvivalComponent
	var health := player.get_node("HealthComponent") as HealthComponent
	var interaction := player.get_node("Interaction")
	var user := player.get_node("ItemUse")
	var weapon := player.get_node("Weapon")
	var ui := main.get_node("InventoryUI")
	var hud := main.get_node("HUD")
	var supplies := main.get_node("World/Supplies")
	var medkit := load("res://resources/items/Medkit.tres") as ItemDefinition
	var water := load("res://resources/items/Water.tres") as ItemDefinition
	var food := load("res://resources/items/Food.tres") as ItemDefinition
	var ammo := load("res://resources/items/PistolAmmo.tres") as ItemDefinition
	for enemy in main.get_node("Zombies").get_children(): enemy.set_physics_process(false)
	survival.set_physics_process(false)
	check(inventory.occupied_slots() == 0 and inventory.capacity == 12, "Mochila inicial vacía")
	check(ui.content.get_node("Body/Bag/Grid").get_child_count() == 12, "Interfaz con doce espacios")
	check(supplies.get_child_count() == 7, "Cuatro recogibles y tres contenedores")
	check(InputMap.action_get_events("interact")[0].physical_keycode == KEY_E
		and InputMap.action_get_events("inventory")[0].physical_keycode == KEY_TAB, "Controles físicos E y Tab")
	for supply in supplies.get_children():
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = supply.get_node("CollisionShape2D").shape
		query.transform = supply.global_transform
		query.collision_mask = 1
		check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Suministro accesible fuera de sólidos: " + supply.name)
	# Lejos no recoge. Cerca, E almacena y elimina exactamente una vez.
	player.position = Vector2(600, 800)
	interaction.try_interact()
	check(inventory.count_item(water.id) == 0, "No recoger fuera del alcance de 56 px")
	player.position = Vector2(560, 805)
	await frames(3)
	check(hud.get_node("InteractionPrompt").text.contains("Botella"), "Indicador de cercanía físico")
	await capture("01-hud")
	await tap("interact")
	check(inventory.count_item(water.id) == 2 and not supplies.has_node("Water"), "E recoge dos botellas y elimina el objeto")
	await tap("interact")
	check(inventory.count_item(water.id) == 2, "E repetida no duplica")
	clear_inventory(inventory)
	inventory.add_item(medkit, 60)
	player.position = Vector2(680, 970)
	await frames(2)
	await tap("interact")
	check(supplies.has_node("Food") and inventory.count_item(food.id) == 0, "Mochila llena conserva el recogible")
	check(hud.get_node("Feedback").text.contains("llena"), "Aviso de capacidad agotada")
	clear_inventory(inventory)
	# Una pared impide la interacción aunque el centro esté a menos de 56 px.
	var behind_wall := load("res://scenes/items/WorldPickup.tscn").instantiate() as WorldPickup
	behind_wall.item = water
	supplies.add_child(behind_wall)
	behind_wall.position = Vector2(720, 495)
	player.position = Vector2(750, 495)
	await frames(2)
	check(not interaction.can_access(behind_wall), "No interactuar a través del colmado")
	behind_wall.queue_free()
	await frames(2)
	# Reentrada durante changed tampoco duplica una recogida válida.
	var real_pickup := supplies.get_node("Medkit") as WorldPickup
	var on_changed := func():
		if is_instance_valid(real_pickup): real_pickup.try_collect(inventory)
	inventory.changed.connect(on_changed)
	player.position = Vector2(650, 880)
	await frames(2)
	interaction.try_interact()
	inventory.changed.disconnect(on_changed)
	await frames(2)
	check(inventory.count_item(medkit.id) == 1 and not supplies.has_node("Medkit"), "Recogida reentrante única")
	clear_inventory(inventory)
	inventory.add_item(medkit, 3)
	inventory.add_item(water, 2)
	inventory.add_item(food, 2)
	inventory.add_item(ammo, 24)
	survival.hunger = 100
	survival.thirst = 100
	check(not user.use_slot(0) and inventory.count_item(medkit.id) == 3, "Botiquín no consumido con salud llena")
	check(not user.use_slot(1) and not user.use_slot(2), "Agua/comida no consumidas sin beneficio")
	health.take_damage(75)
	check(user.use_slot(0) and health.current_health == 65, "Botiquín recupera exactamente 40 HP")
	check(user.use_slot(0) and health.current_health == 100 and inventory.count_item(medkit.id) == 1, "Curación limitada al máximo")
	check(not user.use_slot(-1) and not user.use_slot(11), "Uso de espacio inválido/vacío rechazado")
	survival.hunger = 85
	survival.thirst = 60
	check(user.use_slot(1) and survival.thirst == 90 and inventory.count_item(water.id) == 1, "Agua +30 y descuento único")
	check(user.use_slot(2) and survival.hunger == 100 and inventory.count_item(food.id) == 1, "Comida limitada a 100")
	check(hud.get_node("Panel/Margin/Content/Needs").text == "Hambre: 100 · Sed: 90", "HUD observa necesidades")
	var reserve_before: int = weapon.reserve
	check(user.use_slot(3) and weapon.reserve == reserve_before + 24 and weapon.loaded == 12
		and inventory.count_item(ammo.id) == 0, "Munición transferida una vez a reserva, no al cargador")
	check(not user.use_slot(3) and weapon.reserve == reserve_before + 24, "Munición usada no se duplica")
	weapon.try_fire(player.position, Vector2.DOWN)
	check(weapon.loaded == 11 and weapon.start_reload(), "Pistola y recarga originales")
	player.position = Vector2(680, 970)
	await tap("inventory")
	check(ui.window.visible and player.controls_blocked, "Tab abre y bloquea controles")
	await tap("interact")
	check(supplies.has_node("Food") and inventory.count_item(food.id) == 1, "UI bloquea E sobre un recogible cercano")
	var start := player.position
	var aim_rotation: float = player.get_node("Aim").rotation
	Input.action_press("move_right")
	Input.action_press("shoot")
	Input.action_press("reload")
	await frames(100)
	check(player.position == start and player.velocity == Vector2.ZERO and player.get_node("Aim").rotation == aim_rotation, "UI bloquea movimiento y apuntado")
	check(weapon.loaded == 12 and weapon.reserve == reserve_before + 23 and not weapon.reloading, "Recarga ya iniciada termina; UI no dispara")
	Input.action_release("move_right")
	Input.action_release("reload")
	await tap("inventory")
	check(not ui.window.visible and not player.controls_blocked, "Tab cierra sin pausar mundo")
	await frames(20)
	check(weapon.loaded == 12, "Cerrar con clic mantenido no dispara accidentalmente")
	Input.action_release("shoot")
	await frames(2)
	Input.action_press("shoot")
	await frames(1)
	Input.action_release("shoot")
	check(weapon.loaded == 11, "Disparo vuelve tras soltar y pulsar de nuevo")
	await tap("inventory")
	Input.action_press("reload")
	await frames(2)
	Input.action_release("reload")
	check(not weapon.reloading and weapon.loaded == 11, "UI impide iniciar recarga con cargador incompleto")
	await click_control(ui.content.get_node("Body/Bag/Grid").get_child(0))
	check(ui.selected == 0, "Clic sobre slot selecciona el objeto y descripción")
	await capture("02-inventory")
	await click_control(ui.content.get_node("Header/Close"))
	check(not ui.window.visible, "Botón Cerrar operativo")
	await tap("inventory")
	await tap("ui_cancel")
	check(not ui.window.visible and not player.controls_blocked, "Escape cierra inventario")
	# Contenedores muestran existencias finitas y conservan su estado al cerrar.
	player.position = Vector2(600, 1020)
	await frames(2)
	await tap("interact")
	var backpack := supplies.get_node("Backpack") as LootContainer
	check(ui.window.visible and ui.container == backpack, "E muestra mochila abandonada")
	check(ui.content.get_node("Body/Details/LootScroll/Rows").get_child(0).visible, "Contenido del contenedor visible")
	await capture("03-container")
	var food_before := inventory.count_item(food.id)
	await click_control(ui.content.get_node("Body/Details/LootScroll/Rows").get_child(0))
	check(inventory.count_item(food.id) == food_before + 3 and backpack.inventory.count_item(food.id) == 0, "Botón transfiere pila completa")
	ui.content.get_node("Body/Details/LootScroll/Rows").get_child(0).pressed.emit()
	check(inventory.count_item(food.id) == food_before + 3, "Doble pulsación no duplica contenido")
	ui.close_window()
	await tap("interact")
	check(backpack.inventory.count_item(food.id) == 0, "Contenedor conserva estado al reabrir")
	clear_inventory(inventory)
	inventory.add_item(medkit, 60)
	check(not interaction.transfer_from_container(backpack, 1) and backpack.inventory.count_item(water.id) == 2, "Sin espacio no se pierde contenido")
	ui.close_window()
	player.position = Vector2(1200, 800)
	check(not interaction.transfer_from_container(backpack, 1), "No transferir a distancia")
	clear_inventory(inventory)
	for container_name in ["SupplyCrate", "MedicalCase"]:
		var source := supplies.get_node(container_name) as LootContainer
		player.position = source.position + Vector2(0, -35)
		await frames(2)
		await tap("interact")
		check(ui.window.visible and ui.container == source, "Abrir contenedor: " + container_name)
		for index in range(source.inventory.capacity):
			var slot := source.inventory.get_slot(index)
			if slot.is_empty(): continue
			var prior := inventory.count_item(slot.item.id)
			await click_control(ui.content.get_node("Body/Details/LootScroll/Rows").get_child(index))
			check(inventory.count_item(slot.item.id) == prior + slot.quantity, "Transferir contenido finito: " + container_name)
		check(source.inventory.occupied_slots() == 0 and ui.content.get_node("Body/Details/Empty").text == "Contenedor vacío", "Contenedor agotado visible: " + container_name)
		ui.close_window()
		clear_inventory(inventory)
	# Reloj determinista, sin esperar minutos reales ni cambiar configuración del juego.
	survival.hunger = 100
	survival.thirst = 100
	survival.advance(60)
	check(is_equal_approx(survival.hunger, 98) and is_equal_approx(survival.thirst, 97), "Ritmos: hambre 1/30 s y sed 1/20 s")
	survival.hunger = 1
	survival.thirst = 1
	survival.advance(20)
	check(survival.thirst == 0 and health.current_health == 100, "Sin daño anticipado al cruzar cero")
	survival.advance(4.9)
	check(health.current_health == 100, "Penalización espera su intervalo")
	survival.advance(0.1)
	check(health.current_health == 98, "Primer daño gradual mediante HealthComponent")
	survival.hunger = 0
	survival.thirst = 0
	survival.advance(5)
	check(health.current_health == 96, "Ambas necesidades a cero no duplican daño")
	survival.restore_need("hunger", 30)
	survival.advance(5)
	check(health.current_health == 94, "Una necesidad sigue causando una sola penalización")
	survival.restore_need("thirst", 30)
	survival.advance(5)
	check(health.current_health == 94, "Recuperación de ambas detiene penalización")
	check(survival.restore_need("thirst", -30) == 0 and survival.restore_need("invalid", 30) == 0, "Restauración inválida no muta")
	check(health.heal(-40) == 0 and not weapon.add_reserve(-1), "Adaptadores rechazan cantidades negativas")
	# Consumir desde el botón, no desde un segundo almacén de salud.
	inventory.add_item(medkit, 1)
	ui.open_inventory()
	await click_control(ui.content.get_node("Body/Bag/Grid").get_child(0))
	await click_control(ui.content.get_node("Body/Details/Use"))
	check(health.current_health == 100 and inventory.occupied_slots() == 0, "UTILIZAR conecta efecto y retirada")
	survival.hunger = 0
	survival.thirst = 0
	survival.advance(300)
	check(health.is_dead() and main.game_ended and hud.game_over.visible, "Privación puede provocar Game Over original")
	check(not ui.window.visible and not weapon.enabled, "Muerte cierra UI y deshabilita arma")
	var stopped_hunger := survival.hunger
	var stopped_thirst := survival.thirst
	var stopped_time: float = main.survival_time
	survival.advance(600)
	await frames(10)
	check(survival.hunger == stopped_hunger and survival.thirst == stopped_thirst and main.survival_time == stopped_time, "Supervivencia y reloj detenidos tras muerte")
	await tap("inventory")
	check(not ui.window.visible and not user.use_slot(0) and health.heal(40) == 0, "No abrir, consumir ni revivir tras Game Over")
	await capture("04-game-over")
	hud.get_node("GameOver/Center/Panel/Margin/Content/Retry").pressed.emit()
	await frames(5)
	main = current_scene
	player = main.get_node("Player")
	survival = player.get_node("SurvivalComponent")
	check(player.get_node("InventoryComponent").occupied_slots() == 0 and not player.controls_blocked, "Reintentar limpia mochila y bloqueos")
	check(survival.hunger > 99.9 and survival.thirst > 99.9 and player.health.current_health == 100, "Reintentar restaura necesidades y salud")
	check(main.get_node("World/Supplies").get_child_count() == 7
		and main.get_node("World/Supplies/Backpack/InventoryComponent").count_item(food.id) == 3, "Reintentar restaura recogibles y contenido inicial")
	check(player.weapon.loaded == 12 and player.weapon.reserve == 48 and main.kills == 0, "Arma y bajas originales restauradas")
	main.get_node("Zombies/ZombieA").position = player.position + Vector2(34, 0)
	main.get_node("InventoryUI").open_inventory()
	await frames(3)
	check(player.health.current_health == 90 and survival.thirst < 100, "Zombis y supervivencia siguen activos con UI abierta")
	print("Resultado fase 5: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
