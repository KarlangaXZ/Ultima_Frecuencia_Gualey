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
		for mission in SaveCatalog.MISSIONS.slice(3,7):
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
	if data.version==4:
		data.version=5
		var station: Dictionary = data.world if data.map==ZoneCatalog.STATION else data.zones.get(ZoneCatalog.STATION,{})
		var started := not station.is_empty()
		data.story.perimeter_hint=false
		if started:
			data.story.started.append(ChapterCatalog.STATION)
			data.chapter=ChapterCatalog.STATION
			if station.kills>0: data.missions.totals.station_kills=int(station.kills)
		for mission in SaveCatalog.MISSIONS.slice(7,11):
			data.missions.states[String(mission.id)]=2 if started and mission.id==&"station_records" else 0
			data.missions.progress[String(mission.id)]=mission.objectives.map(func(_o):return 0)
	if data.version==5:
		data.version=6
		if data.missions.states.station_call==3: data.missions.unlocked_zones.append(ZoneCatalog.PERIMETER)
	if data.version==6:
		data.version=7
		var perimeter: Dictionary = data.world if data.map==ZoneCatalog.PERIMETER else data.zones.get(ZoneCatalog.PERIMETER,{})
		var started := not perimeter.is_empty()
		data.story.facility_hint=false
		if started:
			data.story.started.append(ChapterCatalog.CONVOY)
			data.chapter=ChapterCatalog.CONVOY
			var kills := int(perimeter.kills)
			if kills>0: data.missions.totals.convoy_kills=kills
			if kills>=2: data.missions.totals.convoy_security=1
			for pair in [["perimeter_register","convoy_register"],["perimeter_medical","convoy_medical"]]:
				if pair[0] in perimeter.interactions:
					data.missions.totals[pair[1]]=1
					data.missions.receipts.append(pair[1]+":"+pair[1])
		for mission in SaveCatalog.MISSIONS.slice(11):
			var id := String(mission.id)
			data.missions.states[id]=2 if started and id=="convoy_access" else 0
			data.missions.progress[id]=mission.objectives.map(func(o):return int(data.missions.totals.get(String(o.event_key),0)) if started and id=="convoy_access" and o.historical else 0)
	return data
