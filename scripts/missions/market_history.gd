class_name MarketHistory
extends RefCounted
## Consulta pura del historial conservado en WorldSaveState, sin nuevos enemigos.
static func world(data: Dictionary) -> Dictionary:
	return data.world if data.map == ZoneCatalog.MARKET else data.get("zones",{}).get(ZoneCatalog.MARKET,{})
static func kills(state: Dictionary, type_id: String) -> int:
	return state.get("zombies",[]).filter(func(z): return z.type==type_id and z.health<=0).size()
static func unavailable_types(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if state.is_empty(): return result
	var zone := ZoneCatalog.definition(ZoneCatalog.MARKET)
	for type_id in ["runner","resistant"]:
		var present: bool = state.zombies.any(func(z): return z.type==type_id)
		for ordinal in range(int(state.population.spawned)+1,zone.total_budget+1):
			if String(zone.archetype_for(ordinal).id)==type_id: present=true
		if not present: result.append(type_id)
	return result
static func recovered(state: Dictionary, item: String) -> bool:
	if state.is_empty(): return false
	if not state.pickups.get("market_"+item,true): return true
	# Únicas existencias originales pertinentes. Una transferencia válida reduce
	# la pila del mundo; consumir después en mochila no revierte esta evidencia.
	var sources := [["market_medical",0,2]] if item=="medkit" else [["market_medical",1,1],["market_food",1,2]]
	for source in sources:
		var slot: Dictionary = state.containers[source[0]].slots[source[1]]
		if slot.is_empty() or slot.get("item","")!=item or slot.quantity<source[2]: return true
	return false
