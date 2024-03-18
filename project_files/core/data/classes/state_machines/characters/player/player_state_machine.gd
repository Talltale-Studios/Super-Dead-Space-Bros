class_name GamePlayerStateMachine
extends GameCharacterStateMachine


func change_state(new_state : String) -> void:
	state_history.append(current_state.name)
	current_state = get_node("PlayerLeg" + new_state.to_pascal_case() + "State")
	_enter_state()
