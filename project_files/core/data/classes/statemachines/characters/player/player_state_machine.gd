class_name GamePlayerStateMachine
extends GameStateMachine


@export var root : GameKinematicPlayer


func change_state(new_state : String) -> void:
	history.append(current_state.name)
	current_state = get_node("PlayerLeg" + new_state.to_pascal_case() + "State")
	_enter_state()
