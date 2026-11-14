class_name ItemDefinition
extends Resource
## Configuración compartida, inmutable durante la partida.
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: StringName
@export var icon: Texture2D
@export_range(1, 1000) var max_stack: int = 10
@export_enum("health", "hunger", "thirst", "ammo") var effect: String = "health"
@export_range(0.01, 1000.0) var effect_amount: float = 30.0

func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and max_stack > 0 and effect_amount > 0
