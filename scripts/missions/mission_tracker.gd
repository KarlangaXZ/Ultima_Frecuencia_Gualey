class_name MissionTracker
extends Node
## Estado por partida. Definiciones compartidas inmutables; sin inventario ni daño.
signal changed
signal mission_completed(mission: MissionDefinition)
enum State { LOCKED, AVAILABLE, ACTIVE, COMPLETED }
@export var definitions: Array[MissionDefinition] = []
var enabled := true
var _states: Dictionary = {}
var _progress: Dictionary = {}
var _totals: Dictionary = {}
var _receipts: Dictionary = {}
var _busy := false
var _dirty := false

func _ready() -> void:
	for mission in definitions:
		assert(mission != null and not mission.id.is_empty() and not _states.has(mission.id))
		assert(not mission.objectives.is_empty())
		_states[mission.id] = State.LOCKED
		_progress[mission.id] = []
		for objective in mission.objectives:
			assert(objective != null and not objective.event_key.is_empty() and objective.target > 0)
			_progress[mission.id].append(0)
	for mission in definitions:
		for required in mission.prerequisites:
			assert(_states.has(required) and required != mission.id)
	_refresh()

func state_of(id: StringName) -> State:
	return _states.get(id, State.LOCKED)

func progress_of(id: StringName, index: int) -> int:
	var values: Array = _progress.get(id, [])
	return values[index] if index >= 0 and index < values.size() else 0

func active_mission() -> MissionDefinition:
	for mission in definitions:
		if state_of(mission.id) == State.ACTIVE: return mission
	return null

func activate(id: StringName) -> bool:
	if not enabled or state_of(id) != State.AVAILABLE: return false
	_states[id] = State.ACTIVE
	_refresh()
	return true

func accepts(key: StringName) -> bool:
	if not enabled: return false
	for mission in definitions:
		if state_of(mission.id) != State.ACTIVE: continue
		for index in range(mission.objectives.size()):
			var objective := mission.objectives[index]
			if objective.event_key == key and progress_of(mission.id, index) < objective.target:
				if not mission.sequential or _previous_done(mission, index): return true
	return false

func record_event(key: StringName, receipt: String) -> bool:
	if not enabled or key.is_empty() or receipt.is_empty(): return false
	var token := String(key) + ":" + receipt
	if _receipts.has(token): return false
	_receipts[token] = true
	_totals[key] = int(_totals.get(key, 0)) + 1
	# Un evento no histórico solo afecta objetivos activos y en orden.
	for mission in definitions:
		if state_of(mission.id) != State.ACTIVE: continue
		for index in range(mission.objectives.size()):
			var objective := mission.objectives[index]
			if objective.event_key != key or objective.historical: continue
			if progress_of(mission.id, index) >= objective.target: continue
			if mission.sequential and not _previous_done(mission, index): continue
			_progress[mission.id][index] = mini(objective.target, progress_of(mission.id, index) + 1)
			# Una sola interacción no resuelve dos pasos secuenciales iguales.
			if mission.sequential: break
	_refresh()
	return true

func observe_total(key: StringName, value: int) -> void:
	if not enabled or value <= int(_totals.get(key, 0)): return
	_totals[key] = value
	_refresh()

func _previous_done(mission: MissionDefinition, index: int) -> bool:
	for previous in range(index):
		if progress_of(mission.id, previous) < mission.objectives[previous].target: return false
	return true

func _refresh() -> void:
	_dirty = true
	if _busy: return
	_busy = true
	while _dirty and enabled:
		_dirty = false
		var completed: Array[MissionDefinition] = []
		for mission in definitions:
			if state_of(mission.id) == State.LOCKED:
				var ready := true
				for required in mission.prerequisites:
					if state_of(required) != State.COMPLETED: ready = false
				if ready: _states[mission.id] = State.ACTIVE if mission.auto_activate else State.AVAILABLE
			if state_of(mission.id) != State.ACTIVE: continue
			var done := true
			for index in range(mission.objectives.size()):
				var objective := mission.objectives[index]
				if objective.historical and (not mission.sequential or _previous_done(mission, index)):
					_progress[mission.id][index] = mini(objective.target, int(_totals.get(objective.event_key, 0)))
				if progress_of(mission.id, index) < objective.target: done = false
			if done:
				_states[mission.id] = State.COMPLETED
				completed.append(mission)
				_dirty = true
		for mission in completed: mission_completed.emit(mission)
		changed.emit()
	_busy = false

func stop() -> void:
	enabled = false
	changed.emit()

func snapshot() -> Dictionary:
	return {"states": _states.duplicate(true), "progress": _progress.duplicate(true)}
