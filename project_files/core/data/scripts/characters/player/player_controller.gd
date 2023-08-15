extends GameKinematicPlayer


var legs_statemachine : AnimationNodeStateMachinePlayback


func _physics_process(_delta):
	legs_statemachine = legs_anim_tree["parameters/playback"]
	
	_aim()
	if Input.is_action_pressed("shoot"):
		var weaponflash_statemachine : AnimationNodeStateMachinePlayback = weaponflash_anim_tree["parameters/playback"]
		weaponflash_statemachine.travel("shoot")
	
	match environment:
		ENVIRONMENTS.SURFACE:
			_set_gravity_environment("surface")
			_set_jump_vel_cut_environment("surface")
			_set_velocity_clamp_environment("surface")
			if is_on_floor():
				_set_accel_environment("surface_grounded")
				_set_fric_environment("surface_grounded")
			else:
				_set_accel_environment("surface_airborne")
				_set_fric_environment("surface_airborne")
		ENVIRONMENTS.UNDERWATER:
			_set_gravity_environment("underwater")
			_set_jump_vel_cut_environment("underwater")
			_set_velocity_clamp_environment("underwater")
			if is_on_floor():
				_set_accel_environment("underwater_grounded")
				_set_fric_environment("underwater_grounded")
			else:
				_set_accel_environment("underwater_airborne")
				_set_fric_environment("underwater_airborne")
		ENVIRONMENTS.SPACE:
			_set_gravity_environment("space")
			_set_jump_vel_cut_environment("space")
			_set_velocity_clamp_environment("space")
			if is_on_floor():
				_set_accel_environment("space_grounded")
				_set_fric_environment("space_grounded")
			else:
				_set_accel_environment("space_airborne")
				_set_fric_environment("space_airborne")
	
	move_and_slide()


func _input(event):
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= jump_velocity_cut


func _on_jump_buffer_timer_timeout():
	buffered_jump = false
