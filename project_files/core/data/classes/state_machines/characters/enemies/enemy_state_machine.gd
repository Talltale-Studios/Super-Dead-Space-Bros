class_name GameEnemyStateMachine
extends GameCharacterStateMachine


func _enter_state() -> void:
	if DEBUG:
		print("Entering State: ", current_state.name)
	# Give the new state a reference to this statemachine script
	current_state.state_machine = self
	current_state.actor = actor
	current_state.enter_state()
