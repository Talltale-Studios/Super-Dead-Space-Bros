extends GamePlayer


func _physics_process(delta):
	_aim()
	if Input.is_action_pressed("shoot"):
		var weaponflash_statemachine : AnimationNodeStateMachinePlayback = weaponflash_anim_tree["parameters/playback"]
		weaponflash_statemachine.travel("shoot")
	
	match environment:
		ENVIRONMENTS.SURFACE:
			_set_gravity_environment("surface")
			_set_velocity_clamp_environment("surface")
			if is_on_floor():
				_set_accel_environment("surface_grounded")
				_set_fric_environment("surface_grounded")
			else:
				_set_accel_environment("surface_airborne")
				_set_fric_environment("surface_airborne")
		ENVIRONMENTS.UNDERWATER:
			_set_gravity_environment("underwater")
			_set_velocity_clamp_environment("underwater")
			if is_on_floor():
				_set_accel_environment("underwater_grounded")
				_set_fric_environment("underwater_grounded")
			else:
				_set_accel_environment("underwater_airborne")
				_set_fric_environment("underwater_airborne")
		ENVIRONMENTS.SPACE:
			_set_gravity_environment("space")
			_set_velocity_clamp_environment("space")
			if is_on_floor():
				_set_accel_environment("space_grounded")
				_set_fric_environment("space_grounded")
			else:
				_set_accel_environment("space_airborne")
				_set_fric_environment("space_airborne")
	
	_state_handler(delta)
	
	if _get_x_input() > 0:
		legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		legs_sprite.flip_h = true
	
	move_and_slide()


func _state_handler(delta):
	var legs_statemachine : AnimationNodeStateMachinePlayback = legs_anim_tree["parameters/playback"]
	
	# Leg States Handling
	match leg_state:
		LEG_STATES.STAND:
			# State switching
			if not is_zero_approx(_get_x_input()):
				leg_state = LEG_STATES.RUN
			if Input.is_action_just_pressed("jump"):
				leg_state = LEG_STATES.JUMP
			if is_on_floor() and Input.is_action_just_pressed("down"):
				leg_state = LEG_STATES.CROUCH
			if not is_on_floor():
				_apply_coyote_time()
				leg_state = LEG_STATES.FALL
			
			# State animation
			legs_statemachine.travel("stand")
			
			# Movement
			snap_vector = Vector2.DOWN
			velocity.x = lerp(velocity.x, 0.0, fric)
			
			# Gravity
			_apply_gravity(delta)
			
		LEG_STATES.CROUCH:
			# State switching
			if Input.is_action_just_released("down"):
				leg_state = LEG_STATES.STAND
			if not is_on_floor():
				leg_state = LEG_STATES.FALL
			
			# State animation
			legs_statemachine.travel("crouch")
			
			# Movement
			snap_vector = Vector2.DOWN
			velocity.x = lerp(velocity.x, 0.0, fric)
			
			# Gravity
			_apply_gravity(delta)
			
		LEG_STATES.CLIMB:
			pass
		
		LEG_STATES.RUN:
			# State switching
			if is_zero_approx(_get_x_input()):
				leg_state = LEG_STATES.STAND
			if Input.is_action_just_pressed("jump"):
				leg_state = LEG_STATES.JUMP
			if is_on_floor() and Input.is_action_just_pressed("down"):
				leg_state = LEG_STATES.CROUCH
			if not is_on_floor():
				_apply_coyote_time()
				leg_state = LEG_STATES.FALL
			
			# State animation
			legs_statemachine.travel("run")
			
			# Movement
			snap_vector = Vector2.DOWN
			velocity.x = lerp(velocity.x, speed * _get_x_input(), accel)
			
			# Gravity
			_apply_gravity(delta)
			
		LEG_STATES.JUMP:
			# Jumping and state switching
			if can_jump:
				if is_on_floor() or not coyote_timer.is_stopped():
					if not has_jumped:
						coyote_timer.stop()
						_jump()
						has_jumped = true
					else:
						has_jumped = false
						jumps_made = 0
						leg_state = LEG_STATES.STAND
				else:
					if velocity.y > 0:
						leg_state = LEG_STATES.FALL
					if Input.is_action_just_pressed("jump"):
						if jumps_made < max_jumps:
							_jump()
			else:
				if velocity.y > 0:
					leg_state = LEG_STATES.FALL
				else:
					leg_state = LEG_STATES.STAND
			
			# State animation
			legs_statemachine.travel("jump")
			
			# Movement
			snap_vector = Vector2.ZERO
			velocity.x = lerp(velocity.x, speed * _get_x_input(), accel)
			
			# Gravity
			_apply_gravity(delta)
			
		LEG_STATES.FALL:
			# Jumping and state switching
			if can_jump:
				if is_on_floor():
					had_coyote_time = false
					has_jumped = false
					jumps_made = 0
					if buffered_jump:
						buffered_jump = false
						leg_state = LEG_STATES.JUMP
					else:
						leg_state = LEG_STATES.STAND
				else:
					if not is_zero_approx(_get_x_input()):
						legs_statemachine.travel("run")
					else:
						legs_statemachine.travel("stand")
					if Input.is_action_just_pressed("jump"):
						if jumps_made < max_jumps:
							_jump()
						if jumps_made >= max_jumps:
							jump_buffer_timer.start()
							buffered_jump = true
			else:
				if is_on_floor():
					leg_state = LEG_STATES.STAND
			
			# State animation
			if coyote_timer.is_stopped():
				legs_statemachine.travel("fall")
			
			# Movement
			snap_vector = Vector2.ZERO
			velocity.x = lerp(velocity.x, speed * _get_x_input(), accel)
			
			# Gravity
			_apply_gravity(delta)
			
	# Torso States Handling


func _input(event):
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= 0.5


func _on_jump_buffer_timer_timeout():
	buffered_jump = false
