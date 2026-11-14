class_name MissionSaveState
extends RefCounted
static func capture(main: Node) -> Dictionary:
	var tracker: MissionTracker = main.get_node("Missions")
	var radio: Node = main.get_node("Radio")
	var transmission := ""
	for id in SaveCatalog.TRANSMISSIONS:
		if radio.transmission == SaveCatalog.TRANSMISSIONS[id]: transmission = id
	return {"states": tracker._states.duplicate(true), "progress": tracker._progress.duplicate(true),
		"totals": tracker._totals.duplicate(true), "receipts": tracker._receipts.keys(),
		"awarded": main.get_node("Missions/Rewards")._awarded.keys().map(func(id): return String(id)),
		"radio": {"transmission": transmission, "index": radio.index if transmission != "" else 0}, "unlocked_zones": main.get_node("ZoneManager").unlocked.duplicate()}

static func restore(main: Node, data: Dictionary) -> void:
	var tracker: MissionTracker = main.get_node("Missions")
	tracker._states.clear()
	tracker._progress.clear()
	tracker._totals.clear()
	tracker._receipts.clear()
	for id in data.states:
		tracker._states[StringName(id)] = int(data.states[id])
		tracker._progress[StringName(id)] = data.progress[id].map(func(value): return int(value))
	for key in data.totals: tracker._totals[StringName(key)] = int(data.totals[key])
	for receipt in data.receipts: tracker._receipts[receipt] = true
	var rewards: Node = main.get_node("Missions/Rewards")
	rewards._awarded.clear()
	for id in data.awarded: rewards._awarded[StringName(id)] = true
	var radio: Node = main.get_node("Radio")
	radio.transmission = SaveCatalog.TRANSMISSIONS.get(data.radio.transmission)
	radio.index = int(data.radio.index)
	main.get_node("ZoneManager").unlocked.assign(data.unlocked_zones)
	main.get_node("ZoneManager").sync_exits()
	# No changed/mission_completed/leveled_up: reconstruir no vuelve a premiar.
	main.get_node("Missions/Chapter")._update_points()
	main.get_node("MissionUI").refresh()
	main.get_node("ObjectiveHUD").refresh()
