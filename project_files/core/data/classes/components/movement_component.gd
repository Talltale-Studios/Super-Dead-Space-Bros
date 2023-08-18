class_name GameMovementComponent
extends Node


signal jumped
signal knockback_received(direction: Vector2)
signal gravity_changed(enabled: bool)
signal inverted_gravity(inverted: bool)


@export_group("Speed")
## The max speed this character can reach
@export var max_speed: int
## This value makes smoother the time it takes to reach maximum speed  
@export var acceleration: float
@export var friction: float
