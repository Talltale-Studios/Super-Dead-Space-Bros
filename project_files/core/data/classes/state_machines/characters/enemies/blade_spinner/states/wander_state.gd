class_name GameBladeSpinnerWanderState
extends GameBladeSpinnerState


var direction : Vector2 = Vector2.RIGHT
var wall_detection_distance : float = 9
var clockwise : bool = true


func physics_process(_delta: float) -> void:
	actor.wall_detector.force_raycast_update()
	if actor.wall_detector.is_colliding():
		if clockwise:
			direction = direction.rotated(deg_to_rad(90))
		elif not clockwise:
			direction = direction.rotated(deg_to_rad(-90))
		actor.wall_detector.target_position = direction * wall_detection_distance
	actor.velocity = actor.speed * direction
