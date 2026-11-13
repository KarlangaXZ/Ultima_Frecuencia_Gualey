extends "res://scripts/visuals/character_visual.gd"
## Solo presentación. El cooldown de la IA inicia el ciclo visual de ataque.
var previous_cooldown: float = 0.0

func _on_death() -> void:
	super._on_death()
	sprite.speed_scale = 1.0

func _process(delta: float) -> void:
	flash_remaining = maxf(0.0, flash_remaining - delta)
	sprite.modulate = Color(2.0, 0.65, 0.5) if flash_remaining > 0.0 else Color.WHITE
	if dead:
		return
	var cooldown: float = actor.get("cooldown")
	var attacking: bool = actor.get("state") == 2
	var attack_started := attacking and cooldown > previous_cooldown + 0.00001
	previous_cooldown = cooldown
	var direction := actor.velocity
	if attacking and is_instance_valid(actor.get("target")):
		direction = actor.global_position.direction_to(actor.get("target").global_position)
	if not direction.is_zero_approx():
		if absf(direction.x) > absf(direction.y):
			direction_name = "right" if direction.x > 0.0 else "left"
		else:
			direction_name = "down" if direction.y > 0.0 else "up"
	if attacking:
		if attack_started or not String(sprite.animation).begins_with("attack_"):
			var animation_name := "attack_" + direction_name
			sprite.play(animation_name)
			sprite.set_frame_and_progress(0, 0.0)
			var cycle_duration := sprite.sprite_frames.get_frame_count(animation_name) / sprite.sprite_frames.get_animation_speed(animation_name)
			sprite.speed_scale = cycle_duration / actor.get("attack_interval")
			if not attack_started:
				sprite.pause()
				sprite.frame = sprite.sprite_frames.get_frame_count(animation_name) - 1
	else:
		sprite.speed_scale = 1.0
		var state_name := "walk" if actor.velocity.length_squared() > 1.0 else "idle"
		var animation_name := state_name + "_" + direction_name
		if sprite.animation != animation_name:
			sprite.play(animation_name)
	_update_sprite_transform()
