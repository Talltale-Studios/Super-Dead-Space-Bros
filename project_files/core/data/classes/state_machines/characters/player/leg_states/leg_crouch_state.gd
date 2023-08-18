class_name GamePlayerLegCrouchState
extends GamePlayerLegState

func physics_process(delta: float) -> void:
	# Flip Sprite
	if _get_x_input() > 0:
		actor.legs_sprite.flip_h = false
	elif _get_x_input() < 0:
		actor.legs_sprite.flip_h = true
	
	# State switching
	if Input.is_action_just_released("down"):
		transition_to("stand")
		return
	if not actor.is_on_floor():
		transition_to("fall")
		return
	
	# State animation
	actor.legs_statemachine.travel("crouch")
	
	# Movement
	actor.snap_vector = Vector2.DOWN
	actor.velocity.x = lerp(actor.velocity.x, 0.0, actor.fric)
	
	# Gravity
	_apply_gravity(delta)
