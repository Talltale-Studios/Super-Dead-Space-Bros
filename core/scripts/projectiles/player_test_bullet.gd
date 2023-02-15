extends GamePlayerProjectile


var can_move : bool = true


onready var anim_player = $AnimationPlayer


func _physics_process(delta: float) -> void:
	var direction : Vector2 = Vector2.RIGHT.rotated(rotation)
	if can_move:
		velocity = direction * speed
		velocity = move_and_slide(velocity)
	
	if position.distance_to(spawner.global_position) > 2 * ProjectSettings.get_setting("display/window/size/width") or position.distance_to(spawner.global_position) > 2 * ProjectSettings.get_setting("display/window/size/height"):
		anim_player.play("despawn")
	
	

func _despawn() -> void:
	queue_free()


func _on_Area2D_body_entered(body: Node) -> void:
	can_move = false
	anim_player.play("despawn")
