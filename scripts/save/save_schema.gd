class_name SaveSchema
extends RefCounted
const VERSION := 6
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
	if not value.has("version") or not number(value.version, 1, VERSION, true): return "Versión de guardado incompatible."
	var root_fields := ["version", "slot", "saved_at", "chapter", "map", "player", "world", "missions"]
	if value.version >= 2: root_fields.append_array(["zones","stats"])
	if value.version >= 3: root_fields.append("story")
	if not fields(value, root_fields): return "Estructura de guardado incompleta."
	if not number(value.slot, 0, 3, true) or (expected_slot >= 0 and value.slot != expected_slot): return "Identificador de ranura inválido."
	if not timestamp(value.saved_at): return "Fecha de guardado inválida."
	if not value.chapter is String or not ChapterCatalog.DEFINITIONS.has(value.chapter) or (value.version<3 and value.chapter!=ChapterCatalog.FIRST) or not value.map is String or not ZoneCatalog.DEFINITIONS.has(value.map): return "Este capítulo o mapa no está disponible en esta versión."
	if value.version<4 and value.map==ZoneCatalog.STATION: return "Zona incompatible con guardado anterior."
	if value.version<6 and value.map==ZoneCatalog.PERIMETER: return "Perímetro incompatible con guardado anterior."
	if value.version<5 and value.chapter==ChapterCatalog.STATION: return "Capítulo incompatible con guardado anterior."
	if value.version == 1 and value.map != ZoneCatalog.HOME: return "Mapa incompatible con guardado v1."
	if not _player(value.player): return "Datos del protagonista, inventario o armas inválidos."
	if not _world(value.world,value.map,value.version >= 2,value.version>=4): return "Datos del mundo o población inválidos."
	var kills := int(value.world.kills)
	if value.version >= 2:
		if not value.zones is Dictionary or value.zones.size() > (3 if value.version>=6 else 2 if value.version>=4 else 1) or value.zones.has(value.map): return "Estados de zonas inválidos."
		for id in value.zones:
			if value.version<6 and id==ZoneCatalog.PERIMETER: return "Zona inactiva incompatible con guardado anterior."
			if not id is String or not ZoneCatalog.DEFINITIONS.has(id) or (value.version<4 and id==ZoneCatalog.STATION) or not _world(value.zones[id],id,true,value.version>=4): return "Datos de zona inactiva inválidos."
			kills += int(value.zones[id].kills)
		if value.map != ZoneCatalog.HOME and not value.zones.has(ZoneCatalog.HOME): return "Falta el estado de la zona inicial."
		if value.map==ZoneCatalog.STATION and not value.zones.has(ZoneCatalog.MARKET): return "Falta el estado del Mercado."
		if value.map==ZoneCatalog.PERIMETER or value.zones.has(ZoneCatalog.PERIMETER):
			for previous in [ZoneCatalog.HOME,ZoneCatalog.MARKET,ZoneCatalog.STATION]:
				if value.map!=previous and not value.zones.has(previous): return "Falta una zona previa al Perímetro."
		if not fields(value.stats,["kills","survival_time"]) or not number(value.stats.kills,0,72 if value.version>=6 else 54 if value.version>=4 else 36,true) or value.stats.kills != kills or not number(value.stats.survival_time,0,31536000): return "Estadísticas globales incoherentes."
	if value.version>=3 and (not value.story is Dictionary or not value.story.get("started") is Array): return "Capítulos inválidos."
	var started: Array = value.story.get("started",[]) if value.version>=3 else [ChapterCatalog.FIRST]
	if not _missions(value.missions,kills,value.version>=2,value.version>=3,started,value.version>=4,value.version>=5,value.version>=6): return "Progreso de misiones inválido o incoherente."
	if value.version >= 2:
		if (value.map == ZoneCatalog.MARKET or value.zones.has(ZoneCatalog.MARKET)) and ZoneCatalog.MARKET not in value.missions.unlocked_zones: return "Zona visitada sin desbloquear."
	if value.version>=4 and (value.map==ZoneCatalog.STATION or value.zones.has(ZoneCatalog.STATION)) and ZoneCatalog.STATION not in value.missions.unlocked_zones: return "Estación visitada sin desbloquear."
	if value.version>=6 and not _perimeter(value): return "Estado del Perímetro incoherente."
	if value.version>=3 and not _story(value): return "Estado narrativo incoherente."
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
static func _world(w: Variant, zone_id: String = "gualey_sector_04", allow_variants := true, unique_interactions := true) -> bool:
	var zone := ZoneCatalog.definition(zone_id)
	if zone == null: return false
	var expected := ["containers", "pickups", "zombies", "population", "rewarded_zombies", "rewarded_containers", "kills", "survival_time"]
	if unique_interactions: expected.append("interactions")
	if not fields(w,expected): return false
	if unique_interactions and (not strings(w.interactions,zone.interaction_ids.size()) or not w.interactions.all(func(id):return id in zone.interaction_ids)): return false
	if not keys_match(w.containers, zone.container_ids) or not keys_match(w.pickups, zone.pickup_ids): return false
	for available in w.pickups.values():
		if not available is bool: return false
	for container in w.containers.values():
		if not fields(container, ["opened", "slots"]) or not container.opened is bool or not inventory(container.slots): return false
	if not fields(w.population, ["spawned", "remaining", "cursor"]): return false
	if not number(w.population.spawned, 3, zone.total_budget, true) or not number(w.population.remaining, 0, zone.replacement_interval) or not number(w.population.cursor, 0, zone.spawn_points.size() - 1, true): return false
	if not w.zombies is Array or w.zombies.size() != w.population.spawned: return false
	if not strings(w.rewarded_zombies, 18) or not strings(w.rewarded_containers, 5): return false
	var found := {}
	var dead := []
	var living := 0
	for zombie in w.zombies:
		if not fields(zombie, ["id", "type", "position", "health", "cooldown"]) or not zombie.id is String: return false
		if not zombie.type is String: return false
		var archetype := ZombieArchetypes.definition(zombie.type)
		if archetype == null or (not allow_variants and zombie.type != "base"): return false
		if not position(zombie.position) or not number(zombie.health, 0, archetype.health_value()) or not number(zombie.cooldown, 0, archetype.attack_interval): return false
		if found.has(zombie.id): return false
		found[zombie.id] = true
		if zombie.health <= 0: dead.append(zombie.id)
		else: living += 1
	for index in range(1, int(w.population.spawned) + 1):
		if not found.has(zone.enemy_prefix + "%02d" % index): return false
	if living > 6 or not number(w.kills, 0, 18, true) or w.kills != dead.size() or not number(w.survival_time, 0, 31536000): return false
	if dead.size() != w.rewarded_zombies.size() or not dead.all(func(id): return id in w.rewarded_zombies): return false
	for id in w.rewarded_containers:
		if id not in zone.container_ids or not w.containers[id].opened: return false
	return true
static func _missions(m: Variant, kills: int, with_zones := false, chapters := false, started: Array = ["signal_lost"], station := false, voices := false, perimeter := false) -> bool:
	if not fields(m, ["states", "progress", "totals", "receipts", "awarded", "radio", "unlocked_zones"]): return false
	var definitions: Array = SaveCatalog.MISSIONS if voices else SaveCatalog.MISSIONS.slice(0,7 if chapters else 3)
	var mission_ids := definitions.map(func(d): return String(d.id))
	if not keys_match(m.states, mission_ids) or not keys_match(m.progress, mission_ids): return false
	if not strings(m.receipts) or not strings(m.awarded, definitions.size()) or not strings(m.unlocked_zones,3 if perimeter else 2 if station else 1): return false
	if not with_zones and not m.unlocked_zones.is_empty(): return false
	if with_zones:
		if not m.unlocked_zones.all(func(id): return id == ZoneCatalog.MARKET or (station and id==ZoneCatalog.STATION) or (perimeter and id==ZoneCatalog.PERIMETER)): return false
		if (m.states.broadcast == 3) != (ZoneCatalog.MARKET in m.unlocked_zones): return false
		if station and ((m.states.market_frequency==3)!=(ZoneCatalog.STATION in m.unlocked_zones)): return false
		if perimeter and ((m.states.station_call==3)!=(ZoneCatalog.PERIMETER in m.unlocked_zones)): return false
	var events := ["inspect_radio", "recovered_medkit", "recovered_water", "kills", "power_on", "send_radio"]
	if chapters: events.append_array(ChapterCatalog.EVENTS)
	if voices: events.append_array(ChapterCatalog.STATION_EVENTS)
	if not m.totals is Dictionary or m.totals.size() > events.size(): return false
	for key in m.totals:
		if key not in events or not number(m.totals[key], 0, 128, true): return false
	if m.totals.get("kills", 0) != kills: return false
	var completed := []
	for definition in definitions:
		var id := String(definition.id)
		if not number(m.states[id], 0, 3, true) or not m.progress[id] is Array or m.progress[id].size() != definition.objectives.size(): return false
		if chapters and String(definition.chapter_id) not in started and m.states[id]!=0: return false
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
		if m.states[id] == 0 and (not chapters or String(definition.chapter_id) in started) and definition.prerequisites.all(func(required): return m.states[String(required)] == 3): return false
	if completed.size() != m.awarded.size() or not completed.all(func(id): return id in m.awarded): return false
	if not fields(m.radio, ["transmission", "index"]) or not m.radio.transmission is String: return false
	if m.radio.transmission == "": return m.radio.index == 0
	if not voices and m.radio.transmission in ["station_records","station_power","station_hidden","station_final"]: return false
	if not perimeter and m.radio.transmission in SaveCatalog.PERIMETER_RADIOS: return false
	return SaveCatalog.TRANSMISSIONS.has(m.radio.transmission) and number(m.radio.index, 0, SaveCatalog.TRANSMISSIONS[m.radio.transmission].messages.size() - 1, true)

static func _story(data: Dictionary) -> bool:
	var s: Variant = data.story
	var voices: bool = data.version>=5
	var story_fields := ["started","completed","legacy_waivers","station_hint"]
	if voices: story_fields.append("perimeter_hint")
	if not fields(s,story_fields): return false
	if not strings(s.started,3 if voices else 2) or not strings(s.completed,3 if voices else 2) or not strings(s.legacy_waivers,2) or not s.station_hint is bool: return false
	if s.started.is_empty() or s.started[0]!=ChapterCatalog.FIRST: return false
	if not s.started.all(func(id): return ChapterCatalog.DEFINITIONS.has(id)) or not s.completed.all(func(id): return id in s.started): return false
	if not voices and ChapterCatalog.STATION in s.started: return false
	if data.chapter!=s.started[-1]: return false
	var m: Dictionary = data.missions
	for id in ChapterCatalog.DEFINITIONS:
		if not voices and id==ChapterCatalog.STATION: continue
		var done: bool = ChapterCatalog.DEFINITIONS[id].missions.all(func(key): return m.states[key]==3)
		if done!=(id in s.completed): return false
	if ChapterCatalog.MARKET in s.started and ChapterCatalog.FIRST not in s.completed: return false
	if s.station_hint!=(ChapterCatalog.MARKET in s.completed): return false
	if voices and not _station_story(data): return false
	var market := MarketHistory.world(data)
	if (ChapterCatalog.MARKET in s.started)!=(not market.is_empty()): return false
	var unavailable := MarketHistory.unavailable_types(market)
	if not s.legacy_waivers.all(func(id): return id in unavailable): return false
	for id in ["runner","resistant"]:
		var expected := MarketHistory.kills(market,id)
		if id in s.legacy_waivers: expected=1
		if m.totals.get("market_"+id+"_kills",0)!=expected: return false
	if not number(m.totals.get("market_runner_seen",0),0,1,true): return false
	if m.totals.get("market_runner_kills",0)>0 and m.totals.get("market_runner_seen",0)!=1: return false
	for key in ChapterCatalog.POINT_EVENTS.values()+["market_listen","market_container"]:
		if not number(m.totals.get(key,0),0,1,true): return false
	if m.totals.get("market_listen",0)>m.totals.get("market_repeater",0): return false
	var radio_event := {"market_record":"market_record","market_comms":"market_comms","market_power":"market_power","market_final":"market_repeater"}
	if m.radio.transmission in radio_event and m.totals.get(radio_event[m.radio.transmission],0)!=1: return false
	if m.radio.transmission=="station_intro":
		var station_world: Dictionary = data.world if data.map==ZoneCatalog.STATION else data.zones.get(ZoneCatalog.STATION,{})
		if data.version<4 or station_world.is_empty() or "station_radio" not in station_world.interactions: return false
	for item in ["water","medkit"]:
		if m.totals.get("market_"+item,0)>0 and not MarketHistory.recovered(market,item): return false
	if m.totals.get("market_container",0)>0 and (market.is_empty() or not market.containers.market_medical.opened): return false
	return true

static func _perimeter(data: Dictionary) -> bool:
	var world: Dictionary = data.world if data.map==ZoneCatalog.PERIMETER else data.zones.get(ZoneCatalog.PERIMETER,{})
	if not world.is_empty() and ZoneCatalog.PERIMETER not in data.missions.unlocked_zones: return false
	var transmission: String=data.missions.radio.transmission
	if transmission in SaveCatalog.PERIMETER_RADIOS:
		if world.is_empty() or transmission not in world.interactions: return false
	return true

static func _station_story(data: Dictionary) -> bool:
	var s: Dictionary = data.story
	var m: Dictionary = data.missions
	var world: Dictionary = data.world if data.map==ZoneCatalog.STATION else data.zones.get(ZoneCatalog.STATION,{})
	if (ChapterCatalog.STATION in s.started)!=not world.is_empty(): return false
	if ChapterCatalog.STATION in s.started and ChapterCatalog.MARKET not in s.completed: return false
	if not s.perimeter_hint is bool or s.perimeter_hint!=(ChapterCatalog.STATION in s.completed): return false
	if int(m.totals.get("station_kills",0))!=int(world.get("kills",0)): return false
	for definition in SaveCatalog.MISSIONS.slice(7):
		for index in range(definition.objectives.size()):
			var objective: MissionObjective = definition.objectives[index]
			var event := String(objective.event_key)
			if event=="station_kills": continue
			var total: Variant = m.totals.get(event,0)
			if not number(total,0,1,true) or total!=m.progress[String(definition.id)][index]: return false
			var receipt := event+":"+event
			if event=="station_hidden_listen": receipt=event+":station_hidden"
			if event=="station_final_listen": receipt=event+":station_final"
			if (total==1)!=(receipt in m.receipts): return false
	var events := {"station_records":"station_log","station_power":"station_secondary","station_hidden":"station_link","station_final":"station_broadcast"}
	if m.radio.transmission in events:
		if m.totals.get(events[m.radio.transmission],0)!=1: return false
		if m.radio.transmission=="station_hidden" and m.totals.get("station_hidden_listen",0)!=0: return false
		if m.radio.transmission=="station_final" and m.totals.get("station_final_listen",0)!=0: return false
	return true
