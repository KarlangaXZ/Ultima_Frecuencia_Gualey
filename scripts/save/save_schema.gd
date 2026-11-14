class_name SaveSchema
extends RefCounted
const VERSION := 1
static func number(value: Variant, low: float, high: float, integer := false) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value) and value >= low and value <= high and (not integer or floor(value) == value)
static func fields(value: Variant, keys: Array) -> bool:
	return value is Dictionary and value.size() == keys.size() and keys.all(func(key): return value.has(key))
static func keys_match(value: Variant, keys: Array) -> bool:
	return fields(value, keys)
static func strings(value: Variant, maximum: int = 128) -> bool:
	if not value is Array or value.size() > maximum: return false
	var found := {}
	for entry in value:
		if not entry is String or entry.is_empty() or entry.length() > 160 or found.has(entry): return false
		found[entry] = true
	return true
static func position(value: Variant) -> bool:
	return value is Array and value.size() == 2 and number(value[0], 40, 2360) and number(value[1], 40, 1560)
static func inventory(value: Variant) -> bool:
	if not value is Array or value.size() != 12: return false
	for slot in value:
		if not slot is Dictionary: return false
		if slot.is_empty(): continue
		if not fields(slot, ["item", "quantity"]) or not slot.item is String or not SaveCatalog.ITEMS.has(slot.item): return false
		if not number(slot.quantity, 1, SaveCatalog.ITEMS[slot.item].max_stack, true): return false
	return true
static func timestamp(value: Variant) -> bool:
	if not value is String or value.length() != 20: return false
	if RegEx.create_from_string("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$").search(value) == null: return false
	var year := int(value.substr(0,4))
	var month := int(value.substr(5,2))
	var day := int(value.substr(8,2))
	if year < 1970 or month < 1 or month > 12: return false
	var days := [31, 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28, 31,30,31,30,31,31,30,31,30,31]
	return day >= 1 and day <= days[month - 1] and int(value.substr(11,2)) < 24 and int(value.substr(14,2)) < 60 and int(value.substr(17,2)) < 60
static func validate(value: Variant, expected_slot: int = -1) -> String:
	if not value is Dictionary: return "El archivo no contiene una partida válida."
	if not value.has("version") or not number(value.version, VERSION, VERSION, true): return "Versión de guardado incompatible."
	if not fields(value, ["version", "slot", "saved_at", "chapter", "map", "player", "world", "missions"]): return "Estructura de guardado incompleta."
	if not number(value.slot, 0, 3, true) or (expected_slot >= 0 and value.slot != expected_slot): return "Identificador de ranura inválido."
	if not timestamp(value.saved_at): return "Fecha de guardado inválida."
	if value.chapter != "signal_lost" or value.map != "gualey_sector_04": return "Este capítulo o mapa no está disponible en esta versión."
	if not _player(value.player): return "Datos del protagonista, inventario o armas inválidos."
	if not _world(value.world): return "Datos del mundo o población inválidos."
	if not _missions(value.missions, int(value.world.kills)): return "Progreso de misiones inválido o incoherente."
	return ""
static func _player(p: Variant) -> bool:
	if not fields(p, ["position", "base_health", "health", "base_speed", "hunger", "thirst", "hunger_period", "thirst_period", "penalty_time", "progression", "skills", "inventory", "weapons", "equipped", "facing", "aim"]): return false
	if not position(p.position) or not number(p.base_health, 1, 1000) or not number(p.base_speed, 1, 1000): return false
	if not keys_match(p.skills, SaveCatalog.SKILLS): return false
	var spent := 0
	for rank in p.skills.values():
		if not number(rank, 0, 5, true): return false
		spent += int(rank)
	if not number(p.health, 0.001, p.base_health + int(p.skills.vitality) * 5): return false
	for need in [p.hunger, p.thirst]:
		if not number(need, 0, 100): return false
	if not number(p.hunger_period, 0.1, 3600) or not number(p.thirst_period, 0.1, 3600) or not number(p.penalty_time, 0, 5): return false
	if p.hunger > 0 and p.thirst > 0 and p.penalty_time != 0: return false
	if not fields(p.progression, ["level", "xp", "available_points"]): return false
	var progression: Dictionary = p.progression
	if not number(progression.level, 1, 10, true) or not number(progression.available_points, 0, 9, true): return false
	var requirement := 100 + (int(progression.level) - 1) * 50
	if not number(progression.xp, 0, 0 if progression.level == 10 else requirement - 1, true): return false
	if progression.available_points + spent != progression.level - 1: return false
	if not inventory(p.inventory) or not p.weapons is Dictionary or p.weapons.size() < 2 or p.weapons.size() > 4: return false
	if not p.weapons.has("pistol") or not p.weapons.has("machete"): return false
	for id in p.weapons:
		if not SaveCatalog.WEAPONS.has(id): return false
		var weapon: Variant = p.weapons[id]
		if not fields(weapon, ["loaded", "reserve", "cooldown"]): return false
		var config: WeaponConfig = SaveCatalog.WEAPONS[id]
		if not number(weapon.loaded, 0, config.capacity, true) or not number(weapon.reserve, 0, 100000, true) or not number(weapon.cooldown, 0, config.fire_interval): return false
		if id == "machete" and (weapon.loaded != 0 or weapon.reserve != 0): return false
	return p.equipped is String and p.weapons.has(p.equipped) and p.facing in ["down", "up", "left", "right"] and number(p.aim, -1000, 1000)
static func _world(w: Variant) -> bool:
	if not fields(w, ["containers", "pickups", "zombies", "population", "rewarded_zombies", "rewarded_containers", "kills", "survival_time"]): return false
	if not keys_match(w.containers, SaveCatalog.CONTAINERS) or not keys_match(w.pickups, SaveCatalog.PICKUPS): return false
	for available in w.pickups.values():
		if not available is bool: return false
	for container in w.containers.values():
		if not fields(container, ["opened", "slots"]) or not container.opened is bool or not inventory(container.slots): return false
	if not fields(w.population, ["spawned", "remaining", "cursor"]): return false
	if not number(w.population.spawned, 3, 18, true) or not number(w.population.remaining, 0, 10) or not number(w.population.cursor, 0, 14, true): return false
	if not w.zombies is Array or w.zombies.size() != w.population.spawned: return false
	if not strings(w.rewarded_zombies, 18) or not strings(w.rewarded_containers, 5): return false
	var found := {}
	var dead := []
	var living := 0
	for zombie in w.zombies:
		if not fields(zombie, ["id", "type", "position", "health", "cooldown"]) or not zombie.id is String: return false
		if zombie.type != "base" or not position(zombie.position) or not number(zombie.health, 0, 50) or not number(zombie.cooldown, 0, 1.5): return false
		if found.has(zombie.id): return false
		found[zombie.id] = true
		if zombie.health <= 0: dead.append(zombie.id)
		else: living += 1
	for index in range(1, int(w.population.spawned) + 1):
		if not found.has("zombie_%02d" % index): return false
	if living > 6 or not number(w.kills, 0, 18, true) or w.kills != dead.size() or not number(w.survival_time, 0, 31536000): return false
	if dead.size() != w.rewarded_zombies.size() or not dead.all(func(id): return id in w.rewarded_zombies): return false
	for id in w.rewarded_containers:
		if id not in SaveCatalog.CONTAINERS or not w.containers[id].opened: return false
	return true
static func _missions(m: Variant, kills: int) -> bool:
	if not fields(m, ["states", "progress", "totals", "receipts", "awarded", "radio", "unlocked_zones"]): return false
	var mission_ids := ["signal", "supplies", "broadcast"]
	if not keys_match(m.states, mission_ids) or not keys_match(m.progress, mission_ids): return false
	if not strings(m.receipts) or not strings(m.awarded, 3) or not m.unlocked_zones is Array or not m.unlocked_zones.is_empty(): return false
	var events := ["inspect_radio", "recovered_medkit", "recovered_water", "kills", "power_on", "send_radio"]
	if not m.totals is Dictionary or m.totals.size() > events.size(): return false
	for key in m.totals:
		if key not in events or not number(m.totals[key], 0, 128, true): return false
	if m.totals.get("kills", 0) != kills: return false
	var completed := []
	for definition in SaveCatalog.MISSIONS:
		var id := String(definition.id)
		if not number(m.states[id], 0, 3, true) or not m.progress[id] is Array or m.progress[id].size() != definition.objectives.size(): return false
		if definition.auto_activate and m.states[id] == 1: return false
		var done := true
		var previous := true
		for index in range(definition.objectives.size()):
			var objective: MissionObjective = definition.objectives[index]
			var progress: Variant = m.progress[id][index]
			if not number(progress, 0, objective.target, true): return false
			if progress > int(m.totals.get(String(objective.event_key), 0)): return false
			if m.states[id] == 0 and progress != 0: return false
			if definition.sequential and not previous and progress > 0: return false
			previous = previous and progress == objective.target
			if progress != objective.target: done = false
			if m.states[id] != 0 and objective.historical and progress != mini(objective.target, int(m.totals.get(String(objective.event_key), 0))): return false
		if (m.states[id] == 3) != done: return false
		if m.states[id] == 3: completed.append(id)
		for required in definition.prerequisites:
			if m.states[id] != 0 and m.states[String(required)] != 3: return false
		if m.states[id] == 0 and definition.prerequisites.all(func(required): return m.states[String(required)] == 3): return false
	if completed.size() != m.awarded.size() or not completed.all(func(id): return id in m.awarded): return false
	if not fields(m.radio, ["transmission", "index"]) or not m.radio.transmission is String: return false
	if m.radio.transmission == "": return m.radio.index == 0
	return SaveCatalog.TRANSMISSIONS.has(m.radio.transmission) and number(m.radio.index, 0, SaveCatalog.TRANSMISSIONS[m.radio.transmission].messages.size() - 1, true)
