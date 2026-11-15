extends RefCounted
## Construye formatos históricos exactos, sin campos añadidos por fases nuevas.
static func convert(source: Dictionary, version: int) -> Dictionary:
	var data := source.duplicate(true)
	data.version = version
	# v6 tiene cuatro mapas, pero todavía once misiones y tres capítulos.
	if data.has("story"):
		data.story.erase("facility_hint")
		data.story.started=data.story.started.filter(func(id):return id!=ChapterCatalog.CONVOY)
		data.story.completed=data.story.completed.filter(func(id):return id!=ChapterCatalog.CONVOY)
	if data.get("chapter","")==ChapterCatalog.CONVOY: data.chapter=ChapterCatalog.STATION
	for id in data.missions.states.keys():
		if String(id).begins_with("convoy_"):
			data.missions.states.erase(id)
			data.missions.progress.erase(id)
	data.missions.awarded=data.missions.awarded.filter(func(id):return not String(id).begins_with("convoy_"))
	for event in data.missions.totals.keys():
		if String(event).begins_with("convoy_"): data.missions.totals.erase(event)
	data.missions.receipts=data.missions.receipts.filter(func(r):return not r.begins_with("convoy_"))
	if data.missions.radio.transmission in SaveCatalog.CONVOY_RADIOS: data.missions.radio={"transmission":"","index":0}
	if version==6: return data
	data.missions.unlocked_zones=data.missions.unlocked_zones.filter(func(id):return id!=ZoneCatalog.PERIMETER)
	if data.missions.radio.transmission in SaveCatalog.PERIMETER_RADIOS: data.missions.radio={"transmission":"","index":0}
	if version==5: return data
	# v4 conserva tres mapas/introducción, pero aún no tiene el capítulo 3.
	if data.has("story"):
		data.story.erase("perimeter_hint")
		data.story.started=data.story.started.filter(func(id):return id!=ChapterCatalog.STATION)
		data.story.completed=data.story.completed.filter(func(id):return id!=ChapterCatalog.STATION)
	if data.get("chapter","")==ChapterCatalog.STATION: data.chapter=ChapterCatalog.MARKET
	for id in data.missions.states.keys():
		if String(id).begins_with("station_"):
			data.missions.states.erase(id)
			data.missions.progress.erase(id)
	data.missions.awarded=data.missions.awarded.filter(func(id):return not String(id).begins_with("station_"))
	for event in data.missions.totals.keys():
		if String(event).begins_with("station_"): data.missions.totals.erase(event)
	data.missions.receipts=data.missions.receipts.filter(func(r):return not r.begins_with("station_"))
	if data.missions.radio.transmission in ["station_records","station_power","station_hidden","station_final"]: data.missions.radio={"transmission":"","index":0}
	if version==4: return data
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
