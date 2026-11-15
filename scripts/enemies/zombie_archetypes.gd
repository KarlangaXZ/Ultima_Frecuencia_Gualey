class_name ZombieArchetypes
extends RefCounted
const ORDER := ["base","runner","resistant"]
const DEFINITIONS := {"base": preload("res://resources/enemies/Common.tres"),
	"runner": preload("res://resources/enemies/Runner.tres"), "resistant": preload("res://resources/enemies/Resistant.tres")}
static func definition(id: String) -> ZombieArchetype:
	return DEFINITIONS.get(id)
static func valid_weights(weights: Dictionary) -> bool:
	var total := 0
	for id in weights:
		if id not in ORDER or not weights[id] is int or weights[id] < 0: return false
		total += weights[id]
	return total > 0
static func choose(weights: Dictionary, ordinal: int) -> ZombieArchetype:
	if ordinal < 1 or not valid_weights(weights): return definition("base")
	var counts := {"base":0,"runner":0,"resistant":0}
	var total := 0
	for weight in weights.values(): total += weight
	var selected := "base"
	for step in range(1,ordinal + 1):
		var best := -INF
		for id in ORDER:
			var weight: int = weights.get(id,0)
			if weight == 0: continue
			var deficit: int = weight * step - counts[id] * total
			if deficit > best or (deficit == best and counts[id] < counts[selected]):
				selected = id
				best = deficit
		counts[selected] += 1
	return definition(selected)
