class_name PlayerState
extends State


var root : GamePlayer


func enter() -> void:
	root = fsm.root


func _jump():
	root.velocity.y = root.jump_velocity
	root.jumps_made += 1
	root.coyote_timer.stop()


func _ledge_hop():
	root.velocity.y = root.jump_velocity


func _get_gravity() -> float:
	return root.jump_gravity if root.velocity.y < 0.0 else root.fall_gravity


func _apply_coyote_time():
	if root.coyote_timer.is_stopped() and not root.had_coyote_time and not root.has_jumped:
		root.coyote_timer.start()
		root.velocity.y = 0
		root.had_coyote_time = true


func _apply_gravity(delta):
	if root.coyote_timer.is_stopped():
		root.velocity.y += _get_gravity() * delta
		root.velocity.y = clamp(root.velocity.y, root.y_velocity_clamp_min, root.y_velocity_clamp_max)


func _get_x_input() -> float:
	return Input.get_action_strength("right") - Input.get_action_strength("left")


func _get_direction() -> Vector2:
	return Vector2(_get_x_input(), -1.0 if Input.is_action_just_pressed("jump") and fsm.root.has_jumped else 1.0)


