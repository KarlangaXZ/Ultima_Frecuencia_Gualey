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
	return data
