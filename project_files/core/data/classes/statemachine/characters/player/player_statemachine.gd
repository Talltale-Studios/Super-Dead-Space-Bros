class_name PlayerStateMachine
extends FiniteStateMachine


@export var root : GamePlayer


func change_to(new_state : String) -> void:
	history.append(state.name)
	state = get_node("PlayerLeg" + new_state.to_pascal_case() + "State")
	_enter_state()
