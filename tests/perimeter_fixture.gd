extends RefCounted
## Preparación semántica de acceso; el recorrido --perimeter comprueba locomoción.
const F:=preload("res://tests/station_fixture.gd")
static func complete_station(tree: SceneTree) -> void:
	await F.enter(tree)
	var main:=tree.current_scene
	for z in main.get_node("Zombies").get_children():z.set_physics_process(false)
	for z in main.get_node("Zombies").get_children().slice(0,2):z.health.take_damage(500)
	for name in ["Log","Console","Evacuation","Generator","Component","Secondary","Antenna","Link","Broadcast"]:
		var point: Node=main.get_node("World/ChapterPoints/"+name)
		await F.interact(tree,main,point.position+Vector2(0,30))
		F.finish_radio(main)
	await preload("res://tests/archetype_fixture.gd").frames(tree,2)
static func enter(tree: SceneTree) -> bool:
	await complete_station(tree)
	return await F.travel(tree,ZoneCatalog.PERIMETER,"from_station")
