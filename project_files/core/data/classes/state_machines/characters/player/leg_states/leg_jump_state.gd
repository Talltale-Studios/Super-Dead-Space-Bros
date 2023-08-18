class_name GamePlayerLegJumpState
extends GamePlayerLegState


func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		actor.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		actor.legs_sprite.flip_h = true
	
	# Jumping and state switching
	if actor.can_jump:
		if actor.is_on_floor() or not actor.coyote_timer.is_stopped():
			if not actor.has_jumped:
				_jump()
				actor.has_jumped = true
			else:
				actor.has_jumped = false
				actor.jumps_made = 0
				transition_to("stand")
				return
		else:
			if actor.velocity.y > 0:
				transition_to("fall")
				return
			if Input.is_action_just_pressed("jump"):
				# Coyote Jumping
				if actor.jumps_made < actor.max_jumps and GameSettings.is_coyote_jump_allowed:
					_jump()
	else:
		if actor.velocity.y > 0:
			transition_to("fall")
			return
		else:
			transition_to("stand")
			return
	
	# State animation
	actor.legs_statemachine.travel("jump")
	
	# Movement
	actor.snap_vector = Vector2.ZERO
	actor.velocity.x = lerp(actor.velocity.x, actor.speed * _get_x_input(), actor.accel)
	
	# Gravity
	_apply_gravity(delta)
