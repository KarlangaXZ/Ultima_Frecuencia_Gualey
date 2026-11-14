class_name LootContainer
extends Area2D
var opened := false
@export var display_name: String = "Suministros"
@export var icon: Texture2D
@export var initial_items: Array[ItemDefinition] = []
@export var initial_quantities: PackedInt32Array = []
@onready var inventory: InventoryComponent = $InventoryComponent

func _ready() -> void:
	$Sprite.texture = icon
	if initial_items.size() != initial_quantities.size():
		push_error("Contenedor con cantidades incompatibles: " + name)
		return
	for index in range(initial_items.size()):
		if not inventory.add_item(initial_items[index], initial_quantities[index]):
			push_error("Contenido inicial inválido o excesivo: " + name)

func interaction_name() -> String:
	return display_name + (" (vacío)" if inventory.occupied_slots() == 0 else "")

func _draw() -> void:
	draw_rect(Rect2(-25, -21, 50, 42), Color("1c302f"))
	draw_rect(Rect2(-25, -21, 50, 42), Color("b5a46f"), false, 2)
