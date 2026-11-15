extends RefCounted
## Construye formatos históricos exactos, sin campos añadidos por fases nuevas.
static func convert(source: Dictionary, version: int) -> Dictionary:
	var data := source.duplicate(true)
	data.version = version
	if data.has("world"): data.world.erase("interactions")
	for state in data.get("zones",{}).values(): state.erase("interactions")
	data.missions.unlocked_zones = data.missions.unlocked_zones.filter(func(id):return id!=ZoneCatalog.STATION)
	if version==3: return data

	data.chapter = "signal_lost"
	data.erase("story")
	for id in data.missions.states.keys():
		if id not in ["signal","supplies","broadcast"]:
			data.missions.states.erase(id)
			data.missions.progress.erase(id)
	data.missions.awarded = data.missions.awarded.filter(func(id): return id in ["signal","supplies","broadcast"])
	for event in data.missions.totals.keys():
		if String(event).begins_with("market_"): data.missions.totals.erase(event)
	data.missions.receipts = data.missions.receipts.filter(func(r):return not r.begins_with("market_"))
	if String(data.missions.radio.transmission).begins_with("market_"): data.missions.radio={"transmission":"","index":0}
	if version==1:
		data.erase("zones")
		data.erase("stats")
		data.missions.unlocked_zones=[]
	return data
