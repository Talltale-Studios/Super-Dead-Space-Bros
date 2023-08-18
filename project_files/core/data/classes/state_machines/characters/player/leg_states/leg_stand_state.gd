class_name GamePlayerLegStandState
extends GamePlayerLegState


func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		actor.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		actor.legs_sprite.flip_h = true
	
	# State switching
	if not is_zero_approx(_get_x_input()):
		transition_to("run")
		return
	if Input.is_action_just_pressed("jump"):
		transition_to("jump")
		return
	if actor.is_on_floor() and Input.is_action_just_pressed("down"):
		transition_to("crouch")
		return
	if not actor.is_on_floor():
		_apply_coyote_time()
		transition_to("fall")
		return
	
	# State animation
	actor.legs_statemachine.travel("stand")
	
	# Movement
	actor.snap_vector = Vector2.DOWN
	actor.velocity.x = lerp(actor.velocity.x, 0.0, actor.fric)
	
	# Gravity
	_apply_gravity(delta)
