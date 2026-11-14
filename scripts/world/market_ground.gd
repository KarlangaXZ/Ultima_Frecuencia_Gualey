extends Node2D
## Pavimento y señalética técnica; usa texturas existentes, sin arte final nuevo.
const ASPHALT := preload("res://assets/placeholders/environment/tilesets/temp_asphalt.svg")
const DEBRIS := preload("res://assets/placeholders/environment/decals/temp_debris.svg")
func _draw() -> void:
	draw_texture_rect(ASPHALT,Rect2(0,0,2400,1600),true,Color(0.75,0.78,0.75))
	for rect in [Rect2(80,350,2210,70),Rect2(80,1260,2210,55),Rect2(270,430,90,800)]:
		draw_rect(rect,Color("62675e"))
		draw_rect(rect,Color("96917a"),false,3)
	for x in range(380,2180,160): draw_rect(Rect2(x,792,80,5),Color("b8a873"))
	for point in [Vector2(490,650),Vector2(820,1210),Vector2(1800,470),Vector2(2040,1040),Vector2(1350,900),Vector2(1500,1220)]:
		draw_texture_rect(DEBRIS,Rect2(point,Vector2(85,65)),false)
	draw_string(ThemeDB.fallback_font,Vector2(540,440),"MERCADO / ZONA EVACUADA",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("c0af79"))
