class_name SaveMigration
extends RefCounted
## v1 ya fue validado antes de migrar. El archivo original no se reescribe al leer.
static func to_current(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	if data.version == 1:
		data.version = 2
		data.zones = {}
		data.stats = {"kills": int(data.world.kills),"survival_time": data.world.survival_time}
		if data.missions.states.broadcast == 3: data.missions.unlocked_zones = [ZoneCatalog.MARKET]
	if data.version == 2:
		data.version = 3
		var market := MarketHistory.world(data)
		var started := not market.is_empty()
		data.chapter = ChapterCatalog.MARKET if started else ChapterCatalog.FIRST
		data.story = {"started":[ChapterCatalog.FIRST],"completed":[],"legacy_waivers":MarketHistory.unavailable_types(market),"station_hint":false}
		if data.missions.states.broadcast==3: data.story.completed.append(ChapterCatalog.FIRST)
		if started: data.story.started.append(ChapterCatalog.MARKET)
		for mission in SaveCatalog.MISSIONS.slice(3):
			data.missions.states[String(mission.id)] = 2 if started and mission.id==&"market_traces" else 0
			data.missions.progress[String(mission.id)] = mission.objectives.map(func(_o): return 0)
		if started:
			for type_id in ["runner","resistant"]:
				var count := MarketHistory.kills(market,type_id)
				if type_id in data.story.legacy_waivers: count=1
				if count>0: data.missions.totals["market_"+type_id+"_kills"]=count
			if data.missions.totals.get("market_runner_kills",0)>0: data.missions.totals["market_runner_seen"]=1
			for item in ["water","medkit"]:
				if MarketHistory.recovered(market,item): data.missions.totals["market_"+item]=1
			if market.containers.market_medical.opened: data.missions.totals.market_container=1
	if data.version==3:
		data.version=4
		data.world.interactions=[]
		for state in data.zones.values(): state.interactions=[]
		if data.missions.states.market_frequency==3: data.missions.unlocked_zones.append(ZoneCatalog.STATION)
	return data
