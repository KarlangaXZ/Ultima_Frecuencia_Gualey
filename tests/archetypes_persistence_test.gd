extends SceneTree
const FIXTURE := preload("res://tests/archetype_fixture.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await FIXTURE.frames(self,8)
	var main := current_scene
	var saves := main.get_node("SaveCoordinator")
	saves.store.directory = "user://tests/phase-eleven-types-%d" % OS.get_process_id()
	var directory: String = saves.store.directory
	var legacy_one: Dictionary = saves.capture(3)
	legacy_one.version = 1
	legacy_one.erase("zones")
	legacy_one.erase("stats")
	check(saves.store.write_slot(3,legacy_one).has("ok"),"Archivo v1 anterior válido")
	await FIXTURE.enter_market(self,main)
	var manager := main.get_node("ZoneManager")
	var player := main.get_node("Player")
	check(FIXTURE.counts(main) == {"base":3,"runner":2,"resistant":1},"Mercado real inicial 3/2/1")
	check(main.get_node("Population").active_limit == 6 and main.get_node("Population").total_budget == 18 and main.get_node("Population").replacement_interval == 10,"Límites de zona intactos")
	check(main.get_node("Population").active_enemies().all(func(e): return e.is_physics_processing()),"Variantes sin física desactivada")
	var legacy_two: Dictionary = saves.capture(2)
	for enemy in legacy_two.world.zombies:
		enemy.type = "base"
		enemy.health = 50.0
	check(saves.store.write_slot(2,legacy_two).has("ok"),"v2 anterior con seis comunes")
	FIXTURE.by_type(main,"resistant").health.take_damage(12.5)
	var runner := FIXTURE.by_type(main,"runner")
	runner.health.take_damage(7.5)
	check(runner.health.current_health == 30 and FIXTURE.by_type(main,"resistant").health.current_health == 87.5,"Salud parcial por variante")
	var before: int = player.get_node("ProgressionComponent").total_xp()
	runner.health.take_damage(500)
	runner.health.take_damage(500)
	check(player.get_node("ProgressionComponent").total_xp() == before + 45 and main.kills == 3,"Corredor otorga 45 XP una vez")
	var expected := FIXTURE.states(main)
	check(saves.save_slot(1).has("ok"),"Guardar tipos y salud en v2")
	var data: Dictionary = saves.capture(1)
	check(data.version == 2 and SaveSchema.validate(data).is_empty(),"Sin cambiar estructura del formato v2")
	for type_id in ["runner","resistant"]:
		var invalid := data.duplicate(true)
		for enemy in invalid.world.zombies:
			if enemy.type == type_id:
				enemy.health = ZombieArchetypes.definition(type_id).health_value() + 0.1
				break
		check(not SaveSchema.validate(invalid).is_empty(),"Valida salud máxima del tipo: " + type_id)
	var invalid := data.duplicate(true)
	invalid.world.zombies[0].type = "res://enemy.gd"
	check(not SaveSchema.validate(invalid).is_empty(),"No ejecuta tipo procedente de ruta")
	check(manager.request_travel(ZoneCatalog.HOME,"from_market"),"Salir con variantes heridas/eliminadas")
	await manager.transition_finished
	check(main.get_node("Zombies").get_children().all(func(e): return e.archetype.id == &"base"),"Gualey mantiene comunes al volver")
	check(manager.request_travel(ZoneCatalog.MARKET,"from_gualey"),"Regresar a variantes persistentes")
	await manager.transition_finished
	check(FIXTURE.states(main) == expected,"No sortea ni cura variantes al volver")
	check(saves.load_slot(1).has("ok"),"Cargar tipos por ID permitido")
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	player = main.get_node("Player")
	check(FIXTURE.states(main) == expected,"Conserva vivos, cadáver y salud sin duplicados")
	check(main.get_node("Population").total_spawned == 6 and main.get_node("Zombies").get_child_count() == 6,"Presupuesto conservado al cargar")
	check(player.get_node("ProgressionComponent").total_xp() == before + 45 and not player.get_node("ProgressionRewards").zombie_eliminated(FIXTURE.by_type(main,"runner")),"Cargar no repite XP del corredor muerto")
	check(saves.load_slot(2).has("ok"),"Cargar v2 antiguo sin variantes")
	main = current_scene
	saves = main.get_node("SaveCoordinator")
	check(main.get_node("Zombies").get_children().all(func(e): return e.archetype.id == &"base" and e.health.current_health == 50),"Los comunes anteriores no se transforman al cargar")
	check(saves.load_slot(3).get("migrated",false),"Migración v1 sigue funcionando")
	main = current_scene
	check(main.get_node("ZoneManager").current_zone == ZoneCatalog.HOME and FIXTURE.counts(main) == {"base":6,"runner":0,"resistant":0},"v1 conserva población y dificultad original")
	# Presupuesto completo real de mercado; reloj acelerado solo para las reposiciones.
	await FIXTURE.frames(self,8)
	await FIXTURE.enter_market(self,main)
	var population := main.get_node("Population")
	var progression := main.get_node("Player/ProgressionComponent") as ProgressionComponent
	before = progression.total_xp()
	population.spawned.connect(func(enemy: CharacterBody2D):
		check(population.active_enemies().size() <= 6 and population.total_spawned <= 18,"Límites al emitir cada aparición")
		check(enemy.archetype == ZoneCatalog.definition(ZoneCatalog.MARKET).archetype_for(population.total_spawned),"Tipo seleccionado antes de ready/notificación")
		check(not root.get_visible_rect().grow(96).has_point(enemy.get_canvas_transform()*enemy.position),"Variante fuera de cámara")
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = enemy.get_node("CollisionShape2D").shape
		query.transform = enemy.global_transform
		query.collision_mask = 1
		check(enemy.get_world_2d().direct_space_state.intersect_shape(query).is_empty(),"Variante fuera de estructuras"))
	while population.total_spawned < 18:
		population.active_enemies()[0].health.take_damage(500)
		population._physics_process(10.1)
		await FIXTURE.frames(self)
	for enemy in population.active_enemies(): enemy.health.take_damage(500)
	check(FIXTURE.counts(main) == {"base":11,"runner":5,"resistant":2},"Distribución completa real: 11/5/2")
	check(progression.total_xp() == before + 675 and main.kills == 20,"XP por tipos: 11×30 + 5×45 + 2×60")
	for index in range(4): population._physics_process(60.0)
	check(population.total_spawned == 18 and population.active_enemies().is_empty() and main.get_node("Zombies").get_child_count() == 18,"Sin enemigos infinitos ni cadáveres duplicados")
	check(ZombieArchetypes.definition("base").health_value() == 50 and ZombieArchetypes.definition("runner").speed_value() == 147,"Recursos compartidos sin mutación")
	await preload("res://tests/audio_cleanup.gd").finish(self)
	print("Resultado persistencia arquetipos: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures == 0 else 1)
