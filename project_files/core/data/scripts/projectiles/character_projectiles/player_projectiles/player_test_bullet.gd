extends GameKinematicPlayerProjectile


var can_move: bool = true


@onready var anim_player = $AnimationPlayer


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(rotation)
	if can_move:
		velocity = direction * speed
		set_velocity(velocity)
		move_and_slide()
		velocity = velocity
	
	if position.distance_to(spawner.global_position) > 2 * ProjectSettings.get_setting("display/window/size/viewport_width") or position.distance_to(spawner.global_position) > 2 * ProjectSettings.get_setting("display/window/size/viewport_height"):
		anim_player.play("despawn")


func _despawn() -> void:
	queue_free()


func _on_Area2D_body_entered(_body: Node) -> void:
	can_move = false
	anim_player.play("despawn")
