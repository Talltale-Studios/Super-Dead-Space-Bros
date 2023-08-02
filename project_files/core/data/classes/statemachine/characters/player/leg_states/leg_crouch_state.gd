class_name PlayerLegCrouchState
extends PlayerLegState

func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		root.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		root.legs_sprite.flip_h = true
	
	# State switching
	if Input.is_action_just_released("down"):
		exit("stand")
		return
	if not root.is_on_floor():
		exit("fall")
		return
	
	# State animation
	root.legs_statemachine.travel("crouch")
	
	# Movement
	root.snap_vector = Vector2.DOWN
	root.velocity.x = lerp(root.velocity.x, 0.0, root.fric)
	
	# Gravity
	_apply_gravity(delta)
