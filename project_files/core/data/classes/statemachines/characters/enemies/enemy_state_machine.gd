class_name GameEnemyStateMachine
extends GameStateMachine


@export var root : CharacterBody2D


func _enter_state() -> void:
	if DEBUG:
		print("Entering State: ", current_state.name)
	# Give the new state a reference to this statemachine script
	current_state.state_machine = self
	current_state.root = root
	current_state.enter_state()
