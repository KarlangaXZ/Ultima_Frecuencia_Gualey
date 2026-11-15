class_name ChapterCatalog
extends RefCounted
## Identidades narrativas. Una futura estación es una pista, no una zona cargable.
const FIRST := "signal_lost"
const MARKET := "market_echoes"
const DEFINITIONS := {
	FIRST: {"title":"La señal perdida","number":1,"missions":["signal","supplies","broadcast"]},
	MARKET: {"title":"Ecos del Mercado","number":2,"missions":["market_traces","market_supplies","market_horde","market_frequency"]}}
const POINT_EVENTS := {"market_stall":"market_stall", "market_evacuation":"market_evacuation",
	"market_record":"market_record", "market_comms":"market_comms", "market_power":"market_power",
	"market_repeater":"market_repeater"}
const EVENTS := ["market_stall","market_evacuation","market_record","market_water","market_medkit",
	"market_container","market_runner_seen","market_runner_kills","market_resistant_kills",
	"market_comms","market_power","market_repeater","market_listen"]
static func title(id: String) -> String:
	return DEFINITIONS[id].title if DEFINITIONS.has(id) else "Capítulo desconocido"
