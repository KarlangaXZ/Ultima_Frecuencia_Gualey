class_name SaveCatalog
extends RefCounted
## Lista de contenido confiable. Nunca se cargan rutas procedentes del JSON.
const ITEMS := {
	"medkit": preload("res://resources/items/Medkit.tres"), "water": preload("res://resources/items/Water.tres"),
	"food": preload("res://resources/items/Food.tres"), "pistol_ammo": preload("res://resources/items/PistolAmmo.tres"),
	"weapon_machete": preload("res://resources/items/Machete.tres"), "weapon_revolver": preload("res://resources/items/Revolver.tres"),
	"weapon_shotgun": preload("res://resources/items/Shotgun.tres"), "revolver_ammo": preload("res://resources/items/RevolverAmmo.tres"),
	"shotgun_ammo": preload("res://resources/items/ShotgunAmmo.tres")}
const WEAPONS := {"pistol": preload("res://resources/weapons/BasicPistol.tres"),
	"machete": preload("res://resources/weapons/Machete.tres"), "revolver": preload("res://resources/weapons/Revolver.tres"),
	"shotgun": preload("res://resources/weapons/Shotgun.tres")}
const MISSIONS := [preload("res://resources/missions/Signal.tres"), preload("res://resources/missions/Supplies.tres"), preload("res://resources/missions/Broadcast.tres"), preload("res://resources/missions/MarketTraces.tres"), preload("res://resources/missions/MarketSupplies.tres"), preload("res://resources/missions/MarketHorde.tres"), preload("res://resources/missions/MarketFrequency.tres"), preload("res://resources/missions/StationRecords.tres"), preload("res://resources/missions/StationPower.tres"), preload("res://resources/missions/StationFrequency.tres"), preload("res://resources/missions/StationCall.tres")]
const TRANSMISSIONS := {"first": preload("res://resources/radio/FirstSignal.tres"),
	"power": preload("res://resources/radio/PowerRestored.tres"), "final": preload("res://resources/radio/FirstBroadcast.tres"), "market_record": preload("res://resources/radio/MarketRecord.tres"), "market_comms": preload("res://resources/radio/MarketComms.tres"), "market_power": preload("res://resources/radio/MarketPower.tres"), "market_final": preload("res://resources/radio/MarketFinal.tres"), "station_intro": preload("res://resources/radio/StationIntro.tres"), "station_records": preload("res://resources/radio/StationRecords.tres"), "station_power": preload("res://resources/radio/StationPower.tres"), "station_hidden": preload("res://resources/radio/StationHidden.tres"), "station_final": preload("res://resources/radio/StationFinal.tres"), "perimeter_intro":preload("res://resources/radio/PerimeterIntro.tres"), "perimeter_medical":preload("res://resources/radio/PerimeterMedical.tres"), "perimeter_register":preload("res://resources/radio/PerimeterRegister.tres"), "perimeter_comms":preload("res://resources/radio/PerimeterComms.tres")}
const PERIMETER_RADIOS := {"perimeter_intro":preload("res://resources/radio/PerimeterIntro.tres"),"perimeter_medical":preload("res://resources/radio/PerimeterMedical.tres"),"perimeter_register":preload("res://resources/radio/PerimeterRegister.tres"),"perimeter_comms":preload("res://resources/radio/PerimeterComms.tres")}
const PICKUPS := ["pickup_water", "pickup_medkit", "pickup_food", "pickup_ammo"]
const CONTAINERS := ["supply_crate", "medical_case", "abandoned_bag", "revolver_case", "shotgun_case"]
const SKILLS := ["vitality", "agility", "handling", "survival"]

static func id_of(node: Node) -> String:
	return String(node.get_meta("persistence_id", "session:%d" % node.get_instance_id()))

static func find(root: Node, id: String) -> Node:
	if String(root.get_meta("persistence_id", "")) == id: return root
	for child in root.get_children():
		var found := find(child, id)
		if found != null: return found
	return null

static func slots(inventory: InventoryComponent) -> Array:
	var result := []
	for index in range(inventory.capacity):
		var slot := inventory.get_slot(index)
		result.append({} if slot.is_empty() else {"item": String(slot.item.id), "quantity": slot.quantity})
	return result

static func restore_slots(inventory: InventoryComponent, data: Array) -> void:
	# Adaptador versionado: copia exacta de pilas, sin emitir eventos de recogida.
	inventory._slots.clear()
	for slot in data:
		inventory._slots.append({} if slot.is_empty() else {"item": ITEMS[slot.item], "quantity": int(slot.quantity)})
