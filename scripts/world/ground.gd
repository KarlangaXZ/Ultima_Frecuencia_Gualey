extends Node2D
## Depósito urbano evacuado. Solo decoración; no añade colisiones.
@export var asphalt_texture: Texture2D = preload("res://assets/placeholders/environment/tilesets/temp_asphalt.svg")
@export var debris_texture: Texture2D = preload("res://assets/placeholders/environment/decals/temp_debris.svg")

func _draw() -> void:
	draw_texture_rect(asphalt_texture, Rect2(0, 0, 2400, 1600), true)
	for x in range(160, 2320, 240):
		draw_line(Vector2(x, 220), Vector2(x, 420), Color("6b6b54"), 3.0)
		draw_line(Vector2(x, 1300), Vector2(x, 1500), Color("6b6b54"), 3.0)
	for x in range(90, 2350, 100):
		draw_line(Vector2(x, 640), Vector2(x + 46, 640), Color("8d805b"), 4.0)
	draw_rect(Rect2(25, 25, 2350, 1550), Color("778075"), false, 12.0)
	draw_rect(Rect2(36, 36, 2328, 1528), Color("182328"), false, 4.0)
	for y in range(48, 1550, 48):
		draw_line(Vector2(26, y), Vector2(30, y + 18), Color("c5a564"), 6.0)
	var random := RandomNumberGenerator.new()
	random.seed = 404
	for index in range(55):
		var position := Vector2(random.randf_range(80, 2250), random.randf_range(80, 1480))
		draw_texture(debris_texture, position, Color(1, 1, 1, 0.5))
	for position in [Vector2(360, 580), Vector2(1300, 1180), Vector2(2000, 900)]:
		draw_rect(Rect2(position, Vector2(48, 24)), Color("152026"))
		for x in range(5, 44, 6):
			draw_line(position + Vector2(x, 3), position + Vector2(x, 21), Color("526063"), 2.0)
