extends Node2D
## Suelo urbano provisional. Solo superficies planas; los sólidos viven en Obstacles.
@export var asphalt_texture: Texture2D = preload("res://assets/placeholders/environment/tilesets/temp_asphalt.svg")
@export var debris_texture: Texture2D = preload("res://assets/placeholders/environment/decals/temp_debris.svg")

func _draw() -> void:
	draw_texture_rect(asphalt_texture, Rect2(0, 0, 2400, 1600), true)
	# Aceras transitables: no simulan muros ni añaden barreras invisibles.
	for area in [Rect2(24, 24, 2352, 300), Rect2(24, 1328, 2352, 248),
		Rect2(24, 324, 328, 356), Rect2(380, 350, 382, 290),
		Rect2(24, 944, 270, 384), Rect2(2080, 324, 296, 356), Rect2(2080, 930, 296, 398)]:
		_draw_sidewalk(area)
	for x in range(70, 2340, 110):
		draw_line(Vector2(x, 862), Vector2(x + 42, 862), Color("95865d"), 3)
	# Paso de cebra desgastado; pintura sin colisión.
	for y in range(710, 830, 22):
		draw_rect(Rect2(940, y, 86, 11), Color("a4a38a", 0.55))
	for center in [Vector2(515, 930), Vector2(1320, 620), Vector2(1980, 1150)]:
		draw_circle(center, 31, Color("131d21", 0.35))
		draw_arc(center, 38, 0.1, 4.5, 14, Color("454c43"), 2)
	var random := RandomNumberGenerator.new()
	random.seed = 404
	for index in range(55):
		var position := Vector2(random.randf_range(80, 2250), random.randf_range(80, 1480))
		draw_texture(debris_texture, position, Color(1, 1, 1, 0.5))
	for position in [Vector2(360, 580), Vector2(1300, 1180), Vector2(2000, 900)]:
		draw_rect(Rect2(position, Vector2(48, 24)), Color("152026"))
		for x in range(5, 44, 6):
			draw_line(position + Vector2(x, 3), position + Vector2(x, 21), Color("526063"), 2.0)
	# Nombres pintados sobre pavimento: identidad local ficticia, no cartografía real.
	draw_string(ThemeDB.fallback_font, Vector2(420, 1010), "GUALEY / ZONA EVACUADA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9d9b7e", 0.65))
	draw_rect(Rect2(24, 24, 2352, 1552), Color("797b67"), false, 4)

func _draw_sidewalk(area: Rect2) -> void:
	draw_rect(area, Color("626b65"))
	draw_rect(area.grow(-5), Color("777b6c"))
	for x in range(int(area.position.x) + 32, int(area.end.x), 48):
		draw_line(Vector2(x, area.position.y + 5), Vector2(x, area.end.y - 5), Color("666e64"), 1)
	for y in range(int(area.position.y) + 32, int(area.end.y), 48):
		draw_line(Vector2(area.position.x + 5, y), Vector2(area.end.x - 5, y), Color("666e64"), 1)
