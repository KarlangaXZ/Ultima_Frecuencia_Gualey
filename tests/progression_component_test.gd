extends SceneTree
var checks := 0
var failures := 0
var level_events := 0
var granted_points := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _on_level(_level: int, points: int) -> void:
	level_events += 1
	granted_points += points

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var progression := ProgressionComponent.new()
	root.add_child(progression)
	progression.leveled_up.connect(_on_level)
	check(progression.level == 1 and progression.xp == 0 and progression.available_points == 0, "Valores iniciales")
	check(progression.required_xp() == 100 and progression.total_xp() == 0, "Primer requisito")
	check(not progression.add_xp(-10) and not progression.add_xp(0), "No aceptar XP negativa/cero")
	check(not progression.spend_point(), "No gastar sin puntos")
	check(progression.add_xp(99) and progression.level == 1 and progression.xp == 99, "Acumular antes del umbral")
	check(level_events == 0 and progression.available_points == 0, "Sin recompensas anticipadas")
	progression.add_xp(1)
	check(progression.level == 2 and progression.xp == 0 and progression.required_xp() == 150, "Umbral exacto y crecimiento de requisito")
	check(progression.available_points == 1 and level_events == 1, "Un punto por subida")
	progression.add_xp(450)
	check(progression.level == 4 and progression.xp == 100 and progression.required_xp() == 250, "Una recompensa cruza varios niveles y conserva sobrante")
	check(progression.total_xp() == 550 and progression.available_points == 3, "XP total derivada y puntos correctos")
	check(level_events == 2 and granted_points == 3, "Una notificación agregada por recompensa multinivel")
	progression.add_xp(1000000)
	check(progression.level == 10 and progression.xp == 0 and progression.required_xp() == 0, "Límite diez sin XP sobrante utilizable")
	check(progression.available_points == 9 and granted_points == 9, "Exactamente nueve puntos en toda la progresión base")
	check(progression.total_xp() == 2700, "XP útil acumulada hasta nivel máximo")
	check(not progression.add_xp(999) and progression.available_points == 9, "No generar puntos extra al máximo")
	var snapshot := progression.snapshot()
	snapshot.available_points = 999
	check(progression.available_points == 9, "Snapshot desacoplado del estado mutable")
	for index in range(9): check(progression.spend_point(), "Gasto individual válido " + str(index))
	check(progression.available_points == 0 and not progression.spend_point(), "No gastar el mismo punto dos veces")
	var custom := ProgressionComponent.new()
	custom.max_level = 3
	custom.first_requirement = 10
	custom.requirement_increment = 5
	custom.points_per_level = 2
	custom.initial_xp = 40
	root.add_child(custom)
	check(custom.level == 3 and custom.available_points == 4 and custom.total_xp() == 25, "Valores configurables e XP inicial")
	custom.stop()
	check(not custom.spend_point() and not custom.add_xp(10) and custom.available_points == 4, "Bloqueo tras finalizar")
	# Fixture configurable: 27 puntos para verificar cada límite con saldo sobrante.
	var host := Node.new()
	root.add_child(host)
	var generous := ProgressionComponent.new()
	generous.name = "ProgressionComponent"
	generous.points_per_level = 3
	generous.initial_xp = 100000
	host.add_child(generous)
	var skills := SkillsComponent.new()
	host.add_child(skills)
	for skill in skills.definitions:
		for rank in range(5): check(skills.upgrade(skill.id), "Rango permitido: " + String(skill.id) + str(rank + 1))
		check(skills.rank_of(skill.id) == 5 and not skills.upgrade(skill.id), "Tope cinco independiente del saldo: " + String(skill.id))
	check(generous.available_points == 7, "Veinte compras descuentan exactamente veinte puntos")
	check(is_equal_approx(skills.modifier_value("max_health"), 25), "Vitalidad máxima: +25 HP")
	check(is_equal_approx(skills.modifier_value("movement"), 0.15), "Agilidad máxima: +15 % base")
	check(is_equal_approx(skills.modifier_value("reload"), 0.20), "Manejo máximo: −20 % base")
	check(is_equal_approx(skills.modifier_value("consumption"), 0.25), "Supervivencia máxima: −25 % consumo")
	check(not skills.upgrade(&"unknown") and generous.available_points == 7, "ID inválido no gasta")
	host.queue_free()
	progression.queue_free()
	custom.queue_free()
	await process_frame
	print("Resultado componente progresión: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
