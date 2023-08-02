class_name PlayerLegJumpState
extends PlayerLegState


func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		root.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		root.legs_sprite.flip_h = true
	
	# Jumping and state switching
	if root.can_jump:
		if root.is_on_floor() or not root.coyote_timer.is_stopped():
			if not root.has_jumped:
				root.coyote_timer.stop()
				_jump()
				root.has_jumped = true
			else:
				root.has_jumped = false
				root.jumps_made = 0
				exit("stand")
				return
		else:
			if root.velocity.y > 0:
				exit("fall")
				return
			if Input.is_action_just_pressed("jump"):
				if root.jumps_made < root.max_jumps:
					_jump()
	else:
		if root.velocity.y > 0:
			exit("fall")
			return
		else:
			exit("stand")
			return
	
	# State animation
	root.legs_statemachine.travel("jump")
	
	# Movement
	root.snap_vector = Vector2.ZERO
	root.velocity.x = lerp(root.velocity.x, root.speed * _get_x_input(), root.accel)
	
	# Gravity
	_apply_gravity(delta)
