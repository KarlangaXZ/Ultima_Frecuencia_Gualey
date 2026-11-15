extends Node2D
## Suelo/cables pintados estáticos; sin luces dinámicas ni física adicional.
const ASPHALT:=preload("res://assets/placeholders/environment/tilesets/temp_asphalt.svg")
const DEBRIS:=preload("res://assets/placeholders/environment/decals/temp_debris.svg")
func _draw() -> void:
	draw_texture_rect(ASPHALT,Rect2(0,0,2400,1600),true,Color(0.9,0.92,0.96))
	for area in [Rect2(180,710,2040,180),Rect2(830,180,920,500),Rect2(400,1140,1700,240),Rect2(1780,240,380,420)]:
		draw_rect(area,Color("777d83"))
		draw_rect(area.grow(-10),Color("aaa8a2"),false,2)
	draw_rect(Rect2(920,260,760,340),Color("434d59"))
	for x in range(960,1660,80):draw_line(Vector2(x,265),Vector2(x,598),Color("505b67"),1)
	for y in range(300,590,60):draw_line(Vector2(922,y),Vector2(1678,y),Color("505b67"),1)
	draw_rect(Rect2(1020,840,360,360),Color("62656a"))
	draw_rect(Rect2(1030,850,340,340),Color("bba25d"),false,3)
	for x in range(300,2200,120):draw_rect(Rect2(x,795,55,5),Color("bcb67a"))
	for y in range(870,1200,20):draw_rect(Rect2(1020,y,15,8),Color("c1ac65"))
	for segment in [[Vector2(1200,1020),Vector2(1400,1020)],[Vector2(1400,1020),Vector2(1400,640)],[Vector2(1400,640),Vector2(1860,640)]]:
		draw_line(segment[0],segment[1],Color("1c303c"),5)
		draw_line(segment[0]+Vector2(4,4),segment[1]+Vector2(4,4),Color("a49778"),2)
	for p in [Vector2(600,950),Vector2(790,1250),Vector2(1730,730),Vector2(2050,1300)]:draw_texture_rect(DEBRIS,Rect2(p,Vector2(85,65)),false)
	for pair in [[Vector2(940,290),"COMUNICACIONES / SANTO DOMINGO"],[Vector2(1040,1190),"ANTENA PRINCIPAL / RF"],[Vector2(1810,590),"PELIGRO / ALTA TENSIÓN"],[Vector2(420,1340),"EVACUACIÓN INTERRUMPIDA"],[Vector2(930,1470),"ESTACIÓN DE COMUNICACIONES"]]:
		draw_string(ThemeDB.fallback_font,pair[0],pair[1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b9c4ac"))
