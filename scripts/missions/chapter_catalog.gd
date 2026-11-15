class_name ChapterCatalog
extends RefCounted
## Identidades narrativas de los cuatro capítulos; cuatro zonas existentes.
const FIRST := "signal_lost"
const MARKET := "market_echoes"
const STATION := "station_voices"
const CONVOY := "last_convoy"
const DEFINITIONS := {
	FIRST: {"title":"La señal perdida","number":1,"missions":["signal","supplies","broadcast"]},
	MARKET: {"title":"Ecos del Mercado","number":2,"missions":["market_traces","market_supplies","market_horde","market_frequency"]},
	STATION: {"title":"Voces en la oscuridad","number":3,"missions":["station_records","station_power","station_frequency","station_call"]},
	CONVOY: {"title":"El último convoy","number":4,"missions":["convoy_access","convoy_stopped","convoy_quarantine","convoy_route"]}}
const CONVOY_POINTS := ["convoy_checkpoint","convoy_authorized","convoy_bus","convoy_vehicle",
	"convoy_destination","convoy_quarantine_record","convoy_security","convoy_orders","convoy_link"]
const CONVOY_EVENTS := CONVOY_POINTS + ["convoy_register","convoy_medical","convoy_comms","convoy_listen","convoy_kills"]
const STATION_POINTS := ["station_log","station_console","station_evacuation","station_generator",
	"station_component","station_secondary","station_antenna","station_link","station_broadcast"]
const STATION_EVENTS := STATION_POINTS + ["station_kills","station_hidden_listen","station_final_listen"]
const POINT_EVENTS := {"market_stall":"market_stall", "market_evacuation":"market_evacuation",
	"market_record":"market_record", "market_comms":"market_comms", "market_power":"market_power",
	"market_repeater":"market_repeater"}
const EVENTS := ["market_stall","market_evacuation","market_record","market_water","market_medkit",
	"market_container","market_runner_seen","market_runner_kills","market_resistant_kills",
	"market_comms","market_power","market_repeater","market_listen"]
static func title(id: String) -> String:
	return DEFINITIONS[id].title if DEFINITIONS.has(id) else "Capítulo desconocido"
