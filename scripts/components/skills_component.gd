class_name SkillsComponent
extends Node
## Rangos por instancia. Un gasto válido produce un único cambio semántico.
signal skill_acquired(id: StringName, rank: int)
@export var definitions: Array[SkillDefinition] = [
	preload("res://resources/skills/Vitality.tres"), preload("res://resources/skills/Agility.tres"),
	preload("res://resources/skills/Handling.tres"), preload("res://resources/skills/Survival.tres")]
@export var progression_path: NodePath = ^"../ProgressionComponent"
@onready var progression: ProgressionComponent = get_node(progression_path)
var _ranks: Dictionary = {}
var _allocating := false

func definition(id: StringName) -> SkillDefinition:
	for skill in definitions:
		if skill.id == id: return skill
	return null

func rank_of(id: StringName) -> int:
	return _ranks.get(id, 0)

func can_upgrade(id: StringName) -> bool:
	var skill := definition(id)
	return not _allocating and progression.enabled and progression.available_points > 0 \
		and skill != null and rank_of(id) < mini(5, skill.max_rank)

func upgrade(id: StringName) -> bool:
	if not can_upgrade(id): return false
	_allocating = true
	if not progression.spend_point():
		_allocating = false
		return false
	_ranks[id] = rank_of(id) + 1
	_allocating = false
	skill_acquired.emit(id, rank_of(id))
	return true

func modifier_value(kind: String) -> float:
	var value := 0.0
	for skill in definitions:
		if skill.modifier == kind: value += rank_of(skill.id) * skill.per_rank
	return value

func snapshot() -> Dictionary:
	var result := {}
	for skill in definitions: result[String(skill.id)] = rank_of(skill.id)
	return result
