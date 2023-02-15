extends GamePlayer


func _physics_process(delta):
	_aim()
	
	if Input.is_action_pressed("shoot"):
		var weaponflash_statemachine : AnimationNodeStateMachinePlayback = weaponflash_anim_tree["parameters/playback"]
		weaponflash_statemachine.travel("shoot")
	
	match environment:
		ENVIRONMENTS.SURFACE:
			_set_gravity("surface")
			if is_on_floor():
				_set_accel("surface_grounded")
				_set_fric("surface_grounded")
			else:
				_set_accel("surface_airborne")
				_set_fric("surface_airborne")
		ENVIRONMENTS.UNDERWATER:
			_set_gravity("underwater")
			if is_on_floor():
				_set_accel("underwater_grounded")
				_set_fric("underwater_grounded")
			else:
				_set_accel("underwater_afloat")
				_set_fric("underwater_afloat")
		ENVIRONMENTS.SPACE:
			_set_gravity("space")
			if is_on_floor():
				_set_accel("space_grounded")
				_set_fric("space_grounded")
			else:
				_set_accel("space_afloat")
				_set_fric("space_afloat")
	
	_state_handler(delta)
	
	if _get_x_input() > 0:
		legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		legs_sprite.flip_h = true
	
	velocity = move_and_slide_with_snap(velocity, snap_vector, up_direction, stop_on_slope, max_slides, deg2rad(floor_max_angle), infinite_inertia)


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
				leg_state = LEG_STATES.FALL
			
			# State animation
			legs_statemachine.travel("stand")
			
			# Movement
			snap_vector = Vector2.DOWN
			velocity.x = lerp(velocity.x, 0, fric)
			
			# Gravity
			velocity.y += gravity * delta
		
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
			velocity.x = lerp(velocity.x, 0, fric)
			
			# Gravity
			velocity.y += gravity * delta
		
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
				leg_state = LEG_STATES.FALL
			
			# State animation
			legs_statemachine.travel("run")
			
			# Movement
			snap_vector = Vector2.DOWN
			velocity.x = lerp(velocity.x, speed * _get_x_input(), accel)
			
			# Gravity
			velocity.y += gravity * delta
		
		LEG_STATES.JUMP:
			# Jumping and state switching
			if can_jump:
				if is_on_floor():
					if not has_jumped:
						_jump()
						has_jumped = true
					else:
						is_jumping = false
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
			velocity.y += gravity * delta
		
		LEG_STATES.FALL:
			# Jumping and state switching
			if can_jump:
				if is_on_floor():
					is_jumping = false
					has_jumped = false
					jumps_made = 0
					leg_state = LEG_STATES.STAND
				else:
					if Input.is_action_just_pressed("jump"):
						if jumps_made < max_jumps:
							_jump()
			else:
				if is_on_floor():
					leg_state = LEG_STATES.STAND
			
			# State animation
			legs_statemachine.travel("fall")
			
			# Movement
			snap_vector = Vector2.ZERO
			velocity.x = lerp(velocity.x, speed * _get_x_input(), accel)
			
			# Gravity
			velocity.y += gravity * delta
		
	# Torso States Handling
