extends Node
## Recalcula desde bases y rangos: nunca suma bonificaciones sobre valores efectivos.
@onready var actor: Node = get_parent()
@onready var skills: SkillsComponent = $"../SkillsComponent"
@onready var equipment: EquipmentComponent = $"../Equipment"

func _ready() -> void:
	skills.skill_acquired.connect(func(_id: StringName, _rank: int): refresh())
	equipment.arsenal_changed.connect(refresh)
	refresh()

func refresh() -> void:
	actor.get_node("HealthComponent").set_max_health_bonus(skills.modifier_value("max_health"))
	actor.movement_multiplier = 1.0 + skills.modifier_value("movement")
	actor.get_node("SurvivalComponent").consumption_multiplier = maxf(0.1, 1.0 - skills.modifier_value("consumption"))
	var reload_multiplier := maxf(0.1, 1.0 - skills.modifier_value("reload"))
	for weapon in equipment.get_weapons():
		if weapon.config.weapon_type != "melee": weapon.set_reload_multiplier(reload_multiplier)
