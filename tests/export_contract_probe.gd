extends SceneTree
## Contrato de datos: generar desde fuentes, contrastar desde PCK aislado.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var catalog=load("res://scripts/save/save_catalog.gd")
	var zones=load("res://scripts/zones/zone_catalog.gd")
	var data={"radios":{},"missions":{},"zones":{},"loot":{},"geometry":{}}
	for key in catalog.TRANSMISSIONS:
		var radio=catalog.TRANSMISSIONS[key]
		data.radios[key]={"sender":radio.sender,"messages":Array(radio.messages)}
	for mission in catalog.MISSIONS:
		var objectives=[]
		for o in mission.objectives:objectives.append([String(o.event_key),o.target,o.historical,o.description])
		data.missions[String(mission.id)]={"chapter":String(mission.chapter_id),"xp":mission.reward_xp,"prerequisites":mission.prerequisites,"sequential":mission.sequential,"objectives":objectives}
	for key in zones.DEFINITIONS:
		var zone=zones.DEFINITIONS[key]
		data.zones[key]={"entries":zone.entries,"connections":zone.connections,"weights":zone.enemy_weights,"spawn_points":zone.spawn_points,"initial":zone.initial_enemies,"limit":zone.active_limit,"budget":zone.total_budget,"interval":zone.replacement_interval}
		var world=zone.world_scene.instantiate()
		data.geometry[key]={}
		for obstacle in world.get_node("Obstacles").get_children():
			var collider=obstacle.get_node("CollisionShape2D")
			data.geometry[key][String(obstacle.name)]=[obstacle.position,collider.position,collider.shape.size]
		data.loot[key]={}
		for node in world.find_children("*","",true,false):
			if node.get_script()==load("res://scripts/world/loot_container.gd"):
				var items=[]
				for item in node.initial_items:items.append(String(item.id))
				data.loot[key][String(node.get_meta("persistence_id"))]={"items":items,"quantities":Array(node.initial_quantities)}
		world.free()
	var normalized=JSON.parse_string(JSON.stringify(data,"",true,true))
	var path: String=get_script().resource_path.get_base_dir().get_base_dir().path_join("test-results/phase-seventeen/export-contract.json")
	if "--write" in OS.get_cmdline_user_args():
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(normalized,"\t"))
		print("Resultado contrato fuente: 1 comprobaciones, 0 fallos")
		quit()
		return
	var expected=JSON.parse_string(FileAccess.get_file_as_string(path))
	var checks=0
	var failures=0
	for group in expected:
		for id in expected[group]:
			checks+=1
			if normalized[group].get(id)!=expected[group][id]:
				failures+=1
				push_error("Diferencia empaquetada: "+group+"/"+id)
				if group=="geometry":
					for key in expected[group][id]:
						if normalized[group][id].get(key)!=expected[group][id][key]:print(key," esperado=",expected[group][id][key]," real=",normalized[group][id].get(key))
	print("Resultado contrato PCK: ",checks," comprobaciones, ",failures," fallos")
	quit(0 if failures==0 else 1)
