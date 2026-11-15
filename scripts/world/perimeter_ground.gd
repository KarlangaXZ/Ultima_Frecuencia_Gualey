extends Node2D
## Plano de evacuación estático: ruta norte/sur, carriles, triaje y patios laterales.
const ASPHALT:=preload("res://assets/placeholders/environment/tilesets/temp_asphalt.svg")
const DEBRIS:=preload("res://assets/placeholders/environment/decals/temp_debris.svg")
func _draw() -> void:
	draw_rect(Rect2(0,0,2400,1600),Color("5c5146"))
	for r in [Rect2(220,180,650,1200),Rect2(1620,180,550,1200)]:
		draw_rect(r,Color("999187"))
		draw_rect(r.grow(-8),Color("b8afa3"),false,2)
	draw_texture_rect(ASPHALT,Rect2(940,160,520,1300),true,Color("b9b8b5"))
	for y in [400,900,1330]:draw_rect(Rect2(220,y,1950,100),Color("777775"))
	for x in [960,1440]:draw_line(Vector2(x,180),Vector2(x,1440),Color("d8c487"),4)
	for y in range(350,1430,100):
		draw_rect(Rect2(1196,y,8,45),Color("d8c487"))
	for y in [980,1200,1380]:
		draw_polyline(PackedVector2Array([Vector2(1170,y),Vector2(1200,y-30),Vector2(1230,y)]),Color("d8c487"),5)
	for x in range(980,1430,30):draw_rect(Rect2(x,1280,15,40),Color("bfc0a3"))
	for y in range(520,1060,80):draw_rect(Rect2(260,y,380,45),Color("b7afa0"),false,2)
	for x in range(1650,2150,80):draw_rect(Rect2(x,580,50,240),Color("d4b46a"),false,2)
	# Líneas de espera y manchas son transitables; toda física está en Obstacles.
	for y in range(180,1420,70):
		draw_rect(Rect2(180,y,18,32),Color("bd8a4f"))
		draw_rect(Rect2(2200,y,18,32),Color("bd8a4f"))
	for p in [Vector2(620,920),Vector2(1300,740),Vector2(970,530),Vector2(1800,1130),Vector2(820,1040)]:
		draw_texture_rect(DEBRIS,Rect2(p,Vector2(80,55)),false,Color("c6ba9b"))
	for entry in [[Vector2(970,1530),"REGRESO A LA ESTACIÓN"],[Vector2(980,205),"PERÍMETRO / CONVOY NORTE"],[Vector2(270,280),"ATENCIÓN MÉDICA"],[Vector2(1720,245),"CONTROL DE ACCESO"],[Vector2(1630,855),"REVISIÓN"],[Vector2(980,1260),"EVACUACIÓN"]]:
		draw_string(ThemeDB.fallback_font,entry[0],entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ded1a7"))
