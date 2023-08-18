class_name GamePlayerLegFallState
extends GamePlayerLegState


func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		actor.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		actor.legs_sprite.flip_h = true
	
	# Jumping and state switching
	if actor.can_jump:
		if actor.is_on_floor():
			actor.had_coyote_time = false
			actor.has_jumped = false
			actor.jumps_made = 0
			# Transition to the 'jump' state if a jump is buffered and if allowed
			if actor.buffered_jump:
				actor.buffered_jump = false
				if GameSettings.is_buffered_jump_allowed:
					transition_to("jump")
				return
			# Else, transition to the 'stand' state
			else:
				transition_to("stand")
				return
		else:
			if not is_zero_approx(_get_x_input()):
				actor.legs_statemachine.travel("run")
			else:
				actor.legs_statemachine.travel("stand")
			if Input.is_action_just_pressed("jump"):
				# Coyote Jumping
				if actor.jumps_made < actor.max_jumps and GameSettings.is_coyote_jump_allowed:
					_jump()
				# Jump Buffering
				if GameSettings.is_jump_buffering_allowed:
					if actor.jumps_made >= actor.max_jumps:
						actor.jump_buffer_timer.start()
						actor.buffered_jump = true
	else:
		if actor.is_on_floor():
			transition_to("stand")
			return

	# State animation
	if actor.coyote_timer.is_stopped():
		actor.legs_statemachine.travel("fall")

	# Movement
	actor.snap_vector = Vector2.ZERO
	actor.velocity.x = lerp(actor.velocity.x, actor.speed * _get_x_input(), actor.accel)

	# Gravity
	_apply_gravity(delta)
