extends SceneTree
var checks := 0
var failures := 0
var completions := 0
var reentered := false

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func objective(key: StringName, amount: int = 1, historical: bool = false) -> MissionObjective:
	var value := MissionObjective.new()
	value.event_key = key
	value.target = amount
	value.historical = historical
	return value

func mission(id: StringName, objectives: Array[MissionObjective]) -> MissionDefinition:
	var value := MissionDefinition.new()
	value.id = id
	value.title = String(id)
	value.objectives = objectives
	return value

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tracker := MissionTracker.new()
	var first := mission(&"a", [objective(&"inspect")])
	var second := mission(&"b", [objective(&"kills", 2, true), objective(&"water", 1, true)])
	second.prerequisites = [&"a"]
	var third := mission(&"c", [objective(&"power"), objective(&"send")])
	third.prerequisites = [&"b"]
	third.sequential = true
	var optional := mission(&"optional", [objective(&"custom", 2)])
	optional.auto_activate = false
	tracker.definitions = [first, second, third, optional]
	root.add_child(tracker)
	check(tracker.state_of(&"a") == MissionTracker.State.ACTIVE, "Raíz activa")
	check(tracker.state_of(&"b") == MissionTracker.State.LOCKED, "Dependencia bloqueada")
	check(tracker.state_of(&"optional") == MissionTracker.State.AVAILABLE, "Disponible sin autoactivación")
	check(not tracker.activate(&"missing") and not tracker.activate(&"b"), "No activar ID ajeno ni bloqueada")
	check(tracker.activate(&"optional") and not tracker.activate(&"optional"), "Activación explícita única")
	check(tracker.record_event(&"custom", "one"), "Evento configurable")
	check(not tracker.record_event(&"custom", "one"), "Recibo duplicado rechazado")
	check(tracker.progress_of(&"optional", 0) == 1, "Progreso exacto")
	tracker.record_event(&"custom", "two")
	check(tracker.state_of(&"optional") == MissionTracker.State.COMPLETED, "Objetivo configurable completado")
	check(not tracker.record_event(&"", "x") and not tracker.record_event(&"water", ""), "Eventos inválidos")
	tracker.observe_total(&"kills", 2)
	tracker.observe_total(&"kills", 1)
	tracker.record_event(&"water", "world:1")
	check(tracker.progress_of(&"b", 0) == 0, "Bloqueada no presenta progreso activo")
	tracker.record_event(&"power", "early")
	tracker.record_event(&"send", "early")
	tracker.mission_completed.connect(func(value: MissionDefinition):
		completions += 1
		if value.id == &"a": reentered = tracker.record_event(&"inspect", "radio"))
	tracker.record_event(&"inspect", "radio")
	check(not reentered and completions == 2, "Reentrada no repite completadas encadenadas")
	check(tracker.state_of(&"a") == MissionTracker.State.COMPLETED and tracker.state_of(&"b") == MissionTracker.State.COMPLETED, "Históricos completan al activar")
	check(tracker.progress_of(&"b", 0) == 2 and tracker.progress_of(&"b", 1) == 1, "Totales anteriores y monotónicos")
	check(tracker.active_mission() == third, "Siguiente misión activa")
	check(tracker.progress_of(&"c", 0) == 0 and tracker.progress_of(&"c", 1) == 0, "Interacciones previas no cuentan")
	check(not tracker.accepts(&"send") and tracker.accepts(&"power"), "Objetivos secuenciales")
	tracker.record_event(&"send", "out-of-order")
	check(tracker.progress_of(&"c", 1) == 0, "No acreditar segundo paso adelantado")
	tracker.record_event(&"power", "generator")
	check(tracker.accepts(&"send") and not tracker.accepts(&"power"), "Alimentación permite transmisión")
	tracker.record_event(&"send", "transmission")
	check(completions == 3 and tracker.active_mission() == null, "Cadena completa una vez")
	check(not tracker.record_event(&"send", "transmission"), "Final no se duplica")
	var copy := tracker.snapshot()
	copy.progress[&"c"][0] = 999
	copy.states[&"c"] = MissionTracker.State.LOCKED
	check(tracker.progress_of(&"c", 0) == 1 and tracker.state_of(&"c") == MissionTracker.State.COMPLETED, "Snapshot profundo independiente")
	check(tracker.progress_of(&"missing", 99) == 0 and tracker.progress_of(&"c", -1) == 0, "Índices inválidos seguros")
	tracker.stop()
	check(not tracker.record_event(&"custom", "dead") and not tracker.accepts(&"power"), "Muerte bloquea eventos")
	tracker.queue_free()
	# Dos pasos con la misma clave requieren dos eventos distintos.
	var repeated := MissionTracker.new()
	var sequence := mission(&"repeat", [objective(&"use"), objective(&"use")])
	sequence.sequential = true
	repeated.definitions = [sequence]
	root.add_child(repeated)
	repeated.record_event(&"use", "one")
	check(repeated.progress_of(&"repeat", 0) == 1 and repeated.progress_of(&"repeat", 1) == 0, "Un evento, un paso secuencial")
	repeated.record_event(&"use", "two")
	check(repeated.state_of(&"repeat") == MissionTracker.State.COMPLETED, "Segundo evento completa segundo paso")
	check(sequence.objectives[0].target == 1 and sequence.reward_xp == 0, "Configuración inmutable")
	repeated.queue_free()
	await process_frame
	print("Resultado componente misiones: ", checks, " comprobaciones, ", failures, " fallos")
	quit(0 if failures == 0 else 1)
