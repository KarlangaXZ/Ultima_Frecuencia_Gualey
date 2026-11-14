class_name WorldPickup
extends Area2D
@export var item: ItemDefinition
@export_range(1, 1000) var quantity: int = 1
var claimed := false

func _ready() -> void:
	if item != null: $Sprite.texture = item.icon

func interaction_name() -> String:
	return "%s ×%d" % [item.display_name, quantity] if item != null else "Objeto no disponible"

func try_collect(inventory: InventoryComponent) -> String:
	if claimed or item == null or not is_inside_tree(): return ""
	# Reservar antes de emitir inventory.changed: ni señales reentrantes duplican.
	claimed = true
	if not inventory.add_item(item, quantity):
		claimed = false
		return "Mochila llena: necesitas espacio para toda la recogida."
	hide()
	set_deferred("collision_layer", 0)
	queue_free()
	return "Recogido: " + interaction_name()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 18, Color(0.06, 0.11, 0.12, 0.9))
	draw_arc(Vector2.ZERO, 20, 0, TAU, 24, Color("b5a46f"), 1)
