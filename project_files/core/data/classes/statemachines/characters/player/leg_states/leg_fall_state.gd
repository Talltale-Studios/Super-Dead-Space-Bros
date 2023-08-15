class_name GamePlayerLegFallState
extends GamePlayerLegState


func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		root.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		root.legs_sprite.flip_h = true
	
	# Jumping and state switching
	if root.can_jump:
		if root.is_on_floor():
			root.had_coyote_time = false
			root.has_jumped = false
			root.jumps_made = 0
			if root.buffered_jump:
				root.buffered_jump = false
				exit_state("jump")
				return
			else:
				exit_state("stand")
				return
		else:
			if not is_zero_approx(_get_x_input()):
				root.legs_statemachine.travel("run")
			else:
				root.legs_statemachine.travel("stand")
			if Input.is_action_just_pressed("jump"):
				if root.jumps_made < root.max_jumps:
					_jump()
				if root.jumps_made >= root.max_jumps:
					root.jump_buffer_timer.start()
					root.buffered_jump = true
	else:
		if root.is_on_floor():
			exit_state("stand")
			return

	# State animation
	if root.coyote_timer.is_stopped():
		root.legs_statemachine.travel("fall")

	# Movement
	root.snap_vector = Vector2.ZERO
	root.velocity.x = lerp(root.velocity.x, root.speed * _get_x_input(), root.accel)

	# Gravity
	_apply_gravity(delta)
