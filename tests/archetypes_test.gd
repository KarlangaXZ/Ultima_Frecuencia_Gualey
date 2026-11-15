extends SceneTree
var checks := 0
var failures := 0
var travelled := {}
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/archetypes")
	check(root.get_texture().get_image().save_png("res://test-results/archetypes/" + label + ".png") == OK,"Captura " + label)
func prepare(main: Node) -> void:
	main.get_node("Population").stop()
	main.get_node("Player").set_physics_process(false)
	main.get_node("Player/SurvivalComponent").set_physics_process(false)
	for enemy in main.get_node("Zombies").get_children():
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
func create_enemy(main: Node, id: String, label: String) -> Node:
	var enemy: Node = load("res://scenes/enemies/Zombie.tscn").instantiate()
	enemy.archetype = ZombieArchetypes.definition(id)
	enemy.name = label
	enemy.set_meta("persistence_id",label)
	enemy.position = Vector2(1000,800)
	main.get_node("Zombies").add_child(enemy)
	main._register_zombie(enemy)
	return enemy
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var common := ZombieArchetypes.definition("base")
	var runner := ZombieArchetypes.definition("runner")
	var tough := ZombieArchetypes.definition("resistant")
	check(common.health_value() == 50 and common.speed_value() == 105 and common.damage_value() == 10 and common.xp_reward == 30,"Común conserva valores exactos")
	check(runner.health_value() == 37.5 and runner.speed_value() == 147 and runner.damage_value() == 10 and runner.xp_reward == 45,"Corredor: 75 % HP y 140 % velocidad")
	check(tough.health_value() == 100 and tough.speed_value() == 78.75 and tough.damage_value() == 12.5 and tough.xp_reward == 60,"Resistente: 200 % HP, 75 % velocidad, 125 % daño")
	check(ZombieArchetypes.definition("unknown") == null,"ID desconocido no carga recursos")
	check(not ZombieArchetypes.valid_weights({"runner":-1}) and not ZombieArchetypes.valid_weights({"unknown":100}),"Pesos inválidos rechazados")
	check(ZombieArchetypes.choose({},1) == common,"Configuración vacía usa común seguro")
	var counts := {"base":0,"runner":0,"resistant":0}
	for index in range(1,19):
		check(ZoneCatalog.definition(ZoneCatalog.HOME).archetype_for(index) == common,"Gualey mantiene población común")
		counts[String(ZoneCatalog.definition(ZoneCatalog.MARKET).archetype_for(index).id)] += 1
		if index == 6: check(counts == {"base":3,"runner":2,"resistant":1},"Seis iniciales incluyen las tres variantes")
	check(counts == {"base":11,"runner":5,"resistant":2},"Presupuesto 18 aproxima 60/30/10: 11/5/2")
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	var main := current_scene
	var player := main.get_node("Player")
	check(main.get_node("Population").active_enemies().all(func(e): return e.archetype.id == &"base" and e.max_health == 50),"Población real inicial conserva dificultad")
	prepare(main)
	await frames(2)
	var xp := 0
	for id in ZombieArchetypes.ORDER:
		var archetype := ZombieArchetypes.definition(id)
		player.position = Vector2(1000,980)
		player.health.heal(1000)
		var enemy := create_enemy(main,id,"AI_" + id)
		check(enemy.is_physics_processing() and enemy.health.max_health == archetype.health_value() and enemy.health.current_health == archetype.health_value(),"Salud configurada antes de ready: " + id)
		check(enemy.health.base_max_health == archetype.health_value() and enemy.detection_radius == 250 and enemy.attack_distance == 35 and enemy.attack_interval == 1.5,"Detección y componente compartidos: " + id)
		check(enemy.get_node("CollisionShape2D").shape.radius == 16 and enemy.get_node("Visual/Sprite").scale == Vector2(0.85,0.85),"Escala y colisión no se deforman")
		for direction_name in ["up","left","right","down"]:
			var direction: Vector2 = {"up":Vector2.UP,"left":Vector2.LEFT,"right":Vector2.RIGHT,"down":Vector2.DOWN}[direction_name]
			enemy.position = Vector2(1300,800)
			player.position = enemy.position + direction*180
			enemy.repath_time = 0
			await frames(12)
			check(String(enemy.get_node("Visual/Sprite").animation) == "walk_" + direction_name,"Dirección real " + id + "/" + direction_name)
		enemy.position = Vector2(1000,800)
		player.position = Vector2(1000,980)
		enemy.repath_time = 0
		var start: Vector2 = enemy.position
		await frames(30)
		travelled[id] = enemy.position.distance_to(start)
		check(enemy.state == 1 and absf(travelled[id] - archetype.speed_value() * 0.5) < 4,"Velocidad real medida: " + id)
		check(enemy.position.distance_to(player.position) < 160 and String(enemy.get_node("Visual/Sprite").animation) == "walk_down","Persecución y dirección real: " + id)
		check(is_equal_approx(enemy.get_node("Visual/Sprite").speed_scale, archetype.speed_value()/common.speed_value()),"Walk sincronizado con desplazamiento")
		await capture("home-" + id)
		await frames(int(ceil(180.0/archetype.speed_value()*60)) - 30)
		check(enemy.state == 2 and player.health.current_health == 100-archetype.damage_value(),"Ataque con daño del recurso: " + id)
		var hp: float = player.health.current_health
		var emitter: SoundEmitter = enemy.get_node("Audio").emitter
		check(emitter.played_counts.get(&"zombie_attack",0) == 1 and emitter.get_child_count() == 3,"Un sonido por ataque y pool acotado")
		check(is_equal_approx(emitter.pitch_scale,archetype.audio_pitch) and emitter._players.all(func(p): return is_equal_approx(p.pitch_scale,1) or is_equal_approx(p.pitch_scale,archetype.audio_pitch)),"Pitch por instancia, sin modificar WAV")
		await frames(30)
		check(player.health.current_health == hp,"No repite ataque antes del intervalo")
		await frames(65)
		check(player.health.current_health == hp-archetype.damage_value() and emitter.played_counts.get(&"zombie_attack",0) == 2,"Segundo ataque real sin duplicar audio")
		player.health.heal(1000)
		player.position = Vector2(750,800)
		enemy.position = Vector2(730,800)
		enemy.cooldown = 0
		check(not enemy._can_reach_target(),"World bloquea ataque en alcance: " + id)
		await frames(5)
		check(player.health.current_health == 100,"No daña a través de World")
		enemy.position = Vector2(760,550)
		player.position = Vector2(680,650)
		enemy.cooldown = 0
		await frames(200)
		check(enemy.state == 2 and enemy.position.distance_to(player.position) <= 35,"Rodea colmado con IA activa: " + id)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = enemy.get_node("CollisionShape2D").shape
		query.transform = enemy.global_transform
		query.collision_mask = 1
		check(enemy.get_world_2d().direct_space_state.intersect_shape(query).is_empty(),"No atraviesa sólidos: " + id)
		var before: float = enemy.health.current_health
		enemy.health.take_damage(10)
		check(enemy.health.current_health == before-10 and enemy.get_node("Visual").flash_remaining > 0,"Impacto y feedback compartidos")
		enemy.health.take_damage(500)
		enemy.health.take_damage(500)
		xp += archetype.xp_reward
		check(enemy.state == 3 and player.get_node("ProgressionComponent").total_xp() == xp,"Una muerte y XP de arquetipo: " + id)
		check(emitter.played_counts.get(&"zombie_death",0) == 1 and not player.get_node("ProgressionRewards").zombie_eliminated(enemy),"No repite muerte ni premio")
		await frames(30)
		check(enemy.get_node("Visual/Sprite").frame == 5 and enemy.collision_layer == 0,"Death final y colisión desactivada")
	check(travelled.runner > travelled.base*1.3 and travelled.resistant < travelled.base*0.8,"Diferencias reales, no solo estadísticas declaradas")
	check(main.kills == 3 and xp == 135,"Contador y total 30+45+60")
	# Las cuatro armas existentes resuelven impactos reales contra cada variante.
	change_scene_to_file("res://scenes/Main.tscn")
	await frames(8)
	main = current_scene
	player = main.get_node("Player")
	prepare(main)
	var equipment: EquipmentComponent = player.get_node("Equipment")
	equipment.obtain(SaveCatalog.WEAPONS.revolver)
	equipment.obtain(SaveCatalog.WEAPONS.shotgun)
	for weapon_id in EquipmentComponent.ORDER:
		equipment.switch_to(weapon_id)
		var weapon: Node = equipment.active_weapon
		for id in ZombieArchetypes.ORDER:
			player.health.heal(1000)
			player.position = Vector2(1000,800)
			var enemy := create_enemy(main,id,"Combat_" + String(weapon_id) + "_" + id)
			enemy.position = Vector2(1030,800)
			await frames(2)
			weapon.loaded = weapon.config.capacity
			weapon.cooldown = 0
			var expected_damage: float = weapon.config.damage * (weapon.config.pellet_count if weapon.config.weapon_type == "spread" else 1)
			var expected_hits := int(ceil(enemy.max_health/expected_damage))
			var hits := 0
			while not enemy.health.is_dead() and hits < 8:
				check(weapon.try_fire(player.position,Vector2.RIGHT),"Ataque válido " + String(weapon_id) + "/" + id)
				hits += 1
				await frames(int(ceil(weapon.config.fire_interval*60))+1)
			check(enemy.health.is_dead() and hits == expected_hits,"Resistencia real con " + String(weapon_id) + "/" + id)
			check(enemy.get_node("Audio").emitter.played_counts.get(&"zombie_death",0) == 1,"Arma no duplica sonido de muerte")
	check(main.kills == 12 and player.get_node("ProgressionComponent").total_xp() == 540,"Doce bajas de combate y XP correcta")
	check(SaveCatalog.WEAPONS.pistol.damage == 25 and SaveCatalog.WEAPONS.revolver.damage == 45 and SaveCatalog.WEAPONS.shotgun.damage == 8 and SaveCatalog.WEAPONS.machete.damage == 30,"Armas y recursos inmutables")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Desplazamiento en 30 frames: ",travelled)
	print("Resultado arquetipos: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
