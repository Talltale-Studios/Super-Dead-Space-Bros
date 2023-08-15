class_name GamePlayerLegStandState
extends GamePlayerLegState


func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		root.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		root.legs_sprite.flip_h = true
	
	# State switching
	if not is_zero_approx(_get_x_input()):
		exit_state("run")
		return
	if Input.is_action_just_pressed("jump"):
		exit_state("jump")
		return
	if root.is_on_floor() and Input.is_action_just_pressed("down"):
		exit_state("crouch")
		return
	if not root.is_on_floor():
		_apply_coyote_time()
		exit_state("fall")
		return
	
	# State animation
	root.legs_statemachine.travel("stand")
	
	# Movement
	root.snap_vector = Vector2.DOWN
	root.velocity.x = lerp(root.velocity.x, 0.0, root.fric)
	
	# Gravity
	_apply_gravity(delta)
