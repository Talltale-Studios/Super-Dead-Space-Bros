class_name GameCharacterState
extends GameState


var actor: PhysicsBody2D


func enter_state() -> void:
	actor = state_machine.actor
