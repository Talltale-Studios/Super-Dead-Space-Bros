class_name GamePlayerState
extends GameCharacterState


func _jump():
	actor.velocity.y = actor.jump_velocity
	actor.jumps_made += 1
	actor.coyote_timer.stop()


func _ledge_hop():
	actor.velocity.y = actor.jump_velocity


func _get_gravity() -> float:
	return actor.jump_gravity if actor.velocity.y < 0.0 else actor.fall_gravity


func _apply_coyote_time():
	if GameSettings.is_coyote_time_allowed:
		if actor.coyote_timer.is_stopped() and not actor.had_coyote_time and not actor.has_jumped:
			actor.coyote_timer.start()
			actor.velocity.y = 0
			actor.had_coyote_time = true


func _apply_gravity(delta):
	if actor.coyote_timer.is_stopped():
		actor.velocity.y += _get_gravity() * delta


func _get_x_input() -> float:
	return Input.get_action_strength("right") - Input.get_action_strength("left")


func _get_direction() -> Vector2:
	return Vector2(_get_x_input(), -1.0 if Input.is_action_just_pressed("jump") and state_machine.actor.has_jumped else 1.0)


